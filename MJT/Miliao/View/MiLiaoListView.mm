//
//  MiLiaoListView.m
//  MJT_APP
//
//  Created by olymtech on 2017/8/28.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "MiLiaoListView.h"
#import "MiLiaoViewModel.h"
#import "OLYMUserObject.h"
#import "MessageSessionCell.h"
#import "OLYMMessageObject.h"
#import "TimeUtil.h"
#import "AlertViewManager.h"
#import "UIScrollView+EmptyDataSet.h"
#import "UISearchBar+LeftPlaceholder.h"

@interface MiLiaoListView ()<DZNEmptyDataSetSource,DZNEmptyDataSetDelegate>

@property (nonatomic, strong) UISearchBar *mSearchBar;

@property(strong,nonatomic) MiLiaoViewModel *miliaoViewModel;

@property(strong,nonatomic) OLYMUserObject *currentChatUser;

// 上一次通知响铃时间
@property (nonatomic, strong) NSDate *lastNoticeDate;

@end

@implementation MiLiaoListView

- (instancetype)initWithViewModel:(id<OLYMViewModelProtocol>)viewModel {
    self.miliaoViewModel = (MiLiaoViewModel *)viewModel;
    return [super initWithViewModel:viewModel];
}

- (void)updateConstraints {
    
    WeakSelf(weakSelf);
    
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(weakSelf);
    }];
    
    [super updateConstraints];
}

#pragma mark - private
- (void)olym_setupViews {
    
    [self addSubview:self.tableView];
#if MJTDEV
    [self _createTableHeaderView];
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
#endif
    [self setNeedsUpdateConstraints];
    [self updateConstraintsIfNeeded];
    
    WeakSelf(weakSelf);
    
    [self.tableView registerClass:[MessageSessionCell class] forCellReuseIdentifier:[NSString stringWithUTF8String:object_getClassName([MessageSessionCell class])]];
    
//    self.tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
//        [weakSelf.miliaoViewModel.refreshDataCommand execute:nil];
//    }];
}

