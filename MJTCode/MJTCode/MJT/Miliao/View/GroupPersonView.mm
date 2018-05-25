//
//  GroupPersonView.m
//  MJT_APP
//
//  Created by olymtech on 2017/9/14.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "GroupPersonView.h"
#import "GroupMemberModel.h"
#import "GroupMemberViewCell.h"
#import "OLYMUserObject.h"
#import "OLYMHeaderSearchBar.h"
#import "NSString+PinYin.h"
#import "UISearchBar+LeftPlaceholder.h"
#import "OrganizationUtility.h"

@interface GroupPersonView()<OLYMHeaderSearchBarDelegate>

@property(retain,nonatomic) GroupMemberModel *groupMemberModel;

/* 是否正在搜索 */
@property(nonatomic,assign) BOOL isSearch;

@end


@implementation GroupPersonView


- (instancetype)initWithViewModel:(id<OLYMViewModelProtocol>)viewModel {
    self.groupMemberModel = (GroupMemberModel *)viewModel;
    [self.tableView registerClass:[GroupMemberViewCell class] forCellReuseIdentifier:[NSString stringWithUTF8String:object_getClassName([GroupMemberViewCell class])]];
    return [super initWithViewModel:viewModel];
}

- (void)updateConstraints {
    
    WeakSelf(ws);
    [self.searchBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.mas_equalTo(ws);
        make.height.mas_equalTo(56);
    }];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(ws.searchBar.mas_bottom);
        make.left.right.bottom.mas_equalTo(ws);
    }];
    [super updateConstraints];
}

- (void)olym_setupViews {
    [self _createTableHeaderView];

    [self addSubview:self.searchBar];
    [self addSubview:self.tableView];
    [self createIPhoneXFooterView];
    
    [self setNeedsUpdateConstraints];
    [self updateConstraintsIfNeeded];
    
}

-(void)olym_bindViewModel{
    @weakify(self);
    [self.groupMemberModel.refreshUI subscribeNext:^(id x) {
        
        @strongify(self);
        [self.tableView reloadData];
    }];

}



#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return self.groupMemberModel.dataArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return 70.0f;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (Organization && [[olym_Default objectForKey:kAPI_ORGAN_Model] boolValue] && self.groupListType != GroupListTypeeDelete) {
        
        if (section == 0) {
            
            return 1;
        }
    }
    
    NSDictionary *dict = self.groupMemberModel.dataArray[section];
    NSMutableArray *array = dict[@"content"];
    return [array count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    GroupMemberViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[NSString stringWithUTF8String:object_getClassName([GroupMemberViewCell class])] forIndexPath:indexPath];
    
    if (Organization && [[olym_Default objectForKey:kAPI_ORGAN_Model] boolValue] && self.groupListType != GroupListTypeeDelete) {
        
        if (indexPath.section == 0) {
            
            cell.textLabel.text = _T(@"公司通讯录");
            cell.nickNameLabel.text = @"";
            return cell;
        }
    }

    OLYMUserObject *userObj = [self.groupMemberModel userObjAtIndexPath:indexPath];
    cell.userObj = userObj;
    
    //设置已经被选中的人的cell为选中状态
    for (OLYMUserObject *user in [OrganizationUtility sharedOrganizationUtility].selectedArray) {
        
        if ([user.userId isEqualToString:userObj.userId]) {
            
            [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
        }
    }
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    
    if (self.searchBar.text.length > 0) {
        
        return 0;
    }
    
    NSDictionary *dict = self.groupMemberModel.dataArray[section];
    NSString *title = dict[@"firstLetter"];
    return title;
}
//添加索引栏标题数组
- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    
    if (self.searchBar.text.length > 0) {
        
        return nil;
    }
    
    NSMutableArray *resultArray =[NSMutableArray arrayWithObject:UITableViewIndexSearch];
    for (NSDictionary *dict in self.groupMemberModel.dataArray) {
        NSString *title = dict[@"firstLetter"];
        [resultArray addObject:title];
    }
    return resultArray;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    //自定义Header标题
    UIView* myView = [[UIView alloc] init];
    myView.backgroundColor = GJCFQuickHexColor(@"0xefeff4");
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 90, 22)];
    titleLabel.textColor=[UIColor blackColor];
    
    NSString *title = self.groupMemberModel.dataArray[section][@"firstLetter"];
    titleLabel.text=title;
    [myView  addSubview:titleLabel];
    
    return myView;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (Organization && [[olym_Default objectForKey:kAPI_ORGAN_Model] boolValue] && self.groupListType != GroupListTypeeDelete){
        
        if (indexPath.section == 0) {
            
            [self.groupMemberModel.organizationlistSubject sendNext:nil];
            return;
        }
    }
    
    OLYMUserObject *userObj = [self.groupMemberModel userObjAtIndexPath:indexPath];
    if(userObj.isCanNotCheck){
        return;
    }
    userObj.isCheck = !userObj.isCheck;
    
    [self.tableView beginUpdates];
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView endUpdates];
    
    if (userObj.isCheck)
    {
        [self.searchBar addSearchHeader:userObj];
    }else
    {
        [self.searchBar removeSearchHeader:userObj];
    }
    
    [self.groupMemberModel.membersCountRACSubject sendNext:@(self.searchBar.selectedArray.count)];
}

