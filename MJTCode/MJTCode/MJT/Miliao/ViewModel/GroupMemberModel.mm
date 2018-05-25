//
//  GroupMemberModel.m
//  MJT_APP
//
//  Created by olymtech on 2017/9/14.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "GroupMemberModel.h"
#import "RoomManager.h"
#import "OLYMUserObject.h"
#import "NSString+PinYin.h"
#import "OLYMRoomObject.h"
#import "OLYMRoomDataObject.h"
#import "AlertViewManager.h"
#import "OLYMUserObject+Pinyin.h"
#import "OrganizationModel.h"
#import "OrganizationUtility.h"

@interface GroupMemberModel ()<RoomManagerDelegate>
{
    RoomManager *roomManager;
}

@property(nonatomic,strong) NSMutableArray* allContacts;
//刚创建群时，邀请人入群
@property(nonatomic,strong) RACCommand *createInviteUserCommand;

@end
@implementation GroupMemberModel

-(instancetype)initWithType:(PersonSelectType)type{
    self = [super init];
    if(self){
        roomManager = [RoomManager sharedInstance];
        self.type = type;
        [self initView];
    }
    return self;
}

-(instancetype)initWithType:(PersonSelectType)type withMemberArray:(NSArray *)array{
    self = [super init];
    if(self){
        roomManager = [RoomManager sharedInstance];
        self.type = type;
        self.memberArray = [NSMutableArray arrayWithArray:array];
        [self initView];
    }
    return self;
}

-(void)olym_initialize{
   
    
    @weakify(self);
    ////////////////////邀请人入群//////////////////////
    [self.invateMemberCommond.executionSignals.switchToLatest subscribeNext:^(id x) {
        
        @strongify(self);
        
        [SVProgressHUD dismiss];
        
        [self.refreshEndSubject sendNext:x];
    }];
    
    [self.invateMemberCommond.executing subscribeNext:^(id x) {
        
        if ([x isEqualToNumber:@(YES)]) {
    
            [SVProgressHUD showWithStatus:_T(@"正在邀请")];
        }
    }];
    
    
    ////////////////////踢人出群//////////////////////
    [self.deleteMemberCommond.executionSignals.switchToLatest subscribeNext:^(id x) {
        
        @strongify(self);
        
        [SVProgressHUD dismiss];
        
        NSDictionary *dict = x;
        OLYMUserObject *roomUser = [dict objectForKey:@"roomUser"];
        [self.refreshEndSubject sendNext:roomUser];
    }];
    
    [self.deleteMemberCommond.executing subscribeNext:^(id x) {
        
        if ([x isEqualToNumber:@(YES)]) {
            
            [SVProgressHUD showWithStatus:_T(@"正在移除")];
        }
    }];
    
    ////////////////////建新群//////////////////////
    [self.createNewRoomCommond.executionSignals.switchToLatest subscribeNext:^(NSDictionary *newRoomDic) {
        
        @strongify(self);
        if (newRoomDic)
        {
            //保存新建的房间
            OLYMUserObject *user = [[OLYMUserObject alloc]init];
            [user fromRoomDictionary:newRoomDic];
            
            if (![user haveTheUser]){
                if (![user.userId isEqualToString:@""] && user.userId && ![user.domain isEqualToString:@""] && user.domain)
                {
                    [user insertRoom];
                }
            }else{
                [user updateRoom];
            }
            
            OLYMRoomDataObject *roomDataObject = [self getSumbitRoomDataObject];
            [roomDataObject setRoomJid:user.userId];
            [roomDataObject setRoomId:user.roomId];
            [roomDataObject setUserId:olym_UserCenter.userId];
            [roomDataObject setName:user.userNickname];
            [roomDataObject setCreateTime:[[NSDate date]timeIntervalSince1970]];
            
            //开始邀请成员加入房间
            [self.createInviteUserCommand execute:@{@"room":roomDataObject,@"roomUser":user}];
            
        }else
        {
            [SVProgressHUD showErrorWithStatus:_T(@"新建群组失败")];
        }
    }];
    
    [self.createInviteUserCommand.executionSignals.switchToLatest subscribeNext:^(id x) {
        
        @strongify(self);
        
        [SVProgressHUD dismiss];
        
        [self.refreshEndSubject sendNext:x];
    }];
    
    [self.createInviteUserCommand.executing subscribeNext:^(id x) {
        
        if ([x isEqualToNumber:@(YES)]) {
            
            [SVProgressHUD showWithStatus:_T(@"正在邀请")];
        }
    }];

    
    //禁言
    [self.silenceMemberCommond.executionSignals.switchToLatest subscribeNext:^(id  _Nullable x) {
        if ([x isKindOfClass:[NSString class]])
        {
            //网络错误
            [SVProgressHUD showErrorWithStatus:x];
        }else
        {
            //禁言成功
            NSInteger time = [x intValue];
            if (time > 0)
            {
                [SVProgressHUD showSuccessWithStatus:_T(@"禁言成功")];
            }else
            {
                [SVProgressHUD showSuccessWithStatus:_T(@"取消禁言成功")];
            }
            [self.refreshEndSubject sendNext:x];
        }
    }];
}


