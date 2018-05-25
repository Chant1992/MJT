//
//  ChatListView.m
//  MJT_APP
//
//  Created by olymtech on 2017/8/29.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "ChatListView.h"
#import "ChatViewModel.h"
#import "OLYMMessageObject.h"
#import "ChatBaseCell.h"
#import "ChatFriendConstans.h"
#import "GJCFFileDownloadTask.h"
#import "GJCFFileDownloadManager.h"
#import "GJCFFileUploadTask.h"
#import "GJCFFileUploadManager.h"
#import "OLYMMoviePlayerViewController.h"
#import "OLYMBaseNavigationController.h"
#import "GJCUImageBrowserNavigationViewController.h"
#import "FileOpenVC.h"
#import "OLYMUserObject.h"
#import "BurnAfterReadingViewController.h"
#import "OLYMImageBrowserController.h"
#import "AlertViewManager.h"
#import "OLYMMessageObject+CellHeight.h"
#import "SecurityEngineHelper.h"
#import "BDUIViewUpdateQueue.h"
#import "DownloadMessageFileManager.h"
#import "SendFileHelper.h"
#import "PersonalDataViewController.h"
#import "UIView+ViewController.h"

NSString* const kChatListViewWillBeginDraggingNotification = @"kChatListViewWillBeginDraggingNotification";

@interface ChatListView ()<ChatCellDelegate>
{
    CFRunLoopObserverRef reloadObserver;
}
@property (strong, nonatomic) ChatViewModel *chatViewModel;


@property (nonatomic, strong) NSIndexPath *lastAudioIndexPath;


@property (nonatomic, strong) NSMutableDictionary *heightDictionary;

@property (nonatomic, strong) NSMutableArray *unInQueueMessageArray;

@property (nonatomic, strong) NSLock *refreshLock;
@property(nonatomic,assign) BOOL lock;

@end

@implementation ChatListView

- (instancetype)initWithViewModel:(id<OLYMViewModelProtocol>)viewModel {
    self.chatViewModel = (ChatViewModel *)viewModel;
    self.heightDictionary = [NSMutableDictionary dictionary];
    self.refreshLock = [[NSLock alloc]init];
    self.unInQueueMessageArray = [NSMutableArray array];
    return [super initWithViewModel:viewModel];
}

- (void)updateConstraints {
    
    WeakSelf(weakSelf);
    self.tableView.backgroundColor = kTableViewBackgroundColor;
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self.tableView setTableFooterView:[UIView new]];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(weakSelf);
    }];

    [super updateConstraints];

}

#pragma mark - private
- (void)olym_setupViews {
    
    [self addSubview:self.tableView];
    [self setNeedsUpdateConstraints];
    [self updateConstraintsIfNeeded];
    
    @weakify(self);
    self.tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        @strongify(self);
        [self.chatViewModel.refreshDataCommand execute:nil];
    }];
    self.tableView.mj_footer = [MJRefreshBackFooter footerWithRefreshingBlock:^{
        @strongify(self);
        [self.chatViewModel.refreshFooterDataCommand execute:nil];
    }];
    if(self.chatViewModel.dataArray.count > 1){
        NSInteger rows = [self.tableView numberOfRowsInSection:0];
        if (rows > 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:rows - 1 inSection:0];
                if (self.chatViewModel.searchMessgeIndexPath)
                {
                    indexPath = self.chatViewModel.searchMessgeIndexPath;
                }
                [self.tableView scrollToRowAtIndexPath:indexPath
                                      atScrollPosition:UITableViewScrollPositionBottom
                                              animated:NO];
            });
            
        }
        /*
        double delayInSeconds = 0.15;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            //滚动到最后一行
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:(self.chatViewModel.dataArray.count - 1) inSection:0];
            [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:NO];
        });
         */
    }
#if TESTSYNC
    [self addTestSYNCUI];
#endif
}

#if TESTSYNC
- (void)addTestSYNCUI
{
    self.sendLabel = [[UILabel alloc]initWithFrame:CGRectMake(GJCFSystemScreenWidth - 150, 20, 150, 25)];
    self.sendLabel.backgroundColor = [UIColor redColor];
    
    self.receiveLabel = [[UILabel alloc]initWithFrame:CGRectMake(GJCFSystemScreenWidth - 150, 60, 150, 25)];
    self.receiveLabel.backgroundColor = [UIColor greenColor];
    
    self.resetButton = [[UIButton alloc]initWithFrame:CGRectMake(GJCFSystemScreenWidth - 150, 100, 150, 35)];
    [self.resetButton setTitle:@"重置" forState:UIControlStateNormal];
    self.resetButton.backgroundColor = [UIColor blueColor];
    
    [self addSubview:self.sendLabel];
    [self addSubview:self.receiveLabel];
    [self addSubview:self.resetButton];
    
    OLYMUserObject *userObj1 = [OLYMUserObject fetchFriendByUserId:self.chatViewModel.currentChatUserId withDomain:self.chatViewModel.currentChatUserDomain];
    self.sendLabel.text = [NSString stringWithFormat:@"send :%ld",userObj1.sendCount];
    self.receiveLabel.text = [NSString stringWithFormat:@"receive :%ld",userObj1.receiveCount];

}
#endif


- (void)olym_bindViewModel {
    @weakify(self);

#if TESTSYNC
    
    [[olym_Nofity rac_addObserverForName:@"kTestSYNCNotifaction" object:nil] subscribeNext:^(NSNotification *notification){
        @strongify(self);
        OLYMUserObject *user = [notification object];
        if ([self.chatViewModel.currentChatUserId isEqualToString:user.userId])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.sendLabel.text = [NSString stringWithFormat:@"send :%ld",user.sendCount];
                self.receiveLabel.text = [NSString stringWithFormat:@"receive :%ld",user.receiveCount];
            });
        }
    }];
    [[self.resetButton rac_signalForControlEvents:UIControlEventTouchUpInside]subscribeNext:^(__kindof UIControl * _Nullable x) {
        @strongify(self);
        OLYMUserObject *userObj1 = [OLYMUserObject fetchFriendByUserId:self.chatViewModel.currentChatUserId withDomain:self.chatViewModel.currentChatUserDomain];
        [userObj1 updateSend:-userObj1.sendCount receive:-userObj1.receiveCount];
    }];
#endif
    [self addNotifacationObserver];
