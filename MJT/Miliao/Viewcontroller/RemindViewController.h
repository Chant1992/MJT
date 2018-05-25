//
//  RemindViewController.h
//  MJT_APP
//
//  Created by Donny on 2017/9/14.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "OLYMViewController.h"
@class OLYMUserObject;

@interface RemindViewController : OLYMViewController

@property(strong,nonatomic) OLYMUserObject *currentChatUser;

@property (nonatomic, copy) void (^ remindChooseOneContact) (NSString *userName,NSString *userId);

@end
