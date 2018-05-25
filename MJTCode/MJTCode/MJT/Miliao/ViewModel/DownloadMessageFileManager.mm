//
//  DownloadMessageFileManager.m
//  MJT_APP
//
//  Created by Donny on 2017/10/19.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "DownloadMessageFileManager.h"
#import "GJCFFileDownloadManager.h"
#import "OLYMMessageObject.h"

NSString *const MessageFileDownloadFinishedNotification = @"MessageFileDownloadFinishedNotification";
NSString *const MessageFileDownloadFailedNotification = @"MessageFileDownloadFailedNotification";
NSString *const MessageFileDownloadingNotification = @"MessageFileDownloadingNotification";

@interface DownloadMessageFileManager ()

@property (nonatomic, strong) NSMutableArray *messageArray;

@end

@implementation DownloadMessageFileManager
+ (instancetype)shareInstance
{
    static DownloadMessageFileManager *obj = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        obj = [[DownloadMessageFileManager alloc]init];
    });
    return obj;
}

- (instancetype)init
{
    if(self = [super init])
    {
        [self configFileDownloadManager];
    }
    return self;
}

- (void)configFileDownloadManager
{
    GJCFWeakSelf weakSelf = self;
    [[GJCFFileDownloadManager shareDownloadManager] setDownloadCompletionBlock:^(GJCFFileDownloadTask *task, NSData *fileData, BOOL isFinishCache) {
        GJCFStrongSelf strongSelf = weakSelf;
        
        [strongSelf finishDownloadWithTask:task withDownloadFileData:fileData withDecryptSuccess:isFinishCache];
        
    } forObserver:self];
    
    [[GJCFFileDownloadManager shareDownloadManager] setDownloadFaildBlock:^(GJCFFileDownloadTask *task, NSError *error) {
        GJCFStrongSelf strongSelf = weakSelf;
        
        [strongSelf faildDownloadFileWithTask:task];
        
    } forObserver:self];
    
    [[GJCFFileDownloadManager shareDownloadManager] setDownloadProgressBlock:^(GJCFFileDownloadTask *task,CGFloat progress,long long totalUnitCount,long long completedUnitCount) {
        GJCFStrongSelf strongSelf = weakSelf;
        
        [strongSelf downloadFileWithTask:task progress:progress totalUnitCount:totalUnitCount completedUnitCount:completedUnitCount];
        
    } forObserver:self];
}


- (void)downloadTask:(OLYMMessageObject *)message currentChatUserId:(NSString *)userId domain:(NSString *)domain
{
    OLYMMessageObject *imageContentModel = message;
    //判断是否在下载中
    BOOL exist = [self downloadTaskExist:message.messageId];
    
    if(!exist){
        NSString *taskIdentifier = nil;
        NSString *fileName = imageContentModel.fileName;
        if (!fileName) {
            fileName = @"";
        }
        NSString *filePath = [NSString stringWithFormat:@"%@/%ld%@",[olym_FileCenter getMyFileLocalPath:userId],(long)[[NSDate date]timeIntervalSince1970],fileName];
        
        GJCFFileDownloadTask *task = [GJCFFileDownloadTask taskWithDownloadUrl:imageContentModel.content withCachePath:filePath withObserver:self getTaskIdentifer:&taskIdentifier];
        
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
        [userInfo setObject:imageContentModel.fileName forKey:DECRYPT_FILE_NAME_KEY];
        [userInfo setObject:imageContentModel.isGroup?imageContentModel.roomId:olym_UserCenter.userAccount forKey:DECRYPT_IBC_KEY];
        [userInfo setObject:@(imageContentModel.isGroup) forKey:DECRYPT_IS_GROUP_KEY];
        if (imageContentModel.messageId)
        {
            [userInfo setObject:imageContentModel.messageId forKey:DECRYPT_MESSAGE_ID_KEY];
        }
        
        [task setUserInfo:userInfo];
        
        imageContentModel.uniqueIdentifier = taskIdentifier;
        
        message.domain = domain;
        [self.messageArray addObject:message];

        [[GJCFFileDownloadManager shareDownloadManager]addTask:task];
    }
    
}



- (void)finishDownloadWithTask:(GJCFFileDownloadTask *)task withDownloadFileData:(NSData *)fileData withDecryptSuccess:(BOOL)isDecryptSuccess
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if(isDecryptSuccess){
            OLYMMessageObject *message = [self contentModelByUploadUniqueIdentifier:task.taskUniqueIdentifier];
            if (message)
            {
                //发回到UI
                NSString *filePath = task.cachePath;
                if (filePath)
                {
                    message.filePath = [filePath stringByReplacingOccurrencesOfString:[olym_FileCenter documentPrefix] withString:@""];
                }
                message.isFileReceive = YES;
                message.isAESEncrypt = YES;
                [message updateIsFileReceive];
                [self.messageArray removeObject:message];
                //发回到UI
                [olym_Nofity postNotificationName:MessageFileDownloadFinishedNotification object:message];
            }
        }

    });

}

- (void)downloadFileWithTask:(GJCFFileDownloadTask *)task progress:(CGFloat)progress totalUnitCount:(long long)totalUnitCount completedUnitCount:(long long)completedUnitCount
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        OLYMMessageObject *message = [self contentModelByUploadUniqueIdentifier:task.taskUniqueIdentifier];
        if (message)
        {
            message.progress = progress;
            if (message.fileSize == 0) {
                message.fileSize = totalUnitCount;
                [message updateFileSize];
            }
            //发回到UI
            [olym_Nofity postNotificationName:MessageFileDownloadingNotification object:message];
        }
    });
}

- (void)faildDownloadFileWithTask:(GJCFFileDownloadTask *)task
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        OLYMMessageObject *message = [self contentModelByUploadUniqueIdentifier:task.taskUniqueIdentifier];
        if (message)
        {
            //发回到UI
            [self.messageArray removeObject:message];
            [olym_Nofity postNotificationName:MessageFileDownloadFailedNotification object:message];
        }


    });
}




- (BOOL)downloadTaskExist:(NSString *)messageId
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
