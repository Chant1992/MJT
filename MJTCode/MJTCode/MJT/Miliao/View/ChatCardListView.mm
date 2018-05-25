//
//  ChatCardListView.m
//  MJT_APP
//
//  Created by Donny on 2017/9/12.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "ChatCardListView.h"
#import "ChatCardViewModel.h"
#import "OLYMMessageObject.h"
#import "OLYMUserObject.h"
#import "ContactFriendCell.h"
#import "NSString+PinYin.h"
#import "UISearchBar+LeftPlaceholder.h"

#define ContactFriendCellIdentify @"ContactFriendCellIdentify"

@interface ChatCardListView ()<UISearchBarDelegate>

@property (nonatomic, strong) ChatCardViewModel *chatViewModel;

@property (nonatomic, strong) UISearchBar *mSearchBar;
@property (nonatomic) BOOL isSearch;
@end

@implementation ChatCardListView

- (instancetype)initWithViewModel:(id<OLYMViewModelProtocol>)viewModel {
    self.chatViewModel = (ChatCardViewModel *)viewModel;
    return [super initWithViewModel:viewModel];
}

- (void)updateConstraints {
    
    WeakSelf(weakSelf);
    self.tableView.backgroundColor = OLYMHEXCOLOR(0xebebeb);
    if(self.tableView.tableFooterView){
        self.tableView.tableFooterView.backgroundColor = self.tableView.backgroundColor;
    }
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(weakSelf);
    }];
    
    [super updateConstraints];    
}


- (void)olym_setupViews {
    
    [self addSubview:self.tableView];
    [self _createTableHeaderView];
    [self createIPhoneXFooterView];
    [self setNeedsUpdateConstraints];
    [self updateConstraintsIfNeeded];
    
}

- (void)olym_bindViewModel {
    @weakify(self);

}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    if (!self.chatViewModel.dataArray || self.chatViewModel.dataArray.count <= 0) {
        return 0;
    }
    return self.chatViewModel.dataArray.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSDictionary *dict = self.chatViewModel.dataArray[section];
    NSMutableArray *array = dict[@"content"];
    return [array count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    ContactFriendCell *cell = [tableView dequeueReusableCellWithIdentifier:ContactFriendCellIdentify];
    if (!cell)
    {
        cell = [[ContactFriendCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ContactFriendCellIdentify];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    if (Organization && [[olym_Default objectForKey:kAPI_ORGAN_Model] boolValue]) {
        
        if (indexPath.section == 0) {
            
            cell.textLabel.text = _T(@"公司通讯录");
            cell.nickNameLabel.text = @"";
            cell.addButton.hidden = YES;
            return cell;
        }
    }
    
    NSDictionary *dict = self.chatViewModel.dataArray[indexPath.section];
    NSMutableArray *array = dict[@"content"];
    OLYMUserObject *user = array[indexPath.row];
    
    cell.userObj = user;
    cell.addButton.hidden = YES;
    cell.lockView.hidden = YES;
    
    return cell;

}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSDictionary *dict = self.chatViewModel.dataArray[section];
    NSString *title = dict[@"firstLetter"];
    return title;
}


//添加索引栏标题数组
- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    NSMutableArray *resultArray =[NSMutableArray arrayWithObject:UITableViewIndexSearch];
    for (NSDictionary *dict in self.chatViewModel.dataArray) {
        NSString *title = dict[@"firstLetter"];
        [resultArray addObject:title];
    }
    return resultArray;
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    //自定义Header标题
    UIView* myView = [[UIView alloc] init];
    myView.backgroundColor = OLYMHEXCOLOR(0xf2f2f2);
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 90, 22)];
    titleLabel.textColor=[UIColor blackColor];
    
    NSString *title = self.chatViewModel.dataArray[section][@"firstLetter"];
    titleLabel.text = title;
    [myView  addSubview:titleLabel];
    
    return myView;
}


#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return 70.0f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary *dict = self.chatViewModel.dataArray[indexPath.section];
    NSMutableArray *array = dict[@"content"];
    OLYMMessageObject *user = array[indexPath.row];

    [self.chatViewModel.cellClickSubject sendNext:user];
}


