//
//  CreateNewChatViewController.m
//  MJT_APP
//
//  Created by Donny on 2017/12/27.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "CreateNewChatViewController.h"
#import "CreateNewChatListView.h"
#import "CreateNewChatViewModel.h"
#import "RoomListViewController.h"
#import "OLYMMessageObject.h"
#import "OLYMUserObject.h"
#import "ForwardAlertView.h"
#import "UIImage+Image.h"
#import "RecentlyViewModel.h"
#import "OLYMAESCrypt.h"
#import "OrganizationViewController.h"

@interface CreateNewChatViewController ()<RoomListViewControllerDelegate>



@property (nonatomic, strong) CreateNewChatViewModel *cnewChatViewModel;

@property (nonatomic, strong) UIButton *multiButton;

@end

@implementation CreateNewChatViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}
- (void)olym_addSubviews
{
    self.definesPresentationContext = YES;

    [self.view addSubview:self.newChatListView];
    WeakSelf(weakSelf);
    [self.newChatListView mas_makeConstraints:^(MASConstraintMaker *make) {
        if (@available(iOS 11, *)) {
            make.edges.mas_equalTo(weakSelf.view.safeAreaInsets);
        }else{
            make.edges.mas_equalTo(weakSelf.view);
        }
    }];
    if (self.multiSelect)
    {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:self.multiButton];
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
}

- (void)olym_bindViewModel
{
    @weakify(self);
    //转发点击群聊
    [[self.cnewChatViewModel.roomlistSubject takeUntil:self.rac_willDeallocSignal]subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        RoomListViewController *controller = [[RoomListViewController alloc]init];
        controller.roomListType = RoomListForwardType;
        controller.delegate = self;
        [self.navigationController pushViewController:controller animated:YES];
    }];
    
    //转发点击组织架构
    [[self.cnewChatViewModel.organizationlistSubject takeUntil:self.rac_willDeallocSignal]subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        OrganizationViewController *controller = [[OrganizationViewController alloc]initWithHierarchyId:@"0"];
        controller.organizationListType = OrganizationListTypeTranspond;
        controller.isEdit = self.newChatListView.tableView.isEditing;
        
        [self.navigationController pushViewController:controller animated:YES];
    }];
    
    [[self.cnewChatViewModel.cellClickSubject takeUntil:self.rac_willDeallocSignal]subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        //转发给单个用户
        [self forwadToUser:x];
    }];
    
    [[self.cnewChatViewModel.multiSelectSubject takeUntil:self.rac_willDeallocSignal]subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        //
        if (self.cnewChatViewModel.multiSelectArray.count > 0)
        {
            [self.multiButton setTitle:[NSString stringWithFormat:@"完成(%ld)",self.cnewChatViewModel.multiSelectArray.count] forState:UIControlStateNormal];
            self.navigationItem.rightBarButtonItem.enabled = YES;
            _multiButton.alpha = 1.0;
        }else
        {
            [self.multiButton setTitle:_T(@"完成") forState:UIControlStateNormal];
            self.navigationItem.rightBarButtonItem.enabled = NO;
            _multiButton.alpha = 0.5;
        }
        [self.multiButton sizeToFit];

    }];
    
    
}

- (void)olym_layoutNavigation
{
    [self setStrNavTitle:_T(@"选择联系人")];
}

