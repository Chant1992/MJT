//
//  CreateNewChatListView.m
//  MJT_APP
//
//  Created by Donny on 2017/12/27.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "CreateNewChatListView.h"
#import "ContactFriendCell.h"
#import "CreateNewChatViewModel.h"
#import "SearchResultViewController.h"
#import "UISearchBar+LeftPlaceholder.h"
#import "AlertViewManager.h"

@interface CreateNewChatListView()<UISearchBarDelegate,UISearchControllerDelegate,UISearchResultsUpdating>

@property (nonatomic, strong) CreateNewChatViewModel *cnewChatViewModel;

@property(nonatomic,strong) SearchResultViewController *searchResultViewController;
@property(strong,nonatomic) UISearchController  *mySearchController;

@end

@implementation CreateNewChatListView
- (instancetype)initWithViewModel:(id<OLYMViewModelProtocol>)viewModel
{
    if (self = [super initWithViewModel:viewModel]) {
        self.cnewChatViewModel = viewModel;
    }
    return self;
}

- (void)setMultiSelect:(BOOL)multiSelect
{
    _multiSelect = multiSelect;
    if (multiSelect)
    {
        [self.tableView setEditing:YES];
    }
}

- (void)setSelectedUsers:(NSArray *)selectedUsers
{
    _selectedUsers = selectedUsers;
    if (!self.tableView.isEditing) {
        return;
    }
    for (OLYMUserObject *selectedUser in selectedUsers)
    {
        for (int i = 0; i < self.cnewChatViewModel.dataArray.count; i++)
        {
            NSDictionary *dict = self.cnewChatViewModel.dataArray[i];
            NSMutableArray *array = dict[@"content"];
            for (int j = 0; j < array.count; j++)
            {
                OLYMUserObject *user = array[j];
                if ([selectedUser.userId isEqualToString:user.userId] && [selectedUser.domain isEqualToString:user.domain])
                {
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:j inSection:i + 1];
                    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
                }
            }
        }
    }
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
    
    [self.tableView setTableHeaderView:self.mySearchController.searchBar];
    self.tableView.backgroundColor = OLYMHEXCOLOR(0xebebeb);
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self.tableView setTableFooterView:[UIView new]];
    self.tableView.allowsSelectionDuringEditing = YES;
//    self.tableView.tableHeaderView = self.searchCon.searchBar;
//    [self.tableView registerClass:[SearchChatRecordCell class] forCellReuseIdentifier:NSStringFromClass([SearchChatRecordCell class])];
    
    [self addSubview:self.tableView];
    [self setNeedsUpdateConstraints];
    [self updateConstraintsIfNeeded];
}

- (void)olym_bindViewModel {
    WeakSelf(weakSelf)
    _searchResultViewController.searchCallBackBlock = ^(id selectedObj) {
        [weakSelf.cnewChatViewModel.cellClickSubject sendNext:selectedObj];
    };

}

#pragma mark - <------------------- UISearchBarDelegate ------------------->
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
    
    NSString *searchText = searchBar.text;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.userNickname contains [cd] %@ ||SELF.userRemarkname contains [cd] %@ || SELF.telephone contains [cd] %@ ||  SELF.nameLetters contains [cd] %@ || SELF.remarkLetters contains [cd] %@",searchText,searchText,searchText,searchText,searchText];
    _searchResultViewController.searchKeyword = searchBar.text;
    _searchResultViewController.dataArray = [self.cnewChatViewModel.allContacts filteredArrayUsingPredicate:predicate];
    [_searchResultViewController.tableView reloadData];
}

