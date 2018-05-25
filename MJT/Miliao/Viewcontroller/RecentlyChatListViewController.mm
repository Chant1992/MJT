//
//  RecentlyChatListViewController.m
//  MJT_APP
//
//  Created by Donny on 2017/9/11.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "RecentlyChatListViewController.h"
#import "OLYMUserObject.h"
#import "ContactFriendCell.h"
#import "RecentlyViewModel.h"
#import "OLYMMessageObject.h"
#import "OLYMListViewModel.h"
#import "HeaderImageUtils.h"
#import "UIImageView+SDWebImage.h"
#import "OLYMAESCrypt.h"
#import "ForwardAlertView.h"
#import "UIImage+Image.h"
#import "CreateNewChatViewController.h"
#import "UISearchBar+LeftPlaceholder.h"
#import "AlertViewManager.h"
#import "OrganizationUtility.h"

@interface RecentlyChatListViewController ()<UITableViewDataSource,UITableViewDelegate,UISearchBarDelegate,UISearchControllerDelegate,UISearchResultsUpdating,CreateNewChatViewControllerDelegate>

// 返回按钮
@property (nonatomic, strong) UIBarButtonItem *backBtn;


@property (nonatomic, strong) RecentlyViewModel *recentlyViewModel;

@property (nonatomic, strong) UISearchController *searchCon;

@property (nonatomic, strong) UIButton *mutiButton;

@end

@implementation RecentlyChatListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)olym_addSubviews{
    self.navigationItem.leftBarButtonItem = self.backBtn;
    
    [self.view addSubview:self.tableView];
#if MJTDEV
    self.definesPresentationContext = YES;
    self.tableView.tableHeaderView = self.searchCon.searchBar;
    [self setRightButtonWithTitle:_T(@"多选")];
#endif
    WeakSelf(weakSelf);
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        if (@available(iOS 11, *)) {
            make.edges.mas_equalTo(weakSelf.view.safeAreaInsets);
        }else{
            make.edges.mas_equalTo(weakSelf.view);
        }
    }];
}

