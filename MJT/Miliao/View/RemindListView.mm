//
//  RemindListView.m
//  MJT_APP
//
//  Created by Donny on 2017/9/14.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "RemindListView.h"
#import "RemindViewModel.h"
#import "OLYMUserObject.h"
#import "ContactFriendCell.h"
#import "UISearchBar+LeftPlaceholder.h"

#define RemindContactFriendCellIdentify @"RemindContactFriendCellIdentify"

@interface RemindListView ()<UISearchResultsUpdating, UISearchBarDelegate>

@property (nonatomic, strong) RemindViewModel *remindViewModel;

@property (nonatomic, strong) UISearchController *searchCon;

// 数据数组
@property (nonatomic, strong) NSMutableArray *roomArr;
// 搜索结果数组
@property (nonatomic, strong) NSMutableArray *searchArr;
// 首字母排序数组
@property (nonatomic, strong) NSMutableArray *letterResultArr;


@end

@implementation RemindListView

- (instancetype)initWithViewModel:(id<OLYMViewModelProtocol>)viewModel searchController:(UISearchController *)searchController{
    self.remindViewModel = (RemindViewModel *)viewModel;
    self.searchCon = searchController;
    self.searchCon.searchBar.delegate = self;
    
    // SearchController configuration
    self.searchCon.searchResultsUpdater = self;
    
    _searchArr = [[NSMutableArray alloc] init];

    return [super initWithViewModel:viewModel];
}
- (void)updateConstraints {
    
    WeakSelf(weakSelf);
    self.tableView.backgroundColor = OLYMHEXCOLOR(0xebebeb);
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self.tableView setTableFooterView:[UIView new]];
    self.tableView.tableHeaderView = self.searchCon.searchBar;

    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(weakSelf);
    }];
    
    [super updateConstraints];
    
}

- (void)olym_bindViewModel
{
    @weakify(self);
    //刷新列表
    [self.remindViewModel.membersSubject subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        
        [self.tableView reloadData];
    }];
}



#pragma mark - private
- (void)olym_setupViews {
    if (@available(iOS 11, *)) {
        self.tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAlways;
    }
    [self addSubview:self.tableView];
    [self setNeedsUpdateConstraints];
    [self updateConstraintsIfNeeded];
    

}

#pragma mark 《$ ---------------- UISearchResultsUpdating ---------------- $》
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *searchStr = _searchCon.searchBar.text;
    
    if (_searchArr != nil) {
        [_searchArr removeAllObjects];
    }
    //过滤数据
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.userNickname contains [cd] %@ ||  SELF.nameLetters contains [cd] %@",searchStr,searchStr];
    NSArray *tmpArr = [self.remindViewModel.allReminders filteredArrayUsingPredicate:predicate];
    if(tmpArr && tmpArr.count > 0)
    {
        [_searchArr addObjectsFromArray:tmpArr];
    }
    
    //刷新表格
    [self.tableView reloadData];

}




- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    OLYMUserObject *user;
    if (self.searchCon.active)
    {
        user = [self.searchArr objectAtIndex:indexPath.row];
    }else
    {
        NSDictionary *dict = self.remindViewModel.dataArray[indexPath.section];
        NSMutableArray *array = dict[@"content"];
        user = array[indexPath.row];
    }
    
    [self.remindViewModel.cellClickSubject sendNext:user];
}


#pragma mark - UITableView DataSource
#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.searchCon.active)
    {
        return self.searchArr.count;
    }else
    {
        return self.remindViewModel.dataArray.count;

    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.searchCon.active)
    {
        return self.searchArr.count;
    }else
    {
        NSDictionary *dict = self.remindViewModel.dataArray[section];
        NSMutableArray *array = dict[@"content"];
        return [array count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.searchCon.active)
    {
        ContactFriendCell *cell = [tableView dequeueReusableCellWithIdentifier:RemindContactFriendCellIdentify];
        if (!cell)
        {
            cell = [[ContactFriendCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:RemindContactFriendCellIdentify];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        OLYMUserObject *user = self.searchArr[indexPath.row];
        cell.userObj = user;
        cell.addButton.hidden = YES;
        cell.lockView.hidden = YES;
        return cell;
    }else
    {
        ContactFriendCell *cell = [tableView dequeueReusableCellWithIdentifier:RemindContactFriendCellIdentify];
        if (!cell)
        {
            cell = [[ContactFriendCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:RemindContactFriendCellIdentify];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        NSDictionary *dict = self.remindViewModel.dataArray[indexPath.section];
        NSMutableArray *array = dict[@"content"];
        OLYMUserObject *user = array[indexPath.row];
        
        cell.userObj = user;
        cell.addButton.hidden = YES;
        cell.lockView.hidden = YES;
        
        return cell;

    }
    
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (self.searchCon.active)
    {
        return nil;
    }else
    {
        NSDictionary *dict = self.remindViewModel.dataArray[section];
        NSString *title = dict[@"firstLetter"];
        return title;

    }
}


//添加索引栏标题数组
- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    if(self.searchCon.active)
    {
        return nil;
    }else
    {
        NSMutableArray *resultArray =[NSMutableArray arrayWithObject:UITableViewIndexSearch];
        for (NSDictionary *dict in self.remindViewModel.dataArray) {
            NSString *title = dict[@"firstLetter"];
            [resultArray addObject:title];
        }
        return resultArray;
    }
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (self.searchCon.active)
    {
        return nil;
    }else
    {
        //自定义Header标题
        UIView* myView = [[UIView alloc] init];
        myView.backgroundColor = OLYMHEXCOLOR(0xf2f2f2);
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 90, 22)];
        titleLabel.textColor=[UIColor blackColor];
        
        NSString *title = self.remindViewModel.dataArray[section][@"firstLetter"];
        titleLabel.text = title;
        [myView  addSubview:titleLabel];
        
        return myView;
    }
}


#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return 70.0f;
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

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [searchBar setCenterdPlaceholder];
}


@end
