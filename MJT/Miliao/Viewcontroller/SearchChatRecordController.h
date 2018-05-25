//
//  SearchChatRecordController.h
//  MJT_APP
//
//  Created by Donny on 2017/12/18.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "OLYMViewController.h"
@class OLYMUserObject;

@interface SearchChatRecordController : OLYMViewController

@property(strong,nonatomic) OLYMUserObject *currentChatUser;

@property(nonatomic,strong) NSArray *searchArray;

@end
