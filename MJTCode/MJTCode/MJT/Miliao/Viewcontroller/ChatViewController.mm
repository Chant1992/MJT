//
//  ChatViewController.m
//  MJT_APP
//
//  Created by olymtech on 2017/8/29.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "ChatViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "GJGCChatInputPanel.h"
#import "ChatListView.h"
#import "ChatViewModel.h"
#import "UIImage+GJFixOrientation.h"
#import "OLYMUserObject.h"
#import "VoiceConverter.h"
#import "FileCenter.h"
#import "UserInfoViewController.h"
#import "GroupInfoViewController.h"
#import "KZVideoViewController.h"
#import "ConvertMov2MP4.h"
#import "RecentlyChatListViewController.h"
#import "SecurityEngineHelper.h"
#import "OLYMBaseNavigationController.h"
#import "ChatCardViewController.h"
#import "ChatFileViewController.h"
#import "RemindViewController.h"
#import "OLYMImageBrowserController.h"
#import "OLYMMoviePlayerViewController.h"
#import "OLYMBaseNavigationController.h"
#import "FileOpenVC.h"
#import "BurnAfterReadingViewController.h"
#import "UserInfoViewController.h"
#import "AlertViewManager.h"
#import "SearchFriendInfoViewController.h"
#import "GJCUImageBrowserViewController.h"
#import "ZLPhotoActionSheet.h"
#import "ZLDefine.h"
#import <Photos/Photos.h>
#import "ZLPhotoModel.h"
#import "OLYMWebViewController.h"
#import "GJCUImageBrowserModel.h"
#import "OLYMAESCrypt.h"
#import "UIImage+Image.h"
#import "ChatFile2ViewController.h"
#import "MoreInfomationViewController.h"
#import "PersonalDataViewController.h"

#import "TableEditView.h"

#import "FriendInformationViewController.h"


#define InputPanelBottomMargin (GJCFSystemiPhoneX ? 34 : 0)

@interface ChatViewController ()<GJGCChatInputPanelDelegate,UIImagePickerControllerDelegate,KZVideoViewControllerDelegate,UINavigationControllerDelegate>
// 容器
@property (nonatomic, strong) ChatListView *chatListView;
@property (nonatomic, retain) ChatViewModel *chatViewModel;
// 输入栏
@property (nonatomic, strong) GJGCChatInputPanel *inputPanel;

/**
 *  发送消息时间间隔频度控制
 */
@property (nonatomic,assign)NSInteger sendTimeLimit;

/**
 *  上一条消息的时间
 */
@property (nonatomic,assign)long long lastSendMsgTime;

/**
 * 阅后即焚按钮
 */
@property (nonatomic,strong) UIButton *fireButton;


@property (nonatomic,strong) UIButton *editButton;

@property (nonatomic,strong) TableEditView *editView;

@end

@implementation ChatViewController
{
    NSInteger viewCount;
}

-(void)dealloc{
  
}

- (void)viewDidLoad {
    [super viewDidLoad];

}

- (void)viewWillAppear:(BOOL)animated
{
    
    [super viewWillAppear:animated];
    viewCount = self.navigationController.viewControllers.count;
    
    // 禁用返回手势
    if (self.navigationController.viewControllers.count == 2 && [self.navigationController.viewControllers[0] isKindOfClass:NSClassFromString(@"JKRSearchResultViewController")]) {
        
        if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
            self.navigationController.interactivePopGestureRecognizer.enabled = NO;
        }
    }

}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    NSInteger count = self.navigationController.viewControllers.count;
    if (count < viewCount)
    {
        //删除角标
        dispatch_async(dispatch_get_main_queue(), ^{
#if ThirdlyVersion
            
            [self.currentChatUser updateDraftContent:self.inputPanel.inputBarTextViewContent];
#endif
            if(self.currentChatUser.isAppoint)
            {
                self.currentChatUser.isAppoint = NO;
                [self.currentChatUser updateIsAppoint];
            }
            if(self.currentChatUser.unreadCount > 0 ){
                [self.currentChatUser updateUnreadCount:0];
            }
            [olym_Nofity postNotificationName:kgroupMemberEnterChatNotification object:self.currentChatUser];
        });

        //移除通知
        [self.chatViewModel stopAudioPlay];
        [olym_Nofity removeObserver:self];
    }
    
    // 开启返回手势
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    } 
}

#pragma mark - private

-(void)olym_addSubviews{
    [self.view addSubview:self.chatListView];
    [self.view addSubview:self.inputPanel];
    [self.view addSubview:self.editView];

    WeakSelf(ws);
    [self.chatListView mas_makeConstraints:^(MASConstraintMaker *make) {
        StrongSelf(ss);
        if (@available(iOS 11, *)) {
            make.top.mas_equalTo(ss.view.safeAreaInsets.top);
        }else
        {
            make.top.equalTo(ss.view);
        }
        make.left.equalTo(ss.view);
        make.right.equalTo(ss.view);
        make.bottom.mas_equalTo(ss.inputPanel.mas_top);
    }];
    
//    YYFPSLabel *fpsLabel = [[YYFPSLabel alloc]init];
//    [self.view addSubview:fpsLabel];
}

