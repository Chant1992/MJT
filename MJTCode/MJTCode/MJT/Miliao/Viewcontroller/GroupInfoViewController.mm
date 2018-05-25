//
//  GroupInfoViewController.m
//  MJT_APP
//
//  Created by olymtech on 2017/9/13.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "GroupInfoViewController.h"
#import "GroupInfoView.h"
#import "GroupInfoModel.h"
#import "OLYMUserObject.h"
#import "ModifyNameViewController.h"
#import "GroupMemberViewController.h"
#import "ChatFileViewController.h"
#import "SearchFriendInfoViewController.h"
#import "UserInfoViewController.h"
#import "GroupInfoMemberController.h"
#import "FriendInformationViewController.h"
#import "ChatFile2ViewController.h"
#import "SearchChatRecordController.h"
#import "PersonalDataViewController.h"

@interface GroupInfoViewController ()

@property(strong,nonatomic) GroupInfoView *groupInfoView;

@property(retain,nonatomic) GroupInfoModel *groupInfoModel;

@end

@implementation GroupInfoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}


-(void)olym_layoutNavigation{
    [self setStrNavTitle:_T(@"群组信息")];
}

-(void)olym_addSubviews{
    [self.view addSubview:self.groupInfoView];
    WeakSelf(ws);
    [self.groupInfoView mas_makeConstraints:^(MASConstraintMaker *make) {
        if (@available(iOS 11, *)) {
            make.edges.mas_equalTo(ws.view.safeAreaInsets);
        }else{
            make.edges.mas_equalTo(ws.view);
        }
    }];
    
}
-(void)olym_bindViewModel{
    @weakify(self);
    //TODO:进入改群聊名称页面
    [self.groupInfoModel.groupNameChangeSubject subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        ModifyNameViewController *modifyNameViewController = [[ModifyNameViewController alloc]init];
        modifyNameViewController.type = ModifyRoomNameType;
        [modifyNameViewController setNickName:self.userObject.userNickname];
        
        modifyNameViewController.userNickNameBlock = ^(NSString *nickName){
            
            @strongify(self);
            
            [olym_IMRequest updateRoomInfo:self.userObject.roomId withRoomName:nickName Success:^(NSDictionary *dic) {
                
                self.userObject.userNickname = nickName;
                
                [self.userObject updateUserName];
                
                [self.groupInfoModel.groupInfoRefreshSubject sendNext:nil];
                
            } Failure:^(NSString *error) {
                
                [SVProgressHUD showInfoWithStatus:_T(@"修改群聊名称失败")];
                
            }];
        };
        
        [self.navigationController pushViewController:modifyNameViewController animated:YES];
    }];
    
    //TODO:进入群公告页面
    [self.groupInfoModel.groupNoteChangeSubject subscribeNext:^(NSString*  roomNote) {
        @strongify(self);
        
        ModifyNameViewController *modifyNameViewController = [[ModifyNameViewController alloc]init];
        modifyNameViewController.type = ModifyRoomNoteType;
        [modifyNameViewController setNickName:roomNote];
        
        modifyNameViewController.userNickNameBlock = ^(NSString *note){
            
            @strongify(self);
            
            [olym_IMRequest updateRoomNotify:self.userObject.roomId withNote:note Success:^(NSDictionary *dic) {
                
                self.userObject.userDescription = note;
                
                [self.groupInfoModel.groupInfoRefreshSubject sendNext:nil];
                
            } Failure:^(NSString *error) {
                
                [SVProgressHUD showInfoWithStatus:_T(@"修改群聊公告失败")];
                
            }];
        };
        
        [self.navigationController pushViewController:modifyNameViewController animated:YES];
        
    }];
    //进入查看群聊公告
    [self.groupInfoModel.groupNoteWatchSubject subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        
        ModifyNameViewController *modifyNameViewController = [[ModifyNameViewController alloc]init];
        [modifyNameViewController setNickName:x];
        modifyNameViewController.type = ModifyRoomNoteDisableType;
        [self.navigationController pushViewController:modifyNameViewController animated:YES];

    }];
    
    //TODO:进入聊天文件页面
    [self.groupInfoModel.groupFileSubject subscribeNext:^(id  _Nullable x) {
        @strongify(self);
#if MJTDEV
        ChatFile2ViewController *chatFileViewController = [[ChatFile2ViewController alloc]init];
        chatFileViewController.currentChatUser = self.userObject;
        chatFileViewController.operationFileType = ReadFile;
        [self.navigationController pushViewController:chatFileViewController animated:YES];
#else
        ChatFileViewController *chatFileViewController = [[ChatFileViewController alloc]init];
        chatFileViewController.currentChatUser = self.userObject;
        chatFileViewController.operationFileType = ReadFile;
        [self.navigationController pushViewController:chatFileViewController animated:YES];
#endif
    }];
    
    //TODO:进入修改我的昵称页面
    [self.groupInfoModel.groupMyNickNameSubject subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        
        ModifyNameViewController *modifyNameViewController = [[ModifyNameViewController alloc]init];
        modifyNameViewController.nickName = self.userObject.userRemarkname? self.userObject.userRemarkname : olym_UserCenter.userName;
        
        modifyNameViewController.userNickNameBlock = ^(NSString *nickName){
            
            @strongify(self);
            
            [olym_IMRequest setRoomMember:self.userObject.roomId memberId:olym_UserCenter.userId memberName:nickName Success:^(NSDictionary *dic) {
                
                self.userObject.userRemarkname = nickName;
                [self.userObject updateUserName];
                [self.groupInfoModel.groupInfoRefreshSubject sendNext:nil];
                
            } Failure:^(NSString *error) {
                
                 [SVProgressHUD showInfoWithStatus:_T(@"修改我的群昵称失败")];
            }];
        };
        
        [self.navigationController pushViewController:modifyNameViewController animated:YES];
        
    }];
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
    
    //TODO:禁言
    [self.groupInfoModel.groupSilenceSubject subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        
        GroupMemberViewController *groupMemberViewController = [[GroupMemberViewController alloc]initWithArray:self.groupInfoModel.groupMemberArray withType:groupPersonSelectTypeSilence];
        
        [groupMemberViewController setCurrentRoomId:self.userObject.roomId];
        
        OLYMBaseNavigationController *nav = [[OLYMBaseNavigationController alloc]initWithRootViewController:groupMemberViewController];
        [self presentViewController:nav animated:YES completion:nil];
    }];
    
    //TODO:删除并退出群聊
    [self.groupInfoModel.groupDelRoomSubject subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        
        [self.navigationController popToRootViewControllerAnimated:YES];
    }];
    //TODO:退出群聊
    [self.groupInfoModel.groupQuitRoomSubject subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        
        [self.navigationController popToRootViewControllerAnimated:YES];
    }];
    //TODO:查看群用户信息
    [[self.groupInfoModel.getUserInfoSubject takeUntil:self.rac_willDeallocSignal]subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        OLYMUserObject *user = x;
        int status = user.status;
        
#if ThirdlyVersion
        if ([user.userId isEqualToString:olym_UserCenter.userId]) {
            
            PersonalDataViewController *vc = [[PersonalDataViewController alloc]init];
            [self.navigationController pushViewController:vc animated:YES];
            return;
        }
        if ([user.userId isEqualToString:olym_UserCenter.userId]) {
            
            PersonalDataViewController *mineVc = [[PersonalDataViewController alloc]init];
            
            [self.navigationController pushViewController:mineVc animated:YES];
            return ;
        }
        
        FriendInformationViewController *vc = [[FriendInformationViewController alloc]init];
        vc.userObj = user;
        [self.navigationController pushViewController:vc animated:YES];
        
#else
        
#if XYT
        
        OLYMUserObject *userObject = [OLYMUserObject fetchFriendByUserId:user.userId withDomain:user.domain];
        
        if (userObject.userId == nil) {
            
            //陌生人
            SearchFriendInfoViewController *vc = [[SearchFriendInfoViewController alloc]init];
            vc.userObj = user;
            [self.navigationController pushViewController:vc animated:YES];
        }else{
            
            UserInfoViewController *vc = [[UserInfoViewController alloc]init];
            vc.userObject = [OLYMUserObject fetchFriendByUserId:user.userId withDomain:user.domain];
            [self.navigationController pushViewController:vc animated:YES];
        }

#else
        
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
#endif
        

#endif
       
    }];
    //TODO:查看更多群成员
    [self.groupInfoModel.showMoreMemberSubject subscribeNext:^(NSDictionary *  info) {
        @strongify(self);
        OLYMUserObject *userObj = [info objectForKey:@"user"];
        GroupInfoModel *infoModel = [info objectForKey:@"members"];
        OLYMRoomDataObject *roomData = [info objectForKey:@"roomData"];
        GroupInfoMemberController *controller = [[GroupInfoMemberController alloc]init];
        controller.userObject = userObj;
        controller.groupInfoModel = infoModel;
        controller.roomDataObject = roomData;
        [self.navigationController pushViewController:controller animated:YES];
    }];
    [self.groupInfoModel.chatRecordClickSubject subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        SearchChatRecordController *controller = [[SearchChatRecordController alloc]init];
        controller.currentChatUser = self.userObject;
        [self.navigationController pushViewController:controller animated:YES];
    }];
}



-(GroupInfoView *)groupInfoView{
    if(!_groupInfoView){
        _groupInfoView = [[GroupInfoView alloc]initWithViewModel:self.groupInfoModel];
        [_groupInfoView setUserObject:self.userObject];
    }
    return _groupInfoView;
}

-(GroupInfoModel *)groupInfoModel{
    if(!_groupInfoModel){
        _groupInfoModel = [[GroupInfoModel alloc]init];
    }
    return _groupInfoModel;
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