-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText{
    
    [self searchBarSearchButtonClicked:_mySearchController.searchBar];
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section == 0)
    {
        if (indexPath.row == 0) {
            
            [self.cnewChatViewModel.roomlistSubject sendNext:nil];
        }else{
            
            [self.cnewChatViewModel.organizationlistSubject sendNext:nil];
        }
        
    }else
    {
        
        NSDictionary *dict = self.cnewChatViewModel.dataArray[indexPath.section - 1];
        NSMutableArray *array = dict[@"content"];
        OLYMUserObject *user = array[indexPath.row];
        if (self.tableView.editing)
        {
            for (OLYMUserObject *selectedUser in self.selectedUsers)
            {
                if ([selectedUser.userId isEqualToString:user.userId] && [selectedUser.domain isEqualToString:user.domain])
                {
                    return;
                }
            }
            if (self.cnewChatViewModel.multiSelectArray.count + self.selectedUsers.count >= 9)
            {
                [AlertViewManager alertWithTitle:_T(@"最多只能选择9个聊天")];
                [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
                return;
            }
            if (![self.cnewChatViewModel.multiSelectArray containsObject:user]) {
                [self.cnewChatViewModel.multiSelectArray addObject:user];
            }
            [self.cnewChatViewModel.multiSelectSubject sendNext:nil];
            return;
        }
        [self.cnewChatViewModel.cellClickSubject sendNext:user];
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.tableView.editing)
    {
        
        if (indexPath.section == 0) {
            
            //第一组时无视 ，第一组分别是“选择群聊”和“组织架构”
            return;
        }
        
        NSDictionary *dict = self.cnewChatViewModel.dataArray[indexPath.section - 1];
        NSMutableArray *array = dict[@"content"];
        OLYMUserObject *user = array[indexPath.row];
        for (OLYMUserObject *selectedUser in self.selectedUsers)
        {
            if ([selectedUser.userId isEqualToString:user.userId] && [selectedUser.domain isEqualToString:user.domain])
            {
                [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
                return;
            }
        }
        [self.cnewChatViewModel.multiSelectArray removeObject:user];
        [self.cnewChatViewModel.multiSelectSubject sendNext:nil];
    }
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (!self.cnewChatViewModel.dataArray || self.cnewChatViewModel.dataArray.count <= 0) {
        return 1;
    }
    return self.cnewChatViewModel.dataArray.count + 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
    {
        if (Organization && [[olym_Default objectForKey:kAPI_ORGAN_Model] boolValue]) {
        
            return 2;
        }
        
        return 1;
    }else
    {
        NSDictionary *dict = self.cnewChatViewModel.dataArray[section - 1];
        NSMutableArray *array = dict[@"content"];
        return [array count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    ContactFriendCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([ContactFriendCell class])];
    if (!cell)
    {
        cell = [[ContactFriendCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NSStringFromClass([ContactFriendCell class])];
    }
    if (indexPath.section == 0)
    {
        cell.textLabel.text = _T(@"选择群聊");
        cell.addButton.hidden = YES;
        cell.lockView.hidden = YES;
        cell.iconView.hidden = YES;
        cell.nickNameLabel.hidden = YES;
        
        if (indexPath.row == 1) {
            
            cell.textLabel.text = _T(@"公司通讯录");
        }
    }else
    {
        NSDictionary *dict = self.cnewChatViewModel.dataArray[indexPath.section - 1];
        NSMutableArray *array = dict[@"content"];
        OLYMUserObject *user = array[indexPath.row];
        
        cell.userObj = user;
        cell.addButton.hidden = YES;
        cell.lockView.hidden = YES;
        cell.iconView.hidden = NO;
        cell.nickNameLabel.hidden = NO;
        cell.textLabel.text = nil;
    }
    return cell;
    
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0)
    {
        return nil;
    }else
    {
        NSDictionary *dict = self.cnewChatViewModel.dataArray[section - 1];
        NSString *title = dict[@"firstLetter"];
        return title;
    }
}


//添加索引栏标题数组
- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    NSMutableArray *resultArray =[NSMutableArray arrayWithObject:UITableViewIndexSearch];
    for (NSDictionary *dict in self.cnewChatViewModel.dataArray) {
        NSString *title = dict[@"firstLetter"];
        [resultArray addObject:title];
    }
    return resultArray;
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (section > 0)
    {
        //自定义Header标题
        UIView* myView = [[UIView alloc] init];
        myView.backgroundColor = OLYMHEXCOLOR(0xf2f2f2);
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 90, 22)];
        titleLabel.textColor=[UIColor blackColor];
        
        NSString *title = self.cnewChatViewModel.dataArray[section - 1][@"firstLetter"];
        titleLabel.text = title;
        [myView  addSubview:titleLabel];
        
        return myView;
    }
    return nil;
}


- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath{
    return (UITableViewCellEditingStyle)(UITableViewCellEditingStyleDelete | UITableViewCellEditingStyleInsert);
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.tableView.editing)
    {
        if ((indexPath.section == 0 && indexPath.row == 0) || (indexPath.section == 0 && indexPath.row == 1))
        {
            return NO;
        }
    }
    return YES;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0)
    {
        return 50;
    }
    return 70.0f;
}
#pragma mark - UISearchBar Delegate
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [searchBar setCenterdPlaceholder];
}


#pragma mark - LazyLoad
-(UISearchController *)mySearchController{
    
    if (!_mySearchController) {
        
        _searchResultViewController = [[SearchResultViewController alloc]initWithSearchType:SearchResultCallBack];
        self.mySearchController = [[UISearchController alloc] initWithSearchResultsController:_searchResultViewController];
        
        _mySearchController.dimsBackgroundDuringPresentation = NO;
        [_mySearchController.searchBar sizeToFit];
        _mySearchController.searchBar.delegate = self;
        _mySearchController.delegate = self;
        [_mySearchController.searchBar setPlaceholder:_T(@"搜索")];
        [_mySearchController.searchBar setValue:_T(@"取消") forKey:@"_cancelButtonText"];
        _mySearchController.searchBar.barTintColor = RGB(225, 225, 225);
        _mySearchController.hidesNavigationBarDuringPresentation = YES;
        [_mySearchController.searchBar setBackgroundImage:[UIImage new]];
        _mySearchController.searchBar.backgroundColor = RGB(225, 225, 225);
        [_mySearchController.searchBar setCenterdPlaceholder];
        
        //遮住原有的tableview内容
        UIView *view = [[UIView alloc]initWithFrame:_mySearchController.view.bounds];
        view.backgroundColor = kTableViewBackgroundColor;
        
        //遮住状态栏的颜色 与bar4
        UIView *topView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, GJCFSystemScreenWidth, 44)];
        topView.backgroundColor = [UIColor whiteColor];
        [view addSubview:topView];
        
        [_mySearchController.view insertSubview:view atIndex:0];
        _mySearchController.searchBar.barTintColor = [UIColor whiteColor];
        for (UIView *subView in _mySearchController.searchBar.subviews)
        {
            subView.backgroundColor = [UIColor whiteColor];
            for (UIView *view in subView.subviews)
            {
                if ([view isKindOfClass:NSClassFromString(@"UISearchBarSearchFieldBackgroundView")])
                {
                    view.backgroundColor = [UIColor whiteColor];
                }
            }
        }
        UITextField *searchField = [_mySearchController.searchBar valueForKey:@"searchField"];
        if (searchField) {
            [searchField setBackgroundColor:OLYMHEXCOLOR(0XEDEDEE)];
            searchField.layer.cornerRadius = 0;
        }

    }
    
    return _mySearchController;
}



@end
