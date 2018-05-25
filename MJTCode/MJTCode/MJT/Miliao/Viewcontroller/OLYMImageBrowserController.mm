//
//  OLYMImageBrowserController.m
//  MJT_APP
//
//  Created by Donny on 2017/9/13.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "OLYMImageBrowserController.h"
#import "OLYMMessageObject.h"
#import "Session.h"
#import "CircleProgressView.h"

#import "GJCUImageBrowserScrollView.h"
#import "GJCUImageBrowserConstans.h"

#import "BurnAfterReadingViewModel.h"

@interface OLYMImageBrowserController ()<GJCUImageBrowserItemViewControllerDataSource,UIGestureRecognizerDelegate>

/* 焚毁 */
@property(nonatomic,strong) UIButton *burnBtn;
@property(nonatomic,strong) UIVisualEffectView *effectView;
@property(nonatomic,strong) UILabel *showLabel;
@property(nonatomic,strong) UIImageView *showImageView;


@property(assign,nonatomic) BOOL isReadBurnMessage;

@property(assign,nonatomic) int readburn_time;
@property(assign,nonatomic) BOOL messageHasSeen; //消息已经被查看（只要点击看过 就执行销毁）


@property (nonatomic,strong)GJCUImageBrowserScrollView * scrollView;

@property (nonatomic,strong) BurnAfterReadingViewModel *burnAfterReadingViewModel;

@property (nonatomic,strong) NSMutableArray *dataSource;
@end

@implementation OLYMImageBrowserController

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [super viewWillDisappear:animated];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)olym_addSubviews{
    
    GJCUImageBrowserModel *imageModel = [[GJCUImageBrowserModel alloc]init];
    imageModel.filePath = [[olym_FileCenter documentPrefix]stringByAppendingString:self.msgObj.filePath];
    imageModel.isAESEncrypt = self.msgObj.isAESEncrypt;
    self.dataSource = [NSMutableArray array];
    [self.dataSource addObject:imageModel];

    [self createSubview];
    
}

- (void)olym_bindViewModel{
    @weakify(self);
    [olym_Nofity addObserver:self selector:@selector(userDidTakeScreenshot) name:UIApplicationUserDidTakeScreenshotNotification object:nil];
    [olym_Nofity addObserver:self selector:@selector(tapStart:) name:GJCUImageBrowserItemViewControllerDidTapNoti object:nil];

    
}

- (void)olym_layoutNavigation{
}

#pragma mark - Action

- (void)handleGesture:(UIGestureRecognizer *)gestureRecognizer
{
    [self.effectView setHidden:YES];
    self.messageHasSeen = YES;
}

-(void)burnBtnClick{
    if(!self.msgObj.isMySend && self.messageHasSeen){
        //删除文件，同时删除数据库
        [FileCenter deleteFile:[[olym_FileCenter documentPrefix]stringByAppendingString:self.msgObj.filePath]];
        //发出通知，删除消息
        [olym_Nofity postNotificationName:kDeleteReadburnMessageNotifaction object:self.msgObj];
    }
    
    if(self.msgObj.isMySend)
    {
        if (![FileCenter fileExistAt:[[olym_FileCenter documentPrefix]stringByAppendingString:self.msgObj.filePath]])
        {
            if (self.msgObj.isSend != transfer_status_read)
            {
                dispatch_async(XmppGroupBurnQueue, ^{
                    [self.msgObj updateSendStatus:transfer_status_read];
                    [self.msgObj notifyMsgStatus];
                });
            }
        }
    }
    //    [self dismissViewControllerAnimated:YES completion:^{
    //        [self removeNotification];
    //    }];
    
    [self removeNotification];
    if (self.presentingViewController)
    {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    else
    {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

-(void)dismissViewController{
    
    [self burnBtnClick];
    
}


- (void)tapStart:(id)object
{
    if(self.isReadBurnMessage && !self.msgObj.isMySend){
        [self.effectView setHidden:YES];
        self.messageHasSeen = YES;
    }else{
        [self dismissViewControllerAnimated:YES completion:^{
            [self.scrollView removeFromSuperview];
            [self removeNotification];
        }];
    }
}

-(void)longPress:(UILongPressGestureRecognizer *)gestureRecognizer{
    
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:_T(@"保存图片") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        UIImageWriteToSavedPhotosAlbum(self.scrollView.contentImageView.image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
    }];
    
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:_T(@"取消") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        return ;
    }];
    
    [alertVC addAction:cancelAction];
    [alertVC addAction:confirmAction];
    [self presentViewController:alertVC animated:YES completion:nil];
    
}


#pragma mark - Private method

-(void)setMessageHasSeen:(BOOL)messageHasSeen{
    _messageHasSeen = messageHasSeen;
    
    //阅后即焚已读
    if (!self.msgObj.isMySend)
    {
        [self.burnAfterReadingViewModel sendReadedMessage:self.msgObj];
    }
}



- (void)addGestureOnView:(UIView *)view
{
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(handleGesture:)];
    [view addGestureRecognizer:tap];
}


-(void)removeNotification{
    [olym_Nofity removeObserver:self name:UIApplicationUserDidTakeScreenshotNotification object:nil];
}

- (void)addTapGR
{
    UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapStart:)];
    
    tap.delegate = self;
    tap.cancelsTouchesInView = YES;
    [self.scrollView addGestureRecognizer:tap];
    
    if(!self.isReadBurnMessage){
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(longPress:)];
        longPress.cancelsTouchesInView = YES;
        [self.scrollView addGestureRecognizer:longPress];
    }
}


#pragma mark =============== 截屏通知 ===============
-(void)userDidTakeScreenshot{
    if (!self.msgObj.isMySend)
    {
        [self.burnAfterReadingViewModel sendTakeScreenshotMessage:self.msgObj];
    }
}


