//
//  MiLiaoViewController.m
//  MJT_APP
//
//  Created by olymtech on 2017/8/21.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "MiLiaoViewController.h"
#import "MiLiaoViewModel.h"
#import "MiLiaoListView.h"
#import "ChatViewController.h"
#import "NewFriendViewController.h"
#import "PopMenuView.h"
#import "SearchFriendViewController.h"
#import "GroupMemberViewController.h"
#import "OLYMUserObject.h"
#import "CallViewController.h"
#import "OLYMUserObject.h"
#import "SearchFullRecordController.h"
#import "SearchFriend2ViewController.h"
#import "UISearchBar+LeftPlaceholder.h"
#import "OLYMScanController.h"
#import "ScanLoginViewController.h"

@interface MiLiaoViewController ()<PopMenuViewDelegate,GroupMemberViewControllerDelegate,UISearchBarDelegate>

@property (strong,nonatomic) MiLiaoListView *mainView;

@property (strong,nonatomic) MiLiaoViewModel *miLiaoViewModel;

// 弹出菜单
@property (nonatomic, strong) PopMenuView *popMenuView;

// 弹出菜单蒙版
@property (nonatomic, strong) UIView *maskView;

@property(nonatomic,strong) UISegmentedControl *segment;

@end

@implementation MiLiaoViewController

