//
//  ChatFile2ViewController.m
//  MJT_APP
//
//  Created by Donny on 2017/12/26.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "ChatFile2ViewController.h"
#import "ChatMediaViewController.h"
#import "ChatOhterFileViewController.h"
#import "MLMSegmentManager.h"
#import "ChatFileViewModel.h"
#import "FileOpenVC.h"
#import "GJCUImageBrowserViewController.h"
#import "OLYMMoviePlayerViewController.h"
#import "OLYMMessageObject.h"
#import "GJCUImageBrowserModel.h"

@interface ChatFile2ViewController ()<MLMSegmentScrollDelegate>

@property (nonatomic, strong) ChatFileViewModel *chatFileViewModel;

// 返回按钮
@property (nonatomic, strong) UIBarButtonItem *backBtn;

@property (nonatomic, strong) MLMSegmentHead *segHead;
@property (nonatomic, strong) MLMSegmentScroll *segScroll;

@property (nonatomic, assign) MLMSegmentLayoutStyle layout;

@property (nonatomic, strong) NSArray *titles;

@property (nonatomic, strong) NSArray *viewControllers;

@property (nonatomic, strong) UIButton *rightButton;

@end

@implementation ChatFile2ViewController

 
- (void)olym_addSubviews{
    self.navigationItem.leftBarButtonItem = self.backBtn;
    [self createSubviews];
}

- (void)olym_bindViewModel{
    @weakify(self);
    [[self.chatFileViewModel.cellClickSubject takeUntil:self.rac_willDeallocSignal]subscribeNext:^(OLYMMessageObject *fileMessage) {
        @strongify(self);
        
        NSString *lastPath = [fileMessage.filePath lastPathComponent];
        NSString *extension = [lastPath pathExtension];
        NSString *filePath = [self.chatFileViewModel absoluteFilePathfrom:fileMessage];

        switch (_operationFileType) {
            case 0:
            {
                /*
                 *  浏览聊天文件
                 */
                if ([extension isEqualToString:@"mp4"]) {
                    
                    //视频的使用播放器
                    OLYMMoviePlayerViewController *moviePlayer = [[OLYMMoviePlayerViewController alloc]init];
                    moviePlayer.filePath = filePath;
                    moviePlayer.isFileEncrypt = fileMessage.isAESEncrypt;
                    OLYMBaseNavigationController *nav = [[OLYMBaseNavigationController alloc]initWithRootViewController:moviePlayer];
                    [self presentViewController:nav animated:YES completion:nil];
                    
                }else if([extension isEqualToString:@"jpg"] || [extension isEqualToString:@"png"] || [extension isEqualToString:@"gif"]){
                    NSInteger index = NSNotFound;
                    
                    GJCUImageBrowserModel *model = [[GJCUImageBrowserModel alloc]init];
                    model.filePath = filePath;
                    model.isAESEncrypt = fileMessage.isAESEncrypt;
                    
                    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.filePath == %@",filePath];
                    NSArray *filterArray = [self.chatFileViewModel.images filteredArrayUsingPredicate:predicate];
                    if (filterArray && filterArray.count > 0)
                    {
                        index = [self.chatFileViewModel.images indexOfObject:[filterArray lastObject]];
                    }

                    NSArray *images = self.chatFileViewModel.images;
                    if (index == NSNotFound)
                    {
                        images = [NSArray arrayWithObject:model];
                        index = 0;
                    }

                    GJCUImageBrowserViewController *imageBrowser = [[GJCUImageBrowserViewController alloc]initWithImageModels:images];
                    imageBrowser.pageIndex = index;
                    imageBrowser.isPresentModelState = YES;
                    [self presentViewController:imageBrowser animated:YES completion:nil];
                    
                }else if ([extension isEqualToString:@"txt"] || [extension hasPrefix:@"doc"] || [extension isEqualToString:@"pdf"] || [extension hasPrefix:@"xls"]|| [extension hasPrefix:@"ppt"]){
                    
                    if([[NSFileManager defaultManager] fileExistsAtPath:filePath]){
                        FileOpenVC *mFileOpenVC = [[FileOpenVC alloc]init];
                        [mFileOpenVC setUrlPath:filePath];
                        mFileOpenVC.isFileAESEncrypt = fileMessage.isAESEncrypt;
                        [self.navigationController pushViewController:mFileOpenVC animated:YES];
                        
                    } else {
                        UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"" message:_T(@"文件正在下载中") preferredStyle:UIAlertControllerStyleAlert];
                        
                        UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:_T(@"确定") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                            
                        }];
                        
                        [alertVC addAction:confirmAction];
                        [self presentViewController:alertVC animated:YES completion:nil];
                    }
                }
                
                
                
            }
                break;
            case 1:
            {
                //选择文件发送
                
                UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:_T(@"提示") message:_T(@"是否发送此文件") preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:_T(@"取消") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                    
                    return ;
                }];
                
                UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:_T(@"确定") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {                    self.pickFilePathBlock(fileMessage.filePath,fileMessage.fileName,fileMessage.fileSize,fileMessage.thumbnail,fileMessage.isAESEncrypt);
                    [self dismissViewControllerAnimated:YES completion:nil];
                    
                }];
                
                [alertVC addAction:cancelAction];
                [alertVC addAction:confirmAction];
                [self presentViewController:alertVC animated:YES completion:nil];
                
            }
                break;
            default:
                break;
        }
    }];
}

