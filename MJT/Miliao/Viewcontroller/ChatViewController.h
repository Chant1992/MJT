//
//  ChatViewController.h
//  MJT_APP
//
//  Created by olymtech on 2017/8/29.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "OLYMViewController.h"

@class OLYMUserObject;
@class OLYMMessageObject;

@interface ChatViewController : OLYMViewController

@property(strong,nonatomic) OLYMUserObject *currentChatUser;

@property(strong,nonatomic) OLYMMessageObject *searchMessaegObject;


@end
