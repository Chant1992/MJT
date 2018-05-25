//
//  BurnAfterReadingViewController.m
//  MJT_APP
//
//  Created by Donny on 2017/9/12.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "BurnAfterReadingViewController.h"
#import "OLYMMessageObject.h"
#import "CircleProgressView.h"
#import "Session.h"
#import "NormalMacro.h"
#import "BurnAfterReadingViewModel.h"
#import "AttributedTool.h"

@interface BurnAfterReadingViewController ()<UIGestureRecognizerDelegate>

@property(nonatomic,strong) UIImageView *bgImageView;
/* 焚毁 */
@property(nonatomic,strong) UIButton *burnBtn;
@property(nonatomic,strong) UILabel *showLabel;
@property(nonatomic,strong) UIImageView *showImageView;

@property(nonatomic,strong) UIImageView *voiceImage;

@property(nonatomic,strong) UIVisualEffectView *effectView;
@property(assign,nonatomic) BOOL isReadBurnMessage;

@property (nonatomic) Session *session;
@property(assign,nonatomic) int readburn_time;
@property(assign,nonatomic) BOOL messageHasSeen; //消息已经被查看（只要点击看过 就执行销毁）

@property (nonatomic, strong) BurnAfterReadingViewModel *burnAfterReadingViewModel;

@end

@implementation BurnAfterReadingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

}

- (void)olym_addSubviews{
    

    self.readburn_time = READBURN_TIME;
    
    if(self.msgObj.type == kWCMessageTypeVoice){
        self.readburn_time = self.msgObj.fileSize + READBURN_TIME;
    }

    
    [self creatSubview];
    [self addGestures];
}

- (void)olym_bindViewModel{
    @weakify(self);
    
    
    [self addNotification];

    
    
}

- (void)olym_layoutNavigation{
    [self.navigationController setNavigationBarHidden:YES animated:NO];
}


#pragma mark - Action & Response

-(void)dismissViewController{
    [self burnBtnClick];
    
}