- (void)olym_bindViewModel{
    @weakify(self);
    //禁言
    [[olym_Nofity rac_addObserverForName:kgroupSlienceChatNotification object:nil]subscribeNext:^(NSNotification *notification) {
        @strongify(self);
        OLYMUserObject *user = [notification object];
        for (OLYMUserObject *userObj in self.recentlyViewModel.dataArray)
        {
            if ([user.domain isEqualToString:userObj.domain] && [user.userId isEqualToString:userObj.userId])
            {
                userObj.isSilence = user.isSilence;
                userObj.talkTime = user.talkTime;
                break;
            }
        }
    }];

    //多选转发
    [[olym_Nofity rac_addObserverForName:kTranspondMultiMessageNotification object:nil] subscribeNext:^(NSNotification * _Nullable x) {
        @strongify(self);
        
        NSArray *selecteds = x.object;
        //先将在组织架构中选的人加入当前控制器的已选数组
        [self.selectionArray addObjectsFromArray:selecteds];
        //发送给多人
        [self sendToMultiUser];

    }];
    
    [[olym_Nofity rac_addObserverForName:kTranspondSingleMessageNotification object:nil] subscribeNext:^(NSNotification * _Nullable x) {
        @strongify(self);
        
        NSArray *selecteds = x.object;
        OLYMUserObject *userObj = selecteds[0];
        NSString *filePath = self.messageObj.filePath;
        
        switch (self.messageObj.type) {
            case kWCMessageTypeText:
            {
                
                ForwardAlertView *forwardAlertView = [[ForwardAlertView alloc]initWithTitle:userObj.userNickname images:@[[UIImage imageNamed:@"default_head"]] content:self.messageObj.content contentType:Content_Text buttonHandler:^(NSInteger buttonClickIndex) {
                    if (buttonClickIndex == 1)
                    {
                        [self.recentlyViewModel transpondTextMessage:self.messageObj.content filePath:self.messageObj.filePath isAppoint:self.messageObj.isAppoint  toUser:userObj];
                        [self back];
                        [SVProgressHUD showSuccessWithStatus:_T(@"转发成功")];
                        
                        [olym_Nofity postNotificationName:kTranspondMultiMessageSucceedNotification object:nil];
                    }
                    
                    if (buttonClickIndex == 0){
                        
                        //点击取消的时需要移除已选的组织架构的人
                        [self.selectionArray removeObjectsInArray:[OrganizationUtility sharedOrganizationUtility].selectedArray];
                    }
                }];
                [forwardAlertView show];
            }
                break;
            case kWCMessageTypeImage:
            {
                if (filePath == nil)
                { 
                    
                    [SVProgressHUD showErrorWithStatus:_T(@"转发图片出错")];
                }
                filePath = [[olym_FileCenter documentPrefix]stringByAppendingPathComponent:filePath];
                if (![FileCenter fileExistAt:filePath])
                {
                    [SVProgressHUD showErrorWithStatus:_T(@"转发图片不存在")];
                }
                NSString *fileName = [self.messageObj.filePath lastPathComponent];
                NSString *toPath = [NSString stringWithFormat:@"%@/%ld%@",[olym_FileCenter getMyFileLocalPath:userObj.userId],(long)[[NSDate date]timeIntervalSince1970],fileName];
                if (self.messageObj.isAESEncrypt)
                {
                    [FileCenter copyFileAtPath:filePath toPath:toPath];
                }else
                {
                    //文件未进行AES加密，转发的文件需要加密保存
                    [OLYMAESCrypt encryptFileData:[NSData dataWithContentsOfFile:filePath] saveFilePath:toPath];
                }
                
                ForwardAlertView *forwardAlertView = [[ForwardAlertView alloc]initWithTitle:userObj.userNickname images:@[[UIImage imageNamed:@"default_head"]] content:filePath contentType:Content_Image buttonHandler:^(NSInteger buttonClickIndex) {
                    if (buttonClickIndex == 1)
                    {
                        [self.recentlyViewModel transpondImage:toPath imageWidth:self.messageObj.imageWidth imageHeight:self.messageObj.imageHeight thumbnail:self.messageObj.thumbnail toUser:userObj];
                        [self back];
                        [SVProgressHUD showSuccessWithStatus:_T(@"转发成功")];
                        
                        [olym_Nofity postNotificationName:kTranspondMultiMessageSucceedNotification object:nil];
                    }
                    
                    if (buttonClickIndex == 0){
                        
                        //点击取消的时需要移除已选的组织架构的人
                        [self.selectionArray removeObjectsInArray:[OrganizationUtility sharedOrganizationUtility].selectedArray];
                    }
                }];
                [forwardAlertView show];
            }
                break;
            case kWCMessageTypeVideo:
            {
                if (filePath == nil)
                {
                    
                    [SVProgressHUD showErrorWithStatus:_T(@"转发的视频出错")];
                }
                filePath = [[olym_FileCenter documentPrefix]stringByAppendingPathComponent:filePath];
                if (![FileCenter fileExistAt:filePath])
                {
                    
                    [SVProgressHUD showErrorWithStatus:_T(@"转发的视频不存在")];
                }
                NSString *fileName = [self.messageObj.filePath lastPathComponent];
                NSString *toPath = [NSString stringWithFormat:@"%@/%ld%@",[olym_FileCenter getMyFileLocalPath:userObj.userId],(long)[[NSDate date]timeIntervalSince1970],fileName];
                if (self.messageObj.isAESEncrypt)
                {
                    [FileCenter copyFileAtPath:filePath toPath:toPath];
                }else
                {
                    //文件未进行AES加密，转发的文件需要加密保存
                    [OLYMAESCrypt encryptFileData:[NSData dataWithContentsOfFile:filePath] saveFilePath:toPath];
                }
                
                ContentType contenttype = Content_Text;
                id conent = [NSString stringWithFormat:_T(@"[视频]")];
                if (self.messageObj.thumbnail)
                {
                    contenttype = Content_Image;
                    conent = [UIImage imageFromBase64String:self.messageObj.thumbnail];
                }
                ForwardAlertView *forwardAlertView = [[ForwardAlertView alloc]initWithTitle:userObj.userNickname images:@[[UIImage imageNamed:@"default_head"]] content:conent contentType:contenttype buttonHandler:^(NSInteger buttonClickIndex) {
                    if (buttonClickIndex == 1)
                    {
                        [self.recentlyViewModel transpondVideoMessage:toPath fileSize:self.messageObj.fileSize thumbnail:self.messageObj.thumbnail toUser:userObj];
                        [self back];
                        [SVProgressHUD showSuccessWithStatus:_T(@"转发成功")];
                        
                        [olym_Nofity postNotificationName:kTranspondMultiMessageSucceedNotification object:nil];
                    }
                    
                    if (buttonClickIndex == 0){
                        
                        //点击取消的时需要移除已选的组织架构的人
                        [self.selectionArray removeObjectsInArray:[OrganizationUtility sharedOrganizationUtility].selectedArray];
                    }
                }];
                [forwardAlertView show];
                
            }
                break;
            case kWCMessageTypeFile:
            {
                if (filePath == nil)
                {
                    
                    [SVProgressHUD showErrorWithStatus:_T(@"转发文件出错")];
                }
                filePath = [[olym_FileCenter documentPrefix]stringByAppendingPathComponent:filePath];
                if (![FileCenter fileExistAt:filePath])
                {
                    
                    [SVProgressHUD showErrorWithStatus:_T(@"转发文件不存在")];
                }
                NSString *fileName = self.messageObj.fileName;
                NSString *toPath = [NSString stringWithFormat:@"%@/%ld%@",[olym_FileCenter getMyFileLocalPath:userObj.userId],(long)[[NSDate date]timeIntervalSince1970],fileName];
                
                if (self.messageObj.isAESEncrypt)
                {
                    [FileCenter copyFileAtPath:filePath toPath:toPath];
                }else
                {
                    //文件未进行AES加密，转发的文件需要加密保存
                    [OLYMAESCrypt encryptFileData:[NSData dataWithContentsOfFile:filePath] saveFilePath:toPath];
                }
                
                ForwardAlertView *forwardAlertView = [[ForwardAlertView alloc]initWithTitle:userObj.userNickname images:@[[UIImage imageNamed:@"default_head"]] content:[NSString stringWithFormat:_T(@"[文件] %@"),fileName] contentType:Content_Text buttonHandler:^(NSInteger buttonClickIndex) {
                    if (buttonClickIndex == 1)
                    {
                        [self.recentlyViewModel transpondFileMessage:toPath fileSize:self.messageObj.fileSize fileName:fileName toUser:userObj];
                        [self back];
                        [SVProgressHUD showSuccessWithStatus:_T(@"转发成功")];
                        
                        [olym_Nofity postNotificationName:kTranspondMultiMessageSucceedNotification object:nil];
                    }
                    
                    if (buttonClickIndex == 0){
                        
                        //点击取消的时需要移除已选的组织架构的人
                        [self.selectionArray removeObjectsInArray:[OrganizationUtility sharedOrganizationUtility].selectedArray];
                    }
                }];
                [forwardAlertView show];
                
            }
                break;
            default:
                break;
        }

    }];
}