//    [self addRunloopObserver];
    
    [self configFileUploadManager];
    /* 初始化下载组件 */
    [self configFileDownloadManager];
    
    [self.chatViewModel.refreshUI subscribeNext:^(id x) {
        @strongify(self);
        if (!self.chatViewModel.isSearchCondition)
        {
            self.tableView.mj_footer = nil;
        }
    }];
    
    [self.chatViewModel.refreshEndSubject subscribeNext:^(id x) {
        @strongify(self);
        
        [self.tableView reloadData];
        
        switch ([x integerValue]) {
            case OLYM_HeaderRefresh_HasMoreData:{
                [self.tableView.mj_header endRefreshing];
            }
                break;
            case OLYM_HeaderRefresh_HasNoMoreData: {
                
                [self.tableView.mj_header endRefreshing];
                self.tableView.mj_header = nil;
                
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
                self.tableView.mj_footer = nil;
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
        if (!self.chatViewModel.isSearchCondition)
        {
            self.tableView.mj_footer = nil;
        }
    }];
    
    //开始连续播放语音，开启动画
    [self.chatViewModel.playAudioBeginSubject subscribeNext:^(OLYMMessageObject *playMessage) {
        @strongify(self);
        
        [self.chatViewModel.dataArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            OLYMMessageObject *messageObj = obj;
            if ([playMessage.messageId isEqualToString:messageObj.messageId])
            {
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:idx inSection:0];
                ChatBaseCell *chatBaseCell = [self.tableView cellForRowAtIndexPath:indexPath];
                if (chatBaseCell)
                {
                    [chatBaseCell startVoiceAnimation];
                    if ([chatBaseCell respondsToSelector:@selector(hiddenUnreadPrompt)])
                    {
                        [chatBaseCell performSelector:@selector(hiddenUnreadPrompt)];
                    }
    
                }
                
                *stop = YES;
            }
        }];
    }];

    //结束一个语音播放，结束动画
    [self.chatViewModel.playAudioFinishedSubject subscribeNext:^(OLYMMessageObject *playMessage) {
        @strongify(self);
        
        [self.chatViewModel.dataArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            OLYMMessageObject *messageObj = obj;
            if ([playMessage.messageId isEqualToString:messageObj.messageId])
            {
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:idx inSection:0];
                ChatBaseCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
                if (cell)
                {
                    [cell stopVoiceAnimation];
                }
                *stop = YES;
            }
        }];
    }];
    //删除文件，刷新UI
    [self.chatViewModel.fileDeleteSubject subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    }];
}

- (void)removeObserver
{
    [olym_Nofity removeObserver:self name:kXMPPSendStatusNotifaction object:nil];
    [olym_Nofity removeObserver:self name:kDeleteReadburnMessageNotifaction object:nil];
    [olym_Nofity removeObserver:self name:kDeleteMessageHistoryNotifaction object:nil];
//    if (CFRunLoopContainsObserver(CFRunLoopGetCurrent(), reloadObserver, kCFRunLoopDefaultMode)) {
//        CFRunLoopRemoveObserver(CFRunLoopGetCurrent(), reloadObserver, kCFRunLoopDefaultMode);
//    }
//    CFRunLoopObserverInvalidate(reloadObserver);
//    CFRelease(reloadObserver);
//    reloadObserver = NULL;

}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return self.chatViewModel.dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *DefaultBaseCellIdentifier = @"DefaultBaseCellIdentifier";
    
    NSString *identifier = [self contentCellIdentifierAtIndex:indexPath.row];
    
    OLYMMessageObject *messageObject = [self contentModelAtIndex:indexPath.row];
    
    Class cellClass = [self contentCellAtIndex:indexPath.row];
    
    if (!cellClass) {
        
        ChatBaseCell *baseCell = (ChatBaseCell *)[tableView dequeueReusableCellWithIdentifier:DefaultBaseCellIdentifier];
        
        if (!baseCell) {
            
            baseCell = [[ChatBaseCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:DefaultBaseCellIdentifier];
            baseCell.delegate = self;
        }
        return baseCell;
    }
    
    ChatBaseCell *baseCell = (ChatBaseCell *)[tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (!baseCell) {
        
        baseCell = [(ChatBaseCell *)[cellClass alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        UIView* bgview = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
        bgview.backgroundColor = tableView.backgroundColor;
        [baseCell setBackgroundView:bgview];
        

        baseCell.delegate = self;
    }

    //test
//    int status = indexPath.row % 5;
//    messageObject.isSend = status;
//    BOOL fromMyself = indexPath.row % 2;
//    messageObject.isMySend = fromMyself;
//    messageObject.isGroup = YES;
//    messageObject.isRead = fromMyself;

    [baseCell setContentModel:messageObject];
    
    
    //阅后即焚和语音必须查看才标记为已读
    if(!messageObject.isGroup && !messageObject.isRead && !messageObject.isMySend && messageObject.type != kWCMessageTypeVoice && !messageObject.isReadburn)
    {
        [self.chatViewModel sendReadedMessage:messageObject];
    }
       
    
    [self downloadFile:indexPath];
    
    return baseCell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self heightForContentModel:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self heightForContentModel:indexPath];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView.isEditing)
    {
        OLYMMessageObject *messageObject = [self contentModelAtIndex:indexPath.row];
        if (messageObject.type == kWCMessageTypeRemind || messageObject.type == kWCMessageTypeReCall)
        {
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
        }else
        {
            [self.chatViewModel.tablecellEditSubject sendNext:nil];
        }
        return;
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [self.chatViewModel.cellClickSubject sendNext:nil];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView.isEditing)
    {
        [self.chatViewModel.tablecellEditSubject sendNext:nil];
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return (UITableViewCellEditingStyle)(UITableViewCellEditingStyleInsert | UITableViewCellEditingStyleDelete);
}

#pragma mark - 取cell的高度

- (CGFloat)heightForContentModel:(NSIndexPath *)indexPath
{
    OLYMMessageObject *contentModel = [self contentModelAtIndex:indexPath.row];
    if ([self.heightDictionary objectForKey:indexPath])
    {
        return [[self.heightDictionary objectForKey:[NSString stringWithFormat:@"%ld",contentModel.messageNo]]floatValue];
    }else
    {
        CGFloat height = [contentModel heightForContentModel];
        [self.heightDictionary setObject:@(height) forKey:[NSString stringWithFormat:@"%ld",contentModel.messageNo]];
        return height;
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    UIMenuController *shareMenuViewController = [UIMenuController sharedMenuController];
    if (shareMenuViewController.isMenuVisible) {
        [shareMenuViewController setMenuVisible:NO animated:YES];
    }
    [olym_Nofity postNotificationName:kChatListViewWillBeginDraggingNotification object:nil];
}


#pragma mark - chatCellDelegate
#pragma mark - cell点击、长按事件
- (void)chatCellDidTapHeader:(ChatBaseCell *)chatBaseCell
{
    

    
    if (chatBaseCell.contentModel.isGroup)
    {
        //群聊里的
        if (chatBaseCell.contentModel.domain == nil) {
            
            NSLog(@"此人域名为空");
            return;
        }
        
        [self.chatViewModel getUserInfoByUserId:chatBaseCell.contentModel.fromUserId domain:FULL_DOMAIN(olym_UserCenter.userDomain) roomId:self.chatViewModel.currentChatRoomId];
    }else
    {
        //单聊直接获取
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            OLYMUserObject *user;
            if (chatBaseCell.contentModel.isMySend)
            {
                user = [[OLYMUserObject alloc]init];
                user.userId = olym_UserCenter.userId;
                user.domain = FULL_DOMAIN(olym_UserCenter.userDomain);
                user.telephone = olym_UserCenter.userAccount;
                user.userNickname = olym_UserCenter.userName;
                
            }else
            {
                user = [OLYMUserObject fetchFriendByUserId:self.chatViewModel.currentChatUserId withDomain:self.chatViewModel.currentChatUserDomain];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.chatViewModel.cardShowSubject sendNext:@{@"status":@(user.status),@"user":user}];
            });
        });
    }

}