-(void)initView{
    NSArray *tempArray = nil;
    NSMutableArray *allArray = @[].mutableCopy;
    switch (self.type) {
        case groupPersonSelectTypeNew:
           
            [allArray addObjectsFromArray:[OLYMUserObject fetchAllTureFriends]];
//            if (Organization) {
//
//                NSArray *organizationArray = [OrganizationUserModel fetchAllOrganizationUser];
//                [allArray addObjectsFromArray:organizationArray];
//            }
            
            tempArray = allArray;
            
            break;
        case groupPersonSelectTypeInvite:
            
            [allArray addObjectsFromArray:[OLYMUserObject fetchAllTureFriends]];
//            if (Organization) {
//                
//                NSArray *organizationArray = [OrganizationUserModel fetchAllOrganizationUser];
//                [allArray addObjectsFromArray:organizationArray];
//            }
            
            tempArray = allArray;
            
            for(OLYMUserObject *friendObj in tempArray){
                for(OLYMUserObject *memberObj in self.memberArray){
                    if([friendObj.userId isEqualToString:memberObj.userId]){
                        [friendObj setIsCanNotCheck:YES];
                        continue;
                    }
                }
            }
            
            break;
        case groupPersonSelectTypeDelete:
        case groupPersonSelectTypeSilence:
            tempArray = [NSArray arrayWithArray:self.memberArray];
            break;
            
        default:
            break;
    }
    
    NSMutableArray *realArray = [[NSMutableArray alloc]initWithCapacity:tempArray.count];
    
    for(OLYMUserObject *friendObj in tempArray){
        if([friendObj.userId isEqualToString:olym_UserCenter.userId]){
            //把自己过滤掉，不在选择范围内
        }else{
            NSString *nickName = friendObj.userNickname;
            NSString *remarkName = friendObj.userRemarkname;
            NSString *nickNameLetters = [nickName getFirstLetters];
            NSString *remakeLetters = [remarkName getFirstLetters];
            friendObj.nameLetters = nickNameLetters;
            friendObj.remarkLetters = remakeLetters;
            
            //全部还原成为选择状态（有可能之前刚添加，所以IsCheck为YES）
            [friendObj setIsCheck:NO];
            [realArray addObject:friendObj];
        }
    }
    _allContacts = realArray;
    [self processData:realArray];
    [self.refreshUI sendNext:nil];
    
}

#pragma mark - Public
-(OLYMUserObject *)userObjAtIndexPath:(NSIndexPath *)indexPath{
    
    NSDictionary *dict = self.dataArray[indexPath.section];
    NSMutableArray *array = dict[@"content"];
    OLYMUserObject *userObj = array[indexPath.row];
    
    return userObj;
}



#pragma mark - 数据处理
-(void)processData:(NSArray *)array{
    
    [self.dataArray removeAllObjects];
    
    if (Organization && [[olym_Default objectForKey:kAPI_ORGAN_Model] boolValue] && self.type != groupPersonSelectTypeDelete) {
        
        NSMutableDictionary *myDic = [NSMutableDictionary dictionary];
        NSArray *myArray = @[@"公司通讯录"];
        NSString *firstLetter = @"";
        [myDic setObject:firstLetter forKey:@"firstLetter"];
        [myDic setObject:myArray forKey:@"content"];
        
        [self.dataArray addObject:myDic];
    }

    
    [self.dataArray addObjectsFromArray:[[NSMutableArray arrayWithArray:array] arrayWithPinYinFirstLetterFormat]];
}