#pragma mark - <------------------- UISearchBarDelegate ------------------->
-(BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar{
    
    //    _maskView.hidden = NO;
    return YES;
}

-(BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar{
    
    //    _maskView.hidden = YES;
    return YES;
}

// UISearchBarDelegate定义的方法，用户单击取消按钮时激发该方法
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    NSLog(@"----searchBarCancelButtonClicked------");
    // 取消搜索状态
    _isSearch = NO;
    [searchBar resignFirstResponder];
    [searchBar setCenterdPlaceholder];
    //还原数据
    [self.chatViewModel.dataArray removeAllObjects];
    [self.chatViewModel.dataArray addObjectsFromArray:self.chatViewModel.previousArray];
    
    [self.tableView reloadData];
}

// UISearchBarDelegate定义的方法，当搜索文本框内文本改变时激发该方法
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if ([searchText length] == 0) {
        [self performSelector:@selector(hideKeyboardWithSearchBar:) withObject:searchBar afterDelay:0];
    }else{
        
        //如果0.5秒内有输入动作，则取消之前的延时调用
        //        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        [self filterBySubstring:self.mSearchBar.text];
        //如果0.5秒内没有输入动作，则搜索
        //        [self  performSelector:@selector(filterBySubstring:) withObject:self.mSearchBar.text afterDelay:0.5f];
    }
}

- (void)hideKeyboardWithSearchBar:(UISearchBar *)searchBar{
    [searchBar resignFirstResponder];
    
    //    _maskView.hidden = YES;
    _isSearch = NO;
    //还原数据
    
    if (self.chatViewModel.previousArray.count > 0) {
        
        [self.chatViewModel.dataArray removeAllObjects];
        [self.chatViewModel.dataArray addObjectsFromArray:self.chatViewModel.previousArray];
    }
    
    [self.tableView reloadData];
}

// UISearchBarDelegate定义的方法，用户单击虚拟键盘上Search按键时激发该方法
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    //    _maskView.hidden = YES;
    // 调用filterBySubstring:方法执行搜索
    [self filterBySubstring:searchBar.text];
    // 放弃作为第一个响应者，关闭键盘
    [searchBar resignFirstResponder];
}

- (void)filterBySubstring:(NSString*) subStr
{
    subStr = [subStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if ([subStr isEqualToString:@""]) {
        
        return;
    }
    
    if (!self.chatViewModel.previousArray) {
        self.chatViewModel.previousArray = [NSMutableArray array];
    }
    
    if (!_isSearch && self.chatViewModel.previousArray.count == 0) {
        
        [self.chatViewModel.previousArray removeAllObjects];
        [self.chatViewModel.previousArray addObjectsFromArray:self.chatViewModel.dataArray];
    }
    
    [self.chatViewModel.dataArray removeAllObjects];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        WeakSelf(ws);
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.userNickname contains [cd] %@ || SELF.telephone contains [cd] %@ ||  SELF.nameLetters contains [cd] %@",subStr,subStr,subStr,subStr,subStr];
        NSMutableArray *searchs = [self.chatViewModel.allContacts  filteredArrayUsingPredicate:predicate].mutableCopy;
        ws.chatViewModel.dataArray = [searchs arrayWithPinYinFirstLetterFormat];
        
        // 设置为搜索状态
        //        _isSearch = YES;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self.tableView reloadData];
        });
        
        
    });
    
}



-(void)addKeyboardHideTouch{
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] init];
    //设置成NO表示当前控件响应后会传播到其他控件上，默认为YES。
    tapGestureRecognizer.cancelsTouchesInView = NO;
    self.userInteractionEnabled = YES;
    
    [[tapGestureRecognizer rac_gestureSignal] subscribeNext:^(__kindof UIGestureRecognizer * _Nullable x) {
        
        //点击view收起键盘
        [self endEditing:YES];
    }];
    //将触摸事件添加到当前view
    [self addGestureRecognizer:tapGestureRecognizer];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    //滑动时收起键盘
    [self endEditing:YES];
}


#pragma mark - Private
-(void)_createTableHeaderView{
    
    //搜索栏
    _mSearchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, GJCFSystemScreenWidth, 30)];
    _mSearchBar.delegate = self;
    _mSearchBar.placeholder = _T(@"搜索");

    _mSearchBar.backgroundImage = [UIImage new];
    [_mSearchBar setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    [_mSearchBar sizeToFit];
    [_mSearchBar setCenterdPlaceholder];
    self.tableView.sectionIndexBackgroundColor = [UIColor clearColor];
    
    self.tableView.tableHeaderView = _mSearchBar;
    _mSearchBar.backgroundColor = [UIColor whiteColor];
    _mSearchBar.barTintColor = [UIColor whiteColor];
    for (UIView *subView in _mSearchBar.subviews)
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
    UITextField *searchField = [_mSearchBar valueForKey:@"searchField"];
    if (searchField) {
        [searchField setBackgroundColor:OLYMHEXCOLOR(0XEDEDEE)];
        searchField.layer.cornerRadius = 0;
    }

}


@end

