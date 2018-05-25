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
@interface MiLiaoViewController ()<PopMenuViewDelegate,GroupMemberViewControllerDelegate>

@property (strong,nonatomic) MiLiaoListView *mainView;

@property (retain,nonatomic) MiLiaoViewModel *miLiaoViewModel;

// 弹出菜单
@property (nonatomic, strong) PopMenuView *popMenuView;

// 弹出菜单蒙版
@property (nonatomic, strong) UIView *maskView;

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
    
}


- (void)updateViewConstraints {
    
    WeakSelf(weakSelf);
    
    [self.mainView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(weakSelf.view);
    }];
    
    [super updateViewConstraints];
}


#pragma mark - private

-(void)olym_addSubviews{
    [self.view addSubview:self.mainView];
}

-(void)olym_bindViewModel{
    
    [self.miLiaoViewModel.refreshDataCommand execute:nil];
    
    @weakify(self);
    [[olym_Nofity rac_addObserverForName:XMPPStateNotification object:nil]subscribeNext:^(NSNotification * _Nullable x) {
        GJCFAsyncMainQueue(^(void){
            @strongify(self);
            XMPPState state = [[x object]integerValue];
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
            
            [self.miLiaoViewModel.refreshUI sendNext:nil];
        });
    }];

    [[self.miLiaoViewModel.cellClickSubject takeUntil:self.rac_willDeallocSignal] subscribeNext:^(id x) {
        
        
        NSIndexPath *indexPath = (NSIndexPath *)x;
        
        if([[[self.miLiaoViewModel.dataArray objectAtIndex:indexPath.row] userId] intValue] == FRIEND_CENTER_INT){
            
            NewFriendViewController *mNewFriendViewController = [[NewFriendViewController alloc]init];
            
            [self.navigationController pushViewController:mNewFriendViewController animated:YES];
            
        }else{
            
            @strongify(self);
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
    
}

-(void)olym_layoutNavigation{
    [self xmppStateChanged:[[XMPPController sharedInstance]xmppState]];
    [self setRightButtonWithStateImage:@"nav_btn_add_nor" stateHighlightedImage:@"nav_btn_add_pre" stateDisabledImage:nil titleName:nil];
}

-(void)rightButtonPressed:(UIButton *)sender{
    
    if (self.popMenuView.isShow) {
        // 隐藏弹出菜单
        [self hidePopMenuView];
    } else {
        // 弹出菜单
        [self showPopMenuView];
    }
}

- (void)xmppStateChanged:(XMPPState)state
{
    switch (state) {
        case XMPPOnline:
            [self setStrNavTitle:@"密聊(在线)"];
            break;
        case XMPPOffline:
            [self setStrNavTitle:@"密聊(离线)"];
            break;
        case XMPPLoginWait:
            [self setStrNavTitle:@"密聊(连接中)"];
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

    [self.popMenuView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(ws.view);
        make.right.equalTo(ws.view.mas_right);
        make.width.mas_equalTo(140);
        make.height.mas_equalTo(100);
    }];
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
            SearchFriendViewController *mSearchFriendViewController = [[SearchFriendViewController alloc]init];
            OLYMBaseNavigationController *nav = [[OLYMBaseNavigationController alloc]initWithRootViewController:mSearchFriendViewController];
            [self presentViewController:nav animated:YES completion:nil];
        }
        default:
            break;
    }
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



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