- (void)olym_layoutNavigation{
    [self setStrNavTitle:_T(@"选择一个聊天")];
}

- (void)back
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)leftButtonPressed:(UIButton *)sender
{
    self.navigationItem.leftBarButtonItem = self.backBtn;
    [self setRightButtonWithTitle:@"多选"];
    [self.tableView setEditing:NO];
    [self.selectionArray removeAllObjects];
    [self.mutiButton setTitle:@"完成" forState:UIControlStateNormal];
}

- (void)rightButtonPressed:(UIButton *)sender
{
    [self setLeftButtonWithTitle:@"取消"];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:self.mutiButton];
    self.navigationItem.rightBarButtonItem.enabled = NO;
    [self.tableView setEditing:YES];
}

- (void)sendToMultiUser
{
    if (self.forwardMessages)
    {
        ForwardAlertView *forwardAlertView = [[ForwardAlertView alloc]initWithTitle:nil images:self.selectionArray content:[NSString stringWithFormat:_T(@"共%ld条消息"),self.forwardMessages.count] contentType:Content_Text buttonHandler:^(NSInteger buttonClickIndex) {
            if (buttonClickIndex == 1)
            {
                for (OLYMUserObject *userObj in self.selectionArray)
                {
                    [self.recentlyViewModel forwardMessages:self.forwardMessages toUser:userObj];
                    
                }
                [self back];
                [SVProgressHUD showSuccessWithStatus:_T(@"转发成功")];
            }
        }];
        [forwardAlertView show];
        return;
    }else
    {
        NSString *filePath = self.messageObj.filePath;
        ContentType contentType = Content_Text;
        id content = nil;
        switch (self.messageObj.type) {
            case kWCMessageTypeText:
            {
                content = self.messageObj.content;
            }
                break;
            case kWCMessageTypeImage:
            {
                contentType = Content_Image;
                content = [[olym_FileCenter documentPrefix]stringByAppendingPathComponent:filePath];
            }
                break;
            case kWCMessageTypeVideo:
            {
                if (filePath == nil)
                {
                    
                    [SVProgressHUD showErrorWithStatus:_T(@"转发的视频出错")];
                    return;
                }
                filePath = [[olym_FileCenter documentPrefix]stringByAppendingPathComponent:filePath];
                if (![FileCenter fileExistAt:filePath])
                {
                    
                    [SVProgressHUD showErrorWithStatus:_T(@"转发的视频不存在")];
                    return;
                }
                contentType = Content_Text;
                content = [NSString stringWithFormat:_T(@"[视频]")];
                if (self.messageObj.thumbnail)
                {
                    contentType = Content_Image;
                    content = [UIImage imageFromBase64String:self.messageObj.thumbnail];
                }
            }
                break;
            case kWCMessageTypeFile:
            {
                if (filePath == nil)
                {
                    
                    [SVProgressHUD showErrorWithStatus:_T(@"转发文件出错")];
                    break;
                }
                filePath = [[olym_FileCenter documentPrefix]stringByAppendingPathComponent:filePath];
                if (![FileCenter fileExistAt:filePath])
                {
                    
                    [SVProgressHUD showErrorWithStatus:_T(@"转发文件不存在")];
                    break;
                }
                NSString *fileName = self.messageObj.fileName;
                content = [NSString stringWithFormat:_T(@"[文件] %@"),fileName];
            }
                break;
                default:
                break;
        }
        
        
        ForwardAlertView *forwardAlertView = [[ForwardAlertView alloc]initWithTitle:nil images:self.selectionArray content:content contentType:contentType buttonHandler:^(NSInteger buttonClickIndex) {
            if (buttonClickIndex == 1)
            {
                for (OLYMUserObject *userObj in self.selectionArray)
                {
                    [self.recentlyViewModel forwardMessage:self.messageObj toUser:userObj];
                }
                [self back];
                [SVProgressHUD showSuccessWithStatus:_T(@"转发成功")];
                [olym_Nofity postNotificationName:kTranspondMultiMessageSucceedNotification object:nil];
            }
            
            if (buttonClickIndex == 0){
                
                //点击取消的时需要移除已选的组织架构的人
                [self.selectionArray removeObjectsInArray:[OrganizationUtility sharedOrganizationUtility].selectedArray];
            }
        }];
        [forwardAlertView show];

    }
}

