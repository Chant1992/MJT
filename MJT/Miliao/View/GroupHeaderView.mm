//
//  GroupHeaderView.m
//  MJT_APP
//
//  Created by olymtech on 2017/9/13.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "GroupHeaderView.h"
#import "OLYMUserObject.h"

@interface GroupHeaderView()

@property (nonatomic, strong) UIButton *deleteButton;
@property (nonatomic, strong) UIButton *banButton;

@end

@implementation GroupHeaderView

- (instancetype)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        [self createSubViews];
        
        @weakify(self);
        [[self.deleteButton rac_signalForControlEvents:UIControlEventTouchUpInside]subscribeNext:^(__kindof UIControl * _Nullable x) {
            @strongify(self);
            if(self.delegate && [self respondsToSelector:@selector(groupHeaderViewDidTapDelete:)])
            {
                [self.delegate groupHeaderViewDidTapDelete:self];
            }
        }];
        [[self.banButton rac_signalForControlEvents:UIControlEventTouchUpInside]subscribeNext:^(__kindof UIControl * _Nullable x) {
            @strongify(self);
            if(self.delegate && [self respondsToSelector:@selector(groupHeaderViewDidTapBan:)])
            {
                [self.delegate groupHeaderViewDidTapBan:self];
            }
        }];
    }
    
    return self;
}

- (void)createSubViews {
    
    [self addSubview:self.headerView];
    [self addSubview:self.nickNameLabel];
    [self.headerView addSubview:self.deleteButton];
    [self.headerView addSubview:self.banButton];
    
    WeakSelf(ws);
    
    [self.headerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(ws.mas_top).offset(5);
        make.width.height.mas_equalTo(ws.frame.size.width - 10);
        make.centerX.mas_equalTo(ws.mas_centerX);
    }];
    
    [self.nickNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.left.right.mas_equalTo(ws);
        make.height.mas_equalTo(15);
        make.top.mas_equalTo(ws.headerView.mas_bottom).offset(5);
        
    }];
    
    [self.deleteButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.mas_equalTo(0);
        make.width.height.mas_equalTo(20);
    }];
    
    [self.banButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.mas_equalTo(0);
        make.width.height.mas_equalTo(20);
    }];
    
    
}
-(void)setUserObject:(OLYMUserObject *)userObject{
    if(!userObject){
        return;
    }
    
    _userObject = userObject;
    
    NSString *userHeader = nil;
    if(userObject.userHead){
        userHeader = userObject.userHead;
    }else{
        NSString *domain = userObject.domain;
        if (!domain) {
            domain = FULL_DOMAIN(olym_UserCenter.userDomain);
        }
        if ([domain hasPrefix:@"muc."])
        {
            domain = [domain stringByReplacingOccurrencesOfString:@"muc." withString:@""];
        }
        userHeader = [HeaderImageUtils getHeaderImageUrl:userObject.userId withDomain:domain];
    }
#if MJTDEV
    [self.headerView setImageUrl:userHeader withDefault:@"defaultheadv3"];
#else
    [self.headerView setImageUrl:userHeader withDefault:@"default_head"];
#endif
    self.headerView.layer.masksToBounds=YES;
    
    OLYMUserObject *user = [OLYMUserObject fetchFriendByUserId:userObject.userId withDomain:FULL_DOMAIN(olym_UserCenter.userDomain)];
    
    if (user == nil) {
        
        user = userObject;
        NSLog(@"user == nil ,user = userObject,user.telephone : ",user.telephone);
    }
    
    if ([user.userId isEqualToString:olym_UserCenter.userId]) {
        
        [self.nickNameLabel setText:userObject.userNickname];
        return;
    }
    
    [self.nickNameLabel setText:[user getDisplayName]];
}

- (void)setShowBan:(BOOL)showBan
{
    _showBan = showBan;
    self.deleteButton.hidden = YES;
    
    self.banButton.hidden = !showBan;
}

- (void)setShowDelete:(BOOL)showDelete
{
    _showDelete = showDelete;
    self.banButton.hidden = YES;
    
    self.deleteButton.hidden = !showDelete;
}


- (void)layoutSubviews
{
    [super layoutSubviews];
    self.headerView.layer.cornerRadius=self.headerView.frame.size.width/2;
}


#pragma mark - Property

- (UILabel *)nickNameLabel {
    
    if (!_nickNameLabel) {
        _nickNameLabel = [[UILabel alloc] init];
        _nickNameLabel.textAlignment = NSTextAlignmentCenter;
        _nickNameLabel.textColor = OLYMHEXCOLOR(0x545454);
    }
    
    return _nickNameLabel;
}
- (UIImageView *)headerView {
    
    if (!_headerView) {
        _headerView = [[UIImageView alloc] initWithFrame:CGRectZero];
        
    }
    
    return _headerView;
}

- (UIButton *)deleteButton
{
    if (!_deleteButton)
    {
        _deleteButton = [[UIButton alloc]init];
        UIImage *deleteImage = [UIImage imageNamed:@"redDelete_message_info"];
        [_deleteButton setImage:deleteImage forState:UIControlStateNormal];
        [_deleteButton setImage:deleteImage forState:UIControlStateHighlighted];
        _deleteButton.hidden = YES;
    }
    return _deleteButton;
}


- (UIButton *)banButton
{
    if (!_banButton)
    {
        _banButton = [[UIButton alloc]init];
        UIImage *deleteImage = [UIImage imageNamed:@"redDelete_message_info"];
        [_banButton setImage:deleteImage forState:UIControlStateNormal];
        [_banButton setImage:deleteImage forState:UIControlStateHighlighted];
        _banButton.hidden = YES;
    }
    return _banButton;
}
@end