#pragma mark -组装选择的数据为NSDictionary

//-(NSMutableDictionary *)getSumbitDictionary
-(OLYMRoomDataObject *)getSumbitRoomDataObject
{
    if (self.previousArray && self.previousArray.count > 0) {
        [self.dataArray removeAllObjects];
        [self.dataArray addObjectsFromArray:self.previousArray];
    }

    OLYMRoomDataObject *roomDataObject = [[OLYMRoomDataObject alloc]init];
    
    for(NSDictionary *dict in self.dataArray){
        NSMutableArray *array = dict[@"content"];
        
        for(OLYMUserObject *userObj in array){
            if ([userObj isKindOfClass:NSString.class]) {
                //如果是“公司通讯录” ，跳过
                continue;
            }
            
            if(userObj.isCheck){
                [roomDataObject.roomMembersArray addObject:userObj];
            }
        }
    }
    
    if (Organization && [[olym_Default objectForKey:kAPI_ORGAN_Model] boolValue]) {
        
        [roomDataObject.roomMembersArray addObjectsFromArray:[OrganizationUtility sharedOrganizationUtility].selectedArray];
    }
    
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    //解决重复问题
    for (OLYMUserObject *user in roomDataObject.roomMembersArray) {
        if ([user.userId isEqualToString:olym_UserCenter.userId])
        {
            continue;
        }
        [dic setObject:user forKey:user.userId];
    }
    
    //去重
    NSMutableArray *userArray = [dic allValues].mutableCopy;
    [roomDataObject.roomMembersArray removeAllObjects];
    [roomDataObject.roomMembersArray addObjectsFromArray:userArray];
    
    return roomDataObject;
}



-(void)createNewRoom{
   
    [SVProgressHUD showWithStatus:@"正在新建群组"];
    
    OLYMUserObject *newRoomObject = [[OLYMUserObject alloc]init];
    newRoomObject.userId = [olym_Xmpp generateRoomUUID];
    //群名设置,这里要传名字过去，不然安卓那边无法插入数据库
    OLYMRoomDataObject *roomDataObject = [self getSumbitRoomDataObject];
    NSMutableArray *userArray = roomDataObject.roomMembersArray;
    OLYMUserObject *meObject = [[OLYMUserObject alloc]init];
    [meObject setUserId:olym_UserCenter.userId];
    [meObject setUserNickname:olym_UserCenter.userName];
    [userArray insertObject:meObject atIndex:0];

    NSString *roomName = @"";
    roomName = [self generatorRoomName:userArray];
    newRoomObject.userNickname = roomName;
    
    [roomManager setDelegate:self];
    [roomManager createNewRoom:newRoomObject withNewRoom:YES];
    
}

- (NSString *)generatorRoomName:(NSMutableArray *)userArray
{
    NSString *roomName = @"";
    for (OLYMUserObject *userObject in userArray ) {
        
        NSString *name = [userObject getDisplayName];
        
        roomName = [roomName stringByAppendingString:[NSString stringWithFormat:@"%@,",name]];
        
    }
    roomName = [roomName substringWithRange:NSMakeRange(0, roomName.length - 2)];
    if (roomName.length > 15) {
        roomName = [roomName substringWithRange:NSMakeRange(0, 12)];
        roomName = [roomName stringByAppendingString:@"..."];
    }
    roomName = [roomName stringByAppendingString:_T(@"的群聊")];
    return roomName;
}


- (void)slienceRoomUser:(OLYMRoomDataObject *)roomObject timeInterval:(NSTimeInterval)time
{
    for (OLYMUserObject *userObj in roomObject.roomMembersArray)
    {
        userObj.talkTime = time;
    }
    [self.silenceMemberCommond execute:roomObject];
}

#pragma mark-- roomManager Delegate
- (void)xmppRoomDidCreate:(NSString *)roomJid{
    OLYMRoomDataObject *roomDataObject = [self getSumbitRoomDataObject];
    [roomDataObject setRoomJid:roomJid];
    [self.createNewRoomCommond execute:roomDataObject];
}


#pragma mark--命令执行

