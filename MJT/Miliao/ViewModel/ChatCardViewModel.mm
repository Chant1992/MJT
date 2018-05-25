//
//  ChatCardViewModel.m
//  MJT_APP
//
//  Created by Donny on 2017/9/12.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "ChatCardViewModel.h"
#import "OLYMUserObject.h"
#import "NSString+PinYin.h"
#import "OLYMMessageObject.h"
#import "OLYMUserObject+Pinyin.h"

@interface ChatCardViewModel ()

@property(strong,nonatomic) OLYMUserObject *currentChatUser;
@property(nonatomic,assign) ChatCardType chatCardType;
@property(nonatomic,strong) NSMutableArray* allContacts;

@end

@implementation ChatCardViewModel
-(instancetype)initWithUser:(OLYMUserObject *)currentChatUser chatCardType:(ChatCardType)chatCardType{
    
    self = [super init];
    if(self){
        self.currentChatUser = currentChatUser;
        self.chatCardType = chatCardType;
        [self getData];
    }
    return self;
}

- (void)olym_initialize{
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

}


- (void)getData
{
    NSArray *fetchArray = [OLYMUserObject fetchAllFriends];
    
    NSMutableArray *tempFriends = [NSMutableArray array];
    for (OLYMUserObject *userObj in fetchArray)
    {
        
        if (userObj.status == friend_status_friend || userObj.status == friend_status_colleague)
        {
            //好友
            NSString *nickName = userObj.userNickname;
            userObj.nameLetters = [nickName getFirstLetters];
            [tempFriends addObject:userObj];
        }else{
            
        }
    }
    self.allContacts = tempFriends;
    
    if (Organization && [[olym_Default objectForKey:kAPI_ORGAN_Model] boolValue]) {
            
        NSMutableDictionary *myDic = [NSMutableDictionary dictionary];
        NSArray *myArray = @[@"公司通讯录"];
        NSString *firstLetter = @"";
        [myDic setObject:firstLetter forKey:@"firstLetter"];
        [myDic setObject:myArray forKey:@"content"];
        
        [self.dataArray addObject:myDic];
    }
    
    [self.dataArray addObjectsFromArray:[tempFriends arrayWithPinYinFirstLetterFormat]];
}


- (void)sendCardMessagetoUser:(OLYMUserObject *)userObj
{
    OLYMMessageObject *msg = [[OLYMMessageObject alloc]init];
    [msg setMessageId];
    msg.timeSend = [NSDate date];
    msg.type = kWCMessageTypeCard;

    if (self.chatCardType == 0)
    {
        NSString *telephone;
        telephone = userObj.telephone;

        msg.fromUserId = olym_UserCenter.userId;
        msg.isGroup = self.currentChatUser.roomFlag == 1 ? YES:NO;
        msg.toUserId = self.currentChatUser.userId;
        msg.toUserIbcKey = self.currentChatUser.telephone;
        msg.content = [NSString stringWithFormat:@"%@:%@:%@",userObj.userNickname,userObj.domain,telephone];
        msg.domain = self.currentChatUser.domain;
        msg.objectId = userObj.userId;
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

    }else
    {
        msg.fromUserId = olym_UserCenter.userId;
        msg.toUserId = userObj.userId;
        msg.toUserIbcKey = userObj.telephone;
        msg.content = [NSString stringWithFormat:@"%@:%@:%@",self.currentChatUser.userNickname,self.currentChatUser.domain,self.currentChatUser.telephone];
        msg.objectId = self.currentChatUser.userId;
        msg.domain = userObj.domain;
    }

    
    msg.isSend = transfer_status_ing;
    msg.isRead = YES;
    msg.isMySend = YES;
    msg.isEncrypt = YES;

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

}

@end
