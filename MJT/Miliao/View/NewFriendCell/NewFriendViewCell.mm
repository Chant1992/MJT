//
//  NewFriendViewCell.m
//  MJT_APP
//
//  Created by olymtech on 2017/9/4.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "NewFriendViewCell.h"
#import "UIView+Layer.h"
#import "OLYMNewFriendObj.h"
#import "TimeUtil.h"
#import "UIButton+IndexPath.h"

@interface NewFriendViewCell ()

@end

@implementation NewFriendViewCell

#pragma mark 《$ ---------------- LifeCycle ---------------- $》
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        
        [self createSubViews];
    }
    
    return self;
}


#pragma mark 《$ ---------------- Layout ---------------- $》
- (void)createSubViews {
    
    [self.contentView addSubview:self.photoNode];
    [self.contentView addSubview:self.titleNode];
    [self.contentView addSubview:self.timeLabel];
    [self.contentView addSubview:self.textNode];
    [self.contentView addSubview:self.replyButton];
    [self.contentView addSubview:self.acceptButton];
    [self.contentView addSubview:self.sayHiButton];
    
#if ThirdlyVersion
    
    WeakSelf(ws);
    
    [_photoNode mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(ws.contentView.mas_left).offset(10);
        make.width.height.mas_equalTo(50);
        make.centerY.mas_equalTo(ws.contentView.mas_centerY);
    }];
    
    [self.sayHiButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(ws.contentView);
        make.right.mas_equalTo(ws.contentView.mas_right).offset(-10);
        make.width.mas_equalTo(50);
        make.height.mas_equalTo(30);
    }];
    
    [_titleNode mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.top.mas_equalTo(ws.photoNode.mas_top).offset(2);
        make.right.mas_equalTo(ws.sayHiButton.mas_left);
        make.left.mas_equalTo(ws.photoNode.mas_right).offset(10);
        make.height.mas_equalTo(20);
    }];
    
    [_textNode mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.mas_equalTo(ws.photoNode.mas_bottom).offset(-2);
        make.left.mas_equalTo(ws.titleNode.mas_left);
        make.right.mas_equalTo(ws.sayHiButton.mas_left);
        make.height.mas_equalTo(20);
    }];
    
    [self.replyButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(ws.contentView);
        make.right.mas_equalTo(ws.contentView.mas_right).offset(-10);
        make.width.mas_equalTo(50);
        make.height.mas_equalTo(30);
    }];
    
//    [self.acceptButton mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.bottom.mas_equalTo(ws.replyButton.mas_bottom);
//        make.right.mas_equalTo(ws.replyButton.mas_left).offset(-10);
//        make.width.mas_equalTo(50);
//        make.height.mas_equalTo(30);
//    }];
    
    [self.acceptButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(ws.contentView);
        make.right.mas_equalTo(ws.contentView.mas_right).offset(-10);
        make.width.mas_equalTo(50);
        make.height.mas_equalTo(30);
    }];

#else
    
    WeakSelf(ws);
    
    [_photoNode mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(ws.contentView.mas_left).offset(10);
        make.width.height.mas_equalTo(50);
        make.centerY.mas_equalTo(ws.contentView.mas_centerY);
    }];
    
    [self.timeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(ws.photoNode.mas_top);
        make.right.mas_equalTo(ws.contentView.mas_right).offset(-10);
        make.width.mas_equalTo(80);
        make.height.mas_equalTo(25);
    }];
    
    
    [self.acceptButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.mas_equalTo(ws.photoNode.mas_bottom);
        make.right.mas_equalTo(ws.contentView.mas_right).offset(-10);
        make.width.mas_equalTo(30);
        make.height.mas_equalTo(25);
    }];
    
    [self.sayHiButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.mas_equalTo(ws.photoNode.mas_bottom);
        make.right.mas_equalTo(ws.contentView.mas_right).offset(-10);
        make.width.mas_equalTo(50);
        make.height.mas_equalTo(25);
    }];
    
    [self.replyButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.mas_equalTo(ws.acceptButton.mas_bottom);
        make.right.mas_equalTo(ws.acceptButton.mas_left).offset(-10);
        make.width.mas_equalTo(30);
        make.height.mas_equalTo(25);
    }];
    
    [_titleNode mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.top.mas_equalTo(ws.photoNode.mas_top).offset(2);
        make.left.mas_equalTo(ws.photoNode.mas_right).offset(15);
        make.right.mas_equalTo(ws.replyButton.mas_left).offset(-5);
        make.height.mas_equalTo(20);
    }];
    [_textNode mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.mas_equalTo(ws.photoNode.mas_bottom).offset(-2);
        make.left.mas_equalTo(ws.titleNode.mas_left);
        make.right.mas_equalTo(ws.titleNode.mas_right);
        make.height.mas_equalTo(20);
    }];