- (void)chatCellDidLongPressHeader:(ChatBaseCell *)chatBaseCell
{
    if ([chatBaseCell.contentModel.fromUserId isKindOfClass:[NSString class]])
    {
        if ([chatBaseCell.contentModel.fromUserId isEqualToString:olym_UserCenter.userId])
        {
            return;
        }
    }
    [self.chatViewModel.headerLongPressSubject sendNext:[chatBaseCell.contentModel toDictionary]];
}


- (void)chatCellDidTapAudioMessage:(ChatBaseCell *)chatBaseCell
{
    NSIndexPath *tappIndexPath = [self.tableView indexPathForCell:chatBaseCell];
    OLYMMessageObject *contentModel = chatBaseCell.contentModel;

    
    NSString *base64Audio = contentModel.content;
    if ([self.lastAudioIndexPath isEqual:tappIndexPath])
    {
        //点击同一个
        if ([self.chatViewModel isAudioPlaying])
        {
            //暂停
            [self.chatViewModel stopAudioPlay];
            [chatBaseCell stopVoiceAnimation];
        }else
        {
            //播放
            [chatBaseCell startVoiceAnimation];
            [self.chatViewModel playAudio:base64Audio finished:^{
                [chatBaseCell stopVoiceAnimation];
            }];
        }
        return;
    }
    
    ChatBaseCell *lastCell = [self.tableView cellForRowAtIndexPath:self.lastAudioIndexPath];
    [lastCell stopVoiceAnimation];
    
    self.lastAudioIndexPath = tappIndexPath;
    [self.chatViewModel stopAudioPlay];
    
    [chatBaseCell startVoiceAnimation];
    if (contentModel.isRead || contentModel.isMySend)
    {
        [self.chatViewModel playAudio:base64Audio finished:^{
            [chatBaseCell stopVoiceAnimation];
        }];
    }else
    {
        [self.chatViewModel playAudioByTurn:tappIndexPath.row];
    }
    
}

- (void)chatCellDidTapImageMessage:(ChatBaseCell *)chatBaseCell
{
    OLYMMessageObject *contentModel = chatBaseCell.contentModel;
    //未下载完成不显示大图
    if (!contentModel.isFileReceive && !contentModel.isMySend)
    {
        if (contentModel.isSend == transfer_status_no)
        {
            [AlertViewManager alertWithTitle:_T(@"图片下载失败")];
        }else
        {
            [AlertViewManager alertWithTitle:_T(@"图片未下载完毕")];
        }
        return;
    }
    NSString *filePath = [[olym_FileCenter documentPrefix]stringByAppendingString:contentModel.filePath];
    
    [self.chatViewModel.imageShowSubject sendNext:@{@"filePath":filePath,@"isEncrypt":[NSNumber numberWithBool:contentModel.isAESEncrypt]}];

}

- (void)chatCellDidTapVideoMessage:(ChatBaseCell *)chatBaseCell
{
    OLYMMessageObject *contentModel = chatBaseCell.contentModel;
    if (!contentModel.isFileReceive && !contentModel.isMySend)
    {
        [AlertViewManager alertWithTitle:_T(@"视频未下载完毕")];
        return;
    }

    NSString *filePath = [[olym_FileCenter documentPrefix]stringByAppendingPathComponent:contentModel.filePath];
    NSDictionary *infoDict = @{@"filePath":filePath,@"isEncrypt":[NSNumber numberWithBool:contentModel.isAESEncrypt]};
    [self.chatViewModel.videoShowSubject sendNext:infoDict];

}

- (void)chatCellDidTapFileMessage:(ChatBaseCell *)chatBaseCell
{
    OLYMMessageObject *contentModel = chatBaseCell.contentModel;
    NSString *filePath = nil;
    if (contentModel.isMySend || contentModel.isFileReceive)
    {
        filePath = [[olym_FileCenter documentPrefix]stringByAppendingPathComponent:contentModel.filePath];
    }
    
    if([[NSFileManager defaultManager] fileExistsAtPath:filePath]){
        [self.chatViewModel.fileShowSubject sendNext:@{@"filePath":filePath,@"type":@(contentModel.type),@"fileAESEncrypt":@(contentModel.isAESEncrypt)}];
    } else {
        [AlertViewManager alertWithTitle:_T(@"文件正在下载中")];
    }

}