- (void)changeMultiButtonState
{
    if (self.selectionArray.count > 0)
    {
        [self.mutiButton setTitle:[NSString stringWithFormat:@"完成(%ld)",self.selectionArray.count] forState:UIControlStateNormal];
        self.navigationItem.rightBarButtonItem.enabled = YES;
        _mutiButton.alpha = 1.0;
    }else
    {
        [self.mutiButton setTitle:@"完成" forState:UIControlStateNormal];
        self.navigationItem.rightBarButtonItem.enabled = NO;
        _mutiButton.alpha = 0.5;
    }
    [_mutiButton sizeToFit];
}

#pragma mark - CreateNewChatViewControllerDelegate
- (void)createNewChatControllerDidSelectedUsers:(NSArray *)selectedUsers
{
    [self.selectionArray addObjectsFromArray:selectedUsers];
    [self changeMultiButtonState];
}



#pragma mark - <------------------- UITableViewDelegate ------------------->
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    
    OLYMUserObject *userObj;
#if MJTDEV
    if (self.tableView.editing)
    {
        if (!self.searchCon.active)
        {
            if (indexPath.section == 0 && indexPath.row == 0)
            {
                //跳转到创建新的聊天
                CreateNewChatViewController *con = [[CreateNewChatViewController alloc]init];
                con.forwardMessage = self.messageObj;
                con.forwardMessages = self.forwardMessages;
                con.delegate = self;
                con.multiSelect = YES;
                con.selectedUsers = self.selectionArray;
                [self.navigationController pushViewController:con animated:YES];

                return;
            }
        }
        if (self.selectionArray.count >= 9)
        {
            [AlertViewManager alertWithTitle:_T(@"最多只能选择9个聊天")];
            [self.tableView deselectRowAtIndexPath:indexPath animated:NO];

            return;
        }
        userObj = [self.recentlyViewModel.dataArray objectAtIndex:indexPath.row];
        if (![self.selectionArray containsObject:userObj])
        {
            [self.selectionArray addObject:userObj];
            
        }
        [self changeMultiButtonState];
        return;
    }else
    {
        if (!self.searchCon.active)
        {
            if (indexPath.section == 0)
            {
                //跳转到创建新的聊天
                CreateNewChatViewController *con = [[CreateNewChatViewController alloc]init];
                con.forwardMessage = self.messageObj;
                con.forwardMessages = self.forwardMessages;
                [self.navigationController pushViewController:con animated:YES];
                return;
            } else
            {
                userObj = [self.recentlyViewModel.dataArray objectAtIndex:indexPath.row];
            }
        }else
        {
            [self.searchCon.searchBar resignFirstResponder];
            userObj = [self.recentlyViewModel.dataArray objectAtIndex:indexPath.row];
        }
    }