#endif
    
}

-(void)setFriendObj:(OLYMNewFriendObj *)friendObj{
    
#if ThirdlyVersion
    
    _friendObj = friendObj;
    
    [self.titleNode setText:friendObj.userNickname];
    [self.textNode setText:friendObj.content];
    [self.timeLabel setText:[TimeUtil getTimeStrStyle1:[friendObj.updateTime timeIntervalSince1970]]];
    
    NSString *userHeaderUrl =  [HeaderImageUtils getHeaderImageUrl:friendObj.userId withDomain:friendObj.domain];
    [self modifyBtnStatus];
    
#if MJTDEV
    [self.photoNode setImageUrl:userHeaderUrl withDefault:@"defaultheadv3"];
#else
    [self.photoNode setImageUrl:userHeaderUrl withDefault:@"default_head"];
#endif
    
#else
    
    _friendObj = friendObj;
    
    [self.titleNode setText:friendObj.userNickname];
    [self.textNode setText:friendObj.content];
    [self.timeLabel setText:[TimeUtil getTimeStrStyle1:[friendObj.updateTime timeIntervalSince1970]]];
    
    NSString *userHeaderUrl =  [HeaderImageUtils getHeaderImageUrl:friendObj.userId withDomain:friendObj.domain];
    
#if MJTDEV
    [self.photoNode setImageUrl:userHeaderUrl withDefault:@"defaultheadv3"];
#else
    [self.photoNode setImageUrl:userHeaderUrl withDefault:@"default_head"];
#endif

    switch (friendObj.status) {
        case friend_status_none:
        case friend_status_see:
        {
            //XMPP_TYPE_NEWSEE && !friendObj.isMysend 有回话和接受按钮
            //XMPP_TYPE_FEEDBACK && friendObj.isMysend 有回话和接受按
            //XMPP_TYPE_NEWSEE  && friendObj.isMysend 有打招呼按钮
            //XMPP_TYPE_SAYHELLO   && friendObj.isMysend 有打招呼按钮
            //XMPP_TYPE_FEEDBACK && !friendObj.isMysend 有打招呼按钮
            
            switch (friendObj.type) {
                case XMPP_TYPE_NEWSEE:
                    if(friendObj.isMysend){
                        [self showHelloBtn];
                    }else{
                        [self showAcceptAndFeedbackBtn];
                    }
                    break;
                case XMPP_TYPE_SAYHELLO:
                    if(friendObj.isMysend){
                        [self showHelloBtn];
                        
                    }else{
                        
                        [self showAcceptAndFeedbackBtn];
                    }
                    break;
                case XMPP_TYPE_FEEDBACK:
                    if(friendObj.isMysend){
                        [self showAcceptAndFeedbackBtn];
                    }else{
                        [self showHelloBtn];
                        
                    }
                    break;
                default:
                    break;
            }
        }
            break;
            
        default:
            [self.sayHiButton setHidden:YES];
            [self.acceptButton setHidden:YES];
            [self.replyButton setHidden:YES];
            break;
    }
#endif
    
}

