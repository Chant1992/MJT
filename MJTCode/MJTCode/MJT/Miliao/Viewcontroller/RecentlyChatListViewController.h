//
//  RecentlyChatListViewController.h
//  MJT_APP
//
//  Created by Donny on 2017/9/11.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "OLYMViewController.h"

@class OLYMMessageObject;
@interface RecentlyChatListViewController : OLYMViewController

/* 转发的消息 */
@property (nonatomic, strong) OLYMMessageObject *messageObj;

@property (nonatomic, strong) NSArray *forwardMessages;
@property(nonatomic,strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *selectionArray;

- (void)leftButtonPressed:(UIButton *)sender;
@end
