//
//  ChatMediaViewController.h
//  MJT_APP
//
//  Created by Donny on 2017/12/26.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//  某个聊天媒体类文件显示控制器，包含图片和视频

#import "OLYMViewController.h"
@class ChatFileViewModel;
@interface ChatMediaViewController : OLYMViewController

@property (nonatomic, strong) ChatFileViewModel *chatFileViewModel;

@property (nonatomic, strong) UIViewController *mParentController;

@property (nonatomic, assign) BOOL showEdit;

- (void)reserveState;

@end