- (void)olym_bindViewModel {
    
    [self addNotifacationObserver];
    
    @weakify(self);
    [self.miliaoViewModel.refreshUI subscribeNext:^(id x) {
        
        @strongify(self);
        
//        NSMutableArray *systemUsers = @[].mutableCopy;
//        for (OLYMUserObject *userObj in self.miliaoViewModel.dataArray)
//        {
//            
//            if([userObj.userId isEqualToString:SYSTEM_CENTER_USERID]
//               || [userObj.userId isEqualToString:FRIEND_CENTER_USERID]
//               || [userObj.userNickname isEqualToString:@"新的朋友"])
//            {
//                [systemUsers addObject:userObj];
//                break;
//            }
//
//        }
//        [self.miliaoViewModel.dataArray removeObjectsInArray:systemUsers];
        
        [self.tableView reloadData];
    }];
    
    [self.miliaoViewModel.refreshEndSubject subscribeNext:^(id x) {
        @strongify(self);
        
        [self.tableView reloadData];
        
        switch ([x integerValue]) {
                
            case OLYM_HeaderRefresh_HasNoMoreData: {
                
                [self.tableView.mj_header endRefreshing];
                self.tableView.mj_footer = nil;
            }
                break;
            case OLYM_FooterRefresh_HasMoreData: {
                
                [self.tableView.mj_header endRefreshing];
                [self.tableView.mj_footer resetNoMoreData];
                [self.tableView.mj_footer endRefreshing];
            }
                break;
            case OLYM_FooterRefresh_HasNoMoreData: {
                [self.tableView.mj_header endRefreshing];
                [self.tableView.mj_footer endRefreshingWithNoMoreData];
            }
                break;
            case OLYM_RefreshError: {
                
                [self.tableView.mj_footer endRefreshing];
                [self.tableView.mj_header endRefreshing];
            }
                break;
                
            default:
                break;
        }
    }];
    
    //刷新角标
    [[olym_Nofity rac_addObserverForName:kgroupMemberEnterChatNotification object:nil]subscribeNext:^(NSNotification * _Nullable x) {
        @strongify(self);

        OLYMUserObject *currentUserObj = [x object];
        for (OLYMUserObject *userObj in self.miliaoViewModel.dataArray)
        {
            if ([userObj.userId isEqualToString:currentUserObj.userId] && [currentUserObj.domain isEqualToString:userObj.domain])
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [userObj updateUnreadCount:0];
                    NSInteger index = [self.miliaoViewModel.dataArray indexOfObject:userObj];
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
                    [self.tableView beginUpdates];
                    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                    [self.tableView endUpdates];

                });
                break;
            }
        }
    
    }];
    //禁言
    [[olym_Nofity rac_addObserverForName:kgroupSlienceChatNotification object:nil]subscribeNext:^(NSNotification *notification) {
        @strongify(self);
        OLYMUserObject *user = [notification object];
        for (OLYMUserObject *userObj in self.miliaoViewModel.dataArray)
        {
            if ([user.domain isEqualToString:userObj.domain] && [user.userId isEqualToString:userObj.userId])
            {
                userObj.isSilence = user.isSilence;
                userObj.talkTime = user.talkTime;
                break;
            }
        }

    }];
    //设置消息免打扰
    [[olym_Nofity rac_addObserverForName:kDontDisturbChatNotification object:nil]subscribeNext:^(NSNotification * _Nullable x) {
        @strongify(self);
        OLYMUserObject *user = [x object];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.userId == %@ && SELF.domain == %@",user.userId,user.domain];
        NSArray *fiterArray = [self.miliaoViewModel.dataArray filteredArrayUsingPredicate:predicate];
        for (OLYMUserObject *userObj in fiterArray) {
            
            NSInteger index = [self.miliaoViewModel.dataArray indexOfObject:userObj];
            userObj.isDontDisturb = user.isDontDisturb;
            dispatch_async(dispatch_get_main_queue(), ^{
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
                [self.tableView beginUpdates];
                [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                [self.tableView endUpdates];
            });
            break;
        }
    }];

}
#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return self.miliaoViewModel.dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    
    MessageSessionCell *cell = [tableView dequeueReusableCellWithIdentifier:[NSString stringWithUTF8String:object_getClassName([MessageSessionCell class])] forIndexPath:indexPath];
    
    int row = indexPath.row;
    
    OLYMUserObject *userObject = [self.miliaoViewModel.dataArray objectAtIndex:row];
    
    if([userObject isGroup]){
        [cell.titleNode setText:userObject.userNickname];
    }else{
        
        if ([userObject.telephone isEqualToString:olym_UserCenter.userAccount]) {
            
            //文件传输助手
            [cell.titleNode setText:_T(@"文件传输助手")];
        }else{
            
            [cell.titleNode setText:[userObject getDisplayName]];
        }
        
    }
    
    [cell.textNode setText:userObject.content];
    [cell.timeNode setText:[TimeUtil getTimeStrStyle1:[userObject.updateTime timeIntervalSince1970]]];
    [cell changeCornerView:userObject.unreadCount];
#if ThirdlyVersion
    cell.draftMessage = userObject.draftContent;
#endif
    //是否设置了消息免打扰
    cell.isDontdisturb = userObject.isDontDisturb;
    cell.isAppoint = userObject.isAppoint;

    if([userObject.userId intValue] == SYSTEM_CENTER_INT){
        [cell.photoNode setImage:GJCFQuickImage(@"content_system message_head")];
    }else if([userObject.userId intValue] == FRIEND_CENTER_INT){
        [cell.photoNode setImage:GJCFQuickImage(@"content_new friend_head")];
    }else if(userObject.userId == olym_UserCenter.userId){
        [cell.photoNode setImage:GJCFQuickImage(@"file_ transfer")];
    }else if(userObject.roomFlag == 1){
#if MJTDEV
        [cell.photoNode setImage:GJCFQuickImage(@"default_groupv3")];
#else
        [cell.photoNode setImage:GJCFQuickImage(@"content_group_head")];
#endif
    }else{
#if MJTDEV
        [cell.photoNode setImageUrl:userObject.userHead withDefault:@"defaultheadv3"];
#else
        [cell.photoNode setImageUrl:userObject.userHead withDefault:@"chat_groups_header"];
#endif
    }
    
    return cell;
}