#else
    userObj = [self.recentlyViewModel.dataArray objectAtIndex:indexPath.row];
#endif
    
#if MJTDEV
    if (self.forwardMessages)
    {
        ForwardAlertView *forwardAlertView = [[ForwardAlertView alloc]initWithTitle:userObj.userNickname images:@[userObj] content:[NSString stringWithFormat:_T(@"共%ld条消息"),self.forwardMessages.count] contentType:Content_Text buttonHandler:^(NSInteger buttonClickIndex) {
            if (buttonClickIndex == 1)
            {
                [self.recentlyViewModel forwardMessages:self.forwardMessages toUser:userObj];
                [self back];
                [SVProgressHUD showSuccessWithStatus:_T(@"转发成功")];
            }
        }];
        [forwardAlertView show];
        return;
    }
#endif
    
    NSString *filePath = self.messageObj.filePath;

    switch (self.messageObj.type) {
        case kWCMessageTypeText:
        {
#if MJTDEV
            ContactFriendCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            ForwardAlertView *forwardAlertView = [[ForwardAlertView alloc]initWithTitle:userObj.userNickname images:@[cell.iconView.image] content:self.messageObj.content contentType:Content_Text buttonHandler:^(NSInteger buttonClickIndex) {
                if (buttonClickIndex == 1)
                {
                    [self.recentlyViewModel transpondTextMessage:self.messageObj.content filePath:self.messageObj.filePath isAppoint:self.messageObj.isAppoint  toUser:userObj];
                    [self back];
                    [SVProgressHUD showSuccessWithStatus:_T(@"转发成功")];
                }
            }];
            [forwardAlertView show];
#else
            [self.recentlyViewModel transpondTextMessage:self.messageObj.content filePath:self.messageObj.filePath isAppoint:self.messageObj.isAppoint  toUser:userObj];
#endif
        }
            break;
        case kWCMessageTypeImage:
        {
            if (filePath == nil)
            { 

                [SVProgressHUD showErrorWithStatus:_T(@"转发图片出错")];
            }
            filePath = [[olym_FileCenter documentPrefix]stringByAppendingPathComponent:filePath];
            if (![FileCenter fileExistAt:filePath])
            {
                [SVProgressHUD showErrorWithStatus:_T(@"转发图片不存在")];
            }
            NSString *fileName = [self.messageObj.filePath lastPathComponent];
            NSString *toPath = [NSString stringWithFormat:@"%@/%ld%@",[olym_FileCenter getMyFileLocalPath:userObj.userId],(long)[[NSDate date]timeIntervalSince1970],fileName];
            if (self.messageObj.isAESEncrypt)
            {
                [FileCenter copyFileAtPath:filePath toPath:toPath];
            }else
            {
                //文件未进行AES加密，转发的文件需要加密保存
                [OLYMAESCrypt encryptFileData:[NSData dataWithContentsOfFile:filePath] saveFilePath:toPath];
            }
#if MJTDEV
            ContactFriendCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            ForwardAlertView *forwardAlertView = [[ForwardAlertView alloc]initWithTitle:userObj.userNickname images:@[cell.iconView.image] content:filePath contentType:Content_Image buttonHandler:^(NSInteger buttonClickIndex) {
                if (buttonClickIndex == 1)
                {
                    [self.recentlyViewModel transpondImage:toPath imageWidth:self.messageObj.imageWidth imageHeight:self.messageObj.imageHeight thumbnail:self.messageObj.thumbnail toUser:userObj];
                    [self back];
                    [SVProgressHUD showSuccessWithStatus:_T(@"转发成功")];
                }
            }];
            [forwardAlertView show];
#else
            [self.recentlyViewModel transpondImage:toPath imageWidth:self.messageObj.imageWidth imageHeight:self.messageObj.imageHeight thumbnail:self.messageObj.thumbnail toUser:userObj];
#endif
        }
            break;
        case kWCMessageTypeVideo:
        {
            if (filePath == nil)
            {

                [SVProgressHUD showErrorWithStatus:_T(@"转发的视频出错")];
            }
            filePath = [[olym_FileCenter documentPrefix]stringByAppendingPathComponent:filePath];
            if (![FileCenter fileExistAt:filePath])
            {

                [SVProgressHUD showErrorWithStatus:_T(@"转发的视频不存在")];
            }
            NSString *fileName = [self.messageObj.filePath lastPathComponent];
            NSString *toPath = [NSString stringWithFormat:@"%@/%ld%@",[olym_FileCenter getMyFileLocalPath:userObj.userId],(long)[[NSDate date]timeIntervalSince1970],fileName];
            if (self.messageObj.isAESEncrypt)
            {
                [FileCenter copyFileAtPath:filePath toPath:toPath];
            }else
            {
                //文件未进行AES加密，转发的文件需要加密保存
                [OLYMAESCrypt encryptFileData:[NSData dataWithContentsOfFile:filePath] saveFilePath:toPath];
            }
#if MJTDEV
            ContactFriendCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            ContentType contenttype = Content_Text;
            id conent = [NSString stringWithFormat:_T(@"[视频]")];
            
            if (self.messageObj.thumbnail)
            {
                contenttype = Content_Image;
                conent = [UIImage imageFromBase64String:self.messageObj.thumbnail];
            }
            ForwardAlertView *forwardAlertView = [[ForwardAlertView alloc]initWithTitle:userObj.userNickname images:@[cell.iconView.image] content:conent contentType:contenttype buttonHandler:^(NSInteger buttonClickIndex) {
                if (buttonClickIndex == 1)
                {
                    [self.recentlyViewModel transpondVideoMessage:toPath fileSize:self.messageObj.fileSize thumbnail:self.messageObj.thumbnail toUser:userObj];
                    [self back];
                    [SVProgressHUD showSuccessWithStatus:_T(@"转发成功")];
                }
            }];
            [forwardAlertView show];
#else
            [self.recentlyViewModel transpondVideoMessage:toPath fileSize:self.messageObj.fileSize thumbnail:self.messageObj.thumbnail toUser:userObj];
#endif

        }
            break;
        case kWCMessageTypeFile:
        {
            if (filePath == nil)
            {

                [SVProgressHUD showErrorWithStatus:_T(@"转发文件出错")];
            }
            filePath = [[olym_FileCenter documentPrefix]stringByAppendingPathComponent:filePath];
            if (![FileCenter fileExistAt:filePath])
            {

                [SVProgressHUD showErrorWithStatus:_T(@"转发文件不存在")];
            }
            NSString *fileName = self.messageObj.fileName;
            NSString *toPath = [NSString stringWithFormat:@"%@/%ld%@",[olym_FileCenter getMyFileLocalPath:userObj.userId],(long)[[NSDate date]timeIntervalSince1970],fileName];

            if (self.messageObj.isAESEncrypt)
            {
                [FileCenter copyFileAtPath:filePath toPath:toPath];
            }else
            {
                //文件未进行AES加密，转发的文件需要加密保存
                [OLYMAESCrypt encryptFileData:[NSData dataWithContentsOfFile:filePath] saveFilePath:toPath];
            }
#if MJTDEV
            ContactFriendCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            ForwardAlertView *forwardAlertView = [[ForwardAlertView alloc]initWithTitle:userObj.userNickname images:@[cell.iconView.image] content:[NSString stringWithFormat:_T(@"[文件] %@"),fileName] contentType:Content_Text buttonHandler:^(NSInteger buttonClickIndex) {
                if (buttonClickIndex == 1)
                {
                    [self.recentlyViewModel transpondFileMessage:toPath fileSize:self.messageObj.fileSize fileName:fileName toUser:userObj];
                    [self back];
                    [SVProgressHUD showSuccessWithStatus:_T(@"转发成功")];
                }
            }];
            [forwardAlertView show];
#else
            [self.recentlyViewModel transpondFileMessage:toPath fileSize:self.messageObj.fileSize fileName:fileName toUser:userObj];
#endif

        }
            break;
        default:
            break;
    }