-(void)olym_bindViewModel{
    
    @weakify(self);
    
    [[[[[olym_Nofity rac_addObserverForName:kXMPPNewMsgNotifaction object:nil] takeUntil:self.rac_willDeallocSignal] map:^id(NSNotification *value) {
        return value;
    }] distinctUntilChanged] subscribeNext:^(NSNotification *notification) {
        @strongify(self);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.chatListView doRefreshMessageList:notification delay:0.1];
        });
    }];

    
    [[[[[olym_Nofity rac_addObserverForName:kXMPPRefreshMsgListNotifaction object:nil] takeUntil:self.rac_willDeallocSignal] map:^id(NSNotification *value) {
        return value;
    }] distinctUntilChanged] subscribeNext:^(NSNotification *notification) {
        @strongify(self);
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self.chatListView doRefreshMessageList:notification delay:0];
        });
    }];
    
    
    [[olym_Nofity rac_addObserverForName:kDeleteUserSessionNotifaction object:nil] subscribeNext:^(NSNotification *notification){
        GJCFAsyncMainQueue(^(void){
        
            @strongify(self);
            //被删除了，弹出会话界面
            [self.navigationController popToRootViewControllerAnimated:YES];
        });
        
    }];
    [[olym_Nofity rac_addObserverForName:kChatListViewWillBeginDraggingNotification object:nil]subscribeNext:^(id  _Nullable x) {
       //键盘收起
        @strongify(self);
        GJCFAsyncMainQueue(^(void){
            if([self.inputPanel isInputTextFirstResponse] || self.inputPanel.currentActionType == GJGCChatInputBarActionTypeChooseEmoji  || self.inputPanel.currentActionType == GJGCChatInputBarActionTypeExpandPanel)
            {
                [self inputBarBecomeOriginalState];
            }
        });
        
    }];
    //修改群名称
    [[olym_Nofity rac_addObserverForName:kRefreshModifyGroupNameNotification object:nil]subscribeNext:^(NSNotification *notification) {
        @strongify(self);
        GJCFAsyncMainQueue(^(void){
            OLYMUserObject *user = [notification object];
            [self setStrNavTitle:user.userNickname];
        });
        
    }];
    
    
    //阅后即焚状态
    [[self.fireButton rac_signalForControlEvents:UIControlEventTouchUpInside]subscribeNext:^(__kindof UIControl * _Nullable x) {
        @strongify(self);
        self.fireButton.selected = !self.fireButton.selected;
        self.chatViewModel.isReadburn = !self.chatViewModel.isReadburn;
        //更改输入框的文字
        if (self.chatViewModel.isReadburn) {
            _inputPanel.inputBarTextViewPlaceHolder = _T(@"发送 阅后即焚");
        }else{
            _inputPanel.inputBarTextViewPlaceHolder = @"";
        }

    }];
    
    
    
    //群聊中，处理@事件
    self.inputPanel.inputTextChangedBlock = ^(GJGCChatInputPanel *panel, NSString *text){
        @strongify(self);
        [self handleTextInputChange:text];
    };
    [[self.chatViewModel.cellClickSubject takeUntil:self.rac_willDeallocSignal]subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        if ([self.inputPanel isInputTextFirstResponse]) {
            [self.inputPanel inputBarRegsionFirstResponse];
        }
        [self inputBarBecomeOriginalState];
    }];
    
    //转发
    [[self.chatViewModel.transpondClickSubject takeUntil:self.rac_willDeallocSignal]subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        NSIndexPath *indexPath = x;
        RecentlyChatListViewController *vc = [[RecentlyChatListViewController alloc]init];
        vc.messageObj = [self.chatViewModel.dataArray objectAtIndex:indexPath.row];
        OLYMBaseNavigationController *nav = [[OLYMBaseNavigationController alloc]initWithRootViewController:vc];
        [self presentViewController:nav animated:YES completion:nil];
    }];
    
    //长按头像
    [[self.chatViewModel.headerLongPressSubject takeUntil:self.rac_willDeallocSignal]subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        NSDictionary *messageObjDict = x;
        NSString *fromUserName = [messageObjDict objectForKey:kMESSAGE_FROM_NAME];
        NSString *fromUserId = [NSString stringWithFormat:@"%@",[messageObjDict objectForKey:kMESSAGE_FROM]];
        [self messageAddAppointWithUserNickname:fromUserName userId:fromUserId];
 
    }];
    //点击图片
    [[self.chatViewModel.imageShowSubject takeUntil:self.rac_willDeallocSignal]subscribeNext:^(NSDictionary *infoDict) {
        @strongify(self);
        //        @{@"filePath":filePath,@"isEncrypt":[NSNumber numberWithBool:contentModel.isAESEncrypt]}
        NSString *filePath = [infoDict objectForKey:@"filePath"];
        BOOL isEncrypt = [[infoDict objectForKey:@"isEncrypt"]boolValue];
        NSArray *images = [self.chatViewModel getAllMessageImages];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.filePath == %@",filePath];
        NSArray *filterArray = [images filteredArrayUsingPredicate:predicate];
        NSInteger index = NSNotFound;
        if (filterArray && filterArray.count > 0)
        {
            index = [images indexOfObject:[filterArray lastObject]];
        }
        if (index == NSNotFound)
        {
            GJCUImageBrowserModel *model = [[GJCUImageBrowserModel alloc]init];
            model.filePath = filePath;
            model.isAESEncrypt = isEncrypt;
            images = [NSArray arrayWithObject:model];
            index = 0;
        }
       
        GJCUImageBrowserViewController *imageBrowser = [[GJCUImageBrowserViewController alloc]initWithImageModels:images];
        imageBrowser.pageIndex = index;
        imageBrowser.isPresentModelState = YES;
        [self presentViewController:imageBrowser animated:YES completion:nil];
    }];
    //点击视频
    [[self.chatViewModel.videoShowSubject takeUntil:self.rac_willDeallocSignal]subscribeNext:^(NSDictionary*  infoDict) {
        @strongify(self);
        NSString *filePath = [infoDict objectForKey:@"filePath"];
        BOOL isEncrypt = [[infoDict objectForKey:@"isEncrypt"]boolValue];
        OLYMMoviePlayerViewController *player = [[OLYMMoviePlayerViewController alloc]init];
        player.filePath = filePath;
        player.isFileEncrypt = isEncrypt;
        OLYMBaseNavigationController *nav = [[OLYMBaseNavigationController alloc]initWithRootViewController:player];
        [self presentViewController:nav animated:YES completion:nil];
    }];
    
    //点击文件
    [[self.chatViewModel.fileShowSubject takeUntil:self.rac_willDeallocSignal]subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        NSDictionary *dict = x;
        NSString *filePath = [dict objectForKey:@"filePath"];
        NSInteger type = [[dict objectForKey:@"type"]integerValue];
        BOOL fileAESEncrypt = [[dict objectForKey:@"fileAESEncrypt"]boolValue];
        NSString *fileExtension = [[filePath componentsSeparatedByString:@"."]lastObject];
        if ([fileExtension isEqualToString:@"mp3"]||[fileExtension isEqualToString:@"mp4"]||[fileExtension isEqualToString:@"avi"])
        {
            OLYMMoviePlayerViewController *player = [[OLYMMoviePlayerViewController alloc]init];
            player.filePath = filePath;
            player.isFileEncrypt = fileAESEncrypt;
            OLYMBaseNavigationController *nav = [[OLYMBaseNavigationController alloc]initWithRootViewController:player];
            [self presentViewController:nav animated:YES completion:nil];
        }else
        {
            FileOpenVC *mFileOpenVC = [[FileOpenVC alloc]init];
            [mFileOpenVC setUrlPath:filePath];
            [mFileOpenVC setType:type];
            [mFileOpenVC setIsFileAESEncrypt:fileAESEncrypt];
            [self.navigationController pushViewController:mFileOpenVC animated:YES];
        }
    }];
    
    //文字语音阅后即焚
    [[self.chatViewModel.textBurnShowSubject takeUntil:self.rac_willDeallocSignal]subscribeNext:^(id  _Nullable contentModel) {
        @strongify(self);
        BurnAfterReadingViewController *vc = [[BurnAfterReadingViewController alloc]init];
        vc.msgObj = contentModel;
        vc.currentChatUser = self.currentChatUser;
        [self.navigationController pushViewController:vc animated:YES];
    }];
    //图片阅后即焚
    [[self.chatViewModel.imageBurnShowSubject takeUntil:self.rac_willDeallocSignal]subscribeNext:^(id  _Nullable contentModel) {
        @strongify(self);
        OLYMImageBrowserController *imageBrowser = [[OLYMImageBrowserController alloc]init];
        imageBrowser.msgObj = contentModel;
        [self presentViewController:imageBrowser animated:YES completion:nil];
    }];
    //视频阅后即焚
    [[self.chatViewModel.videoBurnShowSubject takeUntil:self.rac_willDeallocSignal]subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        NSDictionary *dict = x;
        NSString *filePath = [dict objectForKey:@"filePath"];
        id contentModel = [dict objectForKey:@"messageModel"];
        BOOL isEncrypt = [[dict objectForKey:@"isEncrypt"]boolValue];
        OLYMMoviePlayerViewController *player = [[OLYMMoviePlayerViewController alloc]init];
        player.filePath = filePath;
        player.isFileEncrypt = isEncrypt;
        OLYMBaseNavigationController *nav = [[OLYMBaseNavigationController alloc]initWithRootViewController:player];
        [self presentViewController:nav animated:YES completion:nil];
        player.oLYMMoviePlayerDidEnd  = ^{
            [self.chatViewModel notifyBurnVideoFinished:contentModel];
        };
        player.oLYMMoviePlayerDidDismiss = ^{
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.chatViewModel notifyBurnVideoFinished:contentModel];
            });
        };
    }];
    //点击名片
    [[self.chatViewModel.cardShowSubject takeUntil:self.rac_willDeallocSignal]subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        
        
        NSDictionary *dict = x;
        NSInteger status = [[dict objectForKey:@"status"]integerValue];
        OLYMUserObject *user = [dict objectForKey:@"user"];
        
#if ThirdlyVersion
        
        FriendInformationViewController *vc = [[FriendInformationViewController alloc]init];
        vc.userObj = user;
        [self.navigationController pushViewController:vc animated:YES];
#else
        
        if (status == 0)
        {
            //陌生人
            SearchFriendInfoViewController *vc = [[SearchFriendInfoViewController alloc]init];
            vc.userObj = user;
            [self.navigationController pushViewController:vc animated:YES];
        }else if (status == friend_status_friend || status == friend_status_colleague || status == friend_status_black)
        {
            //好友
            UserInfoViewController *vc = [[UserInfoViewController alloc]init];
            vc.userObject = user;
            if (self.currentChatUser.roomFlag == 0 && [self.currentChatUser.userId isEqualToString:user.userId])
            {
                vc.isCurrent = YES;
            }
            [self.navigationController pushViewController:vc animated:YES];
        }else
        {
            //待验证
            SearchFriendInfoViewController *vc = [[SearchFriendInfoViewController alloc]init];
            vc.userObj = user;
            [self.navigationController pushViewController:vc animated:YES];
        }
#endif

    }];
    
    //点击头像
    [[self.chatViewModel.getUserInfoSubject takeUntil:self.rac_willDeallocSignal]subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        NSDictionary *dict = x;
        NSInteger status = [[dict objectForKey:@"status"]integerValue];
        OLYMUserObject *user = [dict objectForKey:@"user"];
        
#if ThirdlyVersion
        
        if ([user.userId isEqualToString:olym_UserCenter.userId]) {
            
            PersonalDataViewController *vc = [[PersonalDataViewController alloc]init];
            [self.navigationController pushViewController:vc animated:YES];

            return;
        }
        
        FriendInformationViewController *vc = [[FriendInformationViewController alloc]init];
        vc.userObj = user;
        [self.navigationController pushViewController:vc animated:YES];
#else
        if (status == 0)
        {
            //陌生人
            SearchFriendInfoViewController *vc = [[SearchFriendInfoViewController alloc]init];
            vc.userObj = user;
            [self.navigationController pushViewController:vc animated:YES];
        }else if (status == friend_status_friend || status == friend_status_black)
        {
            //好友
            UserInfoViewController *vc = [[UserInfoViewController alloc]init];
            vc.userObject = user;
            if (self.currentChatUser.roomFlag == 0)
            {
                vc.isCurrent = YES;
            }
            [self.navigationController pushViewController:vc animated:YES];
        }else
        {
            //待验证
            SearchFriendInfoViewController *vc = [[SearchFriendInfoViewController alloc]init];
            vc.userObj = user;
            [self.navigationController pushViewController:vc animated:YES];
        }
#endif

    }];
    //点击链接
    [[self.chatViewModel.linkClickedSubject takeUntil:self.rac_willDeallocSignal]subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        OLYMWebViewController *webViewController = [[OLYMWebViewController alloc]initWithAddress:x];
        [self.navigationController pushViewController:webViewController animated:YES];
    }];
    
    //引用
    [[self.chatViewModel.referenceMsgSubject takeUntil:self.rac_willDeallocSignal]subscribeNext:^(NSString* content) {
        @strongify(self);
        [self.inputPanel.inputBar setInputTextViewContent:content];
        [self.inputPanel becomeFirstResponse];
    }];
    
    [[self.chatViewModel.mutiSelectMsgSubject takeUntil:self.rac_willDeallocSignal]subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        [self addRightEditItems];
        [self inputBarBecomeOriginalState];
        [self.chatListView.tableView setEditing:YES animated:YES];

        self.editView.hidden = NO;
    }];
    //编辑toolbar按钮状态改变
    [[self.chatViewModel.tablecellEditSubject takeUntil:self.rac_willDeallocSignal]subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        NSArray *indexPaths = [self.chatListView.tableView indexPathsForSelectedRows];
        if (indexPaths && indexPaths.count > 0)
        {
            [self.editView setEdit:YES];
        }else
        {
            [self.editView setEdit:NO];
        }
    }];
    //编辑状态回到普通状态
    [[self.editButton rac_signalForControlEvents:UIControlEventTouchUpInside]subscribeNext:^(__kindof UIControl * _Nullable x) {
        @strongify(self);

#if ThirdlyVersion
        
        [self addRightNormalItems];
#else
        
#endif
        [self.chatListView.tableView setEditing:NO animated:YES];
        self.editView.hidden = YES;
    }];
    
    //删除记录，更新用户的最后一条聊天
    [[self.chatViewModel.msgDeleteSubject takeUntil:self.rac_willDeallocSignal]subscribeNext:^(NSString * content) {
        @strongify(self);
        [self.currentChatUser setContent:content];
    }];



    //加密通需要监测截屏通知