#pragma mark - UITableViewDelegate

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        OLYMUserObject *userObject = [self.miliaoViewModel.dataArray objectAtIndex:indexPath.row];
        //删除聊天记录，同时要把未读赋0并且，清空content
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSInteger unreadCount = userObject.unreadCount;
            userObject.content = nil;
            userObject.unreadCount = 0;
            [userObject update];
            [userObject notifyRefreshUnreadBadge:-unreadCount];
            
            [OLYMMessageObject deleteMessage:userObject.userId withDomain:userObject.domain];
        });
        
        
        [self.miliaoViewModel.dataArray removeObject:userObject];
        
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
        
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return 66.0f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    self.currentChatUser = [self.miliaoViewModel.dataArray objectAtIndex:indexPath.row];
    if(self.currentChatUser.unreadCount > 0 ){
        
        [self.currentChatUser updateUnreadCount:0];
        
        [tableView beginUpdates];
        [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        [tableView endUpdates];
    }

    [self.miliaoViewModel.cellClickSubject sendNext:indexPath];
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    
    if ([[olym_Default objectForKey:kAPI_PC_LOGIN] boolValue]) {
        
        return 40;
    }

    return 0;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    
    if (![[olym_Default objectForKey:kAPI_PC_LOGIN] boolValue]) {
        
        return nil;
    }
    
    UIView *view = [[UIView alloc]init];
    view.backgroundColor = white_color;
    
    UIImageView *pcImageView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"computer_small"]];
    [view addSubview:pcImageView];
    
    UILabel *label = [[UILabel alloc]init];
    label.text = @"电脑密九通已经登录";
    label.font = [UIFont systemFontOfSize:14];
    label.textColor = gray_color;
    [view addSubview:label];
    
    UIView *line = [[UIView alloc]init];
    line.backgroundColor = kTableViewBackgroundColor;
    [view addSubview:line];
    
    [pcImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.left.mas_equalTo(view).offset(25);
        make.centerY.mas_equalTo(view);
    }];
    
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.left.mas_equalTo(pcImageView.mas_right).offset(10);
        make.centerY.mas_equalTo(view);
    }];
    
    [line mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.bottom.right.mas_equalTo(view);
        make.left.mas_equalTo(view).offset(15);
        make.height.mas_equalTo(1);
    }];
    
    
    view.userInteractionEnabled = YES;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(pcViewClick)];
    [view addGestureRecognizer:tap];
    
    return view;
}

- (UIImage *)imageForEmptyDataSet:(UIScrollView *)scrollView
{
    return GJCFQuickImage(@"emptyset");
}

- (CGFloat)verticalOffsetForEmptyDataSet:(UIScrollView *)scrollView
{
    return -self.frame.size.height/5.0f;
}

- (NSAttributedString *)descriptionForEmptyDataSet:(UIScrollView *)scrollView
{
    NSString *text = _T(@"暂无数据");
    
    NSMutableParagraphStyle *paragraph = [NSMutableParagraphStyle new];
    paragraph.lineBreakMode = NSLineBreakByWordWrapping;
    paragraph.alignment = NSTextAlignmentCenter;
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont systemFontOfSize:17.0f],
                                 NSForegroundColorAttributeName: [UIColor lightGrayColor],
                                 NSParagraphStyleAttributeName: paragraph};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (CGFloat)spaceHeightForEmptyDataSet:(UIScrollView *)scrollView
{
    return 20.0f;
}

#pragma mark - 监听消息到来通知
-(void)addNotifacationObserver{
    @weakify(self);
    
    [[olym_Nofity rac_addObserverForName:kXMPPNewMsgNotifaction object:nil] subscribeNext:^(NSNotification *notification){
        @strongify(self);
        [self doRefreshMessageList:notification];
    }];
    
    [[olym_Nofity rac_addObserverForName:kXMPPRefreshMsgListNotifaction object:nil] subscribeNext:^(NSNotification *notification){
        @strongify(self);
        [self doRefreshMessageList:notification];
    }];
    
    [[olym_Nofity rac_addObserverForName:kDeleteUserSessionNotifaction object:nil] subscribeNext:^(NSNotification *notification){
        @strongify(self);
        NSDictionary *userInfo = notification.userInfo;
        [self deleteUserFromList:notification.userInfo];
    }];
}

- (void)removeObserver
{
    [olym_Nofity removeObserver:self name:kXMPPNewMsgNotifaction object:nil];
    [olym_Nofity removeObserver:self name:kXMPPRefreshMsgListNotifaction object:nil];
    [olym_Nofity removeObserver:self name:kDeleteUserSessionNotifaction object:nil];
}

