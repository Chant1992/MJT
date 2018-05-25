//
//  ChatViewModel.m
//  MJT_APP
//
//  Created by olymtech on 2017/8/29.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "ChatViewModel.h"
#import "OLYMMessageObject.h"
#import "OLYMUserObject.h"
#import "OLMAmrPlayer+Base64String.h"
#import "FileCenter.h"
#import "JsonUtils.h"
#import "SecurityEngineHelper.h"
#import "AlertViewManager.h"
#include <sys/time.h>
#import "UIImage+Image.h"
#import "GJCUImageBrowserModel.h"
#import "ChatRecordViewModel.h"

#if XJT
#define MESSAGEINTERVAL 5
#else
#define MESSAGEINTERVAL 15
#endif

@interface ChatViewModel()

@property(strong,nonatomic) OLYMUserObject *currentChatUser;

@property (nonatomic, strong) OLMAmrPlayer *audioPlayer;


@property (nonatomic, assign) NSInteger pageIndex;

@property (nonatomic, assign) NSInteger preIndex;

//音频播放队列
@property (nonatomic, strong) NSMutableArray *audioArray;
//标志位，是否在播放
@property (nonatomic) BOOL isPlaying;
@property (nonatomic) NSInteger playIndex;

@end


@implementation ChatViewModel

-(instancetype)initWithUser:(OLYMUserObject *)currentChatUser{
    
    self = [super init];
    if(self){
        self.pageIndex = 0;
        self.preIndex = NSNotFound;
        self.currentChatUser = currentChatUser;
        self.currentChatUserId = self.currentChatUser.userId;
        self.currentChatUserDomain = self.currentChatUser.domain;
        self.currentChatRoomId = self.currentChatUser.roomId;
        [self downloadGroupPrivateKey];
        [self getData:nil];
        
    }
    return self;
}

- (instancetype)initWithUser:(OLYMUserObject *)currentChatUser searchMessage:(OLYMMessageObject *)searchMsg
{
    self = [super init];
    if(self){
        self.pageIndex = 0;
        self.preIndex = NSNotFound;
        self.currentChatUser = currentChatUser;
        self.currentChatUserId = self.currentChatUser.userId;
        self.currentChatUserDomain = self.currentChatUser.domain;
        self.currentChatRoomId = self.currentChatUser.roomId;
        [self downloadGroupPrivateKey];
        [self getDataWithSearchMessage:searchMsg];
        
    }
    return self;
}