#ifdef MESSAGETAKESCREENOFF
#elif JiaMiTong
    [self observeSendTakeScreen];
#endif

}

-(void)olym_layoutNavigation{
    
#if ThirdlyVersion
    
    if(self.currentChatUser.isGroup){
        [self setStrNavTitle:self.currentChatUser.userNickname];
    }else{
        [self setStrNavTitle:self.currentChatUser.userRemarkname? self.currentChatUser.userRemarkname : self.currentChatUser.userNickname];
    }
    if (self.chatListView.tableView.isEditing)
    {
        [self addRightEditItems];
    }else
    {
        [self addRightNormalItems];
    }
#else
    [self addRightNormalItems];
#endif
}

- (void)addRightNormalItems
{
#if ThirdlyVersion
    if(self.currentChatUser.isGroup){        
        [self setRightButtonWithStateImage:@"nav_chat_groupnfo_nor" stateHighlightedImage:@"nav_chat_groupnfo_pre" stateDisabledImage:nil titleName:nil];
    }else{
        
        [self setStrNavTitle:[self.currentChatUser getDisplayName]];
        [self setRightButtonWithStateImage:@"nav_chat_friendinfo_nor" stateHighlightedImage:@"nav_chat_friendinfo_pre" stateDisabledImage:nil titleName:nil];
    }
    
    if ([_currentChatUser.userId isEqualToString:olym_UserCenter.userId]) {
        
        self.fireButton.hidden = YES;
        [self setRightButtonWithStateImage:@"" stateHighlightedImage:@"" stateDisabledImage:nil titleName:nil];
    }
#else
    
    if(self.currentChatUser.isGroup){
        [self setStrNavTitle:self.currentChatUser.userNickname];
        
        [self setRightButtonWithStateImage:@"grouphead_nav_btn_nor" stateHighlightedImage:@"grouphead_nav_btn_pre" stateDisabledImage:nil titleName:nil];
    }else{

        [self setStrNavTitle:self.currentChatUser.userRemarkname? self.currentChatUser.userRemarkname : self.currentChatUser.userNickname];
        [self setRightButtonWithStateImage:@"head_nav_btn_nor" stateHighlightedImage:@"head_nav_btn_pre" stateDisabledImage:nil titleName:nil];
    }
#endif
    

#if XYT
    [self appendRightBarItemWithCustomButton:self.fireButton toOldLeft:YES];
#endif
    
#if MJTDEV
    [self appendRightBarItemWithCustomButton:self.fireButton toOldLeft:YES];
#endif
}

- (void)addRightEditItems
{
    UIBarButtonItem *rightButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.editButton];
    self.navigationItem.rightBarButtonItems = @[rightButtonItem];
}

-(void)rightButtonPressed:(UIButton *)sender{
    
    if ([self.currentChatUser.userId isEqualToString:olym_UserCenter.userId]) {
        
        //文件传输助手
        return;
    }
    
#if ThirdlyVersion
    
    if(self.currentChatUser.roomFlag == 1){
        GroupInfoViewController *groupInfoViewController = [[GroupInfoViewController alloc]init];
        [groupInfoViewController setUserObject:self.currentChatUser];
        [self.navigationController pushViewController:groupInfoViewController animated:YES];
    }else{
        
        FriendInformationViewController *vc = [[FriendInformationViewController alloc]init];
        vc.userObj = self.currentChatUser;
        [self.navigationController pushViewController:vc animated:YES];
    }

#else
    
    if(self.currentChatUser.roomFlag == 1){
        GroupInfoViewController *groupInfoViewController = [[GroupInfoViewController alloc]init];
        [groupInfoViewController setUserObject:self.currentChatUser];
        [self.navigationController pushViewController:groupInfoViewController animated:YES];
    }else{
        UserInfoViewController *userInfoViewController = [[UserInfoViewController alloc]init];
        if (self.currentChatUser.roomFlag == 0)
        {
            userInfoViewController.isCurrent = YES;
        }
        [userInfoViewController setUserObject:self.currentChatUser];
        [self.navigationController pushViewController:userInfoViewController animated:YES];
    }
#endif

}

