//
//  GroupInfoModel.m
//  MJT_APP
//
//  Created by olymtech on 2017/9/13.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "GroupInfoModel.h"
#import "OLYMUserObject.h"
#import "OLYMRoomDataObject.h"
#import "RoomManager.h"
#import "AlertViewManager.h"

@interface GroupInfoModel()<RoomManagerDelegate>

@property (nonatomic, strong) RACCommand *getUserInfoCommand;

@end
@implementation GroupInfoModel

-(void)olym_initialize{
#if MJTDEV
    NSArray *contents = @[@[_T(@"群聊名称"), _T(@"群公告"), _T(@"成员上限")],
                          @[_T(@"聊天文件"),_T(@"查找聊天记录")],
                          @[_T(@"我的群昵称")
                            ,_T(@"消息免打扰")
                            ],
                          @[_T(@"清空聊天记录")]
                          ];
#else
    NSArray *contents = @[@[_T(@"群主"),_T(@"群聊名称"), _T(@"群公告"), _T(@"成员上限")],
                          @[_T(@"聊天文件")],
                          @[_T(@"我的群昵称"), _T(@"禁言")
#if DontDisturb
                            ,_T(@"消息免打扰")
#endif
                            ],
                          @[_T(@"清空聊天记录")]
                          ];
#endif
    [self.dataArray addObjectsFromArray:contents];
    
    
    @weakify(self);
    [self.groupInfoCommand.executionSignals.switchToLatest subscribeNext:^(NSDictionary *dic) {
        
        @strongify(self);
        [SVProgressHUD dismiss];
        
        OLYMRoomDataObject *roomDataObject = [[OLYMRoomDataObject alloc]init];
        [roomDataObject fromDictionary:dic];
        
        [self.groupMemberArray removeAllObjects];
        [self.groupMemberArray addObjectsFromArray:roomDataObject.roomMembersArray];
        
        [self.groupInfoSubject sendNext:roomDataObject];
    }];
    
    [self.groupInfoCommand.executing  subscribeNext:^(id x) {
        
        if ([x isEqualToNumber:@(YES)]) {
            
            [SVProgressHUD showWithStatus:_T(@"正在获取信息")];
        }
    }];
    
    [self.groupDelRoomCommond.executionSignals.switchToLatest subscribeNext:^(OLYMUserObject *userObjet) {
        
        @strongify(self);
        [SVProgressHUD dismiss];
        
        [self destroyRoom:userObjet.userId];
        
        [userObjet deleteUserAndMessage:YES];
        
        [self.groupDelRoomSubject sendNext:nil];
    }];
    
    [self.groupDelRoomCommond.executing  subscribeNext:^(id x) {
        
        if ([x isEqualToNumber:@(YES)]) {
            
            [SVProgressHUD showWithStatus:_T(@"正在执行")];
        }
    }];
    
    [self.groupQuitRoomCommond.executionSignals.switchToLatest subscribeNext:^(OLYMUserObject *userObjet) {
        
        @strongify(self);
        [SVProgressHUD dismiss];
    
        [userObjet deleteUserAndMessage:YES];
        
        [self.groupQuitRoomSubject sendNext:nil];
    }];
    
    [self.groupQuitRoomCommond.executing  subscribeNext:^(id x) {
        
        if ([x isEqualToNumber:@(YES)]) {
            
            [SVProgressHUD showWithStatus:_T(@"正在执行")];
        }
    }];
    
    //获取用户信息
    [self.getUserInfoCommand.executionSignals.switchToLatest subscribeNext:^(NSDictionary* dict) {
        if (dict)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD dismiss];
                NSNumber *code = [dict objectForKey:@"resultCode"];
                if (code)
                {
                    //失败
                    NSString *error;
                    if ([code integerValue] == 1030105) {
                        
                        error = _T(@"用户不存在");
                    }else if ([code integerValue] == 1030109){
                        
                        error = _T(@"您无权限查看该用户信息");
                    }
                    [AlertViewManager alertWithTitle:error];
                }else
                {
                    OLYMUserObject *userObj = [[OLYMUserObject alloc]init];
                    [userObj loadFromBusinessServerDict:dict];
                    [self.getUserInfoSubject sendNext:userObj];
                }
            });
        }else
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD showErrorWithStatus:_T(@"获取失败")];
            });
        }
    }];
    [[[self.getUserInfoCommand.executing skip:1]take:1]subscribeNext:^(NSNumber * _Nullable x) {
        if ([x isEqualToNumber:@(YES)]) {
            
            [SVProgressHUD showWithStatus:nil];
        }
    }];

}


