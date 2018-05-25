//
//  SearchChatRecordDetailCell.m
//  MJT_APP
//
//  Created by Donny on 2017/12/18.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "SearchChatRecordDetailCell.h"
#import "UIView+Layer.h"
#import "HeaderImageUtils.h"
#import "OLYMMessageObject.h"
#import "AttributedTool.h"

@interface SearchChatRecordDetailCell ()

@property(nonatomic,strong) UIImageView *headerImageView;
@property(nonatomic,strong) UILabel *nickNameLabel;
@property(nonatomic,strong) UILabel *contentLabel;
@property(nonatomic,strong) UILabel *timeLabel;
@end

@implementation SearchChatRecordDetailCell

- (void)setContentModel:(OLYMMessageObject *)contentModel
{
    //这里设置用户头像
    self.nickNameLabel.text = contentModel.fromUserName;

    NSString *domain = contentModel.domain;
    if ([domain containsString:@"muc."])
    {
        domain = [domain stringByReplacingOccurrencesOfString:@"muc." withString:@""];
    }
    
    NSString *userHeaderUrl =  [HeaderImageUtils getHeaderImageUrl:contentModel.fromUserId withDomain:domain];
    
    [self.headerImageView setImageUrl:userHeaderUrl withDefault:@"chat_groups_header"];
    NSMutableAttributedString *attrString = GJCFNSCacheGetValue(contentModel.content);
    if (!attrString)
    {
        attrString = [AttributedTool emojiExchangeContent:contentModel.content];
        NSDictionary *attributeDict = @{NSFontAttributeName:[UIFont systemFontOfSize:17.0]};
        [attrString addAttributes:attributeDict range:NSMakeRange(0, attrString.length)];
        GJCFNSCacheSet(contentModel.content, attrString);
    }
    self.contentLabel.attributedText = attrString;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        
        [self createSubViews];
    }
    
    return self;
}

-(void)createSubViews{
    
    [self.contentView addSubview:self.headerImageView];
    [self.contentView addSubview:self.nickNameLabel];
    [self.contentView addSubview:self.contentLabel];
    [self.contentView addSubview:self.timeLabel];
    
    WeakSelf(ws);
    
    [_headerImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.top.mas_equalTo(ws.contentView.mas_top).offset(8);
        make.left.mas_equalTo(ws.contentView.mas_left).offset(10);
        make.width.height.mas_equalTo(50);
    }];
    
    
    [_nickNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.top.mas_equalTo(ws.headerImageView.mas_top).offset(2);
        make.left.mas_equalTo(ws.headerImageView.mas_right).offset(10);
        make.right.mas_equalTo(ws.timeLabel.mas_left).offset(-5);
        make.height.mas_equalTo(20);
    }];
    [_contentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.mas_equalTo(ws.headerImageView.mas_bottom).offset(-2);
        make.left.mas_equalTo(ws.nickNameLabel.mas_left);
        make.right.mas_equalTo(ws.contentView).offset(-5);
        make.height.mas_greaterThanOrEqualTo(20);
    }];
    [_timeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.top.mas_equalTo(ws.headerImageView.mas_top).offset(2);
        make.right.mas_equalTo(ws.contentView.mas_right).offset(-5);
        make.height.mas_equalTo(20);
        make.width.mas_equalTo(70);
    }];

    
}

#pragma mark 《$ ---------------- Getter ---------------- $》

- (UIImageView *)headerImageView {
    
    if (!_headerImageView) {
        
        _headerImageView = [[UIImageView alloc] init];
        [_headerImageView setLayerCornerRadius:25 borderWidth:0 borderColor:nil];
    }
    
    return _headerImageView;
}

- (UILabel *)nickNameLabel {
    
    if (!_nickNameLabel) {
        _nickNameLabel = [[UILabel alloc] init];
    }
    
    return _nickNameLabel;
}

- (UILabel *)contentLabel {
    
    if (!_contentLabel) {
        
        _contentLabel = [[UILabel alloc] init];
        _contentLabel.font = [UIFont systemFontOfSize:14];
        _contentLabel.textColor = kSubContentColor;
    }
    
    return _contentLabel;
}
- (UILabel *)timeLabel {
    
    if (!_timeLabel) {
        _timeLabel = [[UILabel alloc] init];
        [_timeLabel setTextAlignment:NSTextAlignmentRight];
        _timeLabel.font = [UIFont systemFontOfSize:14];
        _timeLabel.textColor = kSubContentColor;
    }
    
    return _timeLabel;
}

@end