- (void)sendToMultiUser
{
    if ([self.delegate respondsToSelector:@selector(createNewChatControllerDidSelectedUsers:)]) {
        [self.delegate createNewChatControllerDidSelectedUsers:self.cnewChatViewModel.multiSelectArray];
    }
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)forwadToUser:(OLYMUserObject *)userObj
{
    RecentlyViewModel *recentlyViewModel = [[RecentlyViewModel alloc]init];

#if MJTDEV
    if (self.forwardMessages)
    {
        ForwardAlertView *forwardAlertView = [[ForwardAlertView alloc]initWithTitle:userObj.userNickname images:@[userObj] content:[NSString stringWithFormat:_T(@"共%ld条消息"),self.forwardMessages.count] contentType:Content_Text buttonHandler:^(NSInteger buttonClickIndex) {
            if (buttonClickIndex == 1)
            {
                [recentlyViewModel forwardMessages:self.forwardMessages toUser:userObj];
                [self back];
                [SVProgressHUD showSuccessWithStatus:_T(@"转发成功")];
            }
        }];
        [forwardAlertView show];
        return;
    }
#endif

    NSString *filePath = self.forwardMessage.filePath;
    
    switch (self.forwardMessage.type) {
        case kWCMessageTypeText:
        {
            ForwardAlertView *forwardAlertView = [[ForwardAlertView alloc]initWithTitle:userObj.userNickname images:@[userObj] content:self.forwardMessage.content contentType:Content_Text buttonHandler:^(NSInteger buttonClickIndex) {
                if (buttonClickIndex == 1)
                {
                    [recentlyViewModel transpondTextMessage:self.forwardMessage.content filePath:self.forwardMessage.filePath isAppoint:self.forwardMessage.isAppoint  toUser:userObj];
                    [self back];
                    [SVProgressHUD showSuccessWithStatus:_T(@"转发成功")];
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
            NSString *fileName = [self.forwardMessage.filePath lastPathComponent];
            NSString *toPath = [NSString stringWithFormat:@"%@/%ld%@",[olym_FileCenter getMyFileLocalPath:userObj.userId],(long)[[NSDate date]timeIntervalSince1970],fileName];
            if (self.forwardMessage.isAESEncrypt)
            {
                [FileCenter copyFileAtPath:filePath toPath:toPath];
            }else
            {
                //文件未进行AES加密，转发的文件需要加密保存
                [OLYMAESCrypt encryptFileData:[NSData dataWithContentsOfFile:filePath] saveFilePath:toPath];
            }
            ForwardAlertView *forwardAlertView = [[ForwardAlertView alloc]initWithTitle:userObj.userNickname images:@[userObj] content:filePath contentType:Content_Image buttonHandler:^(NSInteger buttonClickIndex) {
                if (buttonClickIndex == 1)
                {
                    [recentlyViewModel transpondImage:toPath imageWidth:self.forwardMessage.imageWidth imageHeight:self.forwardMessage.imageHeight thumbnail:self.forwardMessage.thumbnail toUser:userObj];
                    [self back];
                    [SVProgressHUD showSuccessWithStatus:_T(@"转发成功")];
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
            NSString *fileName = [self.forwardMessage.filePath lastPathComponent];
            NSString *toPath = [NSString stringWithFormat:@"%@/%ld%@",[olym_FileCenter getMyFileLocalPath:userObj.userId],(long)[[NSDate date]timeIntervalSince1970],fileName];
            if (self.forwardMessage.isAESEncrypt)
            {
                [FileCenter copyFileAtPath:filePath toPath:toPath];
            }else
            {
                //文件未进行AES加密，转发的文件需要加密保存
                [OLYMAESCrypt encryptFileData:[NSData dataWithContentsOfFile:filePath] saveFilePath:toPath];
            }
            ContentType contenttype = Content_Text;
            id conent = [NSString stringWithFormat:_T(@"[视频]")];
            if (self.forwardMessage.thumbnail)
            {
                contenttype = Content_Image;
                conent = [UIImage imageFromBase64String:self.forwardMessage.thumbnail];
            }
            ForwardAlertView *forwardAlertView = [[ForwardAlertView alloc]initWithTitle:userObj.userNickname images:@[userObj] content:conent contentType:contenttype buttonHandler:^(NSInteger buttonClickIndex) {
                if (buttonClickIndex == 1)
                {
                    [recentlyViewModel transpondVideoMessage:toPath fileSize:self.forwardMessage.fileSize thumbnail:self.forwardMessage.thumbnail toUser:userObj];
                    [self back];
                    [SVProgressHUD showSuccessWithStatus:_T(@"转发成功")];
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
            NSString *fileName = self.forwardMessage.fileName;
            NSString *toPath = [NSString stringWithFormat:@"%@/%ld%@",[olym_FileCenter getMyFileLocalPath:userObj.userId],(long)[[NSDate date]timeIntervalSince1970],fileName];
            
            if (self.forwardMessage.isAESEncrypt)
            {
                [FileCenter copyFileAtPath:filePath toPath:toPath];
            }else
            {
                //文件未进行AES加密，转发的文件需要加密保存
                [OLYMAESCrypt encryptFileData:[NSData dataWithContentsOfFile:filePath] saveFilePath:toPath];
            }
            ForwardAlertView *forwardAlertView = [[ForwardAlertView alloc]initWithTitle:userObj.userNickname images:@[userObj] content:[NSString stringWithFormat:_T(@"[文件] %@"),fileName] contentType:Content_Text buttonHandler:^(NSInteger buttonClickIndex) {
                if (buttonClickIndex == 1)
                {
                    [recentlyViewModel transpondFileMessage:toPath fileSize:self.forwardMessage.fileSize fileName:fileName toUser:userObj];
                    [self back];
                    [SVProgressHUD showSuccessWithStatus:_T(@"转发成功")];
                }
            }];
            [forwardAlertView show];
        }
            break;
        default:
            break;
    }

}

- (void)back
{
    [self dismissViewControllerAnimated:YES completion:nil];
}



#pragma mark - RoomListViewControllerDelegate
- (void)roomListController:(RoomListViewController *)controller didSelectedRoomUser:(OLYMUserObject *)room
{
    //转发到群聊
    [self forwadToUser:room];
}


- (CreateNewChatListView *)newChatListView
{
    if (!_newChatListView)
    {
        _newChatListView = [[CreateNewChatListView alloc]initWithViewModel:self.cnewChatViewModel];
        _newChatListView.multiSelect = self.multiSelect;
        _newChatListView.selectedUsers = self.selectedUsers;
    }
    return _newChatListView;
}

- (CreateNewChatViewModel *)cnewChatViewModel
{
    if (!_cnewChatViewModel) {
        _cnewChatViewModel = [[CreateNewChatViewModel alloc]init];
    }
    return _cnewChatViewModel;
}

- (UIButton *)multiButton
{
    if (!_multiButton)
    {
        _multiButton = [[UIButton alloc]init];
        _multiButton.titleLabel.font = [UIFont systemFontOfSize:16];
        [_multiButton setTitleColor:Global_Theme_Color forState:UIControlStateNormal];
        [_multiButton addTarget:self action:@selector(sendToMultiUser) forControlEvents:UIControlEventTouchUpInside];
        [_multiButton setTitle:_T(@"完成") forState:UIControlStateNormal];
        [_multiButton sizeToFit];
        _multiButton.alpha = 0.5;
    }
    return _multiButton;
}

-(void)setMultiSelect:(BOOL)multiSelect{
    
    _multiSelect = multiSelect;
    
    self.newChatListView.tableView.editing = multiSelect;
    
    if (!multiSelect) {
        
        [self setRightButtonWithTitle:@""];
    }
    
}

@end