#pragma mark-- 退群

-(void)destroyRoom:(NSString *)userId{
    if(userId){
        [[RoomManager sharedInstance] setDelegate:self];
        [[RoomManager sharedInstance] destroyRoom:userId];
    }
}

#pragma mark - 获取用户信息
- (void)getUserInfoByUserId:(NSString *)userId domain:(NSString *)domain roomId:(NSString *)roomId
{
    if (!userId || !domain) {
        return;
    }
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setObject:userId forKey:@"userId"];
    [dictionary setObject:domain forKey:@"domain"];
    if (roomId)
    {
        [dictionary setObject:roomId forKey:@"roomId"];
    }
    [self.getUserInfoCommand execute:dictionary];
}

#pragma mark - 设置消息免打扰
- (void)setChatUser:(OLYMUserObject *)userObj dontDisturb:(BOOL)dontDisturb
{
    [userObj updateDontDisturb:dontDisturb];
}

#pragma mark-- roomManager Delegate
- (void)xmppRoomDidDestroy:(NSString *)roomJid{
    
}


- (NSArray *)filterMembersBy:(NSString *)keyword
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.userNickname contains [cd] %@ || SELF.userRemarkname contains [cd]  %@",keyword,keyword];
    
    return [self.groupMemberArray filteredArrayUsingPredicate:predicate];
}

#pragma mark-- other

-(void)showError:(NSString *)error{
    [SVProgressHUD dismiss];
    if(error){
        [SVProgressHUD showInfoWithStatus:error];
    }
    
}


- (NSMutableArray *)groupMemberArray {
    
    if (!_groupMemberArray) {
        
        _groupMemberArray = [[NSMutableArray alloc] init];
        
    }
    
    return _groupMemberArray;
}

-(RACCommand *)groupInfoCommand{
    if (!_groupInfoCommand) {
        
        @weakify(self);
        
        _groupInfoCommand = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(OLYMUserObject *userObject) {
            
            @strongify(self);
            return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
                
                @strongify(self);
                __weak typeof (userObject) weakUserObject = userObject;
                [olym_IMRequest getRoomInfo:userObject.roomId Success:^(NSDictionary *dic) {
                    [subscriber sendNext:dic];
                    [subscriber sendCompleted];
                } Failure:^(NSString *error) {
                    [self showError:error];
                    [subscriber sendCompleted];
                }];
                
                return nil;
            }];
        }];
    }
    
    return _groupInfoCommand;
}


-(RACCommand *)groupDelRoomCommond{
    if (!_groupDelRoomCommond) {
        
        @weakify(self);
        
        _groupDelRoomCommond = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(OLYMUserObject *userObject) {
            
            @strongify(self);
            return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
               
                @strongify(self);
                __weak typeof (userObject) weakUserObject = userObject;
                [olym_IMRequest delRoomFromServer:userObject.roomId  Success:^(NSDictionary *dic) {
                    [subscriber sendNext:weakUserObject];
                    [subscriber sendCompleted];
                } Failure:^(NSString *error) {
                    [self showError:error];
                    [subscriber sendCompleted];
                }];
                return nil;
            }];
        }];
    }
    
    return _groupDelRoomCommond;
}

-(RACCommand *)groupQuitRoomCommond{
    if (!_groupQuitRoomCommond) {
        
        @weakify(self);
        
        _groupQuitRoomCommond = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(OLYMUserObject *userObject) {
            
            @strongify(self);
            return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
                
                @strongify(self);
                __weak typeof (userObject) weakUserObject = userObject;
                [olym_IMRequest delRoomMember:userObject.roomId memberId:olym_UserCenter.userId Success:^(NSDictionary *dic) {
                    [subscriber sendNext:weakUserObject];
                    [subscriber sendCompleted];
                } Failure:^(NSString *error) {
                    [self showError:error];
                    [subscriber sendCompleted];
                }];
                return nil;
            }];
        }];
    }
    
    return _groupQuitRoomCommond;
}

- (RACCommand *)groupQuitRoomSlienceRoomCommond
{
    if (!_groupQuitRoomSlienceRoomCommond) {
        
        @weakify(self);
        
        _groupQuitRoomSlienceRoomCommond = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(OLYMUserObject *userObject) {
            
            @strongify(self);
            return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
                
                @strongify(self);
                __weak typeof (userObject) weakUserObject = userObject;
                [olym_IMRequest delRoomMember:userObject.roomId memberId:olym_UserCenter.userId Success:^(NSDictionary *dic) {
                    [subscriber sendCompleted];
                } Failure:^(NSString *error) {
                    [subscriber sendCompleted];
                }];
                return nil;
            }];
        }];
    }
    
    return _groupQuitRoomSlienceRoomCommond;
}