-(RACCommand *)createNewRoomCommond{
    if (!_createNewRoomCommond) {
        
        @weakify(self);
        
        _createNewRoomCommond = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(OLYMRoomDataObject *roomDataObject) {
            
            @strongify(self);
            return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
                
                NSString *roomJid = roomDataObject.roomJid;
                NSMutableArray *userArray = roomDataObject.roomMembersArray;
                NSMutableArray *userIds = [NSMutableArray array];

                for(OLYMUserObject *mUserObj in userArray){
                    [userIds addObject:mUserObj.userId];
                }
                
                //添加自己进去,生成群名
                OLYMUserObject *mine = [[OLYMUserObject alloc]init];
                mine.userNickname = olym_UserCenter.userName;
                mine.telephone = olym_UserCenter.userAccount;
                mine.userId = olym_UserCenter.userId;
                mine.domain = FULL_DOMAIN(olym_UserCenter.userDomain);
                [userArray insertObject:mine atIndex:0];
                //群名设置
                NSString *roomName = @"";
                roomName = [self generatorRoomName:userArray];
                
                NSLog(@"新建群聊 提交服务器 jid %@",roomJid);
                    
                //提交服务器
                [olym_IMRequest addRoomToServer:roomJid roomName:roomName userIds:userIds Success:^(NSDictionary *dic) {
                
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
    
    return _createNewRoomCommond;
}



-(RACCommand *)deleteMemberCommond{
    if (!_deleteMemberCommond) {
        
        @weakify(self);
        
        _deleteMemberCommond = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(NSDictionary *infoDict) {
            
            @strongify(self);
            return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
                
                dispatch_group_t requestGroup = dispatch_group_create();
                
                OLYMRoomDataObject *roomDataObject = [infoDict objectForKey:@"room"];
                
                NSString *roomId = roomDataObject.roomId;
                
                OLYMUserObject *roomUserObject = [infoDict objectForKey:@"roomUser"];
                OLYMRoomObject *roomObject = [[OLYMRoomObject alloc]init];
                roomObject.roomJid = roomUserObject.userId;
                roomObject.nickName  = olym_UserCenter.userId;
                roomObject.xmppRoomStorage = olym_Xmpp.xmppRoomStorage;
                roomObject.roomName = roomUserObject.userNickname;
                roomObject.domain = roomUserObject.domain;
                roomObject.roomId = roomUserObject.roomId;
                
                NSMutableArray *userArray = roomDataObject.roomMembersArray;
                
                for(OLYMUserObject *userObject in userArray) {
                    
                    dispatch_group_enter(requestGroup);
                    
                    [olym_IMRequest delRoomMember:roomId memberId:userObject.userId Success:^(NSDictionary *dic) {
                        
                        [roomObject removeUser:userObject.userId withRoom:roomDataObject];
                        
                        //删除成功一个，刷新一个
                        [olym_Nofity postNotificationName:kDeleteUserFromRoomNotifaction object:userObject];
                        
                        dispatch_group_leave(requestGroup);
                    } Failure:^(NSString *error) {
                        dispatch_group_leave(requestGroup);
                    }];
                }
                dispatch_group_notify(requestGroup, dispatch_get_main_queue(), ^{
                    [subscriber sendNext:nil];
                    [subscriber sendCompleted];
                });
                
                return nil;
            }];
        }];
    }
    
    return _deleteMemberCommond;
}

//邀请人入群，此时群已经存在
-(RACCommand *)invateMemberCommond{
    if (!_invateMemberCommond) {
        
        @weakify(self);
        
        _invateMemberCommond = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(NSDictionary *infoDict) {
            OLYMRoomDataObject *roomDataObject = [infoDict objectForKey:@"room"];
            OLYMUserObject *roomUser = [infoDict objectForKey:@"roomUser"];

            @strongify(self);
            return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
                //由于服务器只支持单个添加，所以在这里进行循环操作
                dispatch_group_t requestGroup = dispatch_group_create();
               
                NSMutableArray *userArray = roomDataObject.roomMembersArray;
                
                OLYMRoomObject *roomObject = [roomManager.roomPool objectForKey:roomDataObject.roomJid];
                if (!roomDataObject.name)
                {
                    roomDataObject.name = roomObject.roomName;
                }
                for(OLYMUserObject *userObject in userArray) {
                    
                    dispatch_group_enter(requestGroup);
                    
                    [olym_IMRequest addRoomMember:roomDataObject.roomId userId:userObject.userId nickName:userObject.userNickname Success:^(NSDictionary *dic) {
                        //加入成功一个，邀请一个
                        [roomObject inviteUser:userObject.userId withRoom:roomDataObject];
                        
                        //加入成功一个，刷新一个
                        [olym_Nofity postNotificationName:kInviteUserFromRoomNotifaction object:userObject];
                        
                        dispatch_group_leave(requestGroup);
                    } Failure:^(NSString *error) {
                        dispatch_group_leave(requestGroup);
                        
                    }];
                }
                dispatch_group_notify(requestGroup, dispatch_get_main_queue(), ^{
                    [subscriber sendNext:roomUser];
                    [subscriber sendCompleted];
                });
                
                return nil;
            }];
        }];
    }
    
    return _invateMemberCommond;
}

