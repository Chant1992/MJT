//
//  SearchFullRecordView.m
//  MJT_APP
//
//  Created by Donny on 2017/12/18.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "SearchFullRecordView.h"
#import "ChatRecordViewModel.h"
#import "OLYMSearchObject.h"
#import "SearchChatRecordCell.h"
#import "SearchResultCell.h"
#import "MC_Cell.h"
#import "UIScrollView+EmptyDataSet.h"
#
@interface SearchFullRecordView ()<UISearchBarDelegate,UISearchResultsUpdating,DZNEmptyDataSetSource,DZNEmptyDataSetDelegate>

@property (nonatomic, strong) UISearchController *searchCon;

@property (nonatomic, strong) ChatRecordViewModel *searchViewModel;

@property (nonatomic, strong) NSMutableArray *searchResults;

@end

@implementation SearchFullRecordView

- (instancetype)initWithViewModel:(id<OLYMViewModelProtocol>)viewModel searchController:(UISearchController *)searchController
{
    self.searchViewModel = viewModel;
    
    self.searchCon = searchController;
    
    // SearchController configuration
    self.searchCon.searchResultsUpdater = self;

    return [super initWithViewModel:viewModel];
}
- (void)updateConstraints {
    
    WeakSelf(weakSelf);
    
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(weakSelf);
    }];
    
    [super updateConstraints];
}

- (void)olym_setupViews {
    if (@available(iOS 11, *)) {
        self.tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAlways;
    }
    self.tableView.backgroundColor = OLYMHEXCOLOR(0xebebeb);
    [self.tableView setTableFooterView:[UIView new]];
    self.tableView.tableHeaderView = self.searchCon.searchBar;
    [self.tableView registerClass:[SearchResultCell class] forCellReuseIdentifier:NSStringFromClass([SearchResultCell class])];
    [self.tableView registerClass:[SearchChatRecordCell class] forCellReuseIdentifier:NSStringFromClass([SearchChatRecordCell class])];
    [self.tableView registerClass:[MC_Cell class] forCellReuseIdentifier:NSStringFromClass([MC_Cell class])];
    [self.tableView registerClass:[UITableViewHeaderFooterView class] forHeaderFooterViewReuseIdentifier:NSStringFromClass([UITableViewHeaderFooterView class])];
    
    [self addSubview:self.tableView];
    [self setNeedsUpdateConstraints];
    [self updateConstraintsIfNeeded];
    WeakSelf(weakSelf);
    
}