- (void)chatCellDidTapCardMessage:(ChatBaseCell *)chatBaseCell
{
    OLYMMessageObject *contentModel = chatBaseCell.contentModel;
    NSArray *array = [contentModel.content componentsSeparatedByString:@":"];

    OLYMUserObject *user = [OLYMUserObject fetchFriendByUserId:contentModel.objectId withDomain:array[1]];
    if (!user)
    {
        //陌生人
        OLYMUserObject *userObj = [[OLYMUserObject alloc]init];
        userObj.userNickname = array[0];
        userObj.domain = array[1];
        userObj.telephone = array[2];
        userObj.userId = contentModel.objectId;
        userObj.status = 0;
        
        [self.chatViewModel.cardShowSubject sendNext:@{@"status":@(userObj.status),@"user":userObj}];
        
    }else
    {
        if (user.status != 2)
        {
            //待验证
            [self.chatViewModel.cardShowSubject sendNext:@{@"status":@(user.status),@"user":user}];
        }else
        {
            //好友
            [self.chatViewModel.cardShowSubject sendNext:@{@"status":@(user.status),@"user":user}];
        }
    }
    
}

- (void)chatCellDidTapBurnAfterReadMessage:(ChatBaseCell *)chatBaseCell
{
    OLYMMessageObject *contentModel = chatBaseCell.contentModel;
    if (contentModel.isSend == transfer_status_read)
    {
        //消息已读，不需要相应
        return;
    }
    //视频直接发送已读回执
    if (!contentModel.isMySend && !contentModel.isGroup && contentModel.type == kWCMessageTypeVideo)
    {
        if (contentModel.isFileReceive && !contentModel.isMySend)
        {
            [self.chatViewModel sendReadedMessage:contentModel];
        }
    }
    BOOL gotoIntroPage = YES;
    int type = contentModel.type;
    switch(type){
            case kWCMessageTypeImage:
        {
            if (!contentModel.isFileReceive && !contentModel.isMySend)
            {
                [AlertViewManager alertWithTitle:_T(@"图片未下载完毕")];
                return;
            }
            gotoIntroPage = NO;
            //图片阅后即焚
            [self.chatViewModel.imageBurnShowSubject sendNext:contentModel];
            
        }
            break;
            case kWCMessageTypeVideo:
        {
            if (!contentModel.isFileReceive && !contentModel.isMySend)
            {
                [AlertViewManager alertWithTitle:_T(@"视频未下载完毕")];
                return;
            }
            
            NSString *filePath = [[olym_FileCenter documentPrefix]stringByAppendingPathComponent:contentModel.filePath];
            
            [self.chatViewModel.videoBurnShowSubject sendNext:@{@"filePath":filePath,@"messageModel":contentModel,@"isEncrypt":[NSNumber numberWithBool:contentModel.isAESEncrypt]}];
            gotoIntroPage = NO;

        }
            break;
            default:
            if (contentModel.filePath)
            {
                //图片或视频
                NSString *fileExtension = [[contentModel.filePath componentsSeparatedByString:@"."]lastObject];
                if ([fileExtension isEqualToString:@"mp4"] || [fileExtension isEqualToString:@"MP4"] || [fileExtension isEqualToString:@"MOV"])
                {
                    //视频
                    if (!contentModel.isFileReceive && !contentModel.isMySend)
                    {
                        [AlertViewManager alertWithTitle:_T(@"视频未下载完毕")];
                        return;
                    }
                    
                    NSString *filePath = [[olym_FileCenter documentPrefix]stringByAppendingPathComponent:contentModel.filePath];
                    NSURL *videoUrl = [NSURL fileURLWithPath:filePath];
                    
                    [self.chatViewModel.videoBurnShowSubject sendNext:@{@"videoURL":videoUrl,@"messageModel":contentModel}];
                    gotoIntroPage = NO;
                }else if([fileExtension isEqualToString:@"amr"] || [fileExtension isEqualToString:@"wav"])
                {
                    gotoIntroPage = YES;
                }else
                {
                    //图片
                    if (!contentModel.isFileReceive && !contentModel.isMySend)
                    {
                        [AlertViewManager alertWithTitle:_T(@"图片未下载完毕")];
                        return;
                    }
                    gotoIntroPage = NO;
                    //图片阅后即焚
                    [self.chatViewModel.imageBurnShowSubject sendNext:contentModel];
                }
            }
            break;
    }
    if (gotoIntroPage)
    {
        //文字、语音到阅后即焚页
        [self.chatViewModel.textBurnShowSubject sendNext:contentModel];
    }
}


- (void)chatCellDeleteMessage:(ChatBaseCell *)chatBaseCell
{
    NSIndexPath *tappIndexPath = [self.tableView indexPathForCell:chatBaseCell];
    OLYMMessageObject *contentModel = chatBaseCell.contentModel;
    if (contentModel.type == kWCMessageTypeAudio)
    {
        [self.chatViewModel stopAudioPlay];
    }
    
    [[BDUIViewUpdateQueue shared]updateView:self.tableView block:^{
        [self.chatViewModel.dataArray removeObjectAtIndex:tappIndexPath.row];
        BOOL success = [self.chatViewModel deleteMessageByMessage:contentModel];
        if (self.chatViewModel.dataArray && success)
        {
            OLYMMessageObject *preMsg;
            if (self.chatViewModel.dataArray.count > 0)
            {
                preMsg = [self.chatViewModel.dataArray lastObject];
            }else
            {
                preMsg = [[OLYMMessageObject alloc]init];
            }
            //插入到聊天联系人列表
            [preMsg updateLastSend:YES];
            [self.chatViewModel.msgDeleteSubject sendNext:[preMsg getLastContent]];
        }
        CGFloat animationDuration = 0.28;
        [UIView animateWithDuration:animationDuration animations:^{
            if (contentModel.isMySend)
            {
                [self.tableView deleteRowsAtIndexPaths:@[tappIndexPath] withRowAnimation:UITableViewRowAnimationRight];
            }else{
                [self.tableView deleteRowsAtIndexPaths:@[tappIndexPath] withRowAnimation:UITableViewRowAnimationLeft];
            }

        }];
    }];

}

- (void)chatCellTranspondMessage:(ChatBaseCell *)chatBaseCell
{
    NSIndexPath *tappIndexPath = [self.tableView indexPathForCell:chatBaseCell];
    [self.chatViewModel.transpondClickSubject sendNext:tappIndexPath];
}