#if MJTDEV
#else
    [self back];
    [SVProgressHUD showSuccessWithStatus:_T(@"转发成功")];
#endif
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.tableView.editing)
    {
        if (!self.searchCon.active)
        {
            if (indexPath.section == 0 && indexPath.row == 0)
            {
                return;
            }
        }
        OLYMUserObject *userObj = [self.recentlyViewModel.dataArray objectAtIndex:indexPath.row];
        [self.selectionArray removeObject:userObj];
        [self changeMultiButtonState];
    }
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    NSString *searchStr = _searchCon.searchBar.text;
    [self.recentlyViewModel.dataArray removeAllObjects];
    if (searchStr && ![searchStr isEqualToString:@""]) {
        NSArray *tmpResults = [self.recentlyViewModel queryWithKeyword:searchStr];
        if(tmpResults)
        {
            [self.recentlyViewModel.dataArray addObjectsFromArray:tmpResults];
        }
    }
    
    [self.tableView reloadData];
    [self hightlightSelectUsers];
}


- (void)willPresentSearchController:(UISearchController *)searchController
{
    self.recentlyViewModel.previousArray = [self.recentlyViewModel.dataArray mutableCopy];
}
- (void)didDismissSearchController:(UISearchController *)searchController
{
    [self.recentlyViewModel.dataArray removeAllObjects];
    [self.recentlyViewModel.dataArray addObjectsFromArray:self.recentlyViewModel.previousArray];
    [self.tableView reloadData];
    [self hightlightSelectUsers];

}