#pragma mark - 删除会话
-(void)deleteUserFromList:(NSDictionary *)userInfo{
    
    
    dispatch_async(dispatch_get_main_queue(), ^{
      
        NSString *userId = [userInfo objectForKey:@"userId"];
        NSString *userDomain = [userInfo objectForKey:@"userDomain"];
        BOOL isGroup = [[userInfo objectForKey:@"isGroup"] boolValue];
        BOOL deleteBySelf = [[userInfo objectForKey:@"deleteBySelf"] boolValue];
        
        int count  = self.miliaoViewModel.dataArray.count;
        
        OLYMUserObject *deleteUser = nil;
        
        for(int i = 0 ; i < count; i++){
            
            OLYMUserObject *user = self.miliaoViewModel.dataArray[i];
            
            if([user.userId isEqualToString:userId]
               && [user.domain isEqualToString:userDomain]){
                
                deleteUser = user;
                
                [self.miliaoViewModel.dataArray removeObject:user];
                
                NSIndexPath *deletePath = [NSIndexPath indexPathForRow:i inSection:0];
                
                [self.tableView beginUpdates];
                [self.tableView deleteRowsAtIndexPaths:@[deletePath] withRowAnimation:UITableViewRowAnimationNone];
                [self.tableView endUpdates];
                
                break;
            }
        }
        
        if(deleteUser && !deleteBySelf){
            
            //未读条数更新
            if (deleteUser.unreadCount > 0)
            {
                NSInteger unreadCount =  0 - deleteUser.unreadCount;
                [deleteUser notifyRefreshUnreadBadge:unreadCount];
            }
            
            //延迟 1.5S 弹出对话框，是为了会话界面能够pop出来
            dispatch_time_t time =dispatch_time(DISPATCH_TIME_NOW,  1.5 *NSEC_PER_SEC);
                dispatch_after(time, dispatch_get_main_queue(), ^{
                
                NSString *alertStr = nil;
                
                
                if(isGroup){

                    alertStr = [NSString stringWithFormat:_T(@"您已被移出\"%@\"群"),deleteUser.userNickname];
                }else{
                    alertStr = [NSString stringWithFormat:_T(@"您已被\"%@\"删除"),deleteUser.userNickname];
                }
               
                
                [AlertViewManager alertWithTitle:alertStr];
                
            });
        }
    });
}

#pragma mark - 监听界面是否退出
-(void)chatViewExit{
    if(self.currentChatUser){
        self.currentChatUser = nil;
    }
}

#pragma mark - 刷新消息界面
-(void)doRefreshMessageList:(NSNotification *)notification{
    
    OLYMMessageObject *currentMessage = notification.object;
    
    [self doRefresh:currentMessage showBadge:YES];
    
    
}