#pragma mark - 输入动作变化

- (void)inputBar:(GJGCChatInputBar *)inputBar changeToAction:(GJGCChatInputBarActionType)actionType
{
    CGFloat originY = GJCFSystemNavigationBarHeight + GJCFSystemOriginYDelta + InputPanelBottomMargin;
    
    switch (actionType) {
        case GJGCChatInputBarActionTypeRecordAudio:
        {
            if (self.inputPanel.isFullState) {
                
                [UIView animateWithDuration:0.28 animations:^{
                    
                    self.inputPanel.gjcf_top = GJCFSystemScreenHeight - self.inputPanel.inputBarHeight - originY;
                    self.chatListView.tableView.gjcf_height = GJCFSystemScreenHeight - self.inputPanel.inputBarHeight - originY;
                    [self.chatListView layoutIfNeeded];
                }];
                
                [self.chatListView.tableView scrollRectToVisible:CGRectMake(0, self.chatListView.tableView.contentSize.height - self.chatListView.bounds.size.height, self.chatListView.gjcf_width, self.chatListView.gjcf_height) animated:NO];
            }
        }
            break;
        case GJGCChatInputBarActionTypeChooseEmoji:
        case GJGCChatInputBarActionTypeExpandPanel:
        {
            if (!self.inputPanel.isFullState) {
                
                [UIView animateWithDuration:0.28 animations:^{
                    self.inputPanel.gjcf_top = GJCFSystemScreenHeight - self.inputPanel.inputBarHeight - 216 - originY;
                    
                    self.chatListView.gjcf_height = GJCFSystemScreenHeight - self.inputPanel.inputBarHeight - 216 - originY;
                    [self.chatListView layoutIfNeeded];
                }];
                
                [self.chatListView.tableView scrollRectToVisible:CGRectMake(0, self.chatListView.tableView.contentSize.height - self.chatListView.bounds.size.height, self.chatListView.gjcf_width, self.chatListView.gjcf_height) animated:NO];
                
            }
        }
            break;
            
        default:
            break;
    }
}


- (void)inputBarBecomeOriginalState {
    
    WeakSelf(ws);
    if (self.inputPanel.currentActionType != GJGCChatInputBarActionTypeRecordAudio)
    {
        if ([self.inputPanel isInputTextFirstResponse]) {
            [self.inputPanel inputBarRegsionFirstResponse];
        }

        CGFloat originY = GJCFSystemNavigationBarHeight + GJCFSystemOriginYDelta + InputPanelBottomMargin;
        if (self.inputPanel.inputBarHeight > 50) {
            originY = GJCFSystemNavigationBarHeight + GJCFSystemOriginYDelta;
        }
        [UIView animateWithDuration:0.28 animations:^{
            
            self.inputPanel.gjcf_top = GJCFSystemScreenHeight - self.inputPanel.inputBarHeight - originY;
            
            self.chatListView.tableView.gjcf_height = GJCFSystemScreenHeight - self.inputPanel.inputBarHeight - originY;
            [self.chatListView layoutIfNeeded];
        }];
        
        //mrlyang 2017/09/21
        //因为下面代码会滚动到底部，导致listview向上滚动的时候，到达顶部 又重新回到底部
        //无法达到下拉刷新的目的
//        [self.chatListView.tableView scrollRectToVisible:CGRectMake(0, self.chatListView.tableView.contentSize.height - self.chatListView.bounds.size.height, self.chatListView.gjcf_width, self.chatListView.gjcf_height) animated:NO];
        
        [self.inputPanel reserveState];
    }
}

- (void)handleTextInputChange:(NSString *)text
{
    if (self.currentChatUser.roomFlag == 1)
    {
        //群聊才处理@事件，选择群聊好友
        if([text isEqualToString:@"@"])
        {
            WeakSelf(weakSelf);
            RemindViewController *reminderController = [[RemindViewController alloc]init];
            reminderController.currentChatUser = self.currentChatUser;
            OLYMBaseNavigationController *nav = [[OLYMBaseNavigationController alloc]initWithRootViewController:reminderController];
            [KeyWindow.rootViewController presentViewController:nav animated:YES completion:NULL];
            reminderController.remindChooseOneContact = ^(NSString *userName, NSString *userId) {
                [weakSelf messageAddAppointWithUserNickname:userName userId:userId];
            };
        }
    }
}


#pragma mark - GJGCChatInputPanelDelegate
#pragma mark - 聊天选项输入代理（如图片、视频等）
static BOOL extracted() {
    return GJCFAppCanAccessCamera;
}