- (RACCommand *)getUserInfoCommand
{
    if (!_getUserInfoCommand)
    {
        @weakify(self);
        _getUserInfoCommand = [[RACCommand alloc]initWithSignalBlock:^RACSignal * _Nonnull(NSDictionary*  infoDictionary) {
            @strongify(self);
            
            return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
                
                @strongify(self);
                //请求用户信息
                
                NSString *userId = [infoDictionary objectForKey:@"userId"];
                NSString *domain = [infoDictionary objectForKey:@"domain"];
                NSString *roomId = [infoDictionary objectForKey:@"roomId"];
                [olym_IMRequest getUserInfoByUserId:userId domain:domain roomId:roomId Success:^(NSDictionary *dic) {
                    [subscriber sendNext:dic];
                    [subscriber sendCompleted];
                } Failure:^(NSString *error) {
                    [subscriber sendNext:nil];
                    [subscriber sendCompleted];
                }];
                return nil;
                
            }];
        }];
    }
    return _getUserInfoCommand;
}

- (RACSubject *)groupInfoRefreshSubject {
    
    if (!_groupInfoRefreshSubject) {
        _groupInfoRefreshSubject = [RACSubject subject];
    }
    
    return _groupInfoRefreshSubject;
}

- (RACSubject *)groupInfoSubject {
    
    if (!_groupInfoSubject) {
        _groupInfoSubject = [RACSubject subject];
    }
    
    return _groupInfoSubject;
}

- (RACSubject *)groupNameChangeSubject {
    
    if (!_groupNameChangeSubject) {
        _groupNameChangeSubject = [RACSubject subject];
    }
    
    return _groupNameChangeSubject;
}

- (RACSubject *)groupQuitRoomSubject {
    
    if (!_groupQuitRoomSubject) {
        _groupQuitRoomSubject = [RACSubject subject];
    }
    
    return _groupQuitRoomSubject;
}

- (RACSubject *)groupNoteChangeSubject {
    
    if (!_groupNoteChangeSubject) {
        _groupNoteChangeSubject = [RACSubject subject];
    }
    
    return _groupNoteChangeSubject;
}

- (RACSubject *)groupNoteWatchSubject {
    
    if (!_groupNoteWatchSubject) {
        _groupNoteWatchSubject = [RACSubject subject];
    }
    
    return _groupNoteWatchSubject;
}


- (RACSubject *)groupFileSubject {
    
    if (!_groupFileSubject) {
        _groupFileSubject = [RACSubject subject];
    }
    
    return _groupFileSubject;
}

- (RACSubject *)groupMyNickNameSubject {
    
    if (!_groupMyNickNameSubject) {
        _groupMyNickNameSubject = [RACSubject subject];
    }
    
    return _groupMyNickNameSubject;
}

- (RACSubject *)groupInviteSubject {
    
    if (!_groupInviteSubject) {
        _groupInviteSubject = [RACSubject subject];
    }
    
    return _groupInviteSubject;
}

- (RACSubject *)groupDeleteSubject {
    
    if (!_groupDeleteSubject) {
        _groupDeleteSubject = [RACSubject subject];
    }
    
    return _groupDeleteSubject;
}


- (RACSubject *)groupSilenceSubject {
    
    if (!_groupSilenceSubject) {
        _groupSilenceSubject = [RACSubject subject];
    }
    
    return _groupSilenceSubject;
}

- (RACSubject *)groupDelRoomSubject {
    
    if (!_groupDelRoomSubject) {
        _groupDelRoomSubject = [RACSubject subject];
    }
    
    return _groupDelRoomSubject;
}

- (RACSubject *)getUserInfoSubject
{
    if (!_getUserInfoSubject)
    {
        _getUserInfoSubject = [RACSubject subject];
    }
    return _getUserInfoSubject;
}

- (RACSubject *)showMoreMemberSubject
{
    if(!_showMoreMemberSubject)
    {
        _showMoreMemberSubject = [RACSubject subject];
    }
    return _showMoreMemberSubject;
}

- (RACSubject *)chatRecordClickSubject;
{
    if (!_chatRecordClickSubject)
    {
        _chatRecordClickSubject = [RACSubject subject];
    }
    return _chatRecordClickSubject;
}
@end
