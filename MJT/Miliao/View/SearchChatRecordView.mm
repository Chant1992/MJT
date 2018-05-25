//
//  SearchChatRecordView.m
//  MJT_APP
//
//  Created by Donny on 2017/12/18.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "SearchChatRecordView.h"
#import "ChatRecordViewModel.h"
#import "SearchChatRecordDetailCell.h"
#import "UISearchBar+LeftPlaceholder.h"

@interface SearchChatRecordView ()<UISearchBarDelegate,UISearchResultsUpdating>

@property (nonatomic, strong) UISearchController *searchCon;

@property (nonatomic, strong) ChatRecordViewModel *searchViewModel;

@property (nonatomic, strong) NSMutableArray *searchResults;


@end

@implementation SearchChatRecordView
- (instancetype)initWithViewModel:(id<OLYMViewModelProtocol>)viewModel searchController:(UISearchController *)searchController
{
    self.searchViewModel = viewModel;
    
    self.searchCon = searchController;
    
    // SearchController configuration
    self.searchCon.searchResultsUpdater = self;
    
    return [super initWithViewModel:viewModel];

}

- (instancetype)initWithViewModel:(id<OLYMViewModelProtocol>)viewModel searchController:(UISearchController *)searchController searchArray:(NSArray *)searchArray
{
    self.searchViewModel = viewModel;
    
    self.searchCon = searchController;
    
    // SearchController configuration
    self.searchCon.searchResultsUpdater = self;
    
    [self.searchResults addObjectsFromArray:[self.searchViewModel fillChatRecords:searchArray]];

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
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self.tableView setTableFooterView:[UIView new]];
    self.tableView.tableHeaderView = self.searchCon.searchBar;
    [self.tableView registerClass:[SearchChatRecordDetailCell class] forCellReuseIdentifier:NSStringFromClass([SearchChatRecordDetailCell class])];
    
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
        NSArray *tmpResults = [self.searchViewModel queryChatRecord:searchStr];
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
    OLYMMessageObject *message = [self.searchResults objectAtIndex:indexPath.row];
    [self.searchViewModel.singleRecordSubject sendNext:message];
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
    SearchChatRecordDetailCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([SearchChatRecordDetailCell class]) forIndexPath:indexPath];
    OLYMMessageObject *message = [self.searchResults objectAtIndex:indexPath.row];
    [cell setContentModel:message];
    return cell;
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