- (void)chatInputPanel:(GJGCChatInputPanel *)panel didChooseMenuAction:(GJGCChatInputMenuPanelActionType)actionType
{
    switch (actionType) {
      
        case GJGCChatInputMenuPanelActionTypePhotoLibrary:
        {
            //发消息给系统，做特别处理
            if ([self.chatViewModel.currentChatUserId isEqualToString:@"10000"]) {
                [SVProgressHUD showInfoWithStatus:_T(@"系统暂时不能接受图片")];
                return;
            }
            if (!GJCFAppCanAccessPhotoLibrary) {

                [AlertViewManager alertWithTitle:[NSString stringWithFormat:_T(@"请在“设置-隐私-照片”选项中允许%@访问你的照片"),ProjectName]];
                return;
            }
            ZLPhotoActionSheet *actionSheet = [[ZLPhotoActionSheet alloc] init];
            actionSheet.sender = self;
            actionSheet.sortAscending = YES;
            actionSheet.allowSelectImage = YES;
            actionSheet.allowSelectGif = YES;
            actionSheet.allowSelectVideo = YES;
            actionSheet.allowSelectLivePhoto = NO;
            actionSheet.allowForceTouch = YES;
            actionSheet.allowEditImage = NO;
            actionSheet.allowEditVideo = NO;
            actionSheet.allowSlideSelect = YES;
            actionSheet.allowMixSelect = YES;
            //设置相册内部显示拍照按钮
            actionSheet.allowTakePhotoInLibrary = YES;
            //设置在内部拍照按钮上实时显示相机俘获画面
            actionSheet.showCaptureImageOnTakePhotoBtn = NO;
            //设置照片最大预览数
            actionSheet.maxPreviewCount = 10;
            //设置照片最大选择数
            actionSheet.maxSelectCount = 9;
            //设置允许选择的视频最大时长
            //单选模式是否显示选择按钮
            actionSheet.showSelectBtn = YES;
            //是否在选择图片后直接进入编辑界面
            actionSheet.editAfterSelectThumbnailImage = NO;
            //设置编辑比例
            //    actionSheet.clipRatios = @[GetClipRatio(4, 3)];
            //是否在已选择照片上显示遮罩层
            actionSheet.showSelectedMask = NO;
            zl_weakify(self);
            [actionSheet setSelectImageBlock:^(NSArray<UIImage *> * _Nonnull images, NSArray<PHAsset *> * _Nonnull assets, BOOL isOriginal) {
                zl_strongify(weakSelf);
                NSLog(@"image:%@", images);
                [self pickerViewDidSelectImages:images assets:assets];
            }];
            [actionSheet showPhotoLibrary];
        }
            break;
        case GJGCChatInputMenuPanelActionTypeCamera:
        {
            //发消息给系统，做特别处理
            if ([self.chatViewModel.currentChatUserId isEqualToString:@"10000"]) {
                [SVProgressHUD showInfoWithStatus:_T(@"系统暂时不能接受图片")];
                return;
            }
            if (!GJCFCameraIsAvailable) {
                NSLog(@"照相机不支持");
                return;
            }
            if (!GJCFAppCanAccessCamera) {
                [AlertViewManager alertWithTitle:[NSString stringWithFormat:_T(@"请在“设置-隐私-相机”选项中允许%@访问你的相机"),ProjectName]];
               
                return;
            }
            [self pickPhoto];
        }
            break;
        //拍摄短视频
        case GJGCChatInputMenuPanelActionTypeLimitVideo:
        {
            if ([self.chatViewModel.currentChatUserId isEqualToString:@"10000"]) {
                [SVProgressHUD showInfoWithStatus:_T(@"系统暂时不能接受视频")];
                return;
            }
            if (!GJCFCameraIsAvailable) {
                NSLog(@"照相机不支持");
                return;
            }
            if (!GJCFAppCanAccessCamera) {
                [AlertViewManager alertWithTitle:[NSString stringWithFormat:_T(@"请在“设置-隐私-相机”选项中允许%@访问你的相机"),ProjectName]];
                return;
            }
            if (!GJCFAppCanAccessMic) {

                [AlertViewManager alertWithTitle:[NSString stringWithFormat:_T(@"请在“设置-隐私-麦克风”选项中允许%@访问你的麦克风"),ProjectName]];
                return;
            }
            KZVideoViewController *videoVC = [[KZVideoViewController alloc] init];
            videoVC.delegate = self;
            videoVC.savePhotoAlbum = NO;
            [videoVC startAnimationWithType:KZVideoViewShowTypeSingle];

        }
            break;
        //测试发文件
        case GJGCChatInputMenuPanelActionTypeFile:
        {
            if(self.chatViewModel.isReadburn){
                
                [AlertViewManager alertWithTitle:_T(@"阅后即焚不支持文件发送")];
                
                return;
            }
            //发消息给系统，做特别处理
            if ([self.chatViewModel.currentChatUserId isEqualToString:@"10000"]) {
                
                [SVProgressHUD showInfoWithStatus:_T(@"系统暂时不能接受文件")];
                return;
            }
#if MJTDEV
            ChatFile2ViewController *vc = [[ChatFile2ViewController alloc]init];
#else
            ChatFileViewController *vc = [[ChatFileViewController alloc]init];
#endif
            OLYMBaseNavigationController *nav = [[OLYMBaseNavigationController alloc]initWithRootViewController:vc];
            vc.currentChatUser = self.currentChatUser;
            vc.operationFileType = PickFileToSend;
            WeakSelf(ws);
            vc.pickFilePathBlock = ^(NSString *pickFilePath,NSString *pickFileName,float fileSize,NSString *thumbnail,BOOL isAESEncrypt) {
                StrongSelf(ss);
                if (pickFilePath == nil) {
                    
                    return ;
                }
                pickFilePath = [[olym_FileCenter documentPrefix]stringByAppendingPathComponent:pickFilePath];
                NSString *lastPath = [pickFilePath lastPathComponent];
                NSString *extension = [lastPath pathExtension];
                if ([extension isEqualToString:@"mp4"])
                {
                    //发送视频
                    if(![[NSFileManager defaultManager] fileExistsAtPath:pickFilePath] ){
                        return;
                    }
                    NSString *fileName = lastPath;
                    NSString *toPath = [NSString stringWithFormat:@"%@/%ld%@",[olym_FileCenter getMyFileLocalPath:self.currentChatUser.userId],(long)[[NSDate date]timeIntervalSince1970],fileName];
                    if(isAESEncrypt)
                    {
                        [FileCenter copyFileAtPath:pickFilePath toPath:toPath];
                    }else
                    {
                        //文件进行AES加密
                        [OLYMAESCrypt encryptFileData:[NSData dataWithContentsOfFile:pickFilePath] saveFilePath:toPath];
                    }

                    [ss.chatViewModel sendVideoMessage:toPath fileSize:fileSize thumbnailString:thumbnail];
                    
                }else if ([extension isEqualToString:@"jpg"] || [extension isEqualToString:@"JPG"] || [extension isEqualToString:@"png"] || [extension isEqualToString:@"PNG"] || [extension isEqualToString:@"gif"] || [extension isEqualToString:@"GIF"])
                {
                    NSString *filePath = [olym_FileCenter getMyImagePath:self.currentChatUser.userId];
                    UIImage *image;
                    if(isAESEncrypt)
                    {
                        [FileCenter copyFileAtPath:pickFilePath toPath:filePath];
                        NSData  *data = [OLYMAESCrypt decryptFile:pickFilePath];
                        UIImage *image = [UIImage imageWithData:data];
                    }else
                    {
                        //文件进行AES加密
                        NSData  *data = [NSData dataWithContentsOfFile:pickFilePath];
                        UIImage *image = [UIImage imageWithData:data];
                        [OLYMAESCrypt encryptFileData:data saveFilePath:filePath];
                    }
                    [self.chatViewModel sendImageMessage:filePath imageWidth:image.size.width imageHeight:image.size.height thumbnailString:thumbnail];
                }else
                {
                    NSString *fileName = lastPath;
                    NSString *toPath = [NSString stringWithFormat:@"%@/%ld%@",[olym_FileCenter getMyFileLocalPath:self.currentChatUser.userId],(long)[[NSDate date]timeIntervalSince1970],fileName];
                    if(isAESEncrypt)
                    {
                        [FileCenter copyFileAtPath:pickFilePath toPath:toPath];
                    }else
                    {
                        //文件进行AES加密
                        [OLYMAESCrypt encryptFileData:[NSData dataWithContentsOfFile:pickFilePath] saveFilePath:toPath];
                    }
                    [ss.chatViewModel sendFileMessage:toPath fileSize:fileSize fileName:pickFileName];
                }
            };
            [self presentViewController:nav animated:YES completion:nil];
        }
            break;
        //测试发阅后即焚
        case GJGCChatInputMenuPanelActionTypeBurnAfterReading:
        {
            self.chatViewModel.isReadburn = !self.chatViewModel.isReadburn;
            //改变图标 文字
            
            for (UIView *view in _inputPanel.menuPanel.contentScrollView.subviews) {
                
                if ([view isKindOfClass:[GJGCChatInputExpandMenuPanelItem class]]) {
                    
                    GJGCChatInputExpandMenuPanelItem *item = (GJGCChatInputExpandMenuPanelItem *)view;
                    
                    if (item.actionType == GJGCChatInputMenuPanelActionTypeBurnAfterReading && self.chatViewModel.isReadburn) {
                        
                        
                        [item.iconButton setBackgroundImage:[UIImage imageNamed:@"burn_close_nor"] forState:UIControlStateNormal];
                        [item.iconButton setBackgroundImage:[UIImage imageNamed:@"burn_close_pre"] forState:UIControlStateHighlighted];
                        item.titleLabel.text = _T(@"取消");
                    }else if(item.actionType == GJGCChatInputMenuPanelActionTypeBurnAfterReading && !self.chatViewModel.isReadburn){
                        
                        [item.iconButton setBackgroundImage:[UIImage imageNamed:@"burn_open_nor"] forState:UIControlStateNormal];
                        [item.iconButton setBackgroundImage:[UIImage imageNamed:@"burn_open_pre"] forState:UIControlStateHighlighted];

                        item.titleLabel.text = _T(@"阅后即焚");
                    }
                }
                
            }
            
            //更改输入框的文字
            if (self.chatViewModel.isReadburn) {
                _inputPanel.inputBarTextViewPlaceHolder = _T(@"发送 阅后即焚");
            }else{
                _inputPanel.inputBarTextViewPlaceHolder = @"";
            }
        }
            break;
        //测试发名片
        case GJGCChatInputMenuPanelActionTypeCard:
        {
            if(self.chatViewModel.isReadburn){
                
                [AlertViewManager alertWithTitle:_T(@"阅后即焚不支持名片发送")];
                
                return;
            }
            //发消息给系统，做特别处理
            if ([self.chatViewModel.currentChatUserId isEqualToString:@"10000"]) {
                
                [SVProgressHUD showInfoWithStatus:_T(@"系统暂时不能接受名片")];
                return;
            }

            ChatCardViewController *controller = [[ChatCardViewController alloc]init];
            OLYMBaseNavigationController *nav = [[OLYMBaseNavigationController alloc]initWithRootViewController:controller];
            
            controller.currentChatUser = self.currentChatUser;
            controller.chatCardType = ChatCardToChatPerson;
            [self presentViewController:nav animated:YES completion:nil];
        }
            break;
        //电话
        case GJGCChatInputMenuPanelActionTypeVoice:
        {
            
            //发消息给系统，做特别处理
            if ([self.chatViewModel.currentChatUserId isEqualToString:@"10000"]) {
                
                [SVProgressHUD showInfoWithStatus:_T(@"系统暂时不能接受打电话")];
                return;
            }
            if(self.currentChatUser.roomFlag == 1)
            {

                [AlertViewManager alertWithTitle:_T(@"群聊暂不支持通话功能")];
                return;
            }
            if (!self.currentChatUser.telephone) {
                [AlertViewManager alertWithTitle:_T(@"暂时无法接通")];
                return;
            }
            NSString *domain = self.currentChatUser.domain;
            //通话,内部判断是否跨域
            [olym_Sip dialNumber:self.currentChatUser.telephone domain:domain];

        }
            break;
        default:
            break;
    }
}