- (void)chatCellReDownload:(ChatBaseCell *)chatBaseCell
{
    OLYMMessageObject *contentModel = chatBaseCell.contentModel;
    if (contentModel.isMySend)
    {
        //自己发的不用重新下载
        return;
    }
    NSString *filePath = nil;
    filePath = [[olym_FileCenter documentPrefix]stringByAppendingPathComponent:contentModel.filePath];
    if (![FileCenter fileExistAt:filePath])
    {
        NSString *content = contentModel.content;
        if ([content rangeOfString:@"https://"].location == NSNotFound || !content)
        {
            //下载失败
            [contentModel updateSendStatus:transfer_status_no];
            return;
        }else
        {
            //重新下载
            NSIndexPath *indexPath = [self.tableView indexPathForCell:chatBaseCell];
            [self downloadFile:indexPath];
        }
    }
}



- (void)chatCellDecodeMessage:(ChatBaseCell *)chatBaseCell
{
    OLYMMessageObject *contentModel = chatBaseCell.contentModel;
    NSString *content = [self.chatViewModel decryptMessage:contentModel];
    
    if (content)
    {
        contentModel.isEncrypt = NO;
        contentModel.content = content;
        [contentModel updateContent];
        NSIndexPath *indexPath = [self.tableView indexPathForCell:chatBaseCell];
        [[BDUIViewUpdateQueue shared]updateView:self.tableView block:^{
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        }];
    }else
    {
#if XYT
        [SVProgressHUD showErrorWithStatus:_T(@"解密失败_xyt")];
#else
        [SVProgressHUD showErrorWithStatus:_T(@"解密失败")];
#endif
    }
}

- (void)chatCellResendMessage:(ChatBaseCell *)chatBaseCell
{
    UIAlertController * alertController = [UIAlertController alertControllerWithTitle: nil                                                                             message: nil                                                                       preferredStyle:UIAlertControllerStyleActionSheet];
    
    
    [alertController setModalPresentationStyle:UIModalPresentationPopover];
    
    if(GJCFSystemiPad){
        UIPopoverPresentationController *popPresenter = [alertController
                                                         popoverPresentationController];
        popPresenter.sourceView = chatBaseCell;
        popPresenter.sourceRect = chatBaseCell.bounds;
    }
    
    WeakSelf(ws);
    [alertController addAction: [UIAlertAction actionWithTitle: _T(@"重发") style: UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        OLYMMessageObject *contentModel = chatBaseCell.contentModel;
        [ws.chatViewModel reSendMessage:contentModel uploadBlock:^{
            if(contentModel.uploadFileModel){
                [ws uploadFile:contentModel];
            }
        }];
        
        [[BDUIViewUpdateQueue shared]updateView:ws.tableView block:^{
            NSIndexPath *tappIndexPath = [ws.tableView indexPathForCell:chatBaseCell];
            [ws.tableView reloadRowsAtIndexPaths:@[tappIndexPath] withRowAnimation:UITableViewRowAnimationNone];
            //UITableViewRowAnimationFade
            //UITableViewRowAnimationNone
        }];

    }]];

    [alertController addAction: [UIAlertAction actionWithTitle: _T(@"删除") style: UIAlertActionStyleDefault handler:^(UIAlertAction *action) {

        StrongSelf(ss);
        [ss deleteMsg:chatBaseCell];
    }]];

    [alertController addAction: [UIAlertAction actionWithTitle: _T(@"取消") style: UIAlertActionStyleCancel handler:nil]];

    [KeyWindow.rootViewController presentViewController: alertController animated: YES completion: nil];

}

- (void)chatCellDidTapLink:(NSString *)urlString
{
    [self.chatViewModel.linkClickedSubject sendNext:urlString];
}

- (void)chatCellDidTapPhoneNumber:(NSString *)phoneNumber
{

    NSString *tips = [NSString stringWithFormat:_T(@"%@可能是一个电话号码，你可以"),phoneNumber];
    [AlertViewManager actionSheettWithTitle:nil message:tips actionNumber:2 actionTitles:@[_T(@"呼叫"),_T(@"复制号码")] actionHandler:^(UIAlertAction *action, NSUInteger index) {
        if (index == 0) {
            NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"tel:%@",phoneNumber]];
            [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
        }else if (index == 1){
            UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
            [pasteboard setString:phoneNumber];
        }

    } cancleTitle:_T(@"取消") cancleActionHandler:^(UIAlertAction *action, NSUInteger index) {
        
    }];
}

- (void)deleteMsg:(ChatBaseCell *)tapedCell {
    
    WeakSelf(ws);
    NSIndexPath *tapIndexPath = [self.tableView indexPathForCell:tapedCell];
    OLYMMessageObject *msgObj = tapedCell.contentModel;
    
    if (msgObj.type == kWCMessageTypeVoice) {
        [tapedCell stopVoiceAnimation];
        [self.chatViewModel stopAudioIfPlayInQueue:msgObj];
    }
    
    [self.chatViewModel.dataArray removeObjectAtIndex:tapIndexPath.row];
    BOOL successed = [self.chatViewModel deleteMessageByMessage:msgObj];
    if (self.chatViewModel.dataArray && self.chatViewModel.dataArray.count > 0 && successed) {
        
        //更新最近会话列表的显示内容
        OLYMMessageObject *preMsgObj = [self.chatViewModel.dataArray objectAtIndex:tapIndexPath.row - 1];
        [preMsgObj updateLastSend:NO];
        
        if (msgObj.isMySend) {
            [self.tableView deleteRowsAtIndexPaths:@[tapIndexPath] withRowAnimation:UITableViewRowAnimationRight];
        }
    }
}

//引用
- (void)chatCellReferenceMessage:(ChatBaseCell *)chatBaseCell
{
    OLYMMessageObject *msgObj = chatBaseCell.contentModel;
    NSString *content = [self.chatViewModel getReferenceContent:msgObj];
    //转发到controller
    [self.chatViewModel.referenceMsgSubject sendNext:content];
}

//撤回消息
- (void)chatCellReCallMessage:(ChatBaseCell *)chatBaseCell
{
    if(olym_Xmpp.notReachble)
    {
        [SVProgressHUD showErrorWithStatus:_T(@"撤回失败")];
        return;
    }
    OLYMMessageObject *msgObj = chatBaseCell.contentModel;
    NSIndexPath *tapIndexPath = [self.tableView indexPathForCell:chatBaseCell];
    [self.chatViewModel.dataArray removeObject:msgObj];
    [[BDUIViewUpdateQueue shared]updateView:self.tableView block:^{
        if (tapIndexPath) {
            [self.tableView deleteRowsAtIndexPaths:@[tapIndexPath] withRowAnimation:UITableViewRowAnimationRight];
        }
    }];
    [self.chatViewModel sendRecallMesage:msgObj];
}


