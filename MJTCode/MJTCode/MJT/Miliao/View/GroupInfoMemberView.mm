//
//  GroupInfoMemberView.m
//  MJT_APP
//
//  Created by Donny on 2017/11/9.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "GroupInfoMemberView.h"
#import "GroupInfoModel.h"
#import "GroupHeaderView.h"
#import "AlertViewManager.h"
#import "OLYMUserObject.h"
#import "SearchResultViewController.h"
#import "ContactFriendCell.h"
#import "UISearchBar+LeftPlaceholder.h"

@interface GroupInfoMemberView()<UISearchBarDelegate,UISearchControllerDelegate,UISearchResultsUpdating>
@property(strong,nonatomic) GroupInfoModel *groupInfoModel;
@property(strong,nonatomic) UIView *headerView;

@property (nonatomic,strong) UISearchController *mySearchController;
@property (nonatomic,strong) NSMutableArray *searchArray;

@end

@implementation GroupInfoMemberView
- (instancetype)initWithViewModel:(id<OLYMViewModelProtocol>)viewModel {
    self.groupInfoModel = (GroupInfoModel *)viewModel;
    return [super initWithViewModel:viewModel];
}

- (void)updateConstraints {
    
    WeakSelf(ws);
    
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(ws);
    }];

    [super updateConstraints];
}

- (void)olym_setupViews {
    
    [self getMemberView];
    
    self.tableView.tableFooterView = self.headerView;
#if MJTDEV
    [self.tableView setTableHeaderView:self.mySearchController.searchBar];
    [self.tableView registerClass:[ContactFriendCell class] forCellReuseIdentifier:NSStringFromClass([ContactFriendCell class])];
#endif
    [self addSubview:self.tableView];
    
    [self setNeedsUpdateConstraints];
    [self updateConstraintsIfNeeded];
    
}

-(void)olym_bindViewModel{
    @weakify(self);
    
    [[olym_Nofity rac_addObserverForName:kInviteUserFromRoomNotifaction object:nil] subscribeNext:^(NSNotification *notification){
        
        @strongify(self);
        
        OLYMUserObject *userObject = notification.object;
        
        [self refreshMemberView:userObject withAdd:YES];
    }];
    
    
    [[olym_Nofity rac_addObserverForName:kDeleteUserFromRoomNotifaction object:nil] subscribeNext:^(NSNotification *notification){
        
        @strongify(self);
        
        OLYMUserObject *userObject = notification.object;
        
        [self refreshMemberView:userObject withAdd:NO];
    }];
}

-(void)refreshMemberView:(OLYMUserObject *)userObject withAdd:(BOOL)addValue{
    if(addValue){
        [self.groupInfoModel.groupMemberArray addObject:userObject];
    }else{
        for(OLYMUserObject *exitUserObject in self.groupInfoModel.groupMemberArray){
            if([exitUserObject.userId isEqualToString:userObject.userId]){
                [self.groupInfoModel.groupMemberArray removeObject:exitUserObject];
                break;
            }
        }
    }
    [self getMemberView];
}



-(void)getMemberView{
    
    [self.headerView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
 
    NSInteger imageWidth = 60;
    NSInteger numberOfRow = GJCFSystemScreenWidth > 320? 5 : 4;
    NSInteger margin = (GJCFSystemScreenWidth - (numberOfRow * imageWidth)) / (numberOfRow + 1);
    NSInteger imageHeight = 70;
    
    int count = self.groupInfoModel.groupMemberArray.count;
    
    int totalViewCount = 0;
    //如果群主就是我
    if([self.roomDataObject.userId isEqualToString:olym_UserCenter.userId]){
        //开放邀请 删除按钮
        totalViewCount = count + 2;
    }else{
        //只开放邀请按钮
        totalViewCount = count + 1;
    }
    
    //添加成员头像
    for (NSInteger i = 0; i < totalViewCount; i++) {
        
        NSInteger column = i % numberOfRow;
        
        NSInteger row = i / numberOfRow;
        
        
        GroupHeaderView *view = [[GroupHeaderView alloc]initWithFrame:CGRectMake(margin + column * (imageWidth + margin), 15 + row * (imageHeight + 10), imageWidth, imageHeight)];
        
        view.tag = i;
        
        if(i == count)
        {
            [view.headerView setImage:GJCFQuickImage(@"add_message_info_nor")];
        }
        else if(i > count)
        {
            [view.headerView setImage:GJCFQuickImage(@"delete_message_info_nor")];
        }
        else{
            [view setUserObject:[self.groupInfoModel.groupMemberArray objectAtIndex:i]];
            //            view.delegate = self;
        }
        
        @weakify(self);
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] init];
        [[tap rac_gestureSignal] subscribeNext:^(UITapGestureRecognizer * tap) {
            @strongify(self);
            GroupHeaderView *view = (GroupHeaderView *)tap.view;
            [self headerViewTapAction:view.tag];
        }];
        [view addGestureRecognizer:tap];
        
        [self.headerView addSubview:view];
    }
    
    NSInteger n =  ceil((totalViewCount * 1.0) /numberOfRow) + 1;
    // 80是每一个GroupHeaderView高度 + 上下边距
    // 30是 上下边距 15 + 15
    self.headerView.frame = CGRectMake(0, 0, GJCFSystemScreenWidth, n * 80 + 30);
    
    [self.tableView reloadData];
    
}