// 拍照
- (void)pickPhoto {
    
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        
        [AlertViewManager alertWithTitle:_T(@"本设备不支持相机")];
        
        return;
    }
    UIImagePickerController *imgPicker = [[UIImagePickerController alloc]init];
    [imgPicker setSourceType:UIImagePickerControllerSourceTypeCamera];
    [imgPicker setDelegate:self];
    [imgPicker setAllowsEditing:NO];
    [self presentViewController:imgPicker animated:YES completion:^{}];
    
}

#pragma mark - 添加@联系人
- (void)messageAddAppointWithUserNickname:(NSString *)userNickname userId:(NSString *)userId
{
    NSString *previousStr = self.inputPanel.inputBarTextViewContent;
    if(!previousStr)
    {
        previousStr = @"";
    }
    NSString *inputString = [NSString stringWithFormat:@"%@@%@ ", previousStr, userNickname];
    self.inputPanel.inputBarTextViewContent = inputString;
    NSDictionary *dictionary = [NSDictionary dictionaryWithObject:userId forKey:[NSString stringWithFormat:@"@%@ ", userNickname]];
    if (![self.chatViewModel.reminderArray containsObject:dictionary]) {
        [self.chatViewModel.reminderArray addObject:dictionary];
    }
    [_inputPanel becomeFirstResponse];
}

#pragma mark - 发送文字消息
- (void)chatInputPanel:(GJGCChatInputPanel *)panel sendTextMessage:(NSString *)text{
    
    if (!olym_Securityengine.getIbcParameterFileSucceed) {
        
        //提示用户是否需要跨域，
        [AlertViewManager alertWithTitle:NSLocalizedString(_T(@"提示"), nil)
                                 message:NSLocalizedString(_T(@"ibc参数文件未下载，是否下载支持跨域服务"), nil)
                         textFieldNumber:0
                            actionNumber:2
                            actionTitles:@[NSLocalizedString(_T(@"取消"), nil),NSLocalizedString(_T(@"确定"), nil)]
                        textFieldHandler:nil
                           actionHandler:^(UIAlertAction *action, NSUInteger index) {
                               
                               switch (index) {
                                   case 0:
                                       
                                       //不下载
                                       [self.chatViewModel sendTextMessage:text];
                                       break;
                                   case 1:
                                       
                                       [SVProgressHUD show];
                                       //下载ibc
                                       
                                       [olym_Securityengine getIbcParameterFile:^(int ret) {
                                           dispatch_async(dispatch_get_main_queue(), ^{
                                               
                                               [SVProgressHUD dismiss];
                                           });
                                       }];
                                       [self.chatViewModel sendTextMessage:text];
                                       break;
                                       
                               }
                           }];
    }else{
        
        //已下载ibc参数文件
        [self.chatViewModel sendTextMessage:text];
    }

}

#pragma mark - 发送图片消息
- (void)sendImages:(NSArray *)images
{
    for (NSDictionary *imageInfo in images) {
        [self.chatViewModel sendImageMessage:[imageInfo objectForKey:@"path"] imageWidth:[[imageInfo objectForKey:@"width"] floatValue] imageHeight:[[imageInfo objectForKey:@"height"] floatValue] thumbnailString:[imageInfo objectForKey:@"thumbnail"]];
    }
}

- (void)sendImage:(NSDictionary *)imageInfo
{
    [self.chatViewModel sendImageMessage:[imageInfo objectForKey:@"path"] imageWidth:[[imageInfo objectForKey:@"width"] floatValue] imageHeight:[[imageInfo objectForKey:@"height"] floatValue] thumbnailString:[imageInfo objectForKey:@"thumbnail"]];
}

- (void)sendVideoFromAlbum:(AVAsset *)asset thumbnail:(UIImage *)thumnail completionHandler:(void (^)(void))handler;
{
    NSString *savePath = [FileCenter getMyVideoPath:self.currentChatUser.userId];
    NSDictionary *opts = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO]
                                                     forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    AVAssetExportSession *session = [[AVAssetExportSession alloc]initWithAsset:asset presetName:AVAssetExportPresetHighestQuality];
    session.outputFileType = AVFileTypeMPEG4;
    session.shouldOptimizeForNetworkUse = YES;
    session.outputURL = [NSURL fileURLWithPath:savePath];
    [session exportAsynchronouslyWithCompletionHandler:^{
        switch (session.status)
        {
            case AVAssetExportSessionStatusCompleted:
            {
                NSString *thumPath = [NSString stringWithFormat:@"%@.jpg",[savePath stringByDeletingPathExtension]];
                
                NSData *imageData = UIImageJPEGRepresentation(thumnail, 0.8);
                NSString *base64Encoding = [thumnail base64StringFromImage:1024];

                //FIXME:将图片AES加密后,存储 2017-11-27 Donny
                //01 先保存缩略图
                BOOL saveOriginResult = [OLYMAESCrypt encryptFileData:imageData saveFilePath:thumPath];
                //02 再加密视频
                unsigned long long fileSize = [FileCenter fileSize:savePath];
                NSData *videoData = [NSData dataWithContentsOfFile:savePath];
                [FileCenter deleteFile:savePath]; //删除原来的
                saveOriginResult = [OLYMAESCrypt encryptFileData:videoData saveFilePath:savePath];
                
                [self.chatViewModel sendVideoMessage:savePath fileSize:fileSize thumbnailString:base64Encoding];
            }
                break;
                
            default:
                break;
        }
        if (handler) {
            handler();
        }
    }];
    //
}


#pragma mark - send Audio
- (void)chatInputPanel:(GJGCChatInputPanel *)panel didFinishRecord:(GJCFAudioModel *)audioFile
{
    //发消息给系统，做特别处理
    if ([_currentChatUser.userId isEqualToString:@"10000"]) {
        
        [SVProgressHUD showInfoWithStatus:@"系统暂时不能接受语音消息"];
        [SVProgressHUD dismissWithDelay:1.0f];
        return;
    }
    
    //WAV转amr
    NSData *audioData = [VoiceConverter  wavDataToAmr:[NSData dataWithContentsOfFile:audioFile.localStorePath]];
    
    //删除文件
    [FileCenter deleteFile:audioFile.localStorePath];

    NSString *base64Encoded = [audioData base64EncodedStringWithOptions:0];
    [self.chatViewModel sendAudioMessage:base64Encoded duration:audioFile.duration];
}

#pragma mark - 发送截屏消息
- (void)observeSendTakeScreen
{
    @weakify(self);
    [[[[[olym_Nofity rac_addObserverForName:UIApplicationUserDidTakeScreenshotNotification object:nil] takeUntil:self.rac_willDeallocSignal] map:^id(NSNotification *value) {
        return value;
    }] distinctUntilChanged] subscribeNext:^(NSNotification *notification) {
        @strongify(self);
        [self.chatViewModel sendTakeScreenshotMessage];
    }];
    
}

