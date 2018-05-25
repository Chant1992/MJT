//
//  TranspondHelper.m
//  MJT_APP
//
//  Created by Donny on 2017/9/25.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "SendFileHelper.h"
#import "OLYMMessageObject.h"
#import "GJCFFileUploadManager.h"

NSString *const MessageFileUploadFinishedNotification = @"MessageFileUploadFinishedNotification";
NSString *const MessageFileUploadFailedNotification = @"MessageFileUploadFailedNotification";
NSString *const MessageFileUploadingNotification = @"MessageFileUploadingNotification";

@interface SendFileHelper ()

@property (nonatomic, strong) NSMutableArray *messageArray;
@end

@implementation SendFileHelper

+ (instancetype)shareInstance
{
    static SendFileHelper *obj = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        obj = [[SendFileHelper alloc]init];
    });
    return obj;
}

- (instancetype)init
{
    if(self = [super init])
    {
        [self configFileUploadManager];
    }
    return self;
}



- (void)configFileUploadManager
{
    GJCFWeakSelf weakSelf = self;
    [[GJCFFileUploadManager shareUploadManager] setCompletionBlock:^(GJCFFileUploadTask *task, NSDictionary *resultDict) {
        GJCFStrongSelf strongSelf = weakSelf;
        [strongSelf finishUploadWithTask:task withUploadFileDictiony:resultDict];
        
    } forObserver:self];
    [[GJCFFileUploadManager shareUploadManager] setProgressBlock:^(GJCFFileUploadTask *updateTask, CGFloat progressValue) {
        GJCFStrongSelf strongSelf = weakSelf;
        [strongSelf uploadFileWithTask:updateTask progress:progressValue];
    } forObserver:self];

    [[GJCFFileUploadManager shareUploadManager]setFaildBlock:^(GJCFFileUploadTask *task, NSError *error) {
        GJCFStrongSelf strongSelf = weakSelf;
        [strongSelf failedUploadWithTask:task error:error];
    } forObserver:self];
}



- (void)uploadFile:(OLYMMessageObject *)message{
    
    GJCFUploadFileModel *uploadFileModel = message.uploadFileModel;
    //文件已经在上传或者已经执行过上传
    BOOL exist = [self uploadTaskExist:message.messageId];
    if (exist)
    {
        return;
    }
    NSString *taskIdentifier = nil;
    GJCFFileUploadTask *uploadTask = [GJCFFileUploadTask taskWithFilePath:uploadFileModel.localStorePath withFileName:uploadFileModel.fileName withFormName:uploadFileModel.formName taskObserver:self getTaskUniqueIdentifier:&taskIdentifier];
    
    message.uniqueIdentifier = taskIdentifier;
    
    uploadTask.userInfo = @{
                            ENCRYPT_IBC_KEY:message.isGroup?message.toUserId:message.toUserIbcKey,
                            ENCRYPT_IS_GROUP_KEY:@(message.isGroup),
                            ENCRYPT_MESSAGE_ID_KEY:message.messageId,
                            ENCRYPT_FILE_RECEIVE_DOMAIN_KEY:message.domain,
                            ENCRYPT_FILE_IS_AES_KEY:@(message.isAESEncrypt)
                            };
    
    [[GJCFFileUploadManager shareUploadManager]updateHostUrl];

    [self.messageArray addObject:message];

    [[GJCFFileUploadManager shareUploadManager] addTask:uploadTask];
}

- (void)finishUploadWithTask:(GJCFFileUploadTask *)task withUploadFileDictiony:(NSDictionary *)fileDic
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if([[fileDic objectForKey:@"code"] intValue] == 200){
            NSString *url = [fileDic objectForKey:@"url"];
            
            OLYMMessageObject * messageObject= [self contentModelByUploadUniqueIdentifier:task.uniqueIdentifier];
            if (messageObject)
            {
                [self.messageArray removeObject:messageObject];
                messageObject.content = url;
                [messageObject updateContent];
                
                [messageObject sendMessage];
                
                //发回到UI
                [olym_Nofity postNotificationName:MessageFileUploadFinishedNotification object:messageObject];
            }
        }else
        {
            OLYMMessageObject * messageObject = [self contentModelByUploadUniqueIdentifier:task.uniqueIdentifier];
            if (messageObject)
            {
                [self.messageArray removeObject:messageObject];
                [messageObject updateSendStatus:transfer_status_no];
                //发回到UI
                [olym_Nofity postNotificationName:MessageFileUploadFailedNotification object:messageObject];
            }
        }
    });
}

- (void)failedUploadWithTask:(GJCFFileUploadTask *)task error:(NSError *)error
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        OLYMMessageObject * messageObject= [self contentModelByUploadUniqueIdentifier:task.uniqueIdentifier];
        if (messageObject)
        {
            [self.messageArray removeObject:messageObject];
            [messageObject updateSendStatus:transfer_status_no];
            //发回到UI
            [olym_Nofity postNotificationName:MessageFileUploadFailedNotification object:messageObject];
        }

    });
}

- (void)uploadFileWithTask:(GJCFFileUploadTask *)task progress:(CGFloat)progress
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //发回到UI
//        [olym_Nofity postNotificationName:MessageFileUploadingNotification object:messageObject];
    });

}


- (BOOL)uploadTaskExist:(NSString *)messageId
{
    __block BOOL ret = NO;
    [self.messageArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        OLYMMessageObject *message = obj;
        if ([messageId isEqualToString:message.messageId])
        {
            ret = YES;
            *stop = YES;
        }
    }];
    return ret;
}


- (OLYMMessageObject *)contentModelByUploadUniqueIdentifier:(NSString *)uniqueIdentifier
{
    for(OLYMMessageObject *messageObject in self.messageArray){
        
        if([messageObject.uniqueIdentifier isEqualToString:uniqueIdentifier]){
            return messageObject;
        }
    }
    return nil;
}

#pragma mark - Property
- (NSMutableArray *)messageArray{
    if (!_messageArray) {
        _messageArray = [NSMutableArray array];
    }
    return _messageArray;
}

@end