- (void)chatCellMutiSelectMessage:(ChatBaseCell *)chatBaseCell
{
    NSIndexPath *tapIndexPath = [self.tableView indexPathForCell:chatBaseCell];
    [self.chatViewModel.mutiSelectMsgSubject sendNext:nil];
    [self.tableView selectRowAtIndexPath:tapIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
}

#pragma mark - 文件上传
- (void)uploadFile:(OLYMMessageObject *)message{
    [[SendFileHelper shareInstance]uploadFile:message];
}


#pragma mark - 文件上传处理（包含图片 视频  文件等）

- (void)finishFileUploadNotification:(NSNotification *)notification
{
    OLYMMessageObject *message = [notification object];
    [self.chatViewModel.dataArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        OLYMMessageObject *messageObj = obj;
        if ([message.messageId isEqualToString:messageObj.messageId])
        {
            messageObj.content = message.content;
            *stop = YES;
        }
    }];
    
}

- (void)faildUploadFileNotification:(NSNotification *)notification
{
    OLYMMessageObject *message = [notification object];
    __block NSUInteger index = NSNotFound;
    [self.chatViewModel.dataArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        OLYMMessageObject *messageObj = obj;
        if ([message.messageId isEqualToString:messageObj.messageId])
        {
            messageObj.isSend = message.isSend;
            index = idx;
            *stop = YES;
        }
    }];
    [[BDUIViewUpdateQueue shared]updateView:self.tableView block:^{
        if (index != NSNotFound) {
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
        }
    }];

}



#pragma mark - 文件下载（包含图片 视频  文件等）
- (void)downloadFile:(NSIndexPath *)indexPath
{
    OLYMMessageObject *fileContentModel = [self contentModelAtIndex:indexPath.row];
    
    if (fileContentModel.isMySend || (fileContentModel.isMySend && !fileContentModel.isSyncMessage) ) {
        return;
    }
    //如果没有下载
    if (!fileContentModel.isFileReceive) {
        //普通图片下载
        if (fileContentModel.type == kWCMessageTypeImage || fileContentModel.type == kWCMessageTypeVideo || fileContentModel.type == kWCMessageTypeFile) {
            [self downloadImage:indexPath];
        }
    }
}

- (void)downloadImage:(NSIndexPath *)indexPath
{
    OLYMMessageObject *imageContentModel = [self contentModelAtIndex:indexPath.row];
    [[DownloadMessageFileManager shareInstance]downloadTask:imageContentModel currentChatUserId:self.chatViewModel.currentChatUserId domain:self.chatViewModel.currentChatUserDomain];
}

#pragma mark - 文件下载处理

- (void)finishDownloadNotification:(OLYMMessageObject *)message
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.messageId == %@",message.messageId];
    NSArray *fileterArray = [self.chatViewModel.dataArray filteredArrayUsingPredicate:predicate];
    if (fileterArray && fileterArray.count > 0)
    {
        OLYMMessageObject *messageObj = [fileterArray lastObject];
        WeakSelf(ws);
        [[BDUIViewUpdateQueue shared]updateView:self.tableView block:^{
            NSInteger index = [ws.chatViewModel.dataArray indexOfObject:messageObj];
            messageObj.filePath = message.filePath;
            messageObj.isFileReceive = YES;
            messageObj.isAESEncrypt = YES;
            if (index != NSNotFound)
            {
                [ws.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
            }
        }];
    }
}

- (void)downloadingFileNotification:(OLYMMessageObject *)message
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.messageId == %@",message.messageId];
    NSArray *fileterArray = [self.chatViewModel.dataArray filteredArrayUsingPredicate:predicate];
    if (fileterArray && fileterArray.count > 0)
    {
        OLYMMessageObject *messageObj = [fileterArray lastObject];
        WeakSelf(ws);
        dispatch_async(dispatch_get_main_queue(), ^{
            NSInteger index = [ws.chatViewModel.dataArray indexOfObject:messageObj];
            messageObj.progress = message.progress;
            if (messageObj.fileSize == 0 && message.fileSize > 0) {
                messageObj.fileSize = message.fileSize;
            }
            if (index != NSNotFound)
            {
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
                ChatBaseCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
                cell.downloadProgress = messageObj.progress;
            }
        });
    }
    
}

- (void)faildDownloadFileNotification:(OLYMMessageObject *)message
{
     
}

#pragma mark - GJCFFileUploadManager config
- (void)configFileUploadManager
{
    @weakify(self);
    [[olym_Nofity rac_addObserverForName:MessageFileUploadFinishedNotification object:nil]subscribeNext:^(NSNotification * _Nullable x) {
        @strongify(self);
        [self finishFileUploadNotification:x];
    }];
    [[olym_Nofity rac_addObserverForName:MessageFileUploadFinishedNotification object:nil]subscribeNext:^(NSNotification * _Nullable x) {
        @strongify(self);
        [self faildUploadFileNotification:x];
    }];
}

- (void)addUploadTask:(GJCFFileUploadTask *)task
{
    [[GJCFFileUploadManager shareUploadManager] addTask:task];
}


#pragma mark - 监听下载
- (void)configFileDownloadManager
{
    @weakify(self);
    [[olym_Nofity rac_addObserverForName:MessageFileDownloadingNotification object:nil]subscribeNext:^(NSNotification * _Nullable x) {
        @strongify(self);
        [self downloadingFileNotification:[x object]];
    }];
    [[olym_Nofity rac_addObserverForName:MessageFileDownloadFinishedNotification object:nil]subscribeNext:^(NSNotification * _Nullable x) {
        @strongify(self);
        [self finishDownloadNotification:[x object]];
    }];
    [[olym_Nofity rac_addObserverForName:MessageFileDownloadFailedNotification object:nil]subscribeNext:^(NSNotification * _Nullable x) {
        @strongify(self);
        [self faildDownloadFileNotification:[x object]];
    }];
}


#pragma mark -- 其他
- (OLYMMessageObject *)contentModelAtIndex:(NSInteger)index
{

    OLYMMessageObject *message = [self.chatViewModel.dataArray objectAtIndex:index];
    
    //给每一个object赋值上域名
    message.domain = self.chatViewModel.currentChatUserDomain;
    
    //发送已读给对方
    //阅后即焚和语音必须查看才标记为已读
    [self messageSendReaded:message];

    return message;
}


