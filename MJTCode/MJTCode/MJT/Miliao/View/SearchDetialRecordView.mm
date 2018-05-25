//
//  SearchDetialRecordView.m
//  MJT_APP
//
//  Created by Donny on 2017/12/20.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "SearchDetialRecordView.h"
#import "ChatRecordViewModel.h"
#import "SearchChatRecordDetailCell.h"
#import "SearchResultCell.h"
#import "OLYMSearchObject.h"
#import "SearchChatRecordCell.h"
#import "UISearchBar+LeftPlaceholder.h"

@interface SearchDetialRecordView ()<UISearchBarDelegate,UISearchResultsUpdating>

@property (nonatomic, strong) UISearchController *searchCon;

@property (nonatomic, strong) ChatRecordViewModel *searchViewModel;

@property (nonatomic, strong) NSMutableArray *searchResults;

@property (nonatomic) SearchRecordType type;

@property (nonatomic, strong) NSString *keyword;
@end

@implementation SearchDetialRecordView

- (instancetype)initWithViewModel:(id<OLYMViewModelProtocol>)viewModel searchController:(UISearchController *)searchController searchObj:(OLYMSearchObject *)searchObj keyword:(NSString *)keyword
{
    self.searchViewModel = viewModel;
    
    self.searchCon = searchController;
    
    self.searchCon.searchBar.delegate = self;
    
    // SearchController configuration
    self.searchCon.searchResultsUpdater = self;
    
    self.type = searchObj.type;
    
    self.keyword = keyword;
    
    [self.searchResults addObjectsFromArray:searchObj.searchArray];
    
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
    [self.tableView registerClass:[SearchChatRecordCell class] forCellReuseIdentifier:NSStringFromClass([SearchChatRecordCell class])];
    [self.tableView registerClass:[SearchResultCell class] forCellReuseIdentifier:NSStringFromClass([SearchResultCell class])];

    [self addSubview:self.tableView];
    [self setNeedsUpdateConstraints];
    [self updateConstraintsIfNeeded];
}

- (void)olym_bindViewModel {
    
}
#pragma mark - UISearchResultsUpdating
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    NSString *searchStr = _searchCon.searchBar.text;
    [self.searchResults removeAllObjects];
    if (searchStr && ![searchStr isEqualToString:@""]) {
        self.keyword = _searchCon.searchBar.text;
        NSArray *tmpResults;
        if(self.type == SearchRecordGroupType)
        {
            tmpResults = [self.searchViewModel queryGroupWith:searchStr];
        }else if (self.type == SearchRecordContactType)
        {
            tmpResults = [self.searchViewModel queryAllContactsWith:searchStr];
        }else if(self.type == SearchRecordChatType)
        {
            tmpResults = [self.searchViewModel queryAllChatRecordWith:searchStr];
        }
        if(tmpResults)
        {
            [self.searchResults addObjectsFromArray:tmpResults];
        }
    }
    [self.tableView reloadData];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [searchBar setCenterdPlaceholder];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    if (self.type == SearchRecordGroupType)
    {
        OLYMUserObject *userObj = [self.searchResults objectAtIndex:indexPath.row];
        [self.searchViewModel.miyouSubject sendNext:userObj];
    }else if(self.type == SearchRecordContactType)
    {
        OLYMUserObject *userObj = [self.searchResults objectAtIndex:indexPath.row];
        if (userObj.status == id_local_invited)
        {
            //本地通讯录
            [self.searchViewModel.localContactSubject sendNext:userObj];
        }else
        {
            //密友
            [self.searchViewModel.miyouSubject sendNext:userObj];
        }
    }else
    {
        OLYMMessageSearchObject *object = [self.searchResults objectAtIndex:indexPath.row];
        if (object.searchArray.count > 1)
        {
            [self.searchViewModel.multiRecordSubject sendNext:object];
        }else
        {
            [self.searchViewModel.singleRecordSubject sendNext:object];
        }
    }
}





- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.searchResults) {
        return self.searchResults.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.type == SearchRecordGroupType || self.type == SearchRecordContactType)
    {
        SearchResultCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([SearchResultCell class]) forIndexPath:indexPath];
        if (self.type == SearchRecordGroupType)
        {
            cell.searchResultType = SearchResultRoomList;
        }else
        {
            cell.searchResultType = SearchResultFriendList;
        }
        cell.searchKeyword = self.keyword;
        cell.userObj = [self.searchResults objectAtIndex:indexPath.row];
        return cell;

    }else
    {
        SearchChatRecordCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([SearchChatRecordCell class]) forIndexPath:indexPath];
        OLYMMessageSearchObject *object = [self.searchResults objectAtIndex:indexPath.row];
        cell.searchKeyword = self.keyword;
        cell.searchResults = object.searchArray;
        cell.userObj = object.userObject;
        return cell;
    }
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 70;
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
