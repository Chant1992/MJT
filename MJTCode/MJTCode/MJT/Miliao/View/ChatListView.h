//
//  ChatListView.h
//  MJT_APP
//
//  Created by olymtech on 2017/8/29.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "OLYMBaseListView.h"

extern NSString *const kChatListViewWillBeginDraggingNotification;

@interface ChatListView : OLYMBaseListView

#if TESTSYNC
@property (nonatomic, strong) UILabel *receiveLabel;
@property (nonatomic, strong) UILabel *sendLabel;
@property (nonatomic, strong) UIButton *resetButton;

#endif

- (void)doRefreshMessageList:(NSNotification *)notification delay:(NSTimeInterval)delayInSeconds;

- (void)removeObserver;

@end
