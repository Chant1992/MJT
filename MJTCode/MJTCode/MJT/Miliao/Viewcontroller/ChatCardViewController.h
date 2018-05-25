//
//  ChatCardViewController.h
//  MJT_APP
//
//  Created by Donny on 2017/9/12.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "OLYMViewController.h"


typedef NS_ENUM(NSInteger, ChatCardType){
    
    ChatCardToChatPerson = 0,  //发其他人的名片给当前聊天的人
    ChatCardToOtherPerson      //把此人名片推荐给其他人
};

@class OLYMUserObject;

@interface ChatCardViewController : OLYMViewController

@property(strong,nonatomic) OLYMUserObject *currentChatUser;

/* 是推荐给其他人，还是发名片给当前聊天的人 */
@property(nonatomic,assign) ChatCardType chatCardType;

@end
