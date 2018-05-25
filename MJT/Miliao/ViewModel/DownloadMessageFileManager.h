//
//  DownloadMessageFileManager.h
//  MJT_APP
//
//  Created by Donny on 2017/10/19.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>
@class OLYMMessageObject;

extern NSString *const  MessageFileDownloadFinishedNotification;
extern NSString *const MessageFileDownloadFailedNotification;
extern NSString *const MessageFileDownloadingNotification;


@interface DownloadMessageFileManager : NSObject

+ (instancetype)shareInstance;

- (void)downloadTask:(OLYMMessageObject *)message currentChatUserId:(NSString *)userId domain:(NSString *)domain;

@end