-(void)burnBtnClick{
    
    if(!self.msgObj.isMySend && self.messageHasSeen){
        //删除数据库
                
        //发出通知，删除消息
        [olym_Nofity postNotificationName:kDeleteReadburnMessageNotifaction object:self.msgObj];
    }
    
    [self removeNotification];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    if (self.presentingViewController)
    {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    else
    {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)voiceBtnClick{
    
    // 红外线探测播放时设置YES
    [[UIDevice currentDevice] setProximityMonitoringEnabled:YES];
    
    [_voiceImage startAnimating];
    
    self.messageHasSeen = YES;

    WeakSelf(ws);
    [self.burnAfterReadingViewModel playAudio:self.msgObj.content finished:^{
        StrongSelf(ss);
        [ss.voiceImage stopAnimating];
    }];
}




- (void)handleGesture:(UIGestureRecognizer *)gestureRecognizer
{
    if(self.msgObj.type  != kWCMessageTypeVoice){
        self.messageHasSeen = YES;
    }
    [self.effectView setHidden:YES];

}


#pragma mark - private method

- (void)addNotification
{
    @weakify(self);
    [[[NSNotificationCenter defaultCenter]rac_addObserverForName:UIApplicationUserDidTakeScreenshotNotification object:nil]subscribeNext:^(NSNotification *n){
        @strongify(self);
        if (!self.msgObj.isMySend)
        {
            [self.burnAfterReadingViewModel sendTakeScreenshotMessage:self.msgObj];
        }
    }];
    [[[NSNotificationCenter defaultCenter]rac_addObserverForName:UIApplicationDidEnterBackgroundNotification object:nil]subscribeNext:^(NSNotification * _Nullable x) {
        @strongify(self);
        //关闭语音播放
        [self.burnAfterReadingViewModel stopAudioPlay];
    }];
}
- (void)removeNotification{
    [olym_Nofity removeObserver:self name:UIApplicationUserDidTakeScreenshotNotification object:nil];
    [olym_Nofity removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
}

-(void)setMessageHasSeen:(BOOL)messageHasSeen{
    _messageHasSeen = messageHasSeen;
    
    //阅后即焚已读
    if (!self.msgObj.isMySend)
    {
        [self.burnAfterReadingViewModel sendReadedMessage:self.msgObj];
    }
}



#pragma mark - setup

- (void)addGestures
{
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(handleGesture:)];
    [self.view addGestureRecognizer:tap];
    
}

-(void)creatSubview{
    WeakSelf(ws);
    
    [self.view addSubview:self.bgImageView];
    [self.bgImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        if (@available(iOS 11, *)) {
            make.edges.mas_equalTo(ws.view.safeAreaInsets);
        }else{
            make.edges.mas_equalTo(ws.view);
        }
    }];

    switch (_msgObj.type ) {
        case kWCMessageTypeText:
        {
            //文字
            [self createTextMessageView];
            
            break;
        }
        case kWCMessageTypeImage:
        {
            //图片
            break;
        }
        case kWCMessageTypeVoice:
        {
            //语音
            [self createVoiceMessageView];
            break;
        }
        case kWCMessageTypeVideo:
        {
            
            
            break;
        }
        default:
            //容错
            if (_msgObj.fileSize > 0)
            {
                //语音
                [self createVoiceMessageView];
            }else
            {
                //文字
                [self createTextMessageView];
            }
            break;
    }
    
    
    //防止type类型错乱
    if (self.msgObj.isMySend && !self.msgObj.filePath)
    {
        self.msgObj.type = kWCMessageTypeText;
    }
    if(self.msgObj.type == kWCMessageTypeText)
    {
        
        UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        
        self.effectView = [[UIVisualEffectView alloc] initWithEffect:blur];
        self.effectView.alpha = 1;
        self.effectView.frame = self.view.bounds;
        [self.effectView setMultipleTouchEnabled:YES];
        [self.view addSubview:self.effectView];
        
        [self.effectView.contentView addSubview:self.showLabel];
        [self.effectView.contentView addSubview:self.showImageView];
        
        [self.effectView mas_makeConstraints:^(MASConstraintMaker *make) {
            if (@available(iOS 11, *)) {
                make.edges.mas_equalTo(ws.view.safeAreaInsets);
            }else{
                make.edges.mas_equalTo(ws.view);
            }
        }];

        [self.showLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.mas_equalTo(ws.effectView.contentView.mas_centerX);
            make.centerY.mas_equalTo(ws.effectView.contentView.mas_centerY).offset(-50);
            make.width.mas_equalTo(100);
            make.height.mas_equalTo(30);
        }];
        
        [self.showImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.mas_equalTo(ws.effectView.contentView.mas_centerX).offset(5);
            make.top.mas_equalTo(ws.showLabel.mas_bottom).offset(10);
            //                make.width.mas_equalTo(50);
            //                make.height.mas_equalTo(80);
        }];
    }
    [self.view addSubview:self.burnBtn];
    [_burnBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        if (@available(iOS 11, *)) {
            make.top.mas_equalTo(ws.view.safeAreaInsets.top).offset(44);
        }else{
            make.top.mas_equalTo(ws.view.mas_top).offset(30);
        }
        make.left.mas_equalTo(ws.view.mas_left).offset(20);
        make.width.height.mas_equalTo(40);
    }];

}


- (void)createTextMessageView
{
    WeakSelf(ws);

    UILabel *textLabel = [[UILabel alloc]init];
    textLabel.font = [UIFont systemFontOfSize:16];
    textLabel.numberOfLines = 0;
    textLabel.textColor = [UIColor whiteColor];
    
    NSMutableAttributedString *attrString = [AttributedTool emojiExchangeContent:_msgObj.content];
    NSDictionary *attributeDict = @{NSFontAttributeName:[UIFont systemFontOfSize:17.0]};
    [attrString addAttributes:attributeDict range:NSMakeRange(0, attrString.length)];
    textLabel.attributedText = attrString;
    
    
    [self.view addSubview:textLabel];
    [textLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        if (@available(iOS 11, *)) {
            make.top.mas_equalTo(ws.view.safeAreaInsets.top).offset(100);
        }else{
            make.top.mas_equalTo(ws.view).offset(100);
        }
        make.centerX.mas_equalTo(ws.view);
        make.left.mas_equalTo(ws.view).offset(15);
        make.right.mas_equalTo(ws.view).offset(-15);
    }];
}

