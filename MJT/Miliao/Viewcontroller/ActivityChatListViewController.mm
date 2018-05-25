//
//  ActivityChatListViewController.m
//  MJT_APP
//
//  Created by Donny on 2017/11/14.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "ActivityChatListViewController.h"
#import "ActivityChatListView.h"
#import "RecentlyViewModel.h"
#import "ChatViewController.h"
#import "OLYMUserObject.h"
#import <AVFoundation/AVFoundation.h>
#import "MiYouViewController.h"
#import "MiYouViewModel.h"
#import "UIImage+Image.h"
#import "ChatViewController.h"
#import "OLYMAESCrypt.h"

typedef NS_ENUM(NSUInteger, ActivityChatType) {
    ActivityChatFileUnknowType = 0,
    ActivityChatFileImageType,
    ActivityChatFileMoiveType,
    ActivityChatFileOtherType,
};

@interface ActivityChatListViewController ()

@property (nonatomic, strong) NSURL *dataURL;

@property (nonatomic, strong) RecentlyViewModel *recentlyViewModel;
@property (nonatomic, strong) ActivityChatListView *activityChatListView;
// 返回按钮
@property (nonatomic, strong) UIBarButtonItem *backBtn;


@property (nonatomic) ActivityChatType chatFileType;
@end

@implementation ActivityChatListViewController

+ (void)showActivityChatListViewControllerWith:(NSURL *)url
{
    ActivityChatListViewController *controller = [[ActivityChatListViewController alloc]init];
    controller.dataURL = url;
    OLYMBaseNavigationController *nav = [[OLYMBaseNavigationController alloc]initWithRootViewController:controller];
    [[olym_App getCurrentPresentView] presentViewController:nav animated:YES completion:NULL];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self getChatFileType];
}

- (void)olym_addSubviews{
    self.definesPresentationContext = YES;
    
    self.navigationItem.leftBarButtonItem = self.backBtn;
    
    [self.view addSubview:self.activityChatListView];
    
    WeakSelf(ws);
    [self.activityChatListView mas_makeConstraints:^(MASConstraintMaker *make) {
        if (@available(iOS 11, *)) {
            make.edges.mas_equalTo(ws.view.safeAreaInsets);
        }else{
            make.edges.mas_equalTo(ws.view);
        }
    }];
    
}


- (void)olym_layoutNavigation
{
    [self setStrNavTitle:_T(@"请选择一个聊天")];
    
}


- (void)olym_bindViewModel
{
    WeakSelf(ws);
    @weakify(self);
    //发送给好友
    [self.recentlyViewModel.cellClickSubject subscribeNext:^(OLYMUserObject *userObj) {
        @strongify(self);
        //
        [self sendActivityFile:userObj];
        [self gotoChat:userObj];

    }];
}

- (void)gotoChat:(OLYMUserObject *)chatUser
{
    ChatViewController *chatViewController = [[ChatViewController alloc]init];
    [chatViewController setCurrentChatUser:chatUser];
    
    UIViewController *rootViewControler = olym_App.window.rootViewController;
    if ([rootViewControler isKindOfClass:[UITabBarController class]]) {
        UITabBarController *tabBarController = (UITabBarController *)rootViewControler;
        UINavigationController *nav = (UINavigationController *)tabBarController.selectedViewController;
        [nav popToRootViewControllerAnimated:NO];
        tabBarController.selectedIndex = MILIAOPOSITION;
        [tabBarController.viewControllers[MILIAOPOSITION] pushViewController:chatViewController animated:YES];
    }
    [self back];
}

- (void)back{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)sendActivityFile:(OLYMUserObject *)chatUser
{
    NSData *data = [NSData dataWithContentsOfURL:self.dataURL];
    long long fileSize = data.length;

    NSString *filename = [[self.dataURL absoluteString]lastPathComponent];
    filename = [filename stringByRemovingPercentEncoding];
    NSString *savePath = [NSString stringWithFormat:@"%@/%@",[olym_FileCenter getMyFileLocalPath:chatUser.userId],filename];
    //将文件AES加密
    BOOL saveOriginResult = [OLYMAESCrypt encryptFileData:data saveFilePath:savePath];
        

    if (self.chatFileType == ActivityChatFileImageType) {
        
        UIImage *image = [UIImage imageWithData:data];
        NSString *base64Encoded = [image base64StringFromImage:5 * 1024];
        [self.recentlyViewModel transpondImage:savePath imageWidth:image.size.width imageHeight:image.size.height thumbnail:base64Encoded toUser:chatUser];
    }else if (self.chatFileType == ActivityChatFileMoiveType){
        //获取视频缩略图
        NSURL *url = [NSURL fileURLWithPath:savePath];
        AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:url options:nil];
        AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:urlAsset];
        generator.appliesPreferredTrackTransform = YES;
        generator.maximumSize = CGSizeMake(360, 480);
        NSError *error = nil;
        
        CGImageRef img = [generator copyCGImageAtTime:CMTimeMake(1, 10) actualTime:NULL error:&error];
        UIImage *videoImage = [UIImage imageWithCGImage: img];
        NSString  *thumbFilePath = [NSString stringWithFormat:@"%@.jpg",[savePath stringByDeletingPathExtension]];
        
        NSData *thumbData = UIImageJPEGRepresentation(videoImage, 0.1);
        //缩略图也要进行AES加密
        BOOL saveOriginResult = [OLYMAESCrypt encryptFileData:thumbData saveFilePath:thumbFilePath];
        
        NSString *base64Encoded = [videoImage base64StringFromImage:5 * 1024];

        [self.recentlyViewModel transpondVideoMessage:savePath fileSize:fileSize thumbnail:base64Encoded toUser:chatUser];

    }else{
        [self.recentlyViewModel transpondFileMessage:savePath fileSize:fileSize fileName:filename toUser:chatUser];
    }
}



- (void)getChatFileType
{
    NSString *fileExtension = [self fileExtension];
    if ([fileExtension isEqualToString:@"jpg"] || [fileExtension isEqualToString:@"jpeg"] || [fileExtension isEqualToString:@"png"] || [fileExtension isEqualToString:@"gif"]) {
        self.chatFileType = ActivityChatFileImageType;
    }else if ([fileExtension isEqualToString:@"mp4"])
    {
        self.chatFileType = ActivityChatFileMoiveType;
    }else
    {
        self.chatFileType = ActivityChatFileOtherType;
    }
}

- (NSString *)fileExtension
{
    NSString *dataFilePath = self.dataURL.absoluteString;
    NSString *fileExtension = [[[dataFilePath componentsSeparatedByString:@"."]lastObject]lowercaseString];
    return fileExtension;
}

#pragma mark - Property
- (RecentlyViewModel *)recentlyViewModel
{
    if (!_recentlyViewModel)
    {
        _recentlyViewModel = [[RecentlyViewModel alloc]init];
    }
    return _recentlyViewModel;
}

- (ActivityChatListView *)activityChatListView
{
    if (!_activityChatListView) {
        _activityChatListView = [[ActivityChatListView alloc]initWithViewModel:self.recentlyViewModel];
    }
    return _activityChatListView;
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
