//
//  ChatCardMessageCell.m
//  MJT_APP
//
//  Created by Donny on 2017/9/6.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "ChatCardMessageCell.h"
#import "UIImage+Image.h"
#import "OrganizationModel.h"
#import "OLYMUserObject.h"

#define WIDTH_SCALE [UIScreen mainScreen].bounds.size.width / 375.0
#define kCardWidth (260 * WIDTH_SCALE - 100)

@interface ChatCardMessageCell ()

// 名片头像
@property (nonatomic, strong) UIImageView *iconNode;
// 姓名
@property (nonatomic, strong) UILabel *nameLabel;
// 手机号
@property (nonatomic, strong) UILabel *phoneLabel;
// 说明
@property (nonatomic, strong) UILabel *cardLabel;
// 分割线
@property (nonatomic, strong) UIView *sepLineView;


@end

@implementation ChatCardMessageCell


- (void)setContentModel:(OLYMMessageObject *)contentModel
{
    [super setContentModel:contentModel];
    
    [self adjustLayout];
    [self changeLayout];
    
    NSArray *array = [contentModel.content componentsSeparatedByString:@":"];
    
    OLYMUserObject *userObj = [[OLYMUserObject alloc]init];
    
    _nameLabel.text = array[0];
    if (Organization) {

        userObj.userNickname = array[0];
        userObj.telephone = array[2];
        userObj.domain = array[1];
        _nameLabel.text = [userObj getDisplayName];
    }
    
    if (array.count > 2) {
        
        OrganizationUserModel *userModel = [OrganizationUserModel fetchUserWithTelephone:array[2]];
        
        if (userModel.hidden == YES) {
            
            //保密
            _phoneLabel.text = _T(@"保密");
        }else{
            
            _phoneLabel.text = array[2];
        }
        
    }
    NSString *domain = contentModel.domain;
    if ([domain containsString:@"muc."])
    {
        domain = [domain stringByReplacingOccurrencesOfString:@"muc." withString:@""];
    }
    NSString *userHeaderUrl =  [HeaderImageUtils getHeaderImageUrl:contentModel.objectId withDomain:domain];
    [self.iconNode setImageUrl:userHeaderUrl withDefault:@"chat_groups_header"];

    
    // 更换聊天气泡
    UIEdgeInsets insets = UIEdgeInsetsMake(25, 10, 10, 10);
    if (self.isFromSelf)
    {
        UIImage *bubbleImg = [UIImage imageWithSpecialStretch:insets imageStr:@"bubbly_card_chat_right"];
        UIImage *bubbleImgHigh = [UIImage imageWithSpecialStretch:insets imageStr:@"bubbly_card_chat_right_pre"];
        
        self.bubbleBackImageView.image = bubbleImg;
        self.bubbleBackImageView.highlightedImage = bubbleImgHigh;
    }else
    {
        UIImage *bubbleImg = [UIImage imageWithSpecialStretch:insets imageStr:@"bubbly_card_chat_left"];
        UIImage *bubbleImgHigh = [UIImage imageWithSpecialStretch:insets imageStr:@"bubbly_card_chat_left_pre"];
        self.bubbleBackImageView.image = bubbleImg;
        self.bubbleBackImageView.highlightedImage = bubbleImgHigh;
    }
    
}