#pragma mark -  删除/转发
- (void)deleteSelectedMessages
{
    NSArray *indexPathsForSelectedRows = [self.chatListView.tableView indexPathsForSelectedRows];
    [self.chatViewModel deleteSelectedMessages:indexPathsForSelectedRows];
    [self.chatListView.tableView reloadData];
}

- (void)forwardSelectedMessages
{
    NSArray *indexPathsForSelectedRows = [self.chatListView.tableView indexPathsForSelectedRows];
    NSArray * messagesForSelectedRows = [self.chatViewModel messagesForSelectedRows:indexPathsForSelectedRows];

    RecentlyChatListViewController *controller = [[RecentlyChatListViewController alloc]init];
    if (messagesForSelectedRows.count == 1)
    {
        controller.messageObj = [messagesForSelectedRows firstObject];
    }else
    {
        controller.forwardMessages = messagesForSelectedRows;
    }
    [self.navigationController pushViewController:controller animated:YES];
}

#pragma mark - UIImagePickerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *originImage = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
    
    int width = originImage.size.width;
    int height = originImage.size.height;
    
    if (width > 1200 || height > 1200) {
        
        CGFloat max = width > height ? width : height;
        originImage = [originImage fixOrietationWithScale:1200/max];
        
    }else{
        originImage = [originImage fixOrietationWithScale:1.0];
    }
    
    width = originImage.size.width;
    height = originImage.size.height;
    
    NSString *base64Thumb = [originImage base64StringFromImage:1024];
    NSString *filePath = [self createOriginImageToDocumentDiretory:originImage];
    
    NSDictionary *originImageInfo = @{@"width":@(width),@"height":@(height),@"path":filePath,@"thumbnail":base64Thumb};
    NSMutableArray *images = [NSMutableArray array];
    [images addObject:originImageInfo];
    
    [self sendImages:images];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self removeCropingImageOnView];
        
        [self dismissViewControllerAnimated:YES completion:nil];
        
    });

}

#pragma mark - GJCFAssetsPickerDelegate
- (void)pickerViewDidSelectImages:(NSArray *)images assets:(NSArray<PHAsset *> * _Nonnull) assets{
    [self showCropingImageOnView];
    dispatch_group_t group = dispatch_group_create();
    

    for (NSInteger i = 0; i < assets.count; i++)
    {
        dispatch_group_enter(group);
        
        
        PHAsset *asset = [assets objectAtIndex:i];
        if (asset.mediaType == PHAssetMediaTypeImage)
        {
            UIImage *originImage = [images objectAtIndex:i];
            int width = asset.pixelWidth;
            int height = asset.pixelHeight;
            /*
            if (width > 1200 || height > 1200) {
                
                CGFloat max = width > height ? width : height;
                if (![[asset valueForKey:@"filename"] hasSuffix:@"GIF"])
                {
                    originImage = [originImage fixOrietationWithScale:1200/max];
                }
                
            }else{
                if (![[asset valueForKey:@"filename"] hasSuffix:@"GIF"])
                {
                    originImage = [originImage fixOrietationWithScale:1.0];
                }
            }*/
            
            width = originImage.size.width;
            height = originImage.size.height;
            
            NSString *filePath;
            if ([[asset valueForKey:@"filename"] hasSuffix:@"GIF"])
            {
                PHImageRequestOptions *option = [[PHImageRequestOptions alloc]init];
                option.resizeMode = PHImageRequestOptionsResizeModeFast;
                option.synchronous = YES;
                
                __block NSData *imgData = nil;
                [[PHImageManager defaultManager] requestImageDataForAsset:asset options:option resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
                    imgData = imageData;
                 }];
                NSString *fileName = [NSString stringWithFormat:@"local_file_%@.gif",GJCFStringCurrentTimeStamp];
                NSString *fileParentPath = [olym_FileCenter getMyFileLocalPath:self.currentChatUser.userId];
                filePath = [NSString stringWithFormat:@"%@/%@",fileParentPath,fileName];
                //FIXME:将图片AES加密后,存储 2017-11-27 Donny
                BOOL saveOriginResult = [OLYMAESCrypt encryptFileData:imgData saveFilePath:filePath];;
                
            }else
            {
                filePath = [self createOriginImageToDocumentDiretory:originImage];

            }
            NSString *base64Thumb = [originImage base64StringFromImage:1024];
            NSDictionary *originImageInfo = @{@"width":@(width),@"height":@(height),@"path":filePath,@"thumbnail":base64Thumb};
            
            [self sendImage:originImageInfo];

            dispatch_group_leave(group);
        }else if (asset.mediaType == PHAssetMediaTypeVideo)
        {
            UIImage *thumbnail = [images objectAtIndex:i];
            PHVideoRequestOptions *options1 = [[PHVideoRequestOptions alloc] init];
            options1.version = PHVideoRequestOptionsVersionCurrent;
            options1.deliveryMode = PHVideoRequestOptionsDeliveryModeAutomatic;
            
            PHImageManager *manager = [PHImageManager defaultManager];
            [manager requestAVAssetForVideo:asset options:nil resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
                
                [self sendVideoFromAlbum:asset thumbnail:thumbnail completionHandler:^{
                    dispatch_group_leave(group);
                }];
                
            }];
        }
    }
    
    dispatch_notify(group, dispatch_get_main_queue(), ^{
        [self removeCropingImageOnView];
    });
}


- (void)dismissAssetPicker
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self removeCropingImageOnView];
        
        [self dismissViewControllerAnimated:YES completion:nil];
        
    });
}

#pragma mark - Video RecordDelegate
#pragma mark - Record video finish
- (void)videoViewController:(KZVideoViewController *)videoController didRecordVideo:(KZVideoModel *)videoModel
{
    NSString *savePath = [FileCenter getMyVideoPath:self.currentChatUser.userId];
    
    //FIXME:将图片AES加密后,存储 2017-11-27 Donny
    //01 读取缩略图
    UIImage *thubnailImage = [UIImage imageWithContentsOfFile:videoModel.thumAbsolutePath];
    NSString *base64Encoding = [thubnailImage base64StringFromImage:1024];
    //02 先删除缩略图
    [FileCenter deleteFile:videoModel.thumAbsolutePath];
    //03 再加密视频
    unsigned long long fileSize = [FileCenter fileSize:videoModel.videoAbsolutePath];
    NSData *videoData = [NSData dataWithContentsOfFile:videoModel.videoAbsolutePath];
    [FileCenter deleteFile:videoModel.videoAbsolutePath]; //删除原来的
    BOOL saveOriginResult = [OLYMAESCrypt encryptFileData:videoData saveFilePath:savePath];
    
    [self.chatViewModel sendVideoMessage:savePath fileSize:fileSize thumbnailString:base64Encoding];
    [self dismissViewControllerAnimated:YES completion:nil];

}

#pragma mark - 图片处理UI方法

#define GJGCInputViewToastLabelTag 3344556611

- (void)showCropingImageOnView
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [SVProgressHUD showWithStatus:_T(@"正在处理中...")];
    });
}

- (void)removeCropingImageOnView
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [SVProgressHUD dismiss];
    });
}
- (NSString *)createOriginImageToDocumentDiretory:(UIImage *)originImage
{
    NSString *filePath = [olym_FileCenter getMyImagePath:self.currentChatUser.userId];
    
    NSData *imageData = UIImageJPEGRepresentation(originImage, 0.8);
    
    //FIXME:将图片AES加密后,存储 2017-11-27 Donny
    BOOL saveOriginResult = [OLYMAESCrypt encryptFileData:imageData saveFilePath:filePath];;
    
    NSLog(@"saveOriginResult:%d",saveOriginResult);
    
    return filePath;
}