-(void)modifyBtnStatus{
    
    switch (self.friendObj.status) {
        case friend_status_none:
        case friend_status_see:
        {
            //XMPP_TYPE_NEWSEE && !friendObj.isMysend 有回话和接受按钮
            //XMPP_TYPE_FEEDBACK && friendObj.isMysend 有回话和接受按
            //XMPP_TYPE_NEWSEE  && friendObj.isMysend 有打招呼按钮
            //XMPP_TYPE_SAYHELLO   && friendObj.isMysend 有打招呼按钮
            //XMPP_TYPE_FEEDBACK && !friendObj.isMysend 有打招呼按钮
            
            switch (self.friendObj.type) {
                case XMPP_TYPE_NEWSEE:
                    if(self.friendObj.isMysend){
                        [self showHelloBtn];
                    }else{
                        [self showAcceptAndFeedbackBtn];
                    }
                    break;
                case XMPP_TYPE_SAYHELLO:
                    if(self.friendObj.isMysend){
                        [self showHelloBtn];
                        
                    }else{
                        
                        [self showAcceptAndFeedbackBtn];
                    }
                    break;
                case XMPP_TYPE_FEEDBACK:
                    if(self.friendObj.isMysend){
                        
                        [self showAcceptAndFeedbackBtn];

                    }else{
                        
                        [self showHelloBtn];
                    }
                    break;

            }
        }
            break;
            
        case friend_status_friend:{
            
            [self.sayHiButton setTitle:@"已通过" forState:UIControlStateNormal];
            self.sayHiButton.hidden = NO;
            [self.acceptButton setHidden:YES];
            [self.replyButton setHidden:YES];
            [_sayHiButton setBackgroundImage:GJCFQuickImageByColorWithSize(clear_color, CGSizeMake(50, 30)) forState:UIControlStateNormal];
            [_sayHiButton setTitleColor:lightGray_color forState:UIControlStateNormal];
            _sayHiButton.userInteractionEnabled = NO;
        }
         break;
        default:
            [self.sayHiButton setHidden:YES];
            [self.acceptButton setHidden:YES];
            [self.replyButton setHidden:YES];
            break;
    }
    
//    if(self.friendObj.isMysend){
//
//        //待验证
//        [self.sayHiButton setTitle:_T(@"待验证") forState:UIControlStateNormal];
//    }else{
//
//        if (self.friendObj.type == XMPP_TYPE_FEEDBACK) {
//
//            [self.sayHiButton setTitle:_T(@"回复") forState:UIControlStateNormal];
//        }else{
//
//            [self.sayHiButton setTitle:_T(@"通过") forState:UIControlStateNormal];
//        }
//
//    }
//    [_sayHiButton setBackgroundImage:[UIImage imageNamed:@"login_dologin_normal"] forState:UIControlStateNormal];
//    [_sayHiButton setTitleColor:white_color forState:UIControlStateNormal];
//    _sayHiButton.userInteractionEnabled = YES;
}