- (OLYMMessageObject *)contentModelByUploadUniqueIdentifier:(NSString *)uniqueIdentifier
{
    for(OLYMMessageObject *messageObject in self.chatViewModel.dataArray){
      
        if([messageObject.uniqueIdentifier isEqualToString:uniqueIdentifier]){
            return messageObject;
        }
    }
    return nil;
}


- (Class)contentCellAtIndex:(NSInteger)index
{
    if (index > self.chatViewModel.dataArray.count - 1) {
        return nil;
    }
   
    OLYMMessageObject *messageObject = [self contentModelAtIndex:index];
    
    Class resultClass = [ChatFriendConstans classForContentType:messageObject.type isReadBurn:messageObject.isReadburn];
    
    return resultClass;
}


- (NSString *)contentCellIdentifierAtIndex:(NSInteger)index
{
    if (index > self.chatViewModel.dataArray.count - 1) {
        return nil;
    }
    
    /* 分发信息 */
    OLYMMessageObject *messageObject = [self contentModelAtIndex:index];
    
    NSString *resultIdentifier = [ChatFriendConstans identifierForContentType:messageObject.type isReadBurn:messageObject.isReadburn];
    
    return resultIdentifier;
}




#pragma mark - 监听消息到来通知
-(void)addNotifacationObserver{
    @weakify(self);
    
    [[olym_Nofity rac_addObserverForName:kXMPPSendStatusNotifaction object:nil] subscribeNext:^(NSNotification *notification){
        @strongify(self);
        [self newChatReceipt:notification];
    }];
    
    [[olym_Nofity rac_addObserverForName:kDeleteReadburnMessageNotifaction object:nil]subscribeNext:^(NSNotification * _Nullable x) {
        @strongify(self);
        [self handleDeleteReadBurnMsg:x];
    }];
    
    
    [[olym_Nofity rac_addObserverForName:kDeleteMessageHistoryNotifaction object:nil] subscribeNext:^(NSNotification *notification){
        @strongify(self);
        [self.chatViewModel.dataArray removeAllObjects];
        [self.chatViewModel.refreshUI sendNext:nil];
    }];
}


#pragma mark - send readed message
#pragma mark - 发送已读给对方
- (void)messageSendReaded:(OLYMMessageObject *)message
{
    //发送已读给对方
    //阅后即焚和语音必须查看才标记为已读
    if(!message.isGroup && !message.isRead && !message.isMySend && message.type != kWCMessageTypeVoice && !message.isReadburn)
    {
        [self.chatViewModel sendReadedMessage:message];
    }
}

#pragma mark - 刷新消息界面
- (void)doRefreshMessageList:(NSNotification *)notification delay:(NSTimeInterval)delayInSeconds{
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        OLYMMessageObject *currentMessage = notification.object;
        
        NSString *fromUserId = currentMessage.fromUserId;
        if (currentMessage.isGroup && !currentMessage.isMySend) {
            fromUserId = currentMessage.roomId;
        }
        //如果来的消息 跟当前会话的userid 和 domain 一致，才刷新列表
        if(currentMessage && (([fromUserId isEqualToString:self.chatViewModel.currentChatUserId] && [currentMessage.domain isEqualToString:self.chatViewModel.currentChatUserDomain]) || currentMessage.isMySend)){
            
            //防止转发消息到这里来
            if (currentMessage.isMySend && currentMessage.type != kWCMessageTypeReCall)
            {
                if (![currentMessage.toUserId isEqualToString:self.chatViewModel.currentChatUserId])
                {
                        
                        return;
                }
            }
            
            //设置新消息高度
            CGFloat height = [currentMessage heightForContentModel];
            [self.heightDictionary setObject:@(height) forKey:[NSString stringWithFormat:@"%ld",currentMessage.messageNo]];
            
            if(currentMessage.isMySend && currentMessage.uploadFileModel){
                [self uploadFile:currentMessage];
            }
            
            //被禁言，显示提示
            if (currentMessage.isSlience)
            {
                dispatch_async(dispatch_get_main_queue(), ^{

                    [SVProgressHUD showErrorWithStatus:_T(@"你已经被群组禁言")];
                });
            }
            WeakSelf(ws);
            if (!currentMessage.isMySend)
            {
                //如果撤回了，需要删掉之前那条消息
                if (currentMessage.type == kWCMessageTypeReCall)
                {
        
                    NSString *messageId = currentMessage.content;
                    OLYMMessageObject *msg = [OLYMMessageObject fetchMessageByMessageId:messageId inTableByUserId:ws.chatViewModel.currentChatUserId withDomain:ws.chatViewModel.currentChatRoomId];
                    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.messageId == %@",messageId];
                    NSArray *filterArray = [ws.chatViewModel.dataArray filteredArrayUsingPredicate:predicate];
                    if (filterArray && filterArray.count > 0)
                    {
                        NSMutableArray *indexPaths = [NSMutableArray array];
                        for(OLYMMessageObject *message in filterArray)
                        {
                            NSInteger index = [ws.chatViewModel.dataArray indexOfObject:message];
                            [indexPaths addObject:[NSIndexPath indexPathForRow:index inSection:0]];
                        }
                        [[BDUIViewUpdateQueue shared] updateView:ws.tableView block:^{
                            [ws.chatViewModel.dataArray removeObjectsInArray:filterArray];
                            [ws.tableView reloadData];
                        }];
                    }
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[BDUIViewUpdateQueue shared] updateView:ws.tableView block:^{
                        [ws.chatViewModel addNewMessage:currentMessage];
                        [ws.tableView reloadData];
                        NSInteger rows = [ws.tableView numberOfRowsInSection:0];
                        if (rows > 0) {
                            [ws.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:rows - 1 inSection:0]
                                                atScrollPosition:UITableViewScrollPositionBottom
                                                        animated:NO];
                        }
                    }];
                });
            }else
            {
                [[BDUIViewUpdateQueue shared] updateView:self.tableView block:^{
                    [self.chatViewModel addNewMessage:currentMessage];
                    NSIndexPath* toInsert = [NSIndexPath indexPathForRow:[ws.chatViewModel.dataArray count]-1 inSection:0];
                    [self.tableView insertRowsAtIndexPaths:@[toInsert] withRowAnimation:UITableViewRowAnimationNone];
                    [self.tableView scrollToRowAtIndexPath:toInsert atScrollPosition:UITableViewScrollPositionBottom animated:NO];
                    
                }];
            }
        }
    });

        /*  先改成reloadData，保证消息到达,后面再优化   */
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [self.tableView reloadData];
//            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[self.chatViewModel.dataArray count] - 1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
//            
//        });
    
        
        /*
        [self.refreshLock lock];
        
        self.lock = YES;
        
        //设置新消息高度
        CGFloat height = [currentMessage heightForContentModel];
        [self.heightDictionary setObject:@(height) forKey:[NSString stringWithFormat:@"%ld",currentMessage.messageNo]];

        if(currentMessage.isMySend && currentMessage.uploadFileModel){
            [self uploadFile:currentMessage];
        }
        
        WeakSelf(ws);
        dispatch_async(dispatch_get_main_queue(), ^{
            
            StrongSelf(ss);
            //滚动到最后一行
            NSIndexPath *updateIndexPath = [NSIndexPath indexPathForRow:(ss.chatViewModel.dataArray.count - 1) inSection:0];
            
            [UIView performWithoutAnimation:^{
                [ss.tableView beginUpdates];
                [ss.tableView insertRowsAtIndexPaths:@[updateIndexPath] withRowAnimation:UITableViewRowAnimationNone];
                [ss.tableView endUpdates];
            }];
            
            double delayInSeconds = .15;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                
                [ss.tableView scrollToRowAtIndexPath:updateIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
                
                self.lock = NO;
                
                [ss.refreshLock unlock];
                
            });
        });
         */
}

