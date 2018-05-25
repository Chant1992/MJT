//
//  ChatFriendConstans.m
//  MJT_APP
//
//  Created by olymtech on 2017/8/29.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "ChatFriendConstans.h"
#import "ChatTextMessageCell.h"
#import "ChatImageMessageCell.h"
#import "OLYMMessageObject.h"
#import "ChatAudioMessageCell.h"
#import "ChatFileMessageCell.h"
#import "ChatVideoMessageCell.h"
#import "ChatGifMessageCell.h"
#import "ChatCardMessageCell.h"
#import "ChatBurnMessageCell.h"
#import "ChatRemindMsgCell.h"
#import "ChatRecallCell.h"

@implementation ChatFriendConstans


+ (NSDictionary *)chatCellIdentifierDict
{
    return @{
             
             @"ChatTextMessageCell" : [NSString stringWithUTF8String:object_getClassName([ChatTextMessageCell class])],
             @"ChatImageMessageCell" : [NSString stringWithUTF8String:object_getClassName([ChatImageMessageCell class])],
             @"ChatAudioMessageCell" : [NSString stringWithUTF8String:object_getClassName([ChatAudioMessageCell class])],
             @"ChatVideoMessageCell" : [NSString stringWithUTF8String:object_getClassName([ChatVideoMessageCell class])],
             @"ChatCardMessageCell" : [NSString stringWithUTF8String:object_getClassName([ChatCardMessageCell class])],
             @"ChatFileMessageCell" : [NSString stringWithUTF8String:object_getClassName([ChatFileMessageCell class])],
             @"ChatBurnMessageCell" : [NSString stringWithUTF8String:object_getClassName([ChatBurnMessageCell class])],
             @"ChatBurnRemindMessageCell" : [NSString stringWithUTF8String:object_getClassName([ChatRemindMsgCell class])],
             @"kWCMessageTypeReCall" : [NSString stringWithUTF8String:object_getClassName([ChatRecallCell class])]
             };
    
}


+ (NSDictionary *)chatCellContentTypeDict
{
    return @{
             
             @(kWCMessageTypeText) : [NSString stringWithUTF8String:object_getClassName([ChatTextMessageCell class])],
             @(kWCMessageTypeImage) : [NSString stringWithUTF8String:object_getClassName([ChatImageMessageCell class])],
             @(kWCMessageTypeVoice) : [NSString stringWithUTF8String:object_getClassName([ChatAudioMessageCell class])],
             @(kWCMessageTypeGif) : [NSString stringWithUTF8String:object_getClassName([ChatGifMessageCell class])],
             @(kWCMessageTypeVideo) : [NSString stringWithUTF8String:object_getClassName([ChatVideoMessageCell class])],
             @(kWCMessageTypeAudio) : [NSString stringWithUTF8String:object_getClassName([ChatTextMessageCell class])],
             @(kWCMessageTypeCard) : [NSString stringWithUTF8String:object_getClassName([ChatCardMessageCell class])],
             @(kWCMessageTypeFile) : [NSString stringWithUTF8String:object_getClassName([ChatFileMessageCell class])],
             @(kWCMessageTypeRemind) : [NSString stringWithUTF8String:object_getClassName([ChatRemindMsgCell class])],
             @(kWCMessageTypeReCall) : [NSString stringWithUTF8String:object_getClassName([ChatRecallCell class])]
             };
}


+ (Class)classForContentType:(int)contentType isReadBurn:(BOOL)isReadBurn{
    NSString *className;
    if (isReadBurn)
    {
        className = [NSString stringWithUTF8String:object_getClassName([ChatBurnMessageCell class])];
    }else
    {
        className = [[ChatFriendConstans chatCellContentTypeDict]objectForKey:@(contentType)];
    }
    
    return NSClassFromString(className);
}

+ (NSString *)identifierForContentType:(int)contentType isReadBurn:(BOOL)isReadBurn
{
    NSString *className;
    if (isReadBurn)
    {
        className = [NSString stringWithUTF8String:object_getClassName([ChatBurnMessageCell class])];
    }else
    {
        className = [[ChatFriendConstans chatCellContentTypeDict]objectForKey:@(contentType)];
    }
    
    return [ChatFriendConstans identifierForCellClass:className];
}

+ (NSString *)identifierForCellClass:(NSString *)className
{
    return  [[ChatFriendConstans chatCellIdentifierDict]objectForKey:className];
}


@end