-(void)showAcceptAndFeedbackBtn{
    
    [self.sayHiButton setHidden:YES];
    [self.acceptButton setHidden:NO];
    [self.replyButton setHidden:NO];
    //按钮响应事件
    [self.replyButton setTag:self.tag];
    [self.replyButton addTarget:self.buttonActionTarget action:@selector(replyAction:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.acceptButton setTag:self.tag];
    [self.acceptButton addTarget:self.buttonActionTarget action:@selector(acceptAction:) forControlEvents:UIControlEventTouchUpInside];
    
    if (ThirdlyVersion) {
        
        [self.replyButton setHidden:YES];
    }
}


-(void)showHelloBtn{
    [self.acceptButton setHidden:YES];
    [self.replyButton setHidden:YES];
    [self.sayHiButton setHidden:NO];
    [self.sayHiButton setTag:self.tag];
    [self.sayHiButton addTarget:self.buttonActionTarget action:@selector(sayHiAcction:) forControlEvents:UIControlEventTouchUpInside];
}

#pragma mark - Getter/Setter
-(void)setIndexPath:(NSIndexPath *)indexPath{
    
    _indexPath = indexPath;
    self.sayHiButton.indexPath = indexPath;
}

- (UIImageView *)photoNode {
    
    if (!_photoNode) {
        _photoNode = [[UIImageView alloc] init];
        _photoNode.image = [UIImage imageNamed:@"default_head"];
        [_photoNode setLayerCornerRadius:25 borderWidth:0 borderColor:nil];
    }
    
    return _photoNode;
}

- (UILabel *)titleNode {
    
    if (!_titleNode) {
        _titleNode = [[UILabel alloc] init];
        _titleNode.font = [UIFont systemFontOfSize:16];
    }
    
    return _titleNode;
}

- (UILabel *)textNode {
    
    if (!_textNode) {
        
        _textNode = [[UILabel alloc] init];
        [_textNode setText:_T(@"这是内容")];
        _textNode.font = [UIFont systemFontOfSize:14];
    }
    
    return _textNode;
}

-(UILabel *)timeLabel{
    if(!_timeLabel){
        _timeLabel = [[UILabel alloc] init];
        [_timeLabel setTextAlignment:NSTextAlignmentRight];
        [_timeLabel setFont:[UIFont systemFontOfSize:10.0f]];
        [_timeLabel setText:@"10:03"];
    }
    return _timeLabel;
}

-(UIButton *)replyButton{
    if(!_replyButton){
        
        _replyButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _replyButton.titleLabel.font = [UIFont systemFontOfSize:12.f];
        [_replyButton setTitle:@"回复" forState:UIControlStateNormal];
        [_replyButton setTitleColor:white_color forState:UIControlStateNormal];
        [_replyButton setTitleColor:white_color forState:UIControlStateHighlighted];
        [_replyButton setBackgroundImage:[UIImage imageNamed:@"login_dologin_normal"] forState:UIControlStateNormal];
        [_replyButton setLayerCornerRadius:5 borderWidth:0 borderColor:nil];
        [_replyButton setHidden:YES];
        
    }
    return _replyButton;
}

-(UIButton *)acceptButton{
    if(!_acceptButton){
        _acceptButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _acceptButton.titleLabel.font = [UIFont systemFontOfSize:12.f];
        
        if (ThirdlyVersion) {
            
            [_acceptButton setTitle:@"通过" forState:UIControlStateNormal];
        }else{
            
            [_acceptButton setTitle:@"接受" forState:UIControlStateNormal];
        }
        
        [_acceptButton setTitleColor:white_color forState:UIControlStateNormal];
        [_acceptButton setTitleColor:white_color forState:UIControlStateHighlighted];
        [_acceptButton setBackgroundImage:[UIImage imageNamed:@"login_dologin_normal"] forState:UIControlStateNormal];
        [_acceptButton setLayerCornerRadius:5 borderWidth:0 borderColor:nil];
        [_acceptButton setHidden:YES];
    }
    return _acceptButton;
}

-(UIButton *)sayHiButton{
    if(!_sayHiButton){
        _sayHiButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _sayHiButton.titleLabel.font = [UIFont systemFontOfSize:12.f];
        
        if (ThirdlyVersion) {
            
            [_sayHiButton setTitle:_T(@"打招呼") forState:UIControlStateNormal];
        }else{
            
            [_sayHiButton setTitle:_T(@"待验证") forState:UIControlStateNormal];
        }
        
        [_sayHiButton setTitleColor:white_color forState:UIControlStateNormal];
        [_sayHiButton setTitleColor:white_color forState:UIControlStateHighlighted];
        [_sayHiButton setBackgroundImage:[UIImage imageNamed:@"login_dologin_normal"] forState:UIControlStateNormal];
        [_sayHiButton setLayerCornerRadius:5 borderWidth:0 borderColor:nil];
    }
    return _sayHiButton;
}


@end