- (void)scrollToBottom
{
    CGPoint bottomOffset = CGPointMake(0, self.tableView.contentSize.height - self.tableView.bounds.size.height);
    if ( bottomOffset.y > 0 ) {
        [self.tableView setContentOffset:bottomOffset animated:YES];
    }
}

- (void)handleDeleteReadBurnMsg:(NSNotification *)notifacation{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
 
        OLYMMessageObject *currentMessage = notifacation.object;
        WeakSelf(ws);
        dispatch_async(dispatch_get_main_queue(), ^{
            StrongSelf(ss);
            if (currentMessage)
            {
                [currentMessage updateReadburnMessage];
                NSUInteger index =  NSNotFound;
                for (OLYMMessageObject *object in ss.chatViewModel.dataArray)
                {
                    if ([currentMessage.messageId isEqualToString:[object messageId]])
                    {
                        index = [ss.chatViewModel.dataArray indexOfObject:object];
                        break;
                    }
                }
                if (index != NSNotFound && index < ss.chatViewModel.dataArray.count)
                {
                    [[BDUIViewUpdateQueue shared]updateView:ws.tableView block:^{
                        [ss.chatViewModel.dataArray removeObjectAtIndex:index];
                        NSIndexPath *deleteIndexPath = [NSIndexPath indexPathForRow:index inSection:0];
                        CGFloat animationDuration = 0.28;
                        [UIView animateWithDuration:animationDuration animations:^{
                            if(currentMessage.isMySend){
                                [ss.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObjects:deleteIndexPath, nil] withRowAnimation:UITableViewRowAnimationRight];
                            }else{
                                [ss.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObjects:deleteIndexPath, nil] withRowAnimation:UITableViewRowAnimationLeft];
                            }
                        }];
                    }];
                    
                    if(ss.chatViewModel.dataArray.count > 0){
                        //更新最近会话列表的显示内容
                        OLYMMessageObject *preMsgObj = [ss.chatViewModel.dataArray objectAtIndex:self.chatViewModel.dataArray.count - 1];
                        if(preMsgObj){
                            [preMsgObj updateLastSend:NO];
                        }
                    }else{
                        [currentMessage setContent:@"您的消息已被焚毁"];
                        [currentMessage setType:kWCMessageTypeText];
                        [currentMessage setIsReadburn:NO];
                        [currentMessage updateLastSend:NO];
                    }
                }
            }
        });

    });
}

#pragma mark - 消息状态回执

- (void)newChatReceipt:(NSNotification *)notifacation {

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        OLYMMessageObject *msg = (OLYMMessageObject *)notifacation.object;
        
        if (msg == nil) {
            return;
        }
        
//        [self.unInQueueMessageArray addObject:msg];
        
        NSInteger index = NSNotFound;
        for (int i = [self.chatViewModel.dataArray count] - 1; i >= 0; i--) {
            OLYMMessageObject *p = [self.chatViewModel.dataArray objectAtIndex:i];
            
            if ([p.messageId isEqualToString:msg.messageId]) {
                
                p.isSend = msg.isSend;
                if(!p.domain)
                {
                    p.domain = self.chatViewModel.currentChatUserDomain;
                }
                [p updateSendStatus:p.isSend];

                index = i;
                break;
            }
        }
        
        if (index == NSNotFound)
        {
            return;
        }
        WeakSelf(ws);
        dispatch_async(dispatch_get_main_queue(), ^{
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
            ChatBaseCell *cell = [ws.tableView cellForRowAtIndexPath:indexPath];
            if (cell)
            {
                [cell updateSendStatus:msg.isSend];
            }
        });
    });
    /*
    WeakSelf(ws);
    dispatch_async(dispatch_get_main_queue(), ^{
        
        StrongSelf(ss);
        
        NSInteger index = NSNotFound;
        for (int i = [ss.chatViewModel.dataArray count] - 1; i >= 0; i--) {
            OLYMMessageObject *p = [ss.chatViewModel.dataArray objectAtIndex:i];
            
            if ([p.messageId isEqualToString:msg.messageId]) {
     
                p.isSend = msg.isSend;
                
                [p updateSendStatus:p.isSend];
                index = i;
                break;
            }
        }

        if(ss.lock)
        {
            [self.unInQueueMessageArray addObject:msg];
            return;
        }
        
        [ss.refreshLock lock];

        
        self.lock = YES;
        
        double delayInSeconds = 0.1;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            
            if (index != NSNotFound)
            {
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
                [ss.tableView beginUpdates];
                [ss.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObjects:indexPath, nil] withRowAnimation:UITableViewRowAnimationNone];
                [ss.tableView endUpdates];
            }
            
            self.lock = NO;
            [ss.refreshLock unlock];
        });
    });
     */
}


- (void)dealloc
{
    [self removeObserver];
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
}

@end