//必须实现的保存图片回调方法
- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    NSString *message;
    if (error) {

        message = _T(@"保存失败");
    } else {

        message = _T(@"保存成功");
    }
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:message message:nil preferredStyle:UIAlertControllerStyleAlert];

    [alertController addAction:[UIAlertAction actionWithTitle:_T(@"确定") style:UIAlertActionStyleDefault handler:NULL]];
    [self presentViewController:alertController animated:YES completion:NULL];
}


#pragma mark - GJCUImageBrowserItemViewControllerDataSource
- (GJCUImageBrowserModel *)imageModelAtIndex:(NSInteger)index
{
    GJCUImageBrowserModel *model = [self.dataSource objectAtIndex:index];
    return model;
}


#pragma mark - setup
- (void)createSubview
{
    self.isReadBurnMessage = self.msgObj.isReadburn;

    [self.view addSubview:self.scrollView];
    WeakSelf(ws);
    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        StrongSelf(ss);
        if (@available(iOS 11, *)) {
            make.edges.mas_equalTo(ws.view.safeAreaInsets);
        }else{
            make.edges.mas_equalTo(ws.view);
        }
    }];
    
    if (self.isReadBurnMessage)
    {
        //scrollView内容距离上下的边界边距
        self.scrollView.contentInset = UIEdgeInsetsMake(-22, 0, 0, 0);
        
        [self addGestureOnView:self.scrollView];
        [self.view addSubview:self.effectView];
        [self.effectView.contentView addSubview:self.showLabel];
        [self.effectView.contentView addSubview:self.showImageView];
        
        [self addGestureOnView:self.effectView];
        
        [self.effectView mas_makeConstraints:^(MASConstraintMaker *make) {
            StrongSelf(ss);
            if (@available(iOS 11, *)) {
                make.edges.mas_equalTo(ws.view.safeAreaInsets);
            }else{
                make.edges.mas_equalTo(ws.view);
            }
        }];
        [self.showLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            StrongSelf(ss);
            
            make.centerX.mas_equalTo(ss.effectView.mas_centerX);
            make.centerY.mas_equalTo(ss.effectView.mas_centerY).offset(-20);
            make.width.mas_equalTo(100);
            make.height.mas_equalTo(30);
        }];
        
        [self.showImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            StrongSelf(ss);
            
            make.centerX.mas_equalTo(ss.effectView.mas_centerX);
            make.top.mas_equalTo(ss.showLabel.mas_bottom);
            make.width.mas_equalTo(50);
            make.height.mas_equalTo(80);
        }];

        [self.view addSubview:self.burnBtn];
        [_burnBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            StrongSelf(ss);
            if (@available(iOS 11, *)) {
                make.top.mas_equalTo(ss.view.safeAreaInsets.top).offset(44);
            }else{
                make.top.mas_equalTo(ss.view.mas_top).offset(30);
            }
            make.left.mas_equalTo(ss.view.mas_left).offset(20);
            make.width.height.mas_equalTo(40);
        }];
    }else
    {
        self.scrollView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
        
        [self addTapGR];
        
        //指定scrollView的最大缩放倍率
        self.scrollView.maximumZoomScale = 5.0;
        //指定scrollView的最小缩放倍率
        self.scrollView.minimumZoomScale = 1.0;

    }
}

#pragma mark =============== Getter ===============

-(UIButton *)burnBtn{
    
    if (!_burnBtn) {
        _burnBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_burnBtn setBackgroundImage:[UIImage imageNamed:@"burn_btn_nor"] forState:UIControlStateNormal];
        [_burnBtn setBackgroundImage:[UIImage imageNamed:@"burn_btn_npre"] forState:UIControlStateHighlighted];
        
        [_burnBtn addTarget:self action:@selector(dismissViewController) forControlEvents:UIControlEventTouchUpInside];
    }
    return _burnBtn;
}




-(UILabel *)showLabel{
    
    if (!_showLabel) {
        
        _showLabel = [[UILabel alloc]init];
        [_showLabel setTextAlignment:NSTextAlignmentCenter];
        [_showLabel setTextColor:[UIColor whiteColor]];
        [_showLabel setText:_T(@"点击查看")];
    }
    
    return _showLabel;
}

- (UIImageView *)showImageView{
    
    if (!_showImageView) {
        _showImageView = [[UIImageView alloc]init];
        [_showImageView setImage:[UIImage imageNamed:@"burn_image_nor"]];
        [_showImageView setUserInteractionEnabled:YES];
    }
    
    return _showImageView;
}


- (UIVisualEffectView *)effectView
{
    if (!_effectView)
    {
        UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        _effectView = [[UIVisualEffectView alloc] initWithEffect:blur];
        _effectView.alpha = 1;
        [_effectView setMultipleTouchEnabled:YES];
    }
    return _effectView;
}

- (GJCUImageBrowserScrollView *)scrollView
{
    if (!_scrollView) {
        _scrollView = [[GJCUImageBrowserScrollView alloc]initWithFrame:self.view.bounds];
        _scrollView.backgroundColor = OLYMHEXCOLOR(0x515151);
        _scrollView.dataSource = self;
        _scrollView.alwaysBounceHorizontal = YES;
        _scrollView.alwaysBounceVertical = YES;
        _scrollView.index = 0;
    }
    return _scrollView;
}


- (BurnAfterReadingViewModel *)burnAfterReadingViewModel
{
    if (!_burnAfterReadingViewModel) {
        _burnAfterReadingViewModel = [[BurnAfterReadingViewModel alloc]init];
    }
    return _burnAfterReadingViewModel;
}


@end
