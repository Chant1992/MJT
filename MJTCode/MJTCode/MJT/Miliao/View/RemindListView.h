//
//  RemindListView.h
//  MJT_APP
//
//  Created by Donny on 2017/9/14.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "OLYMBaseListView.h"

@class OLYMUserObject;

@interface RemindListView : OLYMBaseListView

@property(strong,nonatomic)OLYMUserObject *userObject;

- (instancetype)initWithViewModel:(id<OLYMViewModelProtocol>)viewModel searchController:(UISearchController *)searchController;
@end
