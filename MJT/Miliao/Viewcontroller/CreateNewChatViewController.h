//
//  CreateNewChatViewController.h
//  MJT_APP
//
//  Created by Donny on 2017/12/27.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "OLYMViewController.h"
@class OLYMMessageObject;
@class CreateNewChatListView;
@protocol CreateNewChatViewControllerDelegate<NSObject>

- (void)createNewChatControllerDidSelectedUsers:(NSArray *)selectedUsers;

@end

@interface CreateNewChatViewController : OLYMViewController

@property (nonatomic, strong) OLYMMessageObject *forwardMessage;
@property (nonatomic, strong) CreateNewChatListView *newChatListView;

@property (nonatomic, strong) NSArray *forwardMessages;


@property (nonatomic, weak) id<CreateNewChatViewControllerDelegate> delegate;

@property (nonatomic, assign) BOOL multiSelect;

@property (nonatomic, strong) NSArray *selectedUsers;

@end
