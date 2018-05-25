//
//  CreateNewChatListView.h
//  MJT_APP
//
//  Created by Donny on 2017/12/27.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "OLYMBaseListView.h"

@interface CreateNewChatListView : OLYMBaseListView

@property (nonatomic, assign) BOOL multiSelect;
@property (nonatomic, strong) NSArray *selectedUsers;
@end
