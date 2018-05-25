//
//  TranspondHelper.h
//  MJT_APP
//
//  Created by Donny on 2017/9/25.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const  MessageFileUploadFinishedNotification;
extern NSString *const MessageFileUploadFailedNotification;
extern NSString *const MessageFileUploadingNotification;

@class OLYMMessageObject;
@interface SendFileHelper : NSObject

+ (instancetype)shareInstance;


- (void)uploadFile:(OLYMMessageObject *)message;

@end
