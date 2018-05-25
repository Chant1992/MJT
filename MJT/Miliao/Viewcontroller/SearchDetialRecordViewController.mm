//
//  SearchRecordViewController.m
//  MJT_APP
//
//  Created by Donny on 2017/12/20.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "SearchDetialRecordViewController.h"
#import "OLYMSearchObject.h"
#import "ChatViewController.h"
#import "DetailContactViewController.h"
#import "ChatRecordViewModel.h"
#import "SearchDetialRecordView.h"
#import "SearchChatRecordController.h"
#import "UISearchBar+LeftPlaceholder.h"

@interface SearchDetialRecordViewController ()

@property (nonatomic, strong) UISearchController *searchCon;

@property (nonatomic, strong) SearchDetialRecordView *chatRecordListView;

@property (nonatomic, strong) ChatRecordViewModel *searchViewModel;

@end

@implementation SearchDetialRecordViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)olym_addSubviews
{
    self.definesPresentationContext = YES;
    
    [self.view addSubview:self.chatRecordListView];
    
    WeakSelf(ws);
    [self.chatRecordListView mas_makeConstraints:^(MASConstraintMaker *make) {
        if (@available(iOS 11, *)) {
            make.edges.mas_equalTo(ws.view.safeAreaInsets);
        }else{
            make.edges.mas_equalTo(ws.view);
        }
    }];
    
    [self.searchCon.searchBar becomeFirstResponder];
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

- (SearchDetialRecordView *)chatRecordListView
{
    if (!_chatRecordListView) {
        _chatRecordListView = [[SearchDetialRecordView alloc]initWithViewModel:self.searchViewModel searchController:self.searchCon searchObj:self.searchObject keyword:self.keyword];
    }
    return _chatRecordListView;
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
        //        _searchCon.searchBar.delegate = self;
        
        _searchCon.searchBar.placeholder = _T(@"搜索");
        _searchCon.searchBar.backgroundImage = [UIImage new];
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
        [_searchCon.searchBar sizeToFit];
        
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
