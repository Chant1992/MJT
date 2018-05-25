//
//  GroupInfoModel.h
//  MJT_APP
//
//  Created by olymtech on 2017/9/13.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "OLYMListViewModel.h"
@class OLYMUserObject;
@interface GroupInfoModel : OLYMListViewModel

@property (nonatomic, strong) NSMutableArray *groupMemberArray;

@property (nonatomic, strong) RACCommand *groupInfoCommand;
@property (nonatomic, strong) RACSubject *groupInfoSubject;


@property (nonatomic, strong) RACSubject *groupDelRoomSubject;
@property (nonatomic, strong) RACCommand *groupDelRoomCommond;

@property (nonatomic, strong) RACCommand *groupQuitRoomSlienceRoomCommond;
@property (nonatomic, strong) RACSubject *groupQuitRoomSubject;
@property (nonatomic, strong) RACCommand *groupQuitRoomCommond;


@property (nonatomic, strong) RACSubject *groupInfoRefreshSubject;


@property (nonatomic, strong) RACSubject *groupNameChangeSubject;
@property (nonatomic, strong) RACSubject *groupNoteChangeSubject;
@property (nonatomic, strong) RACSubject *groupNoteWatchSubject;
@property (nonatomic, strong) RACSubject *groupFileSubject;
@property (nonatomic, strong) RACSubject *groupMyNickNameSubject;
@property (nonatomic, strong) RACSubject *groupInviteSubject;
@property (nonatomic, strong) RACSubject *groupDeleteSubject;
@property (nonatomic, strong) RACSubject *groupSilenceSubject;

@property (nonatomic, strong) RACSubject *getUserInfoSubject;

@property (nonatomic, strong) RACSubject *showMoreMemberSubject;

@property (nonatomic, strong) RACSubject *chatRecordClickSubject;

-(void)destroyRoom:(NSString *)userId; //删除群

/**
 get userInfo , listen getUserInfoSubject to get result
 
 @param userId userid
 @param domain user domain
 @param roomId room id
 */
- (void)getUserInfoByUserId:(NSString *)userId domain:(NSString *)domain roomId:(NSString *)roomId;



/**
 set chat user dont disturb

 @param userObj current chat user
 @param dontDisturb disturb or not
 */
- (void)setChatUser:(OLYMUserObject *)userObj dontDisturb:(BOOL)dontDisturb;


- (NSArray *)filterMembersBy:(NSString *)keyword;

@end