- (void)changeLayout
{
    WeakSelf(ws);
    
    self.contentSize = CGSizeMake(260*WIDTH_SCALE, 100);
    self.bubbleBackImageView.gjcf_height = 100;
    
    [self.bubbleBackImageView mas_updateConstraints:^(MASConstraintMaker *make) {
        
        make.width.mas_equalTo(260*WIDTH_SCALE);
        make.height.mas_equalTo(100);
    }];

    if (self.isFromSelf) {
        
        [_iconNode mas_remakeConstraints:^(MASConstraintMaker *make) {
            
            make.top.equalTo(ws.bubbleBackImageView).offset(13);
            make.left.mas_equalTo(ws.bubbleBackImageView).offset(13);
            make.width.height.mas_equalTo(48);
        }];
        [_nameLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            
            make.left.equalTo(ws.iconNode.mas_right).offset(13);
            make.top.equalTo(ws.iconNode).offset(5);
            make.width.mas_equalTo(kCardWidth);
        }];
        [_phoneLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            
            make.left.equalTo(ws.iconNode.mas_right).offset(13);
            make.bottom.equalTo(ws.iconNode).offset(-5);
            make.width.mas_equalTo(kCardWidth);
        }];
        [_sepLineView mas_remakeConstraints:^(MASConstraintMaker *make) {
            
            make.top.equalTo(ws.iconNode.mas_bottom).offset(13);
            make.left.equalTo(ws.bubbleBackImageView);
            make.right.equalTo(ws.bubbleBackImageView).offset(-7);
            make.height.mas_equalTo(1);
        }];
        [_cardLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            
            make.top.equalTo(ws.sepLineView.mas_bottom);
            make.left.equalTo(ws.bubbleBackImageView).offset(10);
            make.bottom.equalTo(ws.bubbleBackImageView.mas_bottom);
        }];
        
    } else {
        
        [_iconNode mas_remakeConstraints:^(MASConstraintMaker *make) {
            
            make.top.equalTo(ws.bubbleBackImageView).offset(13);
            make.left.mas_equalTo(ws.bubbleBackImageView).offset(18);
            make.width.height.mas_equalTo(45);
        }];
        [_nameLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            
            make.left.equalTo(ws.iconNode.mas_right).offset(15);
            make.top.equalTo(ws.iconNode).offset(5);
            make.width.mas_equalTo(kCardWidth);
        }];
        [_phoneLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            
            make.left.equalTo(ws.iconNode.mas_right).offset(15);
            make.bottom.equalTo(ws.iconNode).offset(-3);
            make.width.mas_equalTo(kCardWidth);
        }];
        [_sepLineView mas_remakeConstraints:^(MASConstraintMaker *make) {
            
            make.top.equalTo(ws.iconNode.mas_bottom).offset(13);
            make.left.equalTo(ws.bubbleBackImageView).offset(7);
            make.right.equalTo(ws.bubbleBackImageView);
            make.height.mas_equalTo(1);
        }];
        [_cardLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            
            make.top.equalTo(ws.sepLineView.mas_bottom);
            make.left.equalTo(ws.bubbleBackImageView).offset(18);
            make.bottom.equalTo(ws.bubbleBackImageView.mas_bottom);
        }];
    }

}



#pragma mark - Init
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self createSubViews];
    }
    return self;
}


- (void)createSubViews {
    
    [self.bubbleBackImageView addSubview:self.iconNode];
    [self.bubbleBackImageView addSubview:self.nameLabel];
    [self.bubbleBackImageView addSubview:self.phoneLabel];
    [self.bubbleBackImageView addSubview:self.cardLabel];
    [self.bubbleBackImageView addSubview:self.sepLineView];
}


#pragma mark - property
- (UIImageView *)iconNode {
    
    if (!_iconNode) {
        
        _iconNode = [[UIImageView alloc] init];
    }
    
    return _iconNode;
}

- (UILabel *)nameLabel {
    
    if (!_nameLabel) {
        
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.text = @"我是姓名!";
        _nameLabel.font = [UIFont systemFontOfSize:16];
    }
    
    return _nameLabel;
}

- (UILabel *)phoneLabel {
    
    if (!_phoneLabel) {
        
        _phoneLabel = [[UILabel alloc] init];
        _phoneLabel.text = @"我是手机号!";
        _phoneLabel.textColor = OLYMHEXCOLOR(0x888888);
        _phoneLabel.font = [UIFont systemFontOfSize:14];
    }
    
    return _phoneLabel;
}

- (UILabel *)cardLabel {
    
    if (!_cardLabel) {
        
        _cardLabel = [[UILabel alloc] init];
        _cardLabel.text = _T(@"个人名片");
        _cardLabel.textColor = OLYMHEXCOLOR(0x888888);
        _cardLabel.font = [UIFont systemFontOfSize:14];
    }
    
    return _cardLabel;
}

- (UIView *)sepLineView {
    
    if (!_sepLineView) {
        
        _sepLineView = [[UIView alloc] init];
        _sepLineView.backgroundColor = OLYMHEXCOLOR(0xd0d0d0);
    }
    
    return _sepLineView;
}
@end
