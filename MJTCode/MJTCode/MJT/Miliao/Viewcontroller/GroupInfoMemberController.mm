//
//  GroupInfoMemberController.m
//  MJT_APP
//
//  Created by Donny on 2017/11/9.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "GroupInfoMemberController.h"
#import "GroupInfoModel.h"
#import "GroupInfoMemberView.h"
#import "GroupMemberViewController.h"
#import "OLYMUserObject.h"
#import "UserInfoViewController.h"
#import "SearchFriendInfoViewController.h"
#import "PersonalDataViewController.h"

@interface GroupInfoMemberController()

@property (nonatomic, strong) GroupInfoMemberView *groupInfoMemberView;


@end

@implementation GroupInfoMemberController

-(void)olym_layoutNavigation{
    [self setStrNavTitle:_T(@"群成员")];
}

-(void)olym_addSubviews{
    self.definesPresentationContext = YES;

    [self.view addSubview:self.groupInfoMemberView];
    WeakSelf(ws);
    [self.groupInfoMemberView mas_makeConstraints:^(MASConstraintMaker *make) {
        if (@available(iOS 11, *)) {
            make.edges.mas_equalTo(ws.view.safeAreaInsets);
        }else{
            make.edges.mas_equalTo(ws.view);
        }
    }];

}

-(void)olym_bindViewModel{
    @weakify(self);
     //TODO:进入邀请进群组
    [self.groupInfoModel.groupInviteSubject subscribeNext:^(NSString* roomOwnerId) {
        @strongify(self);
        
        GroupMemberViewController *groupMemberViewController = [[GroupMemberViewController alloc]initWithArray:self.groupInfoModel.groupMemberArray withType:groupPersonSelectTypeInvite];
        
        [groupMemberViewController setCurrentRoomId:self.userObject.roomId];
        [groupMemberViewController setCurrentRoomJid:self.userObject.userId];
        [groupMemberViewController setCurrentRoomOwnerId:roomOwnerId];
        
        OLYMBaseNavigationController *nav = [[OLYMBaseNavigationController alloc]initWithRootViewController:groupMemberViewController];
        [self presentViewController:nav animated:YES completion:nil];
    }];
    
    //TODO:进入踢出群组
    [self.groupInfoModel.groupDeleteSubject subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        
        GroupMemberViewController *groupMemberViewController = [[GroupMemberViewController alloc]initWithArray:self.groupInfoModel.groupMemberArray withType:groupPersonSelectTypeDelete];
        
        [groupMemberViewController setCurrentRoomId:self.userObject.roomId];
        [groupMemberViewController setCurrentRoomJid:self.userObject.userId];
        [groupMemberViewController setCurrentChatUser:self.userObject];
        OLYMBaseNavigationController *nav = [[OLYMBaseNavigationController alloc]initWithRootViewController:groupMemberViewController];
        [self presentViewController:nav animated:YES completion:nil];
    }];
    
    
    //查看群用户信息
    [[self.groupInfoModel.getUserInfoSubject takeUntil:self.rac_willDeallocSignal]subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        OLYMUserObject *user = x;
        int status = user.status;
        
        if ([user.userId isEqualToString:olym_UserCenter.userId]) {
            
            //自己
            PersonalDataViewController *vc = [[PersonalDataViewController alloc]init];
            [self.navigationController pushViewController:vc animated:YES];
            
            return ;
        }
        
        if (status == 0)
        {
            //陌生人
            SearchFriendInfoViewController *vc = [[SearchFriendInfoViewController alloc]init];
            vc.userObj = user;
            [self.navigationController pushViewController:vc animated:YES];
        }else if (status == friend_status_friend || status == friend_status_black)
        {
            //好友
            UserInfoViewController *vc = [[UserInfoViewController alloc]init];
            vc.userObject = user;
            [self.navigationController pushViewController:vc animated:YES];
        }else
        {
            //待验证
            SearchFriendInfoViewController *vc = [[SearchFriendInfoViewController alloc]init];
            vc.userObj = user;
            [self.navigationController pushViewController:vc animated:YES];
        }
    }];
}


- (GroupInfoMemberView *)groupInfoMemberView
{
    if(!_groupInfoMemberView)
    {
        _groupInfoMemberView = [[GroupInfoMemberView alloc]initWithViewModel:self.groupInfoModel];
        _groupInfoMemberView.roomDataObject = self.roomDataObject;
    }
    return _groupInfoMemberView;
}


@end