- (void)olym_layoutNavigation{
    switch (_operationFileType) {
        case 0:
        {
            [self setStrNavTitle:_T(@"聊天文件")];
        }
            break;
        case 1:
        {
            
            [self setStrNavTitle:_T(@"选择文件")];
            
        }
            break;
            
        default:
            break;
    }
    
}


- (void)back
{
    if (_operationFileType == ReadFile) {
        
        [self.navigationController popViewControllerAnimated:YES];
    }else{
        
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}



- (void)scrollEndIndex:(NSInteger)index
{
    UIViewController *controller = [self.viewControllers objectAtIndex:index];
    if ([controller respondsToSelector:@selector(reserveState)]) {
        [controller performSelector:@selector(reserveState)];
    }
}

- (void)animationEndIndex:(NSInteger)index
{
    UIViewController *controller = [self.viewControllers objectAtIndex:index];
    if ([controller respondsToSelector:@selector(reserveState)]) {
        [controller performSelector:@selector(reserveState)];
    }
}

#pragma mark - setup
- (void)createSubviews
{
    self.titles = @[@"图片/视频",@"文档"];
    _segHead = [[MLMSegmentHead alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 40) titles:self.titles headStyle:SegmentHeadStyleLine layoutStyle:_layout];
    _segHead.fontScale = 1;
    _segHead.selectColor = OLYMHEXCOLOR(0x008EFF);
    _segHead.deSelectColor = OLYMHEXCOLOR(0x333333);
    _segHead.bottomLineHeight = 0;
    _segHead.lineColor = OLYMHEXCOLOR(0x008EFF);
    _segHead.lineHeight = 4;
    _segHead.lineScale = 0.5;
    _segHead.bottomLineColor = OLYMHEXCOLOR(0xEDEDEE);
    _segHead.bottomLineHeight = 1;
    
    _segScroll = [[MLMSegmentScroll alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(_segHead.frame), SCREEN_WIDTH, SCREEN_HEIGHT-CGRectGetMaxY(_segHead.frame)-GJCFSystemOriginYDelta - 44) vcOrViews:self.viewControllers];
    _segScroll.loadAll = NO;
    _segScroll.showIndex = 0;
    _segScroll.segDelegate = self;
    
    [MLMSegmentManager associateHead:_segHead withScroll:_segScroll completion:^{
        [self.view addSubview:_segHead];
        [self.view addSubview:_segScroll];
    }];

}


- (NSArray *)viewControllers
{
    if (!_viewControllers) {
        WeakSelf(weakSelf)
        ChatMediaViewController *con = [[ChatMediaViewController alloc]init];
        con.chatFileViewModel = weakSelf.chatFileViewModel;
        con.mParentController = weakSelf;
        if (_operationFileType == ReadFile) {
            con.showEdit = YES;
        }
        ChatOhterFileViewController *con2 = [[ChatOhterFileViewController alloc]init];
        con2.chatFileViewModel = weakSelf.chatFileViewModel;
        con2.mParentController = weakSelf;
        if (_operationFileType == ReadFile) {
            con2.showEdit = YES;
        }

        _viewControllers = @[con,con2];

    }
    return _viewControllers;
}

- (ChatFileViewModel *)chatFileViewModel
{
    if (!_chatFileViewModel)
    {
        _chatFileViewModel = [[ChatFileViewModel alloc]initWithUser:self.currentChatUser];
    }
    return _chatFileViewModel;
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