-(void)olym_initialize{
    
    @weakify(self);
    //禁言
    [[olym_Nofity rac_addObserverForName:kgroupSlienceChatNotification object:nil]subscribeNext:^(NSNotification *notification) {
        @strongify(self);
        OLYMUserObject *user = [notification object];
        if ([user.domain isEqualToString:self.currentChatUser.domain] && [user.userId isEqualToString:self.currentChatUser.userId])
        {
            self.currentChatUser.isSilence = user.isSilence;
            self.currentChatUser.talkTime = user.talkTime;
        }
    }];
    //收到语音消息，放入播放队列
    [[olym_Nofity rac_addObserverForName:kXMPPNewMsgNotifaction object:nil]subscribeNext:^(NSNotification *notification) {
        @strongify(self);
        OLYMMessageObject *message = [notification object];
        if (self.isPlaying)
        {
            [self.audioArray addObject:message];
        }
    }];
    
    //收到删除文件的通知，遍历是否在消息数组中
    [[olym_Nofity rac_addObserverForName:kDeleteFileMessageNotifaction object:nil]subscribeNext:^(NSNotification * notification) {
        @strongify(self);
        NSArray *messages = [notification object];
        NSMutableIndexSet *set = [NSMutableIndexSet indexSet];
        for (OLYMMessageObject *message in messages)
        {
            for (OLYMMessageObject *compareMsg in self.dataArray)
            {
                if ([message.messageId isEqualToString:compareMsg.messageId])
                {
                    NSInteger index = [self.dataArray indexOfObject:compareMsg];
                    [set addIndex:index];
                }
            }
        }
        if ([set count] > 0)
        {
            [self.dataArray removeObjectsAtIndexes:set];
            //发送到UI
            [self.fileDeleteSubject sendNext:nil];
        }
    }];
 
    
    [self.refreshDataCommand.executionSignals.switchToLatest subscribeNext:^(id  _Nullable x) {
        @strongify(self);

        dispatch_queue_t chatQueue = dispatch_queue_create("com.nisc.chat", DISPATCH_QUEUE_SERIAL);

        dispatch_async(chatQueue, ^{
            NSArray *fetchArray = [self fetchMoreChatList];
            dispatch_async(dispatch_get_main_queue(), ^{
                if(fetchArray.count >= 20)
                {
                    [self.refreshEndSubject sendNext:@(OLYM_HeaderRefresh_HasMoreData)];
                }else
                {
                    [self.refreshEndSubject sendNext:@(OLYM_HeaderRefresh_HasNoMoreData)];
                }
            });
        });
    }];
   
    [self.refreshFooterDataCommand.executionSignals.switchToLatest subscribeNext:^(id  _Nullable x) {
  
        dispatch_queue_t chatQueue = dispatch_queue_create("com.nisc.chat", DISPATCH_QUEUE_SERIAL);
        
        dispatch_async(chatQueue, ^{
            NSArray *fetchArray = [self fetchMoreFooterChat];
            dispatch_async(dispatch_get_main_queue(), ^{
                if(fetchArray.count >= 20)
                {
                    [self.refreshEndSubject sendNext:@(OLYM_FooterRefresh_HasMoreData)];
                }else
                {
                    [self.refreshEndSubject sendNext:@(OLYM_FooterRefresh_HasNoMoreData)];
                }
            });
        });
    }];
    
    [self.getUserInfoCommand.executionSignals.switchToLatest subscribeNext:^(NSDictionary* dict) {
        @strongify(self);
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
                    NSDictionary *userInfo = @{@"user":userObj,@"status":@(userObj.status)};
                    [self.getUserInfoSubject sendNext:userInfo];
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


- (void)getData:(OLYMMessageObject *)searchMsg
{
    
    NSArray *tempArray = [OLYMMessageObject fetchMessagesByUser:self.currentChatUser.userId withDomain:self.currentChatUser.domain byPageOffset:self.pageIndex];
   
    NSMutableArray *fetchArray = [[NSMutableArray alloc]initWithCapacity:tempArray.count];
    
    for(int i = [tempArray count]-1;i>=0;i--){
        [fetchArray addObject:[tempArray objectAtIndex:i]];
    }
    fetchArray = [self showMessageTime:fetchArray];

    if(fetchArray){
        [self.dataArray addObjectsFromArray:fetchArray];
        if(searchMsg)
        {
            for (OLYMMessageObject *object in fetchArray) {
                if (object.messageNo == searchMsg.messageNo)
                {
                    NSInteger index = [fetchArray indexOfObject:object];
                    self.searchMessgeIndexPath = [NSIndexPath indexPathForRow:index inSection:0];
                    break;
                }
            }
        }
    }
    
    if (fetchArray.count >= 20)
    {
        self.pageIndex += 20;
        WeakSelf(ws);
        dispatch_async(dispatch_get_main_queue(), ^{
            StrongSelf(ss);
            [ss.refreshUI sendNext:nil];
        });
    }else
    {
        WeakSelf(ws);
        dispatch_async(dispatch_get_main_queue(), ^{
            StrongSelf(ss);
            [ss.refreshEndSubject sendNext:@(OLYM_HeaderRefresh_HasNoMoreData)];
        });
        
    }
}


- (void)getDataWithSearchMessage:(OLYMMessageObject *)message
{
    NSArray *messageNos = [OLYMMessageObject fetchAllMessageNoByUser:self.currentChatUserId withDomain:self.currentChatUserDomain messageNo:message.messageNo];
    if (!messageNos || messageNos.count == 0)
    {
        self.pageIndex = 0;
        self.preIndex = NSNotFound;
    }else
    {
        NSUInteger index = NSNotFound;
        index = [messageNos indexOfObject:@[[NSNumber numberWithInteger:message.messageNo]]];
        if (index == NSNotFound)
        {
            self.pageIndex = 0;
            self.preIndex = NSNotFound;
        }else
        {
            NSInteger startIndex = index - 19;
            if (startIndex > 0) {
                self.pageIndex = index - 19;
                self.preIndex = self.pageIndex - 20;
                if (self.preIndex < -19)
                {
                    self.preIndex = NSNotFound;
                }
            }else
            {
                self.pageIndex = 0;
                self.preIndex = NSNotFound;
            }
        }
    }
    [self getData:message];

}


- (void)addNewMessage:(OLYMMessageObject *)message
{
    if(self.dataArray.count <= 0)
    {
        message.isShowTime = YES;
    }else
    {
        OLYMMessageObject *firstMsg = [self.dataArray lastObject];
        if (([message.timeSend timeIntervalSince1970] - [firstMsg.timeSend timeIntervalSince1970] > MESSAGEINTERVAL * 60) && (message.type != kWCMessageTypeRemind)) {
            message.isShowTime = YES;
        }

    }
    [self.dataArray addObject:message];
}

- (BOOL)isSearchCondition
{
    if (self.preIndex != NSNotFound) {
        return YES;
    }
    return NO;
}


-(void)sendTextMessage:(NSString *)text  
{
    WeakSelf(ws);
    dispatch_async(XmppSendQueue, ^{
        StrongSelf(ss);
        //FIXME:把基本必要的信息 统一起来
        OLYMMessageObject *msg = [[OLYMMessageObject alloc]init];
        [msg setMessageId];
        msg.toUserIbcKey = ss.currentChatUser.telephone;
        msg.timeSend = [NSDate date];
        msg.toUserId = ss.currentChatUser.userId;
        msg.fromUserId = olym_UserCenter.userId;
        
        if (ss.currentChatUser.domain) {
            
            msg.domain = ss.currentChatUser.domain;
        }else{
            
            msg.domain = FULL_DOMAIN(olym_UserCenter.userDomain);
        }
        
        msg.isReadburn = ss.isReadburn;
        msg.type = kWCMessageTypeText;
        msg.isGroup = ss.currentChatUser.roomFlag == 1 ? YES:NO;
        //群聊里面如果修改了群昵称，需要放到消息里面去，对方才能显示出来
        if(msg.isGroup){
            NSString *fromUserName;
            if (self.currentChatUser.userRemarkname)
            {
                msg.fromUserName = self.currentChatUser.userRemarkname;
            }else
            {
                msg.fromUserName = olym_UserCenter.userName;
            }
        }
        
        if(GJCFStringIsNull(text))
        {
            msg.content = [msg getLastContent];
        }
        else{
            msg.content = text;
        }
        
        //遍历text，查找是否有@好友
        if (self.reminderArray.count > 0)
        {
            NSMutableArray *userNames = [NSMutableArray array];
            NSMutableArray *userIds = [NSMutableArray array];
            for (NSDictionary *dict in ss.reminderArray) {
                [userNames addObjectsFromArray:[dict allKeys]];
            }
            for (NSString *fromUserName in userNames)
            {
                if ([text rangeOfString:fromUserName].location != NSNotFound)
                {
                    NSInteger index = [userNames indexOfObject:fromUserName];
                    NSDictionary *dict = [ss.reminderArray objectAtIndex:index];
                    [userIds addObject:[dict objectForKey:fromUserName]];
                }
            }
            if (userIds.count > 0) {
                NSString *remindStr = [JsonUtils arrayToJsonString:userIds];
                msg.filePath = [NSString stringWithFormat:@"[%@]",remindStr];
            }
            
            [ss.reminderArray removeAllObjects];
        }
        
        msg.isSend = transfer_status_ing;
        msg.isRead = YES;
        msg.isMySend = YES;
        msg.isEncrypt = YES;
        
        [msg insert];
        
        [msg updateLastSend:YES];
        
        //发消息给系统做特别处理
        if ([msg.toUserId isEqualToString:@"10000"]) {
            msg.isSend = transfer_status_send;
        }else
        {
            if(msg.isGroup)
            {
                NSTimeInterval now = [[NSDate date]timeIntervalSince1970];
                if (self.currentChatUser.isSilence)
                {
                    if (self.currentChatUser.talkTime > now)
                    {
                        msg.isSlience = YES;
                        msg.isSend = transfer_status_no;
                        [msg updateSendStatus:msg.isSend];
                    }else
                    {
                        //禁言时间结束
                        self.currentChatUser.isSilence = NO;
                        self.currentChatUser.talkTime = 0;
                        [self.currentChatUser updateUserSlienceStatus];
                    }
                }
            }
            [msg sendMessage];
            
        }
        
#if TESTSYNC
        [self.currentChatUser updateSend:1 receive:0];
#endif

        [olym_Nofity postNotificationName:kXMPPRefreshMsgListNotifaction object:msg];
    });
}


-(void)sendImageMessage:(NSString *)path imageWidth:(float)width imageHeight:(float)height thumbnailString:(NSString *)thumbnailBase64String
{
    WeakSelf(ws);
    dispatch_async(XmppSendQueue, ^{
        StrongSelf(ss);
        NSString *uploadFilePath = path;
        if (![FileCenter fileExistAt:path])
        {
            return;
        }
        NSString *base64Encoded = thumbnailBase64String;

        NSString* filepath = [path stringByReplacingOccurrencesOfString:[[FileCenter sharedFileCenter]documentPrefix] withString:@""];
        
        OLYMMessageObject *msg = [[OLYMMessageObject alloc]init];
        [msg setMessageId];
        msg.toUserIbcKey = ss.currentChatUser.telephone;
        msg.timeSend = [NSDate date];
        msg.toUserId = ss.currentChatUserId;
        msg.fromUserId = olym_UserCenter.userId;
        msg.domain = ss.currentChatUserDomain;
        msg.isReadburn = ss.isReadburn;
        msg.type = kWCMessageTypeImage;
        msg.content = [msg getLastContent];
        msg.filePath = filepath;
        msg.fileName = [filepath lastPathComponent];
        msg.imageWidth = width;
        msg.imageHeight = height;
        msg.isSend = transfer_status_ing;
        msg.isRead = YES;
        msg.isMySend = YES;
        msg.isEncrypt = YES;
        //文件进行了AES加密
        msg.isAESEncrypt = YES;

        if (base64Encoded)
        {
            msg.thumbnail = base64Encoded;
        }
        
        //通过roomflag 0为单聊 1为群聊
        msg.isGroup = ss.currentChatUser.roomFlag == 1 ? YES:NO;
        //群聊里面如果修改了群昵称，需要放到消息里面去，对方才能显示出来
        if(msg.isGroup){
            NSString *fromUserName;
            if (self.currentChatUser.userRemarkname)
            {
                msg.fromUserName = self.currentChatUser.userRemarkname;
            }else
            {
                msg.fromUserName = olym_UserCenter.userName;
            }

        }

        msg.uploadFileModel = [GJCFUploadFileModel fileModelWithFileName:[uploadFilePath lastPathComponent] withFilePath:uploadFilePath withFormName:@"file"];
        
        [msg insert];
        
        [msg updateLastSend:YES];
        if(msg.isGroup)
        {
            NSTimeInterval now = [[NSDate date]timeIntervalSince1970];
            if (self.currentChatUser.isSilence)
            {
                if (self.currentChatUser.talkTime > now)
                {
                    msg.isSlience = YES;
                    msg.isSend = transfer_status_no;
                    [msg updateSendStatus:msg.isSend];
                }else
                {
                    //禁言时间结束
                    self.currentChatUser.isSilence = NO;
                    self.currentChatUser.talkTime = 0;
                    [self.currentChatUser updateUserSlienceStatus];
                }
            }
        }
        [olym_Nofity postNotificationName:kXMPPRefreshMsgListNotifaction object:msg];

    });
    
    
}

- (void)sendAudioMessage:(NSString *)base64Audio  duration:(CGFloat)duration 
{
    WeakSelf(ws);
    dispatch_async(XmppSendQueue, ^{
        StrongSelf(ss);
        OLYMMessageObject *msg = [[OLYMMessageObject alloc]init];
        [msg setMessageId];
        msg.toUserIbcKey = ss.currentChatUser.telephone;
        msg.timeSend = [NSDate date];
        msg.toUserId = ss.currentChatUserId;
        msg.fromUserId = olym_UserCenter.userId;
        msg.domain = ss.currentChatUserDomain;
        msg.isReadburn = ss.isReadburn;
        msg.type = kWCMessageTypeVoice;
        msg.isGroup = ss.currentChatUser.roomFlag == 1 ? YES:NO;
        
        struct timeval time;
        gettimeofday(&time, NULL);
        long millis = (time.tv_sec * 1000) + (time.tv_usec / 1000);
        msg.filePath = [NSString stringWithFormat:@"%ld.amr",millis];
        //群聊里面如果修改了群昵称，需要放到消息里面去，对方才能显示出来
        if(msg.isGroup){
            NSString *fromUserName;
            if (self.currentChatUser.userRemarkname)
            {
                msg.fromUserName = self.currentChatUser.userRemarkname;
            }else
            {
                msg.fromUserName = olym_UserCenter.userName;
            }

        }

        msg.isSend = transfer_status_ing;
        msg.isRead = YES;
        msg.isMySend = YES;
        msg.isEncrypt = YES;
        
        //audio msg
        msg.content = base64Audio;
        
        //temp
        msg.fileSize = duration;
        
        
        [msg insert];
        
        [msg updateLastSend:YES];
        
        if(msg.isGroup)
        {
            NSTimeInterval now = [[NSDate date]timeIntervalSince1970];
            if (self.currentChatUser.isSilence)
            {
                if (self.currentChatUser.talkTime > now)
                {
                    msg.isSlience = YES;
                    msg.isSend = transfer_status_no;
                    [msg updateSendStatus:msg.isSend];
                }else
                {
                    //禁言时间结束
                    self.currentChatUser.isSilence = NO;
                    self.currentChatUser.talkTime = 0;
                    [self.currentChatUser updateUserSlienceStatus];
                }
            }
        }
        [msg sendMessage];
        
        [olym_Nofity postNotificationName:kXMPPRefreshMsgListNotifaction object:msg];

    });
}

- (void)sendVideoMessage:(NSString *)filePath fileSize:(unsigned long long)fileSize thumbnailString:(NSString *)thumbnailBase64String
{
    WeakSelf(ws);
    dispatch_async(XmppSendQueue, ^{
        StrongSelf(ss);
        if (![FileCenter fileExistAt:filePath])
        {
            return;
        }

        NSString *uploadFilePath = filePath;
        
        NSString *path = [filePath stringByReplacingOccurrencesOfString:[[FileCenter sharedFileCenter]documentPrefix] withString:@""];
        
        NSString *base64Encoded = thumbnailBase64String;

        OLYMMessageObject *msg = [[OLYMMessageObject alloc]init];
        [msg setMessageId];
        msg.toUserIbcKey = ss.currentChatUser.telephone;
        msg.timeSend = [NSDate date];
        msg.toUserId = ss.currentChatUserId;
        msg.fromUserId = olym_UserCenter.userId;
        msg.domain = ss.currentChatUserDomain;
        msg.isReadburn = ss.isReadburn;
        msg.type = kWCMessageTypeVideo;
        msg.isGroup = ss.currentChatUser.roomFlag == 1 ? YES:NO;
        //群聊里面如果修改了群昵称，需要放到消息里面去，对方才能显示出来
        if(msg.isGroup){
            NSString *fromUserName;
            if (self.currentChatUser.userRemarkname)
            {
                msg.fromUserName = self.currentChatUser.userRemarkname;
            }else
            {
                msg.fromUserName = olym_UserCenter.userName;
            }

        }

        msg.isSend = transfer_status_ing;
        msg.isRead = YES;
        msg.isMySend = YES;
        msg.isEncrypt = YES;
        //文件进行了AES加密
        msg.isAESEncrypt = YES;

        //video msg
        msg.content = [[path lastPathComponent] stringByDeletingPathExtension];
        msg.filePath = path;
        msg.fileName = [path lastPathComponent];
        msg.fileSize = fileSize;

        if(base64Encoded){
            msg.thumbnail = base64Encoded;
        }

        
        msg.uploadFileModel = [GJCFUploadFileModel fileModelWithFileName:[uploadFilePath lastPathComponent] withFilePath:uploadFilePath withFormName:@"file"];
        
        [msg insert];
        
        [msg updateLastSend:YES];
        
        if(msg.isGroup)
        {
            NSTimeInterval now = [[NSDate date]timeIntervalSince1970];
            if (self.currentChatUser.isSilence)
            {
                if (self.currentChatUser.talkTime > now)
                {
                    msg.isSlience = YES;
                    msg.isSend = transfer_status_no;
                    [msg updateSendStatus:msg.isSend];
                }else
                {
                    //禁言时间结束
                    self.currentChatUser.isSilence = NO;
                    self.currentChatUser.talkTime = 0;
                    [self.currentChatUser updateUserSlienceStatus];
                }
            }
        }
        [olym_Nofity postNotificationName:kXMPPRefreshMsgListNotifaction object:msg];

    });

}

- (void)sendFileMessage:(NSString *)filePath fileSize:(unsigned long long)fileSize fileName:(NSString *)fileName
{
    WeakSelf(ws);
    dispatch_async(XmppSendQueue, ^{
        StrongSelf(ss);
        NSString *uploadFilePath = filePath;
        NSString *path = [filePath stringByReplacingOccurrencesOfString:[[FileCenter sharedFileCenter]documentPrefix] withString:@""];
        
        OLYMMessageObject *msg = [[OLYMMessageObject alloc]init];
        [msg setMessageId];
        msg.toUserIbcKey = ss.currentChatUser.telephone;
        msg.timeSend = [NSDate date];
        msg.toUserId = ss.currentChatUserId;
        msg.fromUserId = olym_UserCenter.userId;
        msg.domain = ss.currentChatUserDomain;
        msg.isReadburn = ss.isReadburn;
        msg.type = kWCMessageTypeFile;
        msg.isGroup = ss.currentChatUser.roomFlag == 1 ? YES:NO;
        //群聊里面如果修改了群昵称，需要放到消息里面去，对方才能显示出来
        if(msg.isGroup){
            NSString *fromUserName;
            if (self.currentChatUser.userRemarkname)
            {
                msg.fromUserName = self.currentChatUser.userRemarkname;
            }else
            {
                msg.fromUserName = olym_UserCenter.userName;
            }
        }

        msg.isSend = transfer_status_ing;
        msg.isRead = YES;
        msg.isMySend = YES;
        msg.isEncrypt = YES;
        //文件进行了AES加密
        msg.isAESEncrypt = YES;

        //file msg
        msg.content = [msg getLastContent];
        msg.filePath = path;
        msg.fileName = fileName;
        msg.fileSize = fileSize;
        
        msg.uploadFileModel = [GJCFUploadFileModel fileModelWithFileName:[uploadFilePath lastPathComponent] withFilePath:uploadFilePath withFormName:@"file"];
        
        [msg insert];
        
        [msg updateLastSend:YES];
        
        if(msg.isGroup)
        {
            NSTimeInterval now = [[NSDate date]timeIntervalSince1970];
            if (self.currentChatUser.isSilence)
            {
                if (self.currentChatUser.talkTime > now)
                {
                    msg.isSlience = YES;
                    msg.isSend = transfer_status_no;
                    [msg updateSendStatus:msg.isSend];
                }else
                {
                    //禁言时间结束
                    self.currentChatUser.isSilence = NO;
                    self.currentChatUser.talkTime = 0;
                    [self.currentChatUser updateUserSlienceStatus];
                }
            }
        }
        [olym_Nofity postNotificationName:kXMPPRefreshMsgListNotifaction object:msg];

    });
}

- (void)sendCardMessage:(NSString *)userNickName userDomain:(NSString *)userDomain telephone:(NSString *)telephone  
{
    WeakSelf(ws);
    dispatch_async(XmppSendQueue, ^{
        StrongSelf(ss);
        OLYMMessageObject *msg = [[OLYMMessageObject alloc]init];
        [msg setMessageId];
        msg.toUserIbcKey = ss.currentChatUser.telephone;
        msg.timeSend = [NSDate date];
        msg.toUserId = ss.currentChatUserId;
        msg.fromUserId = olym_UserCenter.userId;
        msg.domain = ss.currentChatUserDomain;
        msg.isReadburn = ss.isReadburn;
        msg.type = kWCMessageTypeCard;
        msg.isGroup = ss.currentChatUser.roomFlag == 1 ? YES:NO;
        //群聊里面如果修改了群昵称，需要放到消息里面去，对方才能显示出来
        if(msg.isGroup){
            NSString *fromUserName;
            if (self.currentChatUser.userRemarkname)
            {
                msg.fromUserName = self.currentChatUser.userRemarkname;
            }else
            {
                msg.fromUserName = olym_UserCenter.userName;
            }

        }

        msg.isSend = transfer_status_ing;
        msg.isRead = YES;
        msg.isMySend = YES;
        msg.isEncrypt = YES;
        
        //file msg
        msg.content = [NSString stringWithFormat:@"%@:%@:%@",userNickName,userDomain,telephone];
        
        [msg insert];
        
        [msg updateLastSend:YES];
        
        if(msg.isGroup)
        {
            NSTimeInterval now = [[NSDate date]timeIntervalSince1970];
            if (self.currentChatUser.isSilence)
            {
                if (self.currentChatUser.talkTime > now)
                {
                    msg.isSlience = YES;
                    msg.isSend = transfer_status_no;
                    [msg updateSendStatus:msg.isSend];
                }else
                {
                    //禁言时间结束
                    self.currentChatUser.isSilence = NO;
                    self.currentChatUser.talkTime = 0;
                    [self.currentChatUser updateUserSlienceStatus];
                }
            }
        }
        [msg sendMessage];
        
        [olym_Nofity postNotificationName:kXMPPRefreshMsgListNotifaction object:msg];
        

    });
}


- (void)reSendMessage:(OLYMMessageObject *)msgObj uploadBlock:(void (^)())uploadBlock
{
    WeakSelf(ws);
    dispatch_async(XmppSendQueue, ^{
        BOOL needToReupload = NO;
        msgObj.isSend = transfer_status_ing;
        msgObj.toUserIbcKey = ws.currentChatUser.telephone;
        msgObj.toUserId = ws.currentChatUserId;

        if (msgObj.type == kWCMessageTypeFile || msgObj.type == kWCMessageTypeImage || msgObj.type == kWCMessageTypeVideo)
        {
            //先判断是否上传了文件
            if (![msgObj.content hasPrefix:@"http://"] && ![msgObj.content hasPrefix:@"https://"])
            {
                needToReupload = YES;
                NSString *uploadFilePath = [[olym_FileCenter documentPrefix]stringByAppendingPathComponent:msgObj.filePath];
                //没上传
                msgObj.uploadFileModel = [GJCFUploadFileModel fileModelWithFileName:[uploadFilePath lastPathComponent] withFilePath:uploadFilePath withFormName:@"file"];
                
            }
        }
        NSLog(@"=======> 重发消息 ：%@",msgObj.content);
        //群聊是否被禁言
        if(msgObj.isGroup)
        {
            NSTimeInterval now = [[NSDate date]timeIntervalSince1970];
            if (self.currentChatUser.isSilence)
            {
                if (self.currentChatUser.talkTime > now)
                {
                    msgObj.isSlience = YES;
                    msgObj.isSend = transfer_status_no;
                }else
                {
                    //禁言时间结束
                    self.currentChatUser.isSilence = NO;
                    self.currentChatUser.talkTime = 0;
                    [self.currentChatUser updateUserSlienceStatus];
                }
            }
        }
        if (!needToReupload)
        {
            if (!msgObj.toUserIbcKey)
            {
                msgObj.toUserIbcKey = ws.currentChatUser.telephone;
            }
            
            [msgObj sendMessage];
        }else
        {
            if (uploadBlock)
            {
                uploadBlock();
            }
        }

    });
}

- (void)sendReadedMessage:(OLYMMessageObject *)msgObj
{
    dispatch_async(XmppSendQueue, ^{
        
        
        [msgObj updateIsRead];
        
        NSString *fromUserId = msgObj.fromUserId;
        if (msgObj.isGroup)
        {
            fromUserId = msgObj.objectId;
        }
        
        OLYMMessageObject *msg = [[OLYMMessageObject alloc]init];
        msg.content = [NSString stringWithFormat:@"%@",msgObj.messageId];
        msg.toUserId = fromUserId;
        msg.fromUserId = msgObj.toUserId;
        msg.isRead = YES;
        msg.domain = msgObj.domain;
        msg.toUserIbcKey = msgObj.toUserIbcKey;
        msg.type = kWCMessageTypeIsRead;
        msg.isReadburn = msgObj.isReadburn;
        msg.isMySend = YES;
        
        [msg setMessageId];

        [msg sendMessage];
        
    });
}

- (void)sendTakeScreenshotMessage
{
    WeakSelf(ws);
    dispatch_async(XmppSendQueue, ^{
        OLYMMessageObject *msg = [[OLYMMessageObject alloc]init];
        msg.timeSend = [NSDate date];
        msg.toUserId = ws.currentChatUserId;
        msg.toUserIbcKey = ws.currentChatUser.telephone;
        msg.domain = ws.currentChatUser.domain;
        msg.fromUserId = olym_UserCenter.userId;

        if(GJCFStringIsNull(msg.domain)){
            msg.domain = [olym_Default objectForKey:kMY_USER_LOGIN_DOMAIN];
        }
        msg.type = kWCMessageTypeRemind;
        
        msg.isSend = transfer_status_ing;
        msg.isRead = NO;
        msg.fromUserName = [olym_Default objectForKey:kMY_USER_NICKNAME];
        
        NSString *fromName;
        if(self.currentChatUser.roomFlag == 1)
        {
            NSString *fromUserName;
            if (self.currentChatUser.userRemarkname)
            {
                fromName = self.currentChatUser.userRemarkname;
            }else
            {
                fromName = olym_UserCenter.userName;
            }
        }else
        {
            fromName = olym_UserCenter.userName;
        }
        
        NSString *content = [NSString stringWithFormat:_T(@"%@对聊天消息进行了截屏"),fromName];

        msg.content = content;
        
        msg.isGroup = ws.currentChatUser.roomFlag == 1 ? YES:NO;
        [msg setIsMySend:YES];
        
        [msg setMessageId];
        
        [msg sendMessage];

    });
}

- (void)sendRecallMesage:(OLYMMessageObject *)msgObj
{
    WeakSelf(ws);
    dispatch_async(XmppSendQueue, ^{
        //更新撤回消息内容
        msgObj.isRecall = YES;
        [msgObj updateRecall];
        
        NSString *fromUserId = msgObj.fromUserId;
        if (msgObj.isGroup)
        {
            fromUserId = msgObj.objectId;
        }
        NSString *fromName;
        if(self.currentChatUser.roomFlag == 1)
        {
            NSString *fromUserName;
            if (self.currentChatUser.userRemarkname)
            {
                fromName = self.currentChatUser.userRemarkname;
            }else
            {
                fromName = olym_UserCenter.userName;
            }
        }else
        {
            fromName = olym_UserCenter.userName;
        }

        OLYMMessageObject *msg = [[OLYMMessageObject alloc]init];
        msg.content = [NSString stringWithFormat:@"%@",msgObj.messageId];
        msg.toUserId = ws.currentChatUserId;
        msg.fromUserId = olym_UserCenter.userId;
        msg.isRead = YES;
        msg.domain = ws.currentChatUserDomain;
        msg.toUserIbcKey = ws.currentChatUser.telephone;
        msg.type = kWCMessageTypeReCall;
        msg.fromUserName = fromName;
        msg.isSend = transfer_status_ing;
        msg.isMySend = YES;
        msg.timeSend = msgObj.timeSend;
        msg.isGroup = ws.currentChatUser.roomFlag == 1 ? YES:NO;

        [msg setMessageId];

        [msg insert];
        [msg updateLastSend:YES];

        [msg sendMessage];
        [olym_Nofity postNotificationName:kXMPPRefreshMsgListNotifaction object:msg];
    });

}





- (BOOL)deleteMessageByMessage:(OLYMMessageObject *)msgObj
{
    //先删除文件
    if (msgObj.type == kWCMessageTypeVideo || msgObj.type == kWCMessageTypeImage || msgObj.type == kWCMessageTypeFile) {
        NSString *uploadFilePath = [[olym_FileCenter documentPrefix]stringByAppendingPathComponent:msgObj.filePath];
        [FileCenter deleteFile:uploadFilePath];
        if(msgObj.type == kWCMessageTypeVideo)
        {
            //删除缩略图
            NSString *imagePath  = [NSString stringWithFormat:@"%@.jpg",[uploadFilePath stringByDeletingPathExtension]];
            [FileCenter deleteFile:imagePath];
        }
    }
    return [OLYMMessageObject deleteMessageByMessageId:msgObj.messageId inTableByUserId:self.currentChatUser.userId withDomain:self.currentChatUser.domain];
}


- (void)notifyBurnVideoFinished:(OLYMMessageObject *)msgObj
{
    if(!msgObj.isMySend)
    {
        //删除文件
        [FileCenter deleteFile:[[olym_FileCenter documentPrefix]stringByAppendingPathComponent:msgObj.filePath]];
        //发出通知，删除消息
        [olym_Nofity postNotificationName:kDeleteReadburnMessageNotifaction object:msgObj];
    }
}


- (void)deleteSelectedMessages:(NSArray <NSIndexPath *> *)selectedIndexPaths
{
    NSMutableArray *removeobjects = [NSMutableArray array];
    for (NSIndexPath *indexPath in selectedIndexPaths)
    {
        OLYMMessageObject *message = [self.dataArray objectAtIndex:indexPath.row];
        [self deleteMessageByMessage:message];
        [removeobjects addObject:message];
    }
    [self.dataArray removeObjectsInArray:removeobjects];
}

- (NSArray *)messagesForSelectedRows:(NSArray <NSIndexPath *> *)selectedIndexPaths
{
    NSMutableArray *messages = [NSMutableArray array];
    for (NSIndexPath *indexPath in selectedIndexPaths)
    {
        OLYMMessageObject *message = [self.dataArray objectAtIndex:indexPath.row];
        if (message.isReadburn)
        {
            continue;
        }
        [messages addObject:message];
    }
    return messages;
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

#pragma mark - 播放语音
- (void)playAudio:(NSString *)base64AudioString finished:(void (^)(void))callback
{
    [self.audioPlayer playBase64String:base64AudioString finished:callback];
}

- (void)stopAudioPlay
{
    [self.audioPlayer stop];
    self.isPlaying = NO;
}

- (BOOL)isAudioPlaying
{
    return [self.audioPlayer isPlaying];
}

//开始连续播放
- (void)playAudioByTurn:(NSInteger )startIndex
{
    [self stopAudioPlay];
    [self.audioArray removeAllObjects];
    for (int i = startIndex;  i < self.dataArray.count; i++)
    {
        OLYMMessageObject *message = [self.dataArray objectAtIndex:i];
        if (message.type ==  kWCMessageTypeVoice &&  !message.isMySend && !message.isRead)
        {
            [self.audioArray addObject:message];
        }
    }
    if (self.audioArray.count > 0)
    {
        self.playIndex = NSNotFound;
        self.isPlaying = YES;
        [self playTurnAction:0];
    }
}

//播放动作，发送已读回执
- (void)playTurnAction:(NSInteger)index
{
    if (index >= self.audioArray.count)
    {
        self.playIndex = NSNotFound;
        [self.audioArray removeAllObjects];
        self.isPlaying = NO;
        return;
    }
    if (!self.isPlaying)
    {
        self.playIndex = NSNotFound;
        [self.audioArray removeAllObjects];
        return;
    }
    self.playIndex = index;
    OLYMMessageObject *message = [self.audioArray objectAtIndex:index];
    //发送已读回执
    [self sendReadedMessage:message];
    [self.playAudioBeginSubject sendNext:message];

    WeakSelf(weakself);
    [self playAudio:message.content finished:^{
        [weakself.playAudioFinishedSubject sendNext:message];
        [weakself playTurnAction:index + 1];
    }];
}


- (void)stopAudioIfPlayInQueue:(OLYMMessageObject * )message
{
    //是否正在连续播放
    if (self.audioArray.count > 0)
    {
        __block NSInteger tempIndex = NSNotFound;
        [self.audioArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            OLYMMessageObject *messageObject = obj;
            
            if ([message.messageId isEqualToString:messageObject.messageId])
            {
                tempIndex = idx;
                *stop = YES;
            }
        }];
        if (tempIndex != NSNotFound)
        {
            if (tempIndex > self.playIndex)
            {
                [self.audioArray removeObjectAtIndex:tempIndex];
            }else if (tempIndex == self.playIndex)
            {
                [self stopAudioPlay];
                [self playAudioByTurn:tempIndex + 1];
            }
        }
    }else
    {
        if([self isAudioPlaying])
        {
           [self stopAudioPlay];
        }
    }
}

#pragma mark - 获取当前数组里的所有图片
- (NSArray *)getAllMessageImages
{
    NSMutableArray *images = [NSMutableArray array];
    for (NSInteger i = 0; i < self.dataArray.count; i++)
    {
        OLYMMessageObject *message = [self.dataArray objectAtIndex:i];
        if(message.type == kWCMessageTypeImage && !message.isReadburn)
        {
            GJCUImageBrowserModel *model = [[GJCUImageBrowserModel alloc]init];
            model.filePath = [[olym_FileCenter documentPrefix]stringByAppendingString:message.filePath];
            model.isAESEncrypt = message.isAESEncrypt;
            [images addObject:model];
        }
    }
    return images;
}

#pragma mark - 解密消息
- (NSString *)decryptMessage:(OLYMMessageObject *)messageObject
{
    NSString *content;
    if (messageObject.isGroup)
    {
        NSString *idfv = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        NSString *groupKey = [NSString stringWithFormat:@"%@%@", olym_UserCenter.userAccount, idfv];
        
        NSString *pass = GJCFStringToMD5(groupKey);
        BOOL value = [olym_Securityengine loginLocalDevice:messageObject.fromUserId withPass:pass];
        if(!value)
        {
            //不存在就开始下载
            value = [olym_Securityengine getGrouptPrivateKey:messageObject.fromUserId account:olym_UserCenter.userAccount withPass:pass];//[olym_Securityengine getGrouptPrivateKey:messageObject.fromUserId withPass:pass];
        }
        content = [olym_Securityengine decryptMessage:messageObject.fromUserId withConent:messageObject.content];
        
    }else
    {
        content = [olym_Securityengine decryptMessage:olym_UserCenter.userAccount withConent:messageObject.content];
    }
    return content;
}

- (NSString *)getReferenceContent:(OLYMMessageObject *)msgObj
{
    NSString *fromUserName = msgObj.fromUserName;
    if (msgObj.isMySend)
    {
        if(msgObj.isGroup){
            NSString *fromUserName;
            if (self.currentChatUser.userRemarkname)
            {
                fromUserName = self.currentChatUser.userRemarkname;
            }else
            {
                fromUserName = olym_UserCenter.userName;
            }
        }else
        {
            fromUserName = olym_UserCenter.userName;
        }
    }else
    {
        if (!msgObj.isGroup && !fromUserName) {
            fromUserName = self.currentChatUser.userNickname;
        }
    }
    NSString *content = [NSString stringWithFormat:@"「 %@: %@ 」\n- - - - - - - - - - - - - - -\n",fromUserName,msgObj.content];
    return content;
}

#pragma mark - private Method
- (NSArray *)showMessageTime:(NSArray *)fetchArray
{
    if (!fetchArray || fetchArray.count <= 0) {
        return nil;
    }
    BOOL isFirstPage = YES;
    if(self.dataArray.count > 0)
    {
        isFirstPage =  NO;
    }
    
    if (isFirstPage)
    {
        //第一页的数据
       
        NSMutableArray *tempArray = [NSMutableArray array];
        [tempArray addObjectsFromArray:fetchArray];

        OLYMMessageObject *firstMsg = [tempArray objectAtIndex:0];
        firstMsg.isShowTime = YES;
        for (NSInteger i = 0; (i < [tempArray count] - 1) && ([tempArray count] != 0); i++)
        {
            OLYMMessageObject *firstMsg = [tempArray objectAtIndex:i];
            if (i == 0)
            {
                firstMsg.isShowTime = YES;
            }
            OLYMMessageObject *secondMsg = [tempArray objectAtIndex:(i + 1)];
            if (([secondMsg.timeSend timeIntervalSince1970] - [firstMsg.timeSend timeIntervalSince1970] > MESSAGEINTERVAL * 60) && (secondMsg.type != kWCMessageTypeRemind)) {
                secondMsg.isShowTime = YES;
            }
        }
        return tempArray;
    }else
    {
        //后面的数据，处理后再加到数组
        
        NSMutableArray *tempArray = [NSMutableArray array];
        [tempArray addObjectsFromArray:fetchArray];
        
        OLYMMessageObject *firstMsg = [tempArray objectAtIndex:0];
        firstMsg.isShowTime = YES;
        for (NSInteger i = 0; (i < [tempArray count] - 1) && ([tempArray count] != 0); i++)
        {
            OLYMMessageObject *firstMsg = [tempArray objectAtIndex:i];
            if (i == 0)
            {
                firstMsg.isShowTime = YES;
            }
            OLYMMessageObject *secondMsg = [tempArray objectAtIndex:(i + 1)];
            if (([secondMsg.timeSend timeIntervalSince1970] - [firstMsg.timeSend timeIntervalSince1970] > MESSAGEINTERVAL * 60) && (secondMsg.type != kWCMessageTypeRemind)) {
                secondMsg.isShowTime = YES;
            }
        }
        //其实这个时候显示的应该是和最后一个比
        OLYMMessageObject *firstInArray = [self.dataArray firstObject];
        OLYMMessageObject *lastMsgInTemp = [self.dataArray lastObject];
        if (([firstInArray.timeSend timeIntervalSince1970] - [lastMsgInTemp.timeSend timeIntervalSince1970] > MESSAGEINTERVAL * 60) && (lastMsgInTemp.type != kWCMessageTypeRemind)) {
            firstInArray.isShowTime = YES;
        }else
        {
            firstInArray.isShowTime = NO;
        }

        return tempArray;
    }
    
}


- (NSArray *)showFooterMessageTime:(NSArray *)fetchArray
{
    NSMutableArray *tempArray = [NSMutableArray array];
    [tempArray addObjectsFromArray:fetchArray];
    
    
    OLYMMessageObject *firstMsg = [tempArray objectAtIndex:0];
    firstMsg.isShowTime = YES;
    for (NSInteger i = 0; (i < [tempArray count] - 1) && ([tempArray count] != 0); i++)
    {
        OLYMMessageObject *firstMsg = [tempArray objectAtIndex:i];
        if (i == 0 && firstMsg.type != kWCMessageTypeRemind)
        {
            firstMsg.isShowTime = YES;
        }
        OLYMMessageObject *secondMsg = [tempArray objectAtIndex:(i + 1)];
        if (([secondMsg.timeSend timeIntervalSince1970] - [firstMsg.timeSend timeIntervalSince1970] > MESSAGEINTERVAL * 60) && (secondMsg.type != kWCMessageTypeRemind)) {
            secondMsg.isShowTime = YES;
        }
    }
    //其实这个时候显示的应该是和最后一个比
    OLYMMessageObject *firstInArray = [tempArray firstObject];
    OLYMMessageObject *lastMsgInTemp = [self.dataArray lastObject];
    if (([firstInArray.timeSend timeIntervalSince1970] - [lastMsgInTemp.timeSend timeIntervalSince1970] > MESSAGEINTERVAL * 60) && (lastMsgInTemp.type != kWCMessageTypeRemind)) {
        firstInArray.isShowTime = YES;
    }else
    {
        firstInArray.isShowTime = NO;
    }
    return tempArray;
}


- (NSArray *)fetchMoreChatList
{
    NSArray *tempArray = [OLYMMessageObject fetchMessagesByUser:self.currentChatUser.userId withDomain:self.currentChatUser.domain byPageOffset:self.pageIndex];
    
    NSMutableArray *fetchArray = [[NSMutableArray alloc]initWithCapacity:tempArray.count];
    
    for(int i = [tempArray count]-1;i>=0;i--){
        [fetchArray addObject:[tempArray objectAtIndex:i]];
    }
    fetchArray = [self showMessageTime:fetchArray];
    if(fetchArray){
        NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:
                               NSMakeRange(0,[fetchArray count])];

        [self.dataArray insertObjects:fetchArray atIndexes:indexes];
    }
    
    if (fetchArray.count >= 20)
    {
        self.pageIndex += 20;
    }
    return fetchArray;

}

//这里是上拉加载
- (NSArray *)fetchMoreFooterChat
{
    NSArray *tempArray = [OLYMMessageObject fetchMessagesByUser:self.currentChatUser.userId withDomain:self.currentChatUser.domain byPageOffset:self.preIndex];
    NSMutableArray *fetchArray = [[NSMutableArray alloc]initWithCapacity:tempArray.count];
    
    for(int i = [tempArray count]-1;i>=0;i--){
        [fetchArray addObject:[tempArray objectAtIndex:i]];
    }
    fetchArray = [self showFooterMessageTime:fetchArray];
    if(fetchArray){
        
        [self.dataArray addObjectsFromArray:fetchArray];
    }
    
    if (fetchArray.count >= 20)
    {
        self.preIndex -= 20;
        if (self.preIndex < -19)
        {
            self.preIndex = NSNotFound;
        }
    }else
    {
        self.preIndex = NSNotFound;
    }
    return fetchArray;
}


- (void)downloadGroupPrivateKey
{
    if (!self.currentChatUser.isGroup)
    {
        return;
    }
    dispatch_async(XmppSendQueue, ^{
        NSString *idfv = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        NSString *groupKey = [NSString stringWithFormat:@"%@%@", olym_UserCenter.userAccount, idfv];
        
        NSString *password = GJCFStringToMD5(groupKey);
        
        BOOL value = [olym_Securityengine loginLocalDevice:self.currentChatUser.userId withPass:password];
        
        if(!value){
            //不存在就开始下载群私钥
//            value = [olym_Securityengine getGrouptPrivateKey:self.currentChatUser.userId withPass:password];
            value = [olym_Securityengine getGrouptPrivateKey:self.currentChatUser.userId account:olym_UserCenter.userAccount withPass:password];
        }
    });

}

#pragma mark - property

- (OLMAmrPlayer *)audioPlayer
{
    if (!_audioPlayer) {
        _audioPlayer = [[OLMAmrPlayer alloc]init];
    }
    return _audioPlayer;
}


- (NSMutableArray *)reminderArray
{
    if (!_reminderArray) {
        _reminderArray = [NSMutableArray array];
    }
    return _reminderArray;
}


- (RACSubject *)transpondClickSubject {
    
    if (!_transpondClickSubject) {
        
        _transpondClickSubject = [RACSubject subject];
    }
    
    return _transpondClickSubject;
}


- (RACSubject *)headerLongPressSubject
{
    if (!_headerLongPressSubject) {
        _headerLongPressSubject = [RACSubject subject];
    }
    return _headerLongPressSubject;
}

- (RACCommand *)refreshDataCommand
{
    if (!_refreshDataCommand)
    {
        @weakify(self);
        
        _refreshDataCommand = [[RACCommand alloc]initWithSignalBlock:^RACSignal * _Nonnull(id  _Nullable input) {
            @strongify(self);

            return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
                
                @strongify(self);
                [subscriber sendNext:nil];
                [subscriber sendCompleted];
                return nil;

            }];
        }];
    }
    return _refreshDataCommand;
}