- (void)doRefresh:(OLYMMessageObject *)currentMessage showBadge:(BOOL)isShow{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        OLYMUserObject *currentMsgUser = nil;
        
        NSIndexPath *reloadIndex = nil;
        
        int count = self.miliaoViewModel.dataArray.count;
        
        //是否我已经在打开对方会话界面 是 这不更新消息，不提示声音
        NSString *fromUserId = currentMessage.fromUserId;
        if (currentMessage.isGroup && !currentMessage.isMySend) {
            fromUserId = currentMessage.roomId;
        }
        BOOL isOnChatView = [self.currentChatUser.userId isEqualToString:fromUserId] && [self.currentChatUser.domain isEqualToString:currentMessage.domain];
        
        for(int i = 0 ; i < count; i++){
            
            OLYMUserObject *user = self.miliaoViewModel.dataArray[i];
        
            if([user.userId isEqualToString:currentMessage.isMySend ? currentMessage.toUserId:fromUserId]
               && [user.domain isEqualToString:currentMessage.domain]){
                
                currentMsgUser = user;
                
                user.updateTime = currentMessage.timeSend;
                
                user.content = [currentMessage getLastContent];
                
                //不是我发的，需要记数
                if(!currentMessage.isMySend){
                    
                    if(!isOnChatView && !currentMsgUser.isDontDisturb){
                        [self soundNotice:YES msg:currentMessage];
                    }
                }
                
                [self.miliaoViewModel.dataArray removeObject:user];
                
                break;
            }
        }
    
        //如果当前列表不存在此用户
        if(!currentMsgUser){
           
            currentMsgUser = [OLYMUserObject fetchFriendByUserId:currentMessage.isMySend?currentMessage.toUserId:fromUserId withDomain:currentMessage.domain];
            
            //没聊天过的，自然要提示了
            if(!currentMsgUser.isDontDisturb)
            {
                [self soundNotice:YES msg:currentMessage];
            }
        }
        //容错处理 如果 currentMsgUser = nil
        if(currentMsgUser){
            
            //不是我发的，需要记数
            if(!currentMessage.isMySend && !isOnChatView){
                //更新被@状态,并写入数据库
                if (currentMessage.isAppoint)
                {
                    currentMsgUser.isAppoint = currentMessage.isAppoint;
                }
#if MJTDEV
                if (![currentMsgUser.userId isEqualToString:FRIEND_CENTER_USERID])
                {
                    [currentMsgUser updateUnreadCount:currentMsgUser.unreadCount + 1];
                }
#else
                [currentMsgUser updateUnreadCount:currentMsgUser.unreadCount + 1];
#endif
                
            }else
            {
                if (currentMessage.isAppoint && isOnChatView)
                {
                    currentMsgUser.isAppoint = NO;
                    [currentMsgUser updateIsAppoint];
                }
            }
#if MJTDEV
            if (![currentMsgUser.userId isEqualToString:FRIEND_CENTER_USERID])
            {
                [self.miliaoViewModel.dataArray insertObject:currentMsgUser atIndex:0];
            }
#else
            //重新添加  按最新消息在前排序
            [self.miliaoViewModel.dataArray insertObject:currentMsgUser atIndex:0];
#endif
        }
       
        
        [self.tableView reloadData];
        
    });
}

#pragma mark - 是否需要响铃
-(void)soundNotice:(BOOL)isSound msg:(OLYMMessageObject *)msg{
    
    if([self isNeedToSoundNotice] && !msg.isMySend){
        if(isSound){
            //前台只震动，后期再做铃音通知
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
        }
    }
}

-(BOOL)isNeedToSoundNotice {
    
    if(!self.lastNoticeDate){
        self.lastNoticeDate = [NSDate date];
        return YES;
    }else{
        
        NSTimeInterval time = [self.lastNoticeDate timeIntervalSince1970];
        long long int beTime = (long long int) time;
        
        NSDate *nowDate = [NSDate date];
        NSTimeInterval now = [nowDate timeIntervalSince1970];
        double distanceTime = ( now - beTime );
        
        if (distanceTime < 3) {//小于2S
            return NO;
        }
        
        self.lastNoticeDate = nowDate;
    }
    return YES;
}


#pragma mark - Private
-(void)_createTableHeaderView{
    
    //搜索栏
    _mSearchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, GJCFSystemScreenWidth, 45)];
    _mSearchBar.placeholder = _T(@"搜索");
    _mSearchBar.searchBarStyle = UISearchBarStyleMinimal;
    _mSearchBar.backgroundImage = [UIImage new];
    [_mSearchBar setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    [_mSearchBar sizeToFit];
    _mSearchBar.barTintColor = [UIColor whiteColor];
    _mSearchBar.tintColor = [UIColor whiteColor];
    [_mSearchBar setCenterdPlaceholder];
    self.tableView.sectionIndexBackgroundColor = [UIColor clearColor];
    for (UIView *subView in _mSearchBar.subviews)
    {
        subView.backgroundColor = [UIColor whiteColor];
        for (UIView *view in subView.subviews)
        {
            if ([view isKindOfClass:NSClassFromString(@"UISearchBarSearchFieldBackgroundView")])
            {
                view.backgroundColor = [UIColor whiteColor];
                break;
            }
        }
    }
    UITextField *searchField = [_mSearchBar valueForKey:@"searchField"];
    if (searchField) {
        [searchField setBackgroundColor:OLYMHEXCOLOR(0XEDEDEE)];
        searchField.layer.cornerRadius = 0;
    }

    
    self.tableView.tableHeaderView = _mSearchBar;
}

-(void)pcViewClick{
    
    [self.miliaoViewModel.pcViewClickSubject sendNext:nil];
}

- (void)dealloc
{
    [self removeObserver];
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
}
@end

