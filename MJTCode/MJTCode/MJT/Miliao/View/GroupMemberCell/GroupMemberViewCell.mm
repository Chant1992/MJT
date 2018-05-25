//
//  GroupMemberViewCell.m
//  MJT_APP
//
//  Created by olymtech on 2017/9/14.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "GroupMemberViewCell.h"
#import "UIView+Layer.h"
#import "OLYMUserObject.h"
@interface GroupMemberViewCell ()

@property (nonatomic,copy) NSString *headImage;

@end

@implementation GroupMemberViewCell

-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        
        [self _creatSubview];
        
    }
    
    return self;
}

#pragma mark <------------------- _creatSubview ------------------->
- (void)_creatSubview{
    
    [self.contentView addSubview:self.checkView];
    [self.contentView addSubview:self.iconView];
    [self.contentView addSubview:self.nickNameLabel];
    
    WeakSelf(ws);
    
    [self.checkView mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.left.mas_equalTo(ws.contentView).offset(10);
        make.centerY.mas_equalTo(ws.mas_centerY);
#if MJTDEV
        make.width.height.mas_equalTo(22);
#else
        make.width.height.mas_equalTo(20);
#endif
    }];
    
    [self.iconView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(ws.checkView.mas_right).offset(10);
        make.centerY.mas_equalTo(ws.mas_centerY);
        make.width.height.mas_equalTo(50);
    }];
    
    [_nickNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(ws.iconView.mas_right).offset(10);
        make.centerY.mas_equalTo(ws.contentView.mas_centerY);
        make.right.mas_equalTo(ws.contentView.mas_right).offset(-10);
        make.height.mas_equalTo(30);
    }];
    
}

#pragma mark <------------------- getter/setter ------------------->

-(void)setUserObj:(OLYMUserObject *)userObj{
    
    _userObj = userObj;
    
//    if(_userObj.userRemarkname && ![_userObj.userRemarkname isEqualToString:@""]){
//        self.nickNameLabel.text = _userObj.userRemarkname;
//    }else{
    OLYMUserObject *user = [OLYMUserObject fetchFriendByUserId:userObj.userId withDomain:FULL_DOMAIN(olym_UserCenter.userDomain)];
    
    if (user == nil) {
        
        user = userObj;
    }
    self.nickNameLabel.text = [user getDisplayName];
//    }
    //如果userHead没有url 就重新拼接一个（搜索好友的时候都没有userHead）
    NSString *userHeader = nil;
    if(userObj.userHead){
        userHeader = userObj.userHead;
    }else{
        userHeader = [HeaderImageUtils getHeaderImageUrl:userObj.userId withDomain:userObj.domain];
    }
#if MJTDEV
    [self.iconView setImageUrl:userHeader withDefault:@"defaultheadv3"];
#else
    [self.iconView setImageUrl:userHeader withDefault:@"default_head"];
#endif
    if(userObj.isCanNotCheck){
        [self.checkView setImage:GJCFQuickImage(@"check")];
    }else{
#if MJTDEV
        if(userObj.isCheck){
            [self.checkView setImage:GJCFQuickImage(@"cell_check")];
        }else{
            [self.checkView setImage:GJCFQuickImage(@"cell_uncheck")];
        }
#else
        if(userObj.isCheck){
            [self.checkView setImage:GJCFQuickImage(@"check_lock_select")];
        }else{
            [self.checkView setImage:GJCFQuickImage(@"check_lock_unselect")];
        }
#endif
    }
    
    
}

-(UIImageView *)checkView{
    
    if (!_checkView) {
        _checkView = [[UIImageView alloc]initWithFrame:CGRectZero];
        _checkView.contentMode = UIViewContentModeScaleToFill;
//        [_checkView setLayerCornerRadius:10 borderWidth:0 borderColor:nil];
    }
    
    return _checkView;
}

-(UIImageView *)iconView{
    
    if (!_iconView) {
        _iconView = [[UIImageView alloc]initWithFrame:CGRectZero];
        [_iconView setLayerCornerRadius:25 borderWidth:0 borderColor:nil];
    }
    
    return _iconView;
}

-(UILabel *)nickNameLabel{
    
    if (!_nickNameLabel) {
        
        _nickNameLabel = [[UILabel alloc]initWithFrame:CGRectZero];
        
        _nickNameLabel.font = [UIFont systemFontOfSize:16];
        _nickNameLabel.textAlignment = NSTextAlignmentLeft;
        _nickNameLabel.textColor = [UIColor blackColor];
        _nickNameLabel.text =_T(@"昵称");
    }
    
    return _nickNameLabel;
}


@end