-(instancetype)init{
    self = [super init];
    if(self){
       
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    //设置为YES，xmpp收消息将不再认为是未读了
    [olym_UserCenter setMessageUnreadOn:YES];

}


- (void)updateViewConstraints {
    
    WeakSelf(weakSelf);
    
    [self.mainView mas_makeConstraints:^(MASConstraintMaker *make) {
        if (@available(iOS 11, *)) {
            make.edges.mas_equalTo(weakSelf.view.safeAreaInsets);
        }else{
            make.edges.mas_equalTo(weakSelf.view);
        }
    }];
    
    [super updateViewConstraints];
}


#pragma mark - private

-(void)olym_addSubviews{
    
    [self.view addSubview:self.mainView];

#if ThirdlyVersion
    
    [self setRightButtonWithStateImage:@"nav_add_nor" stateHighlightedImage:@"nav_add_pre" stateDisabledImage:nil titleName:nil];
#else
    
    [self setRightButtonWithStateImage:@"nav_btn_add_nor" stateHighlightedImage:@"nav_btn_add_pre" stateDisabledImage:nil titleName:nil];
#endif

}

-(void)olym_bindViewModel{
    
    [self.miLiaoViewModel.refreshDataCommand execute:nil];
    
    @weakify(self);
    [[olym_Nofity rac_addObserverForName:XMPPStateNotification object:nil]subscribeNext:^(NSNotification *notification) {
        GJCFAsyncMainQueue(^(void){
            @strongify(self);
            NSInteger i = [notification.object integerValue];
            
            XMPPState state;
            switch (i) {
                case 0:
                    
                    state = XMPPLoginWait;
                    break;
                case 1:
                    
                    state = XMPPOnline;
                    break;
                case -1:
                    
                    state = XMPPOffline;
                    break;
            }
            
            [self xmppStateChanged:state];
        });
    }];
    
    //从数据库刷新整个列表
    [[olym_Nofity rac_addObserverForName:kXMPPRefreshMsgListFromDatabaseNotifaction object:nil]subscribeNext:^(NSNotification * _Nullable x) {
        GJCFAsyncMainQueue(^(void){
            @strongify(self);
            [self.miLiaoViewModel.refreshDataCommand execute:nil];
        });
    }];
    
    //修改群名称
    [[olym_Nofity rac_addObserverForName:kRefreshModifyGroupNameNotification object:nil]subscribeNext:^(NSNotification *notification) {
        @strongify(self);
        OLYMUserObject *user = [notification object];
        [self.miLiaoViewModel replaceUser:user];

        GJCFAsyncMainQueue(^(void){
            //reload data here
            [self.mainView.tableView reloadData];
        });
    }];

    
    [[olym_Nofity rac_addObserverForName:kXMPPFriendRemakenameNotifaction object:nil]subscribeNext:^(NSNotification * _Nullable x) {

        GJCFAsyncMainQueue(^(void){
            @strongify(self);
            
            [self.miLiaoViewModel.refreshDataCommand execute:nil];
        });
    }];

    [[self.miLiaoViewModel.cellClickSubject takeUntil:self.rac_willDeallocSignal] subscribeNext:^(id x) {
        @strongify(self)
        NSLog(@"Push to chatview");
        NSIndexPath *indexPath = (NSIndexPath *)x;
        
        if([[[self.miLiaoViewModel.dataArray objectAtIndex:indexPath.row] userId] intValue] == FRIEND_CENTER_INT){
            
            NewFriendViewController *mNewFriendViewController = [[NewFriendViewController alloc]init];
            
            [self.navigationController pushViewController:mNewFriendViewController animated:YES];
            
        }else{
            
            ChatViewController *mChatViewController = [[ChatViewController alloc]init];
            [mChatViewController setCurrentChatUser:[self.miLiaoViewModel.dataArray objectAtIndex:indexPath.row]];
            [self.navigationController pushViewController:mChatViewController animated:YES];
           
        }
    }];
    
    //聊天界面返回 将保存的正在会话的对象清空
    [[self rac_signalForSelector:@selector(viewWillAppear:)] subscribeNext:^(id x) {
        @strongify(self)
        [self.mainView chatViewExit];
    }];
    
    //更改黑名单状态
    [[olym_Nofity rac_addObserverForName:kRefreshModifyBlackListNotification object:nil]subscribeNext:^(NSNotification *notification) {
        @strongify(self);
        GJCFAsyncMainQueue(^(void){
            OLYMUserObject *user = [notification object];
            for (OLYMUserObject *userObj in self.miLiaoViewModel.dataArray)
            {
                if ([user.userId isEqualToString:userObj.userId] && [user.domain isEqualToString:userObj.domain])
                {
                    userObj.status = user.status;
                }
            }
            [self.mainView.tableView reloadData];
        });
    }];

    [[olym_Nofity rac_addObserverForName:kPCLoginSucceedNotification object:nil] subscribeNext:^(NSNotification * _Nullable x) {
        @strongify(self);
        
        [self.mainView.tableView reloadData];
    }];
    
    [[self.miLiaoViewModel.pcViewClickSubject takeUntil:self.rac_willDeallocSignal] subscribeNext:^(id  _Nullable x) {
        @strongify(self);
       
        ScanLoginViewController *vc = [[ScanLoginViewController alloc]init];
        OLYMBaseNavigationController *nav = [[OLYMBaseNavigationController alloc]initWithRootViewController:vc];
        vc.scanType = ScanTypeLogined;
        
        [self presentViewController:nav animated:YES completion:nil];
    }];
}

-(void)olym_layoutNavigation{
    
    [self xmppStateChanged:[[XMPPController sharedInstance]xmppState]];
    
#if MiXinOn
    
//    [self.miXinViewModel.refreshDataCommand execute:nil];
#endif
    
}
                   
-(void)rightButtonPressed:(UIButton *)sender{
#if XYT
    GroupMemberViewController *groupMemberViewController = [[GroupMemberViewController alloc]initWithType:groupPersonSelectTypeNew];
    groupMemberViewController.delegate = self;
    OLYMBaseNavigationController *nav = [[OLYMBaseNavigationController alloc]initWithRootViewController:groupMemberViewController];
    [self presentViewController:nav animated:YES completion:nil];
#else
    //密聊
    if (self.popMenuView.isShow) {
        // 隐藏弹出菜单
        [self hidePopMenuView];
    } else {
        // 弹出菜单
        [self showPopMenuView];
    }
#endif
}

- (void)xmppStateChanged:(XMPPState)state
{
//#if MiXinOn
//    switch (state) {
//        case XMPPOnline:
//            [self.segment setTitle:@"密聊(在线)" forSegmentAtIndex:0];
//            break;
//        case XMPPOffline:
//            [self.segment setTitle:@"密聊(离线)" forSegmentAtIndex:0];
//            break;
//        case XMPPLoginWait:
//            [self.segment setTitle:@"密聊(连接中)" forSegmentAtIndex:0];
//            break;
//        default:
//            break;
//    }
//    return;
//#endif
    
    switch (state) {
        case XMPPOnline:
#if XYT
            [self setStrNavTitle:_T(@"密聊(在线)_xyt")];
#else
            [self setStrNavTitle:_T(@"密聊(在线)")];
#endif
            break;
        case XMPPOffline:
#if XYT
            [self setStrNavTitle:_T(@"密聊(离线)_xyt")];
#else
            [self setStrNavTitle:_T(@"密聊(离线)")];
#endif
            
            break;
        case XMPPLoginWait:
#if XYT
            [self setStrNavTitle:_T(@"密聊(连接中)_xyt")];
#else
            [self setStrNavTitle:_T(@"密聊(连接中)")];
#endif
            break;
        default:
            break;
    }
}

#pragma mark - 右上角菜单事件

// 弹出菜单
- (void)showPopMenuView {
    
    [self.view addSubview:self.maskView];
    [self.view addSubview:self.popMenuView];
    
    WeakSelf(ws);
    [self.maskView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(ws.view);
    }];

    if(GJCFSystemiPad){
        [self.popMenuView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(ws.view);
            make.right.equalTo(ws.view.mas_right).offset(-5);
            make.width.mas_equalTo(140);
            make.height.mas_equalTo(125);
        }];
    }else
    {

        [self.popMenuView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(ws.view);
            if (ScanLogin) {
                
                make.height.mas_equalTo(150);
            }else{
                
                make.height.mas_equalTo(100);
            }

#if MJTDEV
            make.right.equalTo(ws.view.mas_right).offset(-5);
            make.width.mas_equalTo(140);
            
#else
            make.right.equalTo(ws.view.mas_right);
            make.width.mas_equalTo(140);
#endif
        }];
    }
    
    _popMenuView.isShow = YES;
    _popMenuView.alpha = 0.0f;
    _popMenuView.transform = CGAffineTransformMakeScale(0.5, 0.5);
    [UIView animateWithDuration:.3 animations:^{
        
        _popMenuView.alpha = 1.0;
        _popMenuView.transform = CGAffineTransformMakeScale(1.0, 1.0);
        
    }];
}