- (void)createVoiceMessageView
{
    WeakSelf(ws);

    _bgImageView.image = [UIImage imageNamed:@"voice_bg"];
    
    UILabel *textLabel = [[UILabel alloc]init];
    textLabel.font = [UIFont systemFontOfSize:16];
    textLabel.textColor = [UIColor whiteColor];
    textLabel.text = _T(@"语音消息");
    
    [self.view addSubview:textLabel];
    [textLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.centerX.mas_equalTo(ws.view);
        make.centerY.mas_equalTo(ws.view).offset(-5);
    }];
    
    //播放按钮
    UIButton *voiceBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [voiceBtn setBackgroundImage:[UIImage imageNamed:@"voice_btn"] forState:UIControlStateNormal];
    [voiceBtn addTarget:self action:@selector(voiceBtnClick) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:voiceBtn];
    [voiceBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.top.mas_equalTo(textLabel.mas_bottom).offset(15);
        make.left.mas_equalTo(ws.view).offset(75);
        make.right.mas_equalTo(ws.view).offset(-75);
        make.height.mas_equalTo(44);
    }];
    
    //声音图标
    _voiceImage = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"voice_icon"]];
    
    [voiceBtn addSubview:_voiceImage];
    [_voiceImage mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.left.mas_equalTo(voiceBtn.mas_left).offset(60);
        make.centerY.mas_equalTo(voiceBtn);
        make.height.mas_equalTo(18);
        make.width.mas_equalTo(12);
    }];
    
    UILabel *timeLabel = [[UILabel alloc]init];
    timeLabel.font = [UIFont systemFontOfSize:16];
    timeLabel.text = [NSString stringWithFormat:@"%ld''",(long)_msgObj.fileSize];
    
    [voiceBtn addSubview:timeLabel];
    [timeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.center.mas_equalTo(voiceBtn);
    }];
    
    //更改播放语音动画的图片
    NSString *file,*s;
    file = @"voice_paly_left_";
    NSMutableArray *array = @[].mutableCopy;
    for(int i=1;i<=3;i++){
        s = [NSString stringWithFormat:@"%@%d",file,i];
        [array addObject:[UIImage imageNamed:s]];
    }
    _voiceImage.animationImages = array;
    _voiceImage.animationDuration = 1;
}


#pragma mark =============== Getter ===============
- (UIImageView *)bgImageView{
    
    if (!_bgImageView) {
        
        _bgImageView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"burn_bg"]];
        
        _bgImageView.frame = self.view.bounds;
    }
    
    return _bgImageView;
}

- (UIButton *)burnBtn{
    
    if (!_burnBtn) {
        
        _burnBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_burnBtn setBackgroundImage:[UIImage imageNamed:@"burn_btn_nor"] forState:UIControlStateNormal];
        [_burnBtn setBackgroundImage:[UIImage imageNamed:@"burn_btn_npre"] forState:UIControlStateHighlighted];
        
        [_burnBtn addTarget:self action:@selector(dismissViewController) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _burnBtn;
}

- (UILabel *)showLabel{
    
    if (!_showLabel) {
        
        _showLabel = [[UILabel alloc]init];
        [_showLabel setTextAlignment:NSTextAlignmentCenter];
        [_showLabel setTextColor:[UIColor whiteColor]];
        _showLabel.font = [UIFont systemFontOfSize:22];
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



- (BurnAfterReadingViewModel *)burnAfterReadingViewModel
{
    if (!_burnAfterReadingViewModel) {
        _burnAfterReadingViewModel = [[BurnAfterReadingViewModel alloc]initWithUser:self.currentChatUser];
    }
    return _burnAfterReadingViewModel;
}

@end
