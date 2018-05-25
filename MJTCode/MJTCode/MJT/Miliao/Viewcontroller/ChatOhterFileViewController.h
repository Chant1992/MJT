//
//  ChatOhterFileViewController.h
//  MJT_APP
//
//  Created by Donny on 2017/12/26.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "OLYMViewController.h"
@class ChatFileViewModel;
@interface ChatOhterFileViewController : OLYMViewController

@property (nonatomic, strong) ChatFileViewModel *chatFileViewModel;

@property (nonatomic, strong) UIViewController *mParentController;

@property (nonatomic, assign) BOOL showEdit;

- (void)reserveState;

@end
