//
//  BurnAfterReadingViewModel.m
//  MJT_APP
//
//  Created by Donny on 2017/9/12.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "BurnAfterReadingViewModel.h"
#import "OLYMMessageObject.h"
#import "OLMAmrPlayer+Base64String.h"
#import "OLYMUserObject.h"

@interface  BurnAfterReadingViewModel ()

@property (nonatomic, strong) OLMAmrPlayer *audioPlayer;
@property (nonatomic,strong) OLYMUserObject *currentChatUser;
@end


@implementation BurnAfterReadingViewModel

- (instancetype)initWithUser:(OLYMUserObject *)currentChatUser
{
    self = [super init];
    if(self){
        self.currentChatUser = currentChatUser;
    }
    return self;

}
- (void)olym_initialize{
    
}

- (void)sendReadedMessage:(OLYMMessageObject *)msgObj
{
    // 标记阅后即焚已读
    if(msgObj.isMySend && msgObj.isGroup)
    {
        return;
    }
    NSString *fromUserId = msgObj.fromUserId;
    if (msgObj.isGroup)
    {
        fromUserId = msgObj.roomId;
    }
    

    OLYMMessageObject *msg = [[OLYMMessageObject alloc]init];
    msg.content = [NSString stringWithFormat:@"%@",msgObj.messageId];
    msg.toUserId = fromUserId;
    msg.fromUserId = msgObj.toUserId;
    msg.isRead = YES;
    msg.domain = msgObj.domain;
    if(GJCFStringIsNull(msgObj.domain)){
        msg.domain = [olym_Default objectForKey:kMY_USER_LOGIN_DOMAIN];
    }
    msg.toUserIbcKey = msgObj.toUserIbcKey;
    msg.isReadburn = msgObj.isReadburn;
    msg.type = kWCMessageTypeIsRead;
    
    [msg setMessageId];
    
    [msg sendMessage];
}


- (void)sendTakeScreenshotMessage:(OLYMMessageObject *)msgObj
{
    if (!msgObj.isMySend)
    {
        OLYMMessageObject *msg = [[OLYMMessageObject alloc]init];
        msg.timeSend = [NSDate date];
        msg.toUserId = self.currentChatUser.userId;
        msg.toUserIbcKey = msgObj.toUserIbcKey;
        msg.fromUserId = olym_UserCenter.userId;
        msg.domain = msgObj.domain;
        if(GJCFStringIsNull(msgObj.domain)){
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
        

        NSString *content;
        if(self.currentChatUser.roomFlag == 1)
        {
            content = [NSString stringWithFormat:_T(@"%@对阅后即焚消息进行了截屏"),fromName];
        }else
        {
            content = [NSString stringWithFormat:@"%@%@",fromName,_T(@"对您的阅后即焚消息进行了截屏")];
        }
        msg.content = content;
        
        msg.isGroup = self.currentChatUser.roomFlag == 1 ? YES:NO;
        [msg setIsMySend:YES];
        
        [msg setMessageId];
        
        [msg sendMessage];

    }
}


- (void)playAudio:(NSString *)base64AudioString finished:(void (^)(void))callback
{
    [self.audioPlayer playBase64String:base64AudioString finished:callback];
}

- (void)stopAudioPlay
{
    [self.audioPlayer stop];
}

- (BOOL)isAudioPlaying
{
    return [self.audioPlayer isPlaying];
}



#pragma mark - property
- (OLMAmrPlayer *)audioPlayer
{
    if (!_audioPlayer) {
        _audioPlayer = [[OLMAmrPlayer alloc]init];
    }
    return _audioPlayer;
}




@end