//刚创建群时，邀请人入群
- (RACCommand *)createInviteUserCommand
{
    if(!_createInviteUserCommand)
    {
        @weakify(self);
        _createInviteUserCommand = [[RACCommand alloc]initWithSignalBlock:^RACSignal * _Nonnull(NSDictionary *infoDict) {
            OLYMRoomDataObject *roomDataObject = [infoDict objectForKey:@"room"];
            OLYMUserObject *roomUser = [infoDict objectForKey:@"roomUser"];
            @strongify(self);
            return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
                
                NSMutableArray *userArray = roomDataObject.roomMembersArray;
                OLYMRoomObject *roomObject = [roomManager.roomPool objectForKey:roomDataObject.roomJid];
                if (!roomDataObject.name)
                {
                    roomDataObject.name = roomObject.roomName;
                }
                
                NSMutableArray *userIds = [NSMutableArray array];
                
                for(OLYMUserObject *userObject in userArray)
                {
                    [userIds addObject:userObject.userId];
                }
                [roomObject invateUsers:userIds withRoom:roomDataObject];
                //建完群清空数组
                [[OrganizationUtility sharedOrganizationUtility].selectedArray removeAllObjects];
                [subscriber sendNext:roomUser];
                [subscriber sendCompleted];

                return nil;
            }];
        }];
    }
    return _createInviteUserCommand;
}


-(RACCommand *)silenceMemberCommond{
    if (!_silenceMemberCommond) {
        
        @weakify(self);
        
        _silenceMemberCommond = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(OLYMRoomDataObject *roomDataObject) {
            
            @strongify(self);
            return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
                
                dispatch_group_t requestGroup = dispatch_group_create();
                
                NSString *roomId = roomDataObject.roomId;
                
                NSMutableArray *userArray = roomDataObject.roomMembersArray;
                NSInteger time;
                __block NSString *networkError = nil;
                for(OLYMUserObject *userObject in userArray) {
                    time = userObject.talkTime;
                    
                    dispatch_group_enter(requestGroup);
                    
                    [olym_IMRequest setDisableSay:roomId userId:userObject.userId time:userObject.talkTime Success:^(NSDictionary *dic) {
                        
                        dispatch_group_leave(requestGroup);
                    } Failure:^(NSString *error) {
                        networkError = error;
                        dispatch_group_leave(requestGroup);
                    }];
                }
                dispatch_group_notify(requestGroup, dispatch_get_main_queue(), ^{
                    if (!networkError)
                    {
                        [subscriber sendNext:[NSNumber numberWithInt:time]];
                    }else
                    {
                        [subscriber sendNext:networkError];
                    }
                    [subscriber sendCompleted];
                });
                
                return nil;
            }];
        }];
    }
    
    return _silenceMemberCommond;
}




-(NSMutableArray *)friendArray{
    if(!_friendArray){
        _friendArray = [[NSMutableArray alloc]init];
    }
    return _friendArray;
}

-(NSMutableArray *)groupMemberArray{
    if(!_groupMemberArray){
        _groupMemberArray = [[NSMutableArray alloc]init];
    }
    return _groupMemberArray;
}

-(RACSubject *)membersCountRACSubject{
    
    if (!_membersCountRACSubject) {
        
        _membersCountRACSubject = [[RACSubject alloc]init];
    }
    
    return _membersCountRACSubject;
}

- (RACSubject *)organizationlistSubject
{
    if(!_organizationlistSubject)
    {
        _organizationlistSubject = [RACSubject subject];
    }
    return _organizationlistSubject;
}

@end