#pragma mark 《$ ---------------- Setter/Getter ---------------- $》
-(void)setCurrentChatUser:(OLYMUserObject *)currentChatUser{
    
    _currentChatUser = currentChatUser;
    if (_currentChatUser.roomFlag) {
        
        self.inputPanel;
    }
    
    if ([_currentChatUser.userId isEqualToString:olym_UserCenter.userId]) {
        
        //文件助手
        _currentChatUser.userId = olym_UserCenter.userId;
    }
}

-(ChatViewModel *)chatViewModel{
    if(!_chatViewModel){
        if (self.searchMessaegObject)
        {
            _chatViewModel = [[ChatViewModel alloc] initWithUser:self.currentChatUser searchMessage:self.searchMessaegObject];
        }else
        {
            _chatViewModel = [[ChatViewModel alloc] initWithUser:self.currentChatUser];
        }
    }
    return _chatViewModel;
}

- (ChatListView *)chatListView {
    
    if (!_chatListView) {
        _chatListView = [[ChatListView alloc] initWithViewModel:self.chatViewModel];
    }
    return _chatListView;
}

- (GJGCChatInputPanel *)inputPanel {
    
    if (!_inputPanel) {
        
        _inputPanel = [[GJGCChatInputPanel alloc]initWithPanelDelegate:self];
        CGFloat originY = GJCFSystemNavigationBarHeight + GJCFSystemOriginYDelta + InputPanelBottomMargin;
        self.inputPanel.frame = (CGRect){0,GJCFSystemScreenHeight-self.inputPanel.inputBarHeight-originY,GJCFSystemScreenWidth,self.inputPanel.inputBarHeight+216+InputPanelBottomMargin};
        
        
        
        if (self.currentChatUser.roomFlag || [self.currentChatUser.userId isEqualToString:olym_UserCenter.userId]) {
            
            //群聊中电话按钮隐藏
            for (GJGCChatInputExpandMenuPanelItem *item in _inputPanel.menuPanel.contentScrollView.subviews) {
                
                if ([item.titleLabel.text isEqualToString:@"电话"]){
                    
                    [item removeFromSuperview];
                }
            }
            
        }
        
        _inputPanel.delegate = self;
        
        WeakSelf(weakSelf);
#if ThirdlyVersion
        _inputPanel.inputBarTextViewContent = self.currentChatUser.draftContent;
#endif
        [_inputPanel configInputPanelKeyboardFrameChange:^(GJGCChatInputPanel *panel,CGRect keyboardBeginFrame, CGRect keyboardEndFrame, NSTimeInterval duration,BOOL isPanelReserve) {
            
            /* 不要影响其他不带输入面板的系统视图对话 */
            if (panel.hidden) {
                return ;
            }
            CGFloat originY1 = originY - InputPanelBottomMargin;
            [UIView animateWithDuration:duration animations:^{
                
                weakSelf.chatListView.gjcf_height = GJCFSystemScreenHeight - weakSelf.inputPanel.inputBarHeight - originY1 - keyboardEndFrame.size.height;
                
                if (keyboardEndFrame.origin.y == GJCFSystemScreenHeight) {
                    
                    if (isPanelReserve) {
                        
                        weakSelf.inputPanel.gjcf_top = GJCFSystemScreenHeight - weakSelf.inputPanel.inputBarHeight  - originY;
                        
                        weakSelf.chatListView.gjcf_height = GJCFSystemScreenHeight - weakSelf.inputPanel.inputBarHeight - originY;
                        
                    }else{
                        
                        weakSelf.inputPanel.gjcf_top = GJCFSystemScreenHeight - 216 - weakSelf.inputPanel.inputBarHeight - originY;
                        
                        weakSelf.chatListView.gjcf_height = GJCFSystemScreenHeight - weakSelf.inputPanel.inputBarHeight - originY - 216;
                        
                    }
                    
                }else{
                    
                    weakSelf.inputPanel.gjcf_top = weakSelf.chatListView.gjcf_bottom;
                    if (IS_IPHONE_X) {
                        if (weakSelf.inputPanel.inputBarHeight > 50) {
                            weakSelf.inputPanel.gjcf_top = weakSelf.chatListView.gjcf_bottom + InputPanelBottomMargin;
                        }
                    }
                    
                }
                [weakSelf.chatListView layoutIfNeeded];
            }];
            
            [weakSelf.chatListView.tableView scrollRectToVisible:CGRectMake(0, weakSelf.chatListView.tableView.contentSize.height - weakSelf.chatListView.bounds.size.height, weakSelf.chatListView.gjcf_width, weakSelf.chatListView.gjcf_height) animated:NO];

        }];
        
        [_inputPanel configInputPanelRecordStateChange:^(GJGCChatInputPanel *panel, BOOL isRecording) {
//
            if (isRecording) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    //                    [weakSelf stopPlayCurrentAudio];
                    
                    weakSelf.chatListView.userInteractionEnabled = NO;
                    
                });
                
            }else{
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    weakSelf.chatListView.userInteractionEnabled = YES;
                    
                });
            }
            
        }];
        
        [_inputPanel configInputPanelInputTextViewHeightChangedBlock:^(GJGCChatInputPanel *panel, CGFloat changeDelta) {


            panel.gjcf_top = panel.gjcf_top - changeDelta;
            
            panel.gjcf_height = panel.gjcf_height + changeDelta;
            
            [UIView animateWithDuration:0.2 animations:^{
                
                weakSelf.chatListView.gjcf_height = weakSelf.chatListView.gjcf_height - changeDelta;
                [weakSelf.chatListView layoutIfNeeded];
                
                [weakSelf.chatListView.tableView scrollRectToVisible:CGRectMake(0, weakSelf.chatListView.tableView.contentSize.height - weakSelf.chatListView.bounds.size.height, weakSelf.chatListView.gjcf_width, weakSelf.chatListView.gjcf_height) animated:NO];
                
            }];
            
        }];
        
        /* 动作变化 */
        [_inputPanel setActionChangeBlock:^(GJGCChatInputBar *inputBar, GJGCChatInputBarActionType toActionType) {

            [weakSelf inputBar:inputBar changeToAction:toActionType];
        }];
    }
    return _inputPanel;
}

- (UIButton *)fireButton
{
    if (!_fireButton)
    {
        _fireButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _fireButton.frame = CGRectMake(0, 0, 35, 35);
        [_fireButton setImage:[UIImage imageNamed:@"chat_burn_nor"] forState:UIControlStateNormal];
        [_fireButton setImage:[UIImage imageNamed:@"chat_burn_pre"] forState:UIControlStateSelected];
    }
    return _fireButton;
}

- (UIButton *)editButton
{
    if (!_editButton)
    {
        _editButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _editButton.frame = CGRectMake(0, 0, 50, 35);
        [_editButton setTitle:@"取消" forState:UIControlStateNormal];
        [_editButton setTitleColor:Global_Theme_Color forState:UIControlStateNormal];
    }
    return _editButton;
}

- (TableEditView *)editView
{
    if (!_editView)
    {
        CGFloat originY = GJCFSystemNavigationBarHeight + GJCFSystemOriginYDelta + InputPanelBottomMargin;
        _editView = [[TableEditView alloc]initWithFrame:(CGRect){0,GJCFSystemScreenHeight-self.inputPanel.inputBarHeight-originY,GJCFSystemScreenWidth,self.inputPanel.inputBarHeight+216+InputPanelBottomMargin} editType:(TableEditType)(TableEditDeleteType | TableEditForwardType)];
        _editView.hidden = YES;
        WeakSelf(weakSelf)
        _editView.editViewButtonClick = ^(TableEditType type) {
            if (type == TableEditDeleteType)
            {
                [AlertViewManager actionSheettWithTitle:nil
                 message:nil
                 actionNumber:2
                 actionTitles:@[@"删除",@"取消"]
                                          actionHandler:^(UIAlertAction *action, NSUInteger index) {
                                              if (index == 0)
                                              {
                                                  [weakSelf deleteSelectedMessages];
                                              }
                                          }];
            }else if (type == TableEditForwardType)
            {
                [weakSelf forwardSelectedMessages];
            }
        };
    }
    return _editView;
}

@end