- (RACCommand *)refreshFooterDataCommand
{
    if (!_refreshFooterDataCommand)
    {
        @weakify(self);
        
        _refreshFooterDataCommand = [[RACCommand alloc]initWithSignalBlock:^RACSignal * _Nonnull(id  _Nullable input) {
            @strongify(self);
            
            return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
                
                @strongify(self);
                [subscriber sendNext:nil];
                [subscriber sendCompleted];
                return nil;
                
            }];
        }];
    }
    return _refreshFooterDataCommand;
}

- (RACCommand *)getUserInfoCommand
{
    if(!_getUserInfoCommand)
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


- (RACSubject *)imageShowSubject
{
    if (!_imageShowSubject) {
        _imageShowSubject = [RACSubject subject];
    }
    return _imageShowSubject;
}

- (RACSubject *)imageBurnShowSubject
{
    if (!_imageBurnShowSubject) {
        _imageBurnShowSubject = [RACSubject subject];
    }
    return _imageBurnShowSubject;
}


- (RACSubject *)videoShowSubject
{
    if (!_videoShowSubject) {
        _videoShowSubject = [RACSubject subject];
    }
    return _videoShowSubject;
}


- (RACSubject *)fileShowSubject
{
    if (!_fileShowSubject) {
        _fileShowSubject = [RACSubject subject];
    }
    return _fileShowSubject;
}


- (RACSubject *)textBurnShowSubject
{
    if (!_textBurnShowSubject) {
        _textBurnShowSubject = [RACSubject subject];
    }
    return _textBurnShowSubject;
}


- (RACSubject *)cardShowSubject
{
    if (!_cardShowSubject) {
        _cardShowSubject = [RACSubject subject];
    }
    return _cardShowSubject;
}

- (RACSubject *)videoBurnShowSubject
{
    if (!_videoBurnShowSubject) {
        _videoBurnShowSubject = [RACSubject subject];
    }
    return _videoBurnShowSubject;
}

- (RACSubject *)getUserInfoSubject
{
    if (!_getUserInfoSubject) {
        _getUserInfoSubject = [RACSubject subject];
    }
    return _getUserInfoSubject;
}

- (RACSubject *)playAudioFinishedSubject
{
    if(!_playAudioFinishedSubject)
    {
        _playAudioFinishedSubject = [RACSubject subject];
    }
    return _playAudioFinishedSubject;
}

- (RACSubject *)playAudioBeginSubject
{
    if(!_playAudioBeginSubject)
    {
        _playAudioBeginSubject = [RACSubject subject];
    }
    return _playAudioBeginSubject;
}

- (RACSubject *)linkClickedSubject
{
    if (!_linkClickedSubject) {
        _linkClickedSubject = [RACSubject subject];
    }
    return _linkClickedSubject;
}

- (RACSubject *)referenceMsgSubject
{
    if (!_referenceMsgSubject)
    {
        _referenceMsgSubject = [RACSubject subject];
    }
    return _referenceMsgSubject;
}

- (RACSubject *)mutiSelectMsgSubject
{
    if (!_mutiSelectMsgSubject)
    {
        _mutiSelectMsgSubject = [RACSubject subject];
    }
    return _mutiSelectMsgSubject;
}

- (RACSubject *)tablecellEditSubject
{
    if (!_tablecellEditSubject)
    {
        _tablecellEditSubject = [RACSubject subject];
    }
    return _tablecellEditSubject;
}

- (RACSubject *)fileDeleteSubject
{
    if (!_fileDeleteSubject)
    {
        _fileDeleteSubject = [RACSubject subject];
    }
    return _fileDeleteSubject;
}

- (RACSubject *)msgDeleteSubject
{
    if (!_msgDeleteSubject)
    {
        _msgDeleteSubject = [RACSubject subject];
    }
    return _msgDeleteSubject;
}


- (NSMutableArray *)audioArray
{
    if (!_audioArray)
    {
        _audioArray = [NSMutableArray array];
    }
    return _audioArray;
}

- (void)dealloc
{
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
}
@end
