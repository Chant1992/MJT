//
//  RemindViewController.m
//  MJT_APP
//
//  Created by Donny on 2017/9/14.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "RemindViewController.h"
#import "RemindListView.h"
#import "RemindViewModel.h"
#import "OLYMUserObject.h"
#import "UISearchBar+LeftPlaceholder.h"

@interface RemindViewController ()
// 返回按钮
@property (nonatomic, strong) UIBarButtonItem *backBtn;

// 搜索框
@property (nonatomic, strong) UISearchController *searchCon;

@property (nonatomic, strong) RemindListView *remindListView;

@property (nonatomic, strong) RemindViewModel *remindViewModel;

@end

@implementation RemindViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)olym_addSubviews{
    self.definesPresentationContext = YES;
    
    self.navigationItem.leftBarButtonItem = self.backBtn;
    
    [self.view addSubview:self.remindListView];
    
    WeakSelf(ws);
    [self.remindListView mas_makeConstraints:^(MASConstraintMaker *make) {
        if (@available(iOS 11, *)) {
            make.edges.mas_equalTo(ws.view.safeAreaInsets);
        }else{
            make.edges.mas_equalTo(ws.view);
        }
    }];
    
}


- (void)olym_layoutNavigation
{
    [self setStrNavTitle:_T(@"请选择要提醒的人")];

}


- (void)olym_bindViewModel
{
    WeakSelf(ws);

    //
    [self.remindViewModel.membersCommand execute:self.currentChatUser];
    
    [self.remindViewModel.cellClickSubject subscribeNext:^(id  _Nullable x) {
        StrongSelf(ss);
        if (ss.remindChooseOneContact)
        {
            OLYMUserObject *userObj = x;
            ss.remindChooseOneContact(userObj.userNickname,userObj.userId);
            [ss back];
        }
    }];
    
}


#pragma mark - <------------------- Action ------------------->
- (void)back
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}



#pragma mark 《$ ---------------- Setter/Getter ---------------- $》

- (RemindViewModel *)remindViewModel{
    if(!_remindViewModel){
        
        _remindViewModel = [[RemindViewModel alloc] init];
    }
    return _remindViewModel;
}

- (RemindListView *)remindListView {
    
    if (!_remindListView) {
        _remindListView = [[RemindListView alloc] initWithViewModel:self.remindViewModel searchController:self.searchCon];
    }
    return _remindListView;
}


- (UISearchController *)searchCon {
    
    if (!_searchCon) {
        
        _searchCon = [[UISearchController alloc] initWithSearchResultsController:nil];
        // SearchBar configuration
        _searchCon.searchBar.frame = CGRectMake(0, 0, CGRectGetWidth([UIScreen mainScreen].bounds), 44.0f);
//        _searchCon.searchBar.delegate = self;

        _searchCon.searchBar.placeholder = _T(@"搜索");
        _searchCon.searchBar.backgroundImage = [UIImage imageNamed:@"searchbar_bg"];
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
    }
    
    return _searchCon;
}


// 返回按钮
- (UIBarButtonItem *)backBtn {
    
    if (!_backBtn) {
        
#if ThirdlyVersion
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(0, 0, 35, 35);
        [button setImage:[UIImage imageNamed:@"back"] forState:UIControlStateNormal];
        [button setImage:[UIImage imageNamed:@"back_pre"] forState:UIControlStateHighlighted];
        [button addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
        button.imageEdgeInsets = UIEdgeInsetsMake(0, -20, 0, 0);
        _backBtn = [[UIBarButtonItem alloc]initWithCustomView:button];
#else
        
        _backBtn = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"return"] style:UIBarButtonItemStylePlain target:self action:@selector(back)];
#endif
    }
    
    return _backBtn;
}



@end
