//
//  SearchFullTextController.m
//  MJT_APP
//
//  Created by Donny on 2017/12/18.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "SearchFullRecordController.h"
#import "ChatRecordViewModel.h"
#import "SearchFullRecordView.h"
#import "ChatViewController.h"
#import "DetailContactViewController.h"
#import "OLYMUserObject.h"
#import "SearchDetialRecordViewController.h"
#import "OLYMSearchObject.h"
#import "SearchChatRecordController.h"
#import "UISearchBar+LeftPlaceholder.h"

@interface SearchFullRecordController ()<UISearchControllerDelegate,UISearchBarDelegate>

@property (nonatomic, strong) UISearchController *searchCon;

@property (nonatomic, strong) SearchFullRecordView *searchRecordListView;

@property (nonatomic, strong) ChatRecordViewModel *searchViewModel;
@end

@implementation SearchFullRecordController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear: animated];
    self.searchCon.active = true;
}

- (void)olym_addSubviews
{
    self.definesPresentationContext = YES;

    [self.view addSubview:self.searchRecordListView];
    
    WeakSelf(ws);
    [self.searchRecordListView mas_makeConstraints:^(MASConstraintMaker *make) {
        if (@available(iOS 11, *)) {
            make.edges.mas_equalTo(ws.view.safeAreaInsets);
        }else{
            make.edges.mas_equalTo(ws.view);
        }
    }];
    
}


- (void)olym_layoutNavigation
{
 
}


- (void)olym_bindViewModel
{
    @weakify(self);
    [[self.searchViewModel.miyouSubject takeUntil:self.rac_willDeallocSignal]subscribeNext:^(OLYMUserObject* userObj) {
        @strongify(self);
        ChatViewController *chatController = [[ChatViewController alloc]init];
        chatController.currentChatUser = userObj;
        [self.navigationController pushViewController:chatController animated:YES];
    }];
    [[self.searchViewModel.localContactSubject takeUntil:self.rac_willDeallocSignal]subscribeNext:^(OLYMUserObject* userObj) {
        @strongify(self);
        DetailContactViewController *vc = [[DetailContactViewController alloc]init];
        vc.isEditContact = YES;
        vc.userObj = userObj;
        vc.isToBeInvitedContact = YES;
        [self.navigationController pushViewController:vc animated:YES];
    }];
    //更多联系人
    [[self.searchViewModel.moreContactsSubject takeUntil:self.rac_willDeallocSignal]subscribeNext:^(OLYMSearchObject *searchObj) {
        @strongify(self);
        SearchDetialRecordViewController *controller = [[SearchDetialRecordViewController alloc]init];
        controller.searchObject = searchObj;
        controller.keyword = self.searchCon.searchBar.text;
        [self.navigationController pushViewController:controller animated:YES];

    }];
    //更多群组
    [[self.searchViewModel.moreGroupsSubject takeUntil:self.rac_willDeallocSignal]subscribeNext:^(OLYMSearchObject *searchObj) {
        SearchDetialRecordViewController *controller = [[SearchDetialRecordViewController alloc]init];
        controller.searchObject = searchObj;
        controller.keyword = self.searchCon.searchBar.text;
        [self.navigationController pushViewController:controller animated:YES];

    }];
    //更多聊天记录
    [[self.searchViewModel.moreFullRecordsSubject takeUntil:self.rac_willDeallocSignal]subscribeNext:^(OLYMSearchObject *searchObj) {
        @strongify(self);
        SearchDetialRecordViewController *controller = [[SearchDetialRecordViewController alloc]init];
        controller.searchObject = searchObj;
        controller.keyword = self.searchCon.searchBar.text;
        [self.navigationController pushViewController:controller animated:YES];

    }];
    //搜索到的单条聊天记录，跳转到聊天界面
    [[self.searchViewModel.singleRecordSubject takeUntil:self.rac_willDeallocSignal]subscribeNext:^(OLYMMessageSearchObject *searchObj) {
        @strongify(self);
        ChatViewController *chatController = [[ChatViewController alloc]init];
        chatController.currentChatUser = searchObj.userObject;
        chatController.searchMessaegObject = [searchObj.searchArray firstObject];
        [self.navigationController pushViewController:chatController animated:YES];

    }];
    //搜索到的聊天对话有多条聊天记录
    [[self.searchViewModel.multiRecordSubject takeUntil:self.rac_willDeallocSignal]subscribeNext:^(OLYMMessageSearchObject *searchObj) {
        @strongify(self);
        SearchChatRecordController *controller = [[SearchChatRecordController alloc]init];
        controller.currentChatUser = searchObj.userObject;
        controller.searchArray = searchObj.searchArray;
        [self.navigationController pushViewController:controller animated:YES];
    }];
}

#pragma mark UISearchControllerDelegate
- (void)didPresentSearchController:(UISearchController *)searchController {
    [UIView animateWithDuration:0.1 animations:^{} completion:^(BOOL finished) {
        [self.searchCon.searchBar becomeFirstResponder];
    }];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [searchBar setCenterdPlaceholder];
    [self.navigationController popViewControllerAnimated:YES];
}



#pragma mark - Property

- (SearchFullRecordView *)searchRecordListView
{
    if (!_searchRecordListView)
    {
        _searchRecordListView = [[SearchFullRecordView alloc]initWithViewModel:self.searchViewModel searchController:self.searchCon];
    }
    return _searchRecordListView;
}

- (ChatRecordViewModel *)searchViewModel
{
    if (!_searchViewModel) {
        _searchViewModel = [[ChatRecordViewModel alloc]init];
    }
    return _searchViewModel;
}

- (UISearchController *)searchCon {
    
    if (!_searchCon) {
        
        _searchCon = [[UISearchController alloc] initWithSearchResultsController:nil];
        // SearchBar configuration
        _searchCon.searchBar.frame = CGRectMake(0, 0, CGRectGetWidth([UIScreen mainScreen].bounds), 44.0f);
        _searchCon.searchBar.delegate = self;
        
        _searchCon.searchBar.placeholder = _T(@"搜索");
        [_searchCon.searchBar setBackgroundImage:[UIImage new]];
        [_searchCon.searchBar setAutocapitalizationType:UITextAutocapitalizationTypeNone];
        [_searchCon.searchBar setCenterdPlaceholder];
        // SearchController configuration
        //        _searchCon.searchResultsUpdater = self;
        // 背景变暗色
        _searchCon.dimsBackgroundDuringPresentation = NO;
        // 背景变模糊
        _searchCon.obscuresBackgroundDuringPresentation = NO;
        //隐藏导航栏
        _searchCon.hidesNavigationBarDuringPresentation = YES;
        _searchCon.delegate = self;
        [_searchCon.searchBar sizeToFit];

        _searchCon.searchBar.backgroundColor = RGB(225, 225, 225);
        
        //遮住状态栏的颜色 与bar4
        UIView *topView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, GJCFSystemScreenWidth, 44)];
        topView.backgroundColor = [UIColor whiteColor];
        
        [_searchCon.view insertSubview:topView atIndex:0];
        
        _searchCon.searchBar.barTintColor = [UIColor whiteColor];
        for (UIView *subView in _searchCon.searchBar.subviews)
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
        UITextField *searchField = [_searchCon.searchBar valueForKey:@"searchField"];
        if (searchField) {
            [searchField setBackgroundColor:OLYMHEXCOLOR(0XEDEDEE)];
            searchField.layer.cornerRadius = 0;
        }

    }
    
    return _searchCon;
}


@end