- (void)hightlightSelectUsers
{
    for (OLYMUserObject *selectedUserObj in self.selectionArray)
    {
        for (OLYMUserObject *userObj in self.recentlyViewModel.dataArray)
        {
            if ([selectedUserObj isEqual:userObj])
            {
                NSInteger index = [self.recentlyViewModel.dataArray indexOfObject:userObj];
                if (!self.searchCon.active)
                {
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:1];
                    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
                }else
                {
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
                    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
                }
            }
        }
    }
}
#pragma mark - <------------------- UITableViewDateSource ------------------->

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
#if MJTDEV
    if(section == 1){
        //自定义Header标题
        UIView* myView = [[UIView alloc] init];
        myView.backgroundColor = OLYMHEXCOLOR(0xf2f2f2);
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 90, 22)];
        titleLabel.textColor= [UIColor blackColor];
        
        titleLabel.text = _T(@"最近聊天");
        titleLabel.font = [UIFont systemFontOfSize:14];
        titleLabel.textColor = [UIColor lightGrayColor];
        [myView  addSubview:titleLabel];
        
        return myView;
    }
#else
    if(section == 0){
        //自定义Header标题
        UIView* myView = [[UIView alloc] init];
        myView.backgroundColor = OLYMHEXCOLOR(0xf2f2f2);
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 90, 22)];
        titleLabel.textColor= [UIColor blackColor];
        
        titleLabel.text = _T(@"最近聊天");
        titleLabel.font = [UIFont systemFontOfSize:14];
        titleLabel.textColor = [UIColor lightGrayColor];
        [myView  addSubview:titleLabel];
        
        return myView;
    }
#endif
    
    return nil;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
#if MJTDEV
    if (self.searchCon.active)
    {
        return 70.0f;
    }else
    {
        if (indexPath.section == 0) {
            return 50.0f;
        }
    }
#endif
    return 70.0f;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
#if MJTDEV
    if (!self.searchCon.active)
    {
        if (section == 1) {
            return 22;
        }
    }
#else
    return 22;
#endif
    return 0;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    
#if MJTDEV
    if (self.searchCon.active)
    {
        return 1;
    }else
    {
        return 2;
    }
#else
    return 1;
#endif
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
#if MJTDEV
    if (self.searchCon.active)
    {
        return self.recentlyViewModel.dataArray.count;
    }else
    {
        if (section == 0) {
            return 1;
        } else {
            return self.recentlyViewModel.dataArray.count;
        }
    }
#else
    return self.recentlyViewModel.dataArray.count;
#endif

}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    ContactFriendCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ContactFriendCellIdentify" forIndexPath:indexPath];
    cell.addButton.hidden = YES;
#if MJTDEV
    if (!self.searchCon.active)
    {
        if (indexPath.section == 0) {
            cell.textLabel.text = _T(@"创建新的聊天");
            cell.nickNameLabel.hidden = YES;
            cell.iconView.hidden = YES;
        } else {
            OLYMUserObject *user = (OLYMUserObject*) [self.recentlyViewModel.dataArray objectAtIndex:indexPath.row];
            NSString *remarkName = user.userNickname;
            cell.nickNameLabel.hidden = NO;
            cell.iconView.hidden = NO;
            cell.textLabel.text = @"";

            if(remarkName && ![remarkName isEqualToString:@""]){
                cell.nickNameLabel.text = remarkName;
            }else{
                cell.nickNameLabel.text = user.telephone;
            }
            if (user.roomFlag == 1)
            {
                //群聊
                [cell.iconView setImage:[UIImage imageNamed:@"chat_groups_header"]];
            }else
            {
                NSString *userHeaderUrl =  [HeaderImageUtils getHeaderImageUrl:user.userId withDomain:user.domain];
                [cell.iconView setImageUrl:userHeaderUrl withDefault:@"chat_groups_header"];
            }
        }
    }else
    {
        OLYMUserObject *user = (OLYMUserObject*) [self.recentlyViewModel.dataArray objectAtIndex:indexPath.row];
        NSString *remarkName = user.userNickname;
        cell.nickNameLabel.hidden = NO;
        cell.iconView.hidden = NO;
        cell.textLabel.text = @"";

        if(remarkName && ![remarkName isEqualToString:@""]){
            cell.nickNameLabel.text = remarkName;
        }else{
            cell.nickNameLabel.text = user.telephone;
        }
        if (user.roomFlag == 1)
        {
            //群聊
            [cell.iconView setImage:[UIImage imageNamed:@"chat_groups_header"]];
        }else
        {
            NSString *userHeaderUrl =  [HeaderImageUtils getHeaderImageUrl:user.userId withDomain:user.domain];
            [cell.iconView setImageUrl:userHeaderUrl withDefault:@"chat_groups_header"];
        }
    }