- (void)olym_bindViewModel {
    
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    OLYMSearchObject *searchObject = [self.searchResults objectAtIndex:indexPath.section];
    if (searchObject.type == SearchRecordContactType)
    {
        if (indexPath.row >= 3)
        {
            [self.searchViewModel.moreContactsSubject sendNext:searchObject];
        }else
        {
            OLYMUserObject *userObj = [searchObject.searchArray objectAtIndex:indexPath.row];
            if (userObj.status == id_local_invited)
            {
                //本地通讯录
                [self.searchViewModel.localContactSubject sendNext:userObj];
            }else
            {
                //密友
                [self.searchViewModel.miyouSubject sendNext:userObj];
            }
        }
        
    }else if (searchObject.type == SearchRecordGroupType)
    {
        if (indexPath.row >= 3)
        {
            [self.searchViewModel.moreGroupsSubject sendNext:searchObject];
        }else
        {
            OLYMUserObject *userObj = [searchObject.searchArray objectAtIndex:indexPath.row];
            [self.searchViewModel.miyouSubject sendNext:userObj];
        }
        
    }else if (searchObject.type == SearchRecordChatType)
    {
        if (indexPath.row >= 3)
        {
            [self.searchViewModel.moreFullRecordsSubject sendNext:searchObject];

        }else
        {
            OLYMMessageSearchObject *object = [searchObject.searchArray objectAtIndex:indexPath.row];
            if (object.searchArray.count > 1)
            {
                [self.searchViewModel.multiRecordSubject sendNext:object];
            }else
            {
                [self.searchViewModel.singleRecordSubject sendNext:object];
            }
        }
        
    }

}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.searchResults)
    {
        return self.searchResults.count;
    }
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    OLYMSearchObject *searchObject = [self.searchResults objectAtIndex:section];
    if (searchObject.searchArray.count > 3)
    {
        return 4;
    }else
    {
        return searchObject.searchArray.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OLYMSearchObject *searchObject = [self.searchResults objectAtIndex:indexPath.section];
    if (searchObject.type == SearchRecordContactType)
    {
        //联系人
        if (indexPath.row < 3)
        {
            SearchResultCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([SearchResultCell class]) forIndexPath:indexPath];
            cell.searchResultType = SearchResultFriendList;
            cell.searchKeyword = self.searchCon.searchBar.text;
            cell.userObj = [searchObject.searchArray objectAtIndex:indexPath.row];
            return cell;

        }else
        {
            MC_Cell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([MC_Cell class]) forIndexPath:indexPath];
            cell.iconView.image = [UIImage imageNamed:@"search_more"];
#if XYT
            cell.contentLabel.text = _T(@"查看更多好友");
#else
            
            cell.contentLabel.text = _T(@"查看更多密友");
#endif
            
            return cell;
        }
        
    }else if (searchObject.type == SearchRecordGroupType)
    {
        //群聊
        if (indexPath.row < 3)
        {
            SearchResultCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([SearchResultCell class]) forIndexPath:indexPath];
            cell.searchResultType = SearchResultRoomList;
            cell.searchKeyword = self.searchCon.searchBar.text;
            cell.userObj = [searchObject.searchArray objectAtIndex:indexPath.row];
            return cell;
        }
        else
        {
            MC_Cell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([MC_Cell class]) forIndexPath:indexPath];
            cell.iconView.image = [UIImage imageNamed:@"search_more"];
            cell.contentLabel.text = _T(@"查看更多群组");
            return cell;
        }
    }else if (searchObject.type == SearchRecordChatType)
    {
        //聊天记录
        if (indexPath.row < 3)
        {
            SearchChatRecordCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([SearchChatRecordCell class]) forIndexPath:indexPath];
            OLYMMessageSearchObject *object = [searchObject.searchArray objectAtIndex:indexPath.row];
            cell.searchKeyword = self.searchCon.searchBar.text;
            cell.searchResults = object.searchArray;
            cell.userObj = object.userObject;
            return cell;
        }else
        {
            MC_Cell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([MC_Cell class]) forIndexPath:indexPath];
            cell.iconView.image = [UIImage imageNamed:@"search_more"];
            cell.contentLabel.text = _T(@"查看更多聊天记录");
            return cell;
        }
    }
    return nil;
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 40;
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UITableViewHeaderFooterView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:NSStringFromClass([UITableViewHeaderFooterView class])];
    headerView.contentView.backgroundColor = OLYMHEXCOLOR(0xf4f4f4);
    UILabel *headLabel = [headerView.contentView viewWithTag:10086];
    if (!headLabel)
    {
        headLabel = [[UILabel alloc]initWithFrame:CGRectMake(15, 0, CGRectGetWidth(tableView.frame) - 15, 40)];
        headLabel.textColor = OLYMHEXCOLOR(0x8e8e93);
        headLabel.font = [UIFont systemFontOfSize:13];
        headLabel.tag = 10086;
        [headerView.contentView addSubview:headLabel];
    }
    OLYMSearchObject *searchObject = [self.searchResults objectAtIndex:section];
    if (searchObject.type == SearchRecordContactType)
    {
        headLabel.text = _T(@"联系人");
    }else if (searchObject.type == SearchRecordGroupType)
    {
        headLabel.text = _T(@"群聊");
    }else if (searchObject.type == SearchRecordChatType)
    {
        headLabel.text = _T(@"聊天记录");
    }
    return headerView;
}


#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    OLYMSearchObject *searchObject = [self.searchResults objectAtIndex:indexPath.section];
    if (searchObject.type == SearchRecordContactType)
    {
        if (indexPath.row < 3)
        {
            return 70;
        }else
        {
            return 45;
        }
    }else if (searchObject.type == SearchRecordGroupType)
    {
        if (indexPath.row < 3)
        {
            return 70;
        }else
        {
            return 45;
        }
    }else if (searchObject.type == SearchRecordChatType)
    {
        if (indexPath.row < 3)
        {
            return 70;//66
        }else
        {
            return 45;
        }
    }
    return 0;
}



#pragma mark - UISearchResultsUpdating
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    NSString *searchStr = _searchCon.searchBar.text;
    [self.searchResults removeAllObjects];
    if (searchStr && ![searchStr isEqualToString:@""]) {
        NSArray *tmpResults = [self.searchViewModel queryFullRecordWith:searchStr];
        if(tmpResults)
        {
            [self.searchResults addObjectsFromArray:tmpResults];
        }
    }
    
    [self.tableView reloadData];
}

#pragma mark 《$ ---------------- UISearchBarDelegate ---------------- $》
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    // 修改搜索框背景
    searchBar.showsCancelButton = YES;
    searchBar.translucent = YES;
    // 修改右侧按钮文字
    for(UIView *view in  [[[searchBar subviews] objectAtIndex:0] subviews]) {
        if([view isKindOfClass:[NSClassFromString(@"UINavigationButton") class]]) {
            UIButton *cancelBtn =(UIButton *)view;
            [cancelBtn setTitle:_T(@"取消") forState:UIControlStateNormal];
        }
    }
    
    for (UIView *subview in [[[searchBar subviews] objectAtIndex:0] subviews]) {
        if ([subview isKindOfClass:[NSClassFromString(@"UISearchBarBackground") class]]) {
            
            // 覆盖SearchBar背景
            [subview removeFromSuperview];
            UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"searchbar_bg"]];
            imageView.frame = CGRectMake(0, -20, CGRectGetWidth([UIScreen mainScreen].bounds), 64);
            
            [searchBar insertSubview:imageView atIndex:0];
            break;
        }
    }
}

- (NSMutableArray *)searchResults
{
    if (!_searchResults)
    {
        _searchResults = [NSMutableArray array];
    }
    return _searchResults;
}
@end
