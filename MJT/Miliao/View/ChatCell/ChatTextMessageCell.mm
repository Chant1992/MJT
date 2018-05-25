//
//  ChatTextMessageCell.m
//  MJT_APP
//
//  Created by olymtech on 2017/8/29.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "ChatTextMessageCell.h"
#import "GJCFCoreTextContentView.h"
#import "GJGCChatContentEmojiParser.h"
#import "UIImage+Image.h"
#import "AttributedTool.h"
#import "OLYMMessageObject.h"
#import "GJGCChatFriendCellStyle.h"
#import "AttributedTool.h"
#import "MLLinkLabel.h"

@interface ChatTextMessageCell()<MLLinkLabelDelegate>


@property (nonatomic,strong) MLLinkLabel *contentLabel;

@property (nonatomic,assign)CGFloat contentInnerMargin;

//复制到剪贴板
@property (nonatomic,copy)NSString *contentCopyString;



@end


@implementation ChatTextMessageCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])
    {
        self.contentInnerMargin = 10.f;
        
        [self createSubViews];
    }
    return self;
}

/* 虚方法 */
- (void)setContentModel:(OLYMMessageObject *)contentModel
{
    [super setContentModel:contentModel];
    
    self.isGroupChat = contentModel.isGroup;
    self.contentCopyString = contentModel.content;
    
    NSMutableAttributedString *attrString = GJCFNSCacheGetValue(contentModel.content);
    if (!attrString)
    {
        attrString = [AttributedTool emojiExchangeContent:contentModel.content];
        NSDictionary *attributeDict = @{NSFontAttributeName:[UIFont systemFontOfSize:17.0]};
        [attrString addAttributes:attributeDict range:NSMakeRange(0, attrString.length)];
        GJCFNSCacheSet(contentModel.content, attrString);
    }
    self.contentLabel.attributedText = attrString;

    CGFloat bubbleToBordMargin = 56.0f;
    CGFloat maxTextContentWidth = GJCFSystemScreenWidth - bubbleToBordMargin - 40 - 3 - self.contentInnerMargin/2.0 - 13 - 2*self.contentInnerMargin;
    CGSize baseSize = CGSizeMake(maxTextContentWidth, MAXFLOAT);
    CGSize textSize = [attrString boundingRectWithSize:baseSize options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;

    self.contentSize = textSize;
    self.contentLabel.gjcf_size = textSize;

    if(self.isFromSelf || ([self.contentModel.toUserId isEqualToString:olym_UserCenter.userId] && [self.contentModel.fromUserId isEqualToString:olym_UserCenter.userId]))
    {
        self.contentLabel.textColor = [UIColor whiteColor];
    }else
    {
        self.contentLabel.textColor = [UIColor blackColor];
    }
    
    CGFloat textHeight = self.contentLabel.gjcf_height + 2 * self.contentInnerMargin;
    textHeight = MAX(textHeight, 40);
    self.bubbleBackImageView.gjcf_height = textHeight;
    self.bubbleBackImageView.gjcf_width = self.contentLabel.gjcf_width + 2*self.contentInnerMargin + self.contentInnerMargin/2.0;
    
    if (self.isFromSelf) {
        self.contentLabel.gjcf_right = self.bubbleBackImageView.gjcf_width - self.contentInnerMargin/2.0 - self.contentInnerMargin;
    }else{
        self.contentLabel.gjcf_left = self.contentInnerMargin + self.contentInnerMargin/2.0;
    }
    
    [self adjustLayout];
    self.contentLabel.gjcf_centerY = self.bubbleBackImageView.gjcf_height/2;
}


- (CGFloat)heightForContentModel:(OLYMMessageObject *)contentModel
{
    return [super heightForContentModel:contentModel];
    
    if(contentModel.contentHeight > 0){
        
    }else{
        /*
         contentModel.contentSize = self.contentSize;
         contentModel.contentHeight = [super heightForContentModel:contentModel] + contentModel.contentSize.height + self.cellMargin;
         */
    }
    
    return contentModel.contentHeight;
}

- (void)didClickLink:(MLLink*)link linkText:(NSString*)linkText linkLabel:(MLLinkLabel*)linkLabel
{
    if (link.linkType == MLLinkTypeURL ) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(chatCellDidTapLink:)]) {
            [self.delegate chatCellDidTapLink:linkText];
        }
    }else if(link.linkType == MLLinkTypePhoneNumber){
        if (self.delegate && [self.delegate respondsToSelector:@selector(chatCellDidTapPhoneNumber:)]) {
            [self.delegate chatCellDidTapPhoneNumber:linkText];
        }
    }

}
- (void)didLongPressLink:(MLLink*)link linkText:(NSString*)linkText linkLabel:(MLLinkLabel*)linkLabel{
    [self didClickLink:link linkText:linkText linkLabel:linkLabel];
}


#pragma mark 《$ ---------------- createSuperViews ---------------- $》
- (void)createSubViews {
   
    [self.bubbleBackImageView addSubview:self.contentLabel];
}


#pragma mark - Property

-(MLLinkLabel *)contentLabel{
    if(!_contentLabel){
        _contentLabel = [[MLLinkLabel alloc] init];
        _contentLabel.numberOfLines = 0;
        _contentLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _contentLabel.dataDetectorTypes = MLDataDetectorTypeURL | MLDataDetectorTypePhoneNumber;
        CGFloat bubbleToBordMargin = 56.0f;
        CGFloat maxTextContentWidth = GJCFSystemScreenWidth - bubbleToBordMargin - 40 - 3 - self.contentInnerMargin/2.0 - 13 - 2*self.contentInnerMargin;
        _contentLabel.gjcf_width = maxTextContentWidth;
        _contentLabel.gjcf_height = 20;
        _contentLabel.gjcf_top = self.contentInnerMargin;
        _contentLabel.delegate = self;
        /*
         CGFloat bubbleToBordMargin = 56.0f;
         CGFloat maxTextContentWidth = GJCFSystemScreenWidth - bubbleToBordMargin - 40 - 3 - self.contentInnerMargin/2.0 - 13 - 2*self.contentInnerMargin;
        
        _contentLabel = [[GJCFCoreTextContentView alloc]init];
        [_contentLabel appendImageTag:[GJGCChatFriendCellStyle imageTag]];
        _contentLabel.gjcf_left = self.contentInnerMargin;
        _contentLabel.gjcf_width = maxTextContentWidth;
        _contentLabel.gjcf_height = 23;
        _contentLabel.backgroundColor = [UIColor clearColor];
        [_contentLabel setTextColor:black_color];
        _contentLabel.contentBaseWidth = _contentLabel.gjcf_width;
        _contentLabel.contentBaseHeight = _contentLabel.gjcf_height;
        _contentLabel.userInteractionEnabled = YES;
         */
        
    }
    return _contentLabel;
}



@end
