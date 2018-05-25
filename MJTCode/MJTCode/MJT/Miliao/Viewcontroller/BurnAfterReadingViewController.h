//
//  BurnAfterReadingViewController.h
//  MJT_APP
//
//  Created by Donny on 2017/9/12.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "OLYMViewController.h"
@class OLYMMessageObject;
@class OLYMUserObject;

@interface BurnAfterReadingViewController : OLYMViewController

@property(nonatomic,strong) OLYMMessageObject *msgObj;
@property(nonatomic,strong) OLYMUserObject *currentChatUser;
@end