// 隐藏弹出菜单
- (void)hidePopMenuView {
    _popMenuView.isShow = NO;
    _popMenuView.alpha = 1.0;
    _popMenuView.transform = CGAffineTransformMakeScale(1.0, 1.0);
    [UIView animateWithDuration:.3f animations:^{
        _popMenuView.alpha = 0.0;
        _popMenuView.transform = CGAffineTransformMakeScale(0.5, 0.5);
    } completion:^(BOOL finished) {
        
        if (finished) {
            [_popMenuView removeFromSuperview];
            [_maskView removeFromSuperview];
        }
    }];
}

#pragma mark - PopView Delagte
-(void)popViewCellClick:(NSInteger)index{
    
    [self hidePopMenuView];
    
    switch (index) {
        case 0:
        {
            GroupMemberViewController *groupMemberViewController = [[GroupMemberViewController alloc]initWithType:groupPersonSelectTypeNew];
            groupMemberViewController.delegate = self;
            OLYMBaseNavigationController *nav = [[OLYMBaseNavigationController alloc]initWithRootViewController:groupMemberViewController];
            [self presentViewController:nav animated:YES completion:nil];
            
            
        }
            break;
        case 1:
        {
#if MJTDEV
            SearchFriend2ViewController *mSearchFriendViewController = [[SearchFriend2ViewController alloc]init];
            OLYMBaseNavigationController *nav = [[OLYMBaseNavigationController alloc]initWithRootViewController:mSearchFriendViewController];
            [self presentViewController:nav animated:YES completion:nil];
#else
            
            SearchFriendViewController *mSearchFriendViewController = [[SearchFriendViewController alloc]init];
            OLYMBaseNavigationController *nav = [[OLYMBaseNavigationController alloc]initWithRootViewController:mSearchFriendViewController];
            [self presentViewController:nav animated:YES completion:nil];
#endif
        }
            break;
        case 2:
        {
            //扫一扫
            OLYMScanController *scanVc = [[OLYMScanController alloc]init];
            UINavigationController *nav = [[UINavigationController alloc]initWithRootViewController:scanVc];
            
            [self presentViewController:nav animated:YES completion:nil];
        }
            
            break;
    }
}

#pragma mark - UISearchBarDelegate
- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    [self.mainView.mSearchBar setCenterdPlaceholder];
    SearchFullRecordController *controller = [[SearchFullRecordController alloc]init];
    [self.navigationController pushViewController:controller animated:YES];
    return NO;
}

#pragma mark - GroupMemberViewControllerDelegate
- (void)groupMemberViewController:(GroupMemberViewController *)groupMemberController willEnterChatController:(UIViewController *)controller
{
    [self.navigationController pushViewController:controller animated:YES];
}

#pragma mark - layzLoad
- (MiLiaoListView *)mainView {

    if (!_mainView) {

        _mainView = [[MiLiaoListView alloc] initWithViewModel:self.miLiaoViewModel];
        _mainView.mSearchBar.delegate = self;
    }

    return _mainView;
}

- (MiLiaoViewModel *)miLiaoViewModel {

    if (!_miLiaoViewModel) {

        _miLiaoViewModel = [[MiLiaoViewModel alloc] init];
    }

    return _miLiaoViewModel;
}

- (PopMenuView *)popMenuView {
    
    if (!_popMenuView) {
        
        _popMenuView = [[PopMenuView alloc] init];
        [_popMenuView setDelegate:self];
    }
    
    return _popMenuView;
}

- (UIView *)maskView {
    
    if (!_maskView) {
        
        _maskView = [[UIView alloc] init];
        _maskView.backgroundColor = [UIColor clearColor];
        _maskView.alpha = 0.2;
        _maskView.userInteractionEnabled = YES;
        // 添加手势隐藏MaskView
        [_maskView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hidePopMenuView)]];
    }
    
    return _maskView;
}

-(UISegmentedControl *)segment{
    
    if (!_segment) {
        
        //先生成存放标题的数据
        NSArray *array = [NSArray arrayWithObjects:_T(@"密聊(连接中)"),_T(@"密信"), nil];
        //初始化UISegmentedControl
        _segment = [[UISegmentedControl alloc]initWithItems:array];
        _segment.frame = CGRectMake(0, 0, 150, 30);
        _segment.selectedSegmentIndex = 0;
        _segment.tintColor = white_color;
    }
    
    return _segment;
}

-(NSInteger)badgeValue{
    
    return [OLYMUserObject fetchAllUnreadCount];
}

@end
