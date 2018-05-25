//
//  BurnAfterReadingViewModel.h
//  MJT_APP
//
//  Created by Donny on 2017/9/12.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "OLYMListViewModel.h"

@class OLYMMessageObject;
@class OLYMUserObject;

@interface BurnAfterReadingViewModel : OLYMListViewModel


- (instancetype)initWithUser:(OLYMUserObject *)currentChatUser;

/**
 send message read receipt
 
 @param msgObj read message object
 */

- (void)sendReadedMessage:(OLYMMessageObject *)msgObj;


/**
 send take screen message

 @param msgObj burnafterreading message
 */
- (void)sendTakeScreenshotMessage:(OLYMMessageObject *)msgObj;


/**
 play audio with base64String
 
 @param base64AudioString base64AudioString
 @param callback finish play
 */
- (void)playAudio:(NSString *)base64AudioString finished:(void (^)(void))callback;


/**
 stop audio
 */
- (void)stopAudioPlay;


/**
 detect if audio is playing
 
 @return audio is playing
 */
- (BOOL)isAudioPlaying;

@end