- (void)headerSearchBar:(OLYMHeaderSearchBar *)searchBar didDeleteObject:(id)object
{
    OLYMUserObject *userObj = object;
    for (NSDictionary *dict in self.groupMemberModel.dataArray) {
        NSMutableArray *array = dict[@"content"];
        if ([array containsObject:userObj])
        {
            if(userObj.isCanNotCheck){
                return;
            }

            NSInteger section = [self.groupMemberModel.dataArray indexOfObject:dict];
            NSInteger row = [array indexOfObject:userObj];
            
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
            userObj.isCheck = !userObj.isCheck;
            
            [self.tableView beginUpdates];
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            [self.tableView endUpdates];

            break;
        }
    }
}

- (void)headerSearchBar:(OLYMHeaderSearchBar *)searchBar  setCollectionCellImage:(OLYMSearchHeaderCollectionCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    //如果userHead没有url 就重新拼接一个（搜索好友的时候都没有userHead）
    OLYMUserObject *userObj = [searchBar.selectedArray objectAtIndex:indexPath.row];

    NSString *userHeader = nil;
    if(userObj.userHead){
        userHeader = userObj.userHead;
    }else{
        userHeader = [HeaderImageUtils getHeaderImageUrl:userObj.userId withDomain:userObj.domain];
    }
#if MJTDEV
    [cell.imageView setImageUrl:userHeader withDefault:@"defaultheadv3"];
#else
    [cell.imageView setImageUrl:userHeader withDefault:@"default_head"];
#endif

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
    [self.groupMemberModel.dataArray removeAllObjects];
    [self.groupMemberModel.dataArray addObjectsFromArray:self.groupMemberModel.previousArray];
    
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
//
//        //如果0.5秒内没有输入动作，则搜索
//        [self  performSelector:@selector(filterBySubstring:) withObject:self.searchBar.text afterDelay:0.5f];
        [self filterBySubstring:self.searchBar.text];

    }
}

- (void)hideKeyboardWithSearchBar:(UISearchBar *)searchBar{
    [searchBar resignFirstResponder];

    //    _maskView.hidden = YES;
    _isSearch = NO;
    //还原数据
    
    if (self.groupMemberModel.previousArray.count > 0) {
        
        [self.groupMemberModel.dataArray removeAllObjects];
        [self.groupMemberModel.dataArray addObjectsFromArray:self.groupMemberModel.previousArray];
        //还原从选择的数据
        for (OLYMUserObject *uesrObj in self.searchBar.selectedArray) {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.userId == %@ && SELF.domain == %@",uesrObj.userId,uesrObj.domain];
            NSArray *results = [self.groupMemberModel.dataArray filteredArrayUsingPredicate:predicate];
            for (OLYMUserObject *rUesrObj in results) {
                rUesrObj.isCheck = uesrObj.isCheck;
            }
        }
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
    if (!self.groupMemberModel.previousArray) {
        self.groupMemberModel.previousArray = [NSMutableArray array];
    }
    
    if (!_isSearch && self.groupMemberModel.previousArray.count == 0) {
        
        [self.groupMemberModel.previousArray removeAllObjects];
        [self.groupMemberModel.previousArray addObjectsFromArray:self.groupMemberModel.dataArray];
    }
    
    [self.groupMemberModel.dataArray removeAllObjects];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        WeakSelf(ws);
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.userNickname contains [cd] %@ ||SELF.userRemarkname contains [cd] %@ || SELF.telephone contains [cd] %@ ||  SELF.nameLetters contains [cd] %@ || SELF.remarkLetters contains [cd] %@",subStr,subStr,subStr,subStr,subStr];
        NSMutableArray *searchs = [self.groupMemberModel.allContacts  filteredArrayUsingPredicate:predicate].mutableCopy;
        ws.groupMemberModel.dataArray = [searchs arrayWithPinYinFirstLetterFormat];
        
        // 设置为搜索状态
        //        _isSearch = YES;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self.tableView reloadData];
        });
        
        
    });
    
}


#pragma mark - Private
-(void)_createTableHeaderView{
    
    //搜索栏
    _searchBar = [[OLYMHeaderSearchBar alloc] initWithFrame:CGRectMake(0, 0, GJCFSystemScreenWidth, 30)];
//    _searchBar.delegate = self;
    _searchBar.searBarDelegate = self;
    [_searchBar setCenterdPlaceholder];
    _searchBar.placeholder = _T(@"搜索");
    _searchBar.backgroundImage = [UIImage imageNamed:@"searchbar_bg"];
    [_searchBar setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    [_searchBar sizeToFit];
    self.tableView.sectionIndexBackgroundColor = [UIColor clearColor];
    
}


/**
 选中或者取消选中某cell

 @param user user
 @param isChick 是否取消选中某cell
 */
-(void)deselectCell:(OLYMUserObject *)user isCheck:(BOOL)isCheck{
    
    for (NSInteger i = 0; i < self.groupMemberModel.dataArray.count; i++) {
        
        NSDictionary *dict = self.groupMemberModel.dataArray[i];
        NSMutableArray *array = dict[@"content"];
        
        for (NSInteger j = 0; j < array.count; j++) {
            
            OLYMUserObject *userObj = array[j];
            
            if ([userObj isKindOfClass:OLYMUserObject.class]
                && [userObj.userId isEqualToString:user.userId]
                && userObj.isCheck == isCheck) {
                
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:j inSection:i];
                [self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
                
            }
            
        }
    }
    
}

@end