-(void)headerViewTapAction:(int)index{
    int count = self.groupInfoModel.groupMemberArray.count;
    if(index == count)
    {
        [self.groupInfoModel.groupInviteSubject sendNext:self.roomDataObject.userId];
    }
    else if(index > count)
    {
        if (![self.roomDataObject.userId isEqualToString:olym_UserCenter.userId])
        {
            [AlertViewManager alertWithTitle:_T(@"您不是群主，不能删除群成员")];
            return;
        }
        //        [self showHeaderDelete];
        [self.groupInfoModel.groupDeleteSubject sendNext:nil];
    }
    else{
        //显示用户信息
        OLYMUserObject *userObj = [self.groupInfoModel.groupMemberArray objectAtIndex:index];
        NSString *domain = userObj.domain;
        if (!domain)
        {
            domain = FULL_DOMAIN(olym_UserCenter.userDomain);
        }
        [self.groupInfoModel getUserInfoByUserId:userObj.userId domain:domain roomId:self.roomDataObject.roomId];
    }
}

#pragma mark - UISearchResultsUpdating
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    self.headerView.hidden = YES;
    NSString *searchStr = searchController.searchBar.text;
    [self.searchArray removeAllObjects];
    if (searchStr && ![searchStr isEqualToString:@""]) {
        //
        NSArray *tmpResults = [self.groupInfoModel filterMembersBy:searchStr];
        if(tmpResults)
        {
            [self.searchArray addObjectsFromArray:tmpResults];
        }
    }
    [self.tableView reloadData];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [searchBar setCenterdPlaceholder];
    [self.headerView performSelector:@selector(setHidden:) withObject:[NSNumber numberWithBool:NO] afterDelay:0.01];
}

#pragma mark - UITableView DataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.searchArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    ContactFriendCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([ContactFriendCell class])];
    if (!cell)
    {
        cell = [[ContactFriendCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NSStringFromClass([ContactFriendCell class])];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    OLYMUserObject *user = [self.searchArray objectAtIndex:indexPath.row];
        
    cell.userObj = user;
    cell.addButton.hidden = YES;
    cell.lockView.hidden = YES;
    return cell;
    
}


#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 70.0f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    OLYMUserObject *userObj = [self.searchArray objectAtIndex:indexPath.row];
    NSString *domain = userObj.domain;
    if (!domain)
    {
        domain = FULL_DOMAIN(olym_UserCenter.userDomain);
    }
    [self.groupInfoModel getUserInfoByUserId:userObj.userId domain:domain roomId:self.roomDataObject.roomId];
}


#pragma mark - Property
- (UIView *)headerView{
    if(!_headerView){
        _headerView = [[UIView alloc]init];
        [_headerView setBackgroundColor:white_color];
    }
    return _headerView;
}


#pragma mark - LazyLoad
-(UISearchController *)mySearchController{
    
    if (!_mySearchController) {
        
        _mySearchController = [[UISearchController alloc] initWithSearchResultsController:nil];
        // SearchBar configuration
        _mySearchController.searchBar.frame = CGRectMake(0, 0, CGRectGetWidth([UIScreen mainScreen].bounds), 44.0f);
        //        _searchCon.searchBar.delegate = self;
        
        _mySearchController.searchBar.placeholder = _T(@"搜索");
        _mySearchController.searchBar.backgroundImage = [UIImage new];
        [_mySearchController.searchBar setAutocapitalizationType:UITextAutocapitalizationTypeNone];
        
        // SearchController configuration
        _mySearchController.searchResultsUpdater = self;
        _mySearchController.searchBar.delegate = self;
        // 背景变暗色
        _mySearchController.dimsBackgroundDuringPresentation = NO;
        // 背景变模糊
        _mySearchController.obscuresBackgroundDuringPresentation = NO;
        //隐藏导航栏
        _mySearchController.hidesNavigationBarDuringPresentation = YES;
        [_mySearchController.searchBar sizeToFit];
        [_mySearchController.searchBar setCenterdPlaceholder];
        
        //遮住状态栏的颜色 与bar4
        UIView *topView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, GJCFSystemScreenWidth, 44)];
        topView.backgroundColor = [UIColor whiteColor];
        
        [_mySearchController.view insertSubview:topView atIndex:0];
        
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

- (NSMutableArray *)searchArray
{
    if (!_searchArray)
    {
        _searchArray = [NSMutableArray array];
    }
    return _searchArray;
}

@end