#else
    OLYMUserObject *user = (OLYMUserObject*) [self.recentlyViewModel.dataArray objectAtIndex:indexPath.row];
    NSString *remarkName = user.userNickname;
    
    if(remarkName && ![remarkName isEqualToString:@""]){
        cell.nickNameLabel.text = remarkName;
    }else{
        cell.nickNameLabel.text = user.telephone;
    }
    if (user.roomFlag == 1)
    {
        //群聊
        [cell.iconView setImage:[UIImage imageNamed:@"chat_groups_header"]];
    }else
    {
        NSString *userHeaderUrl =  [HeaderImageUtils getHeaderImageUrl:user.userId withDomain:user.domain];
        [cell.iconView setImageUrl:userHeaderUrl withDefault:@"chat_groups_header"];
    }
#endif
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!self.searchCon.active) {
        if (indexPath.section == 0 && indexPath.row == 0) {
            return NO;
        }
        return YES;
    }
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return (UITableViewCellEditingStyle)(UITableViewCellEditingStyleInsert | UITableViewCellEditingStyleDelete);
}

#pragma mark - UISearchBarDelegate
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [searchBar setCenterdPlaceholder];
}

#pragma mark - <------------------- Getter/Setter ------------------->
-(UITableView *)tableView{
    
    if (!_tableView) {
        
        _tableView = [[UITableView alloc]init];
        
        //多余的分割线不显示出来
        _tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
        
        _tableView.backgroundColor = kTableViewBackgroundColor;
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.allowsSelectionDuringEditing = YES;

        [_tableView registerClass:[ContactFriendCell class] forCellReuseIdentifier:@"ContactFriendCellIdentify"];
        [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"UITableViewCellIdentify"];
    }
    
    return _tableView;
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


- (RecentlyViewModel *)recentlyViewModel
{
    if (!_recentlyViewModel)
    {
        _recentlyViewModel = [[RecentlyViewModel alloc]init];
    }
    return _recentlyViewModel;
}


- (UISearchController *)searchCon {
    
    if (!_searchCon) {
        
        _searchCon = [[UISearchController alloc] initWithSearchResultsController:nil];
        // SearchBar configuration
        _searchCon.searchBar.frame = CGRectMake(0, 0, CGRectGetWidth([UIScreen mainScreen].bounds), 44.0f);
        _searchCon.searchBar.delegate = self;
        [_searchCon.searchBar setCenterdPlaceholder];
        _searchCon.searchBar.placeholder = _T(@"搜索");
        [_searchCon.searchBar setBackgroundImage:[UIImage new]];
        [_searchCon.searchBar setAutocapitalizationType:UITextAutocapitalizationTypeNone];
        
        // SearchController configuration
        //        _searchCon.searchResultsUpdater = self;
        // 背景变暗色
        _searchCon.dimsBackgroundDuringPresentation = NO;
        // 背景变模糊
        _searchCon.obscuresBackgroundDuringPresentation = NO;
        //隐藏导航栏
        _searchCon.hidesNavigationBarDuringPresentation = YES;
        _searchCon.delegate = self;
        _searchCon.searchResultsUpdater = self;
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


- (UIButton *)mutiButton
{
    if (!_mutiButton)
    {
        _mutiButton = [[UIButton alloc]init];
        _mutiButton.titleLabel.font = [UIFont systemFontOfSize:16];
        [_mutiButton setTitleColor:Global_Theme_Color forState:UIControlStateNormal];
        [_mutiButton addTarget:self action:@selector(sendToMultiUser) forControlEvents:UIControlEventTouchUpInside];
        [_mutiButton setTitle:_T(@"完成") forState:UIControlStateNormal];
        [_mutiButton sizeToFit];
        _mutiButton.alpha = 0.5;
    }
    return _mutiButton;
}


- (NSMutableArray *)selectionArray
{
    if (!_selectionArray)
    {
        _selectionArray = [NSMutableArray array];
    }
    return _selectionArray;
}

@end
