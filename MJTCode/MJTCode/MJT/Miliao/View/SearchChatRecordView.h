//
//  SearchChatRecordView.h
//  MJT_APP
//
//  Created by Donny on 2017/12/18.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "OLYMBaseListView.h"

@interface SearchChatRecordView : OLYMBaseListView

- (instancetype)initWithViewModel:(id<OLYMViewModelProtocol>)viewModel searchController:(UISearchController *)searchController;


- (instancetype)initWithViewModel:(id<OLYMViewModelProtocol>)viewModel searchController:(UISearchController *)searchController searchArray:(NSArray *)searchArray;

@end
