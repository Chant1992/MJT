//
//  GroupMemberModel.h
//  MJT_APP
//
//  Created by olymtech on 2017/9/14.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "OLYMListViewModel.h"
@class OLYMRoomDataObject;
#define User_Id_Parameter_Key @"group_user_id"
#define User_Room_Id_Parameter_Key @"group_user_room_id"
#define User_Array_Parameter_Key @"group_user_array"

@class OLYMUserObject;
typedef NS_ENUM (NSUInteger, PersonSelectType) {
    
    groupPersonSelectTypeNew,//建群
    groupPersonSelectTypeInvite,//加人入群
    groupPersonSelectTypeDelete,//踢人出群
    groupPersonSelectTypeSilence //禁言
    
};


@interface GroupMemberModel : OLYMListViewModel

@property (nonatomic, strong) NSArray *memberArray; //当前群组人员

@property (nonatomic, strong) NSMutableArray *friendArray; //建群，加人入群所用

@property (nonatomic, strong) NSMutableArray *groupMemberArray; //禁言 踢人出群所用

@property (nonatomic, assign) PersonSelectType type;

/* 搜索状态下保存的原来数组 */
@property(nonatomic,strong) NSMutableArray* previousArray;
@property(nonatomic,readonly) NSMutableArray* allContacts;

@property (nonatomic, strong) RACCommand *createNewRoomCommond;
@property (nonatomic, strong) RACCommand *invateMemberCommond; //邀请人加群
@property (nonatomic, strong) RACCommand *deleteMemberCommond; //踢人出群
@property (nonatomic, strong) RACCommand *silenceMemberCommond; //禁言
@property (nonatomic, strong) RACSubject *membersCountRACSubject; //计数显示

@property (nonatomic, strong) RACSubject *organizationlistSubject; //计数显示

-(instancetype)initWithType:(PersonSelectType)type;

-(instancetype)initWithType:(PersonSelectType)type withMemberArray:(NSArray *)array;

-(OLYMUserObject *)userObjAtIndexPath:(NSIndexPath *)indexPath;

-(OLYMRoomDataObject *)getSumbitRoomDataObject;

-(void)createNewRoom; //建新群


/**
 禁言

 @param roomObject 群组
 @param time 禁言时间
 */
- (void)slienceRoomUser:(OLYMRoomDataObject *)roomObject timeInterval:(NSTimeInterval)time;


@end
