//
//  SearchDetialRecordView.h
//  MJT_APP
//
//  Created by Donny on 2017/12/20.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "OLYMBaseListView.h"
@class OLYMSearchObject;
@interface SearchDetialRecordView : OLYMBaseListView

- (instancetype)initWithViewModel:(id<OLYMViewModelProtocol>)viewModel searchController:(UISearchController *)searchController searchObj:(OLYMSearchObject *)searchObj keyword:(NSString *)keyword;

@end
