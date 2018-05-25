//
//  ChatCardViewController.m
//  MJT_APP
//
//  Created by Donny on 2017/9/12.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "ChatCardViewController.h"
#import "ChatCardListView.h"
#import "ChatCardViewModel.h"
#import "OLYMUserObject.h"
#import "ForwardAlertView.h"
#import "OrganizationViewController.h"

@interface ChatCardViewController ()

// 返回按钮
@property (nonatomic, strong) UIBarButtonItem *backBtn;

@property (nonatomic, strong) ChatCardListView *chatCardListView;

@property (nonatomic, strong) ChatCardViewModel *chatCardViewModel;

@end

@implementation ChatCardViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)olym_addSubviews{
    self.navigationItem.leftBarButtonItem = self.backBtn;
    
    [self.view addSubview:self.chatCardListView];
    
    WeakSelf(ws);
    [self.chatCardListView mas_makeConstraints:^(MASConstraintMaker *make) {
        if (@available(iOS 11, *)) {
            make.edges.mas_equalTo(ws.view.safeAreaInsets);
        }else{
            make.edges.mas_equalTo(ws.view);
        }
    }];

}

- (void)olym_bindViewModel{
    @weakify(self);
    
    [[self.chatCardViewModel.cellClickSubject takeUntil:self.rac_willDeallocSignal]subscribeNext:^(OLYMUserObject *userObj) {
        @strongify(self);
        
#if MJTDEV
        OLYMUserObject *toPerson;
        OLYMUserObject *cardPerson;
        
        if (Organization && [[olym_Default objectForKey:kAPI_ORGAN_Model] boolValue] && [userObj isKindOfClass:NSString.class]) {
        
            OrganizationViewController *controller = [[OrganizationViewController alloc]initWithHierarchyId:@"0"];
            controller.organizationListType = OrganizationListTypeCard;
            [self.navigationController pushViewController:controller animated:YES];
            return ;
        }
        
        if (self.chatCardType == ChatCardToOtherPerson)
        {
            toPerson = userObj;
            cardPerson = self.currentChatUser;
        }else
        {
            toPerson = self.currentChatUser;
            cardPerson = userObj;
        }
        
        ForwardAlertView *forwardAlertView = [[ForwardAlertView alloc]initWithTitle:toPerson.userNickname images:@[toPerson] content:[NSString stringWithFormat:_T(@"[个人名片] %@"), [cardPerson getDisplayName]] contentType:Content_Text buttonHandler:^(NSInteger buttonClickIndex) {
            if (buttonClickIndex == 1)
            {
                [self.chatCardViewModel sendCardMessagetoUser:userObj];

                [self dismissViewControllerAnimated:YES completion:^{
                    if (self.chatCardType == ChatCardToOtherPerson) {
                        [SVProgressHUD showSuccessWithStatus:_T(@"发送成功")];
                    }
                }];
            }
        }];
        [forwardAlertView show];
#else
        [self.chatCardViewModel sendCardMessagetoUser:userObj];
        
        [self dismissViewControllerAnimated:YES completion:^{
            if (self.chatCardType == ChatCardToOtherPerson) {
                [SVProgressHUD showSuccessWithStatus:_T(@"发送成功")];
            }
        }];
#endif
        
    }];
    
    [[[olym_Nofity rac_addObserverForName:kOrganizationCardNotification object:nil] takeUntil:self.rac_willDeallocSignal] subscribeNext:^(NSNotification * _Nullable x) {
        @strongify(self);
        
        OLYMUserObject *userObj = x.object;
        userObj.domain = FULL_DOMAIN(olym_UserCenter.userDomain);
        if (self.chatCardType == ChatCardToOtherPerson)
        {
            //推荐给别人

            if (userObj.status == friend_status_friend ||
                userObj.status == friend_status_orgination ||
                userObj.status == friend_status_colleague) {
                
                [self.chatCardViewModel.cellClickSubject sendNext:userObj];
            }else{
                
                [SVProgressHUD showInfoWithStatus:_T(@"请先添加好友")];
            }
            
        }else{
            //发送给当前聊天
            [self.chatCardViewModel.cellClickSubject sendNext:userObj];
        }
        
        
    }];
    
}

- (void)olym_layoutNavigation{
    [self setStrNavTitle:_T(@"选择朋友")];
}

#pragma mark - <------------------- Action ------------------->
- (void)back
{
    if (self.presentingViewController)
    {
        [self dismissViewControllerAnimated:YES completion:nil];
    }else
    {
        [self.navigationController popViewControllerAnimated:YES];
    }
}



#pragma mark 《$ ---------------- Setter/Getter ---------------- $》

- (ChatCardViewModel *)chatCardViewModel{
    if(!_chatCardViewModel){
        
        _chatCardViewModel = [[ChatCardViewModel alloc] initWithUser:self.currentChatUser chatCardType:self.chatCardType];
    }
    return _chatCardViewModel;
}

- (ChatCardListView *)chatCardListView {
    
    if (!_chatCardListView) {
        _chatCardListView = [[ChatCardListView alloc] initWithViewModel:self.chatCardViewModel];
    }
    return _chatCardListView;
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
