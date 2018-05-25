//
//  ChatVideoMessageCell.m
//  MJT_APP
//
//  Created by Donny on 2017/9/6.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "ChatVideoMessageCell.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>
#import "UCZProgressView.h"
#import "UIImage+Image.h"
#import "OLYMAESCrypt.h"

@interface ChatVideoMessageCell ()

@property (nonatomic, strong) UIImageView *messageContentView;
// 播放按钮
@property (nonatomic,strong) UIImageView *playBtnImgView;
// 视频图片
@property(nonatomic,strong) UIImageView *videoImageView;

@property (nonatomic,strong) UCZProgressView *progressView;


@end

@implementation ChatVideoMessageCell
@synthesize downloadProgress = _downloadProgress;




- (void)setDownloadProgress:(CGFloat)downloadProgress
{
    if (_downloadProgress == downloadProgress) {
        return;
    }
    self.progressView.hidden = NO;
    _downloadProgress = downloadProgress;
    [self.progressView setProgress:downloadProgress animated:NO];
    
    if (downloadProgress == 1)
    {
        self.progressView.hidden = YES;
    }
}

#pragma mark - 设置数据源
- (void)setContentModel:(OLYMMessageObject *)contentModel
{
    [super setContentModel:contentModel];
    
    [self adjustLayout];
    [self changeVideoLayout];
    
    [self fillContent];
}

- (void)fillContent
{
    if(!self.isFromSelf && self.contentModel.isFileReceive)
    {
        self.progressView.progress = 0.0f;
        self.progressView.hidden = YES;
    }
    //获取视频显示的图片路径
    NSString *fileName = self.contentModel.filePath;
    NSString *filepath = [NSString stringWithFormat:@"%@.jpg",[fileName stringByDeletingPathExtension]];
    
    filepath = [[olym_FileCenter documentPrefix]stringByAppendingPathComponent:filepath];

    BOOL captrueExist = NO;
    if([[NSFileManager defaultManager] fileExistsAtPath:filepath]) {
        //如本地文件存在
        if([[filepath pathExtension] isEqualToString:@"jpg"] && _videoImageView != nil)
        {
            NSError *error;
            captrueExist = YES;
            NSData *data = [NSData dataWithContentsOfFile:filepath options:NSDataReadingMappedIfSafe error:&error];
            if (self.contentModel.isAESEncrypt)
            {
                data = [OLYMAESCrypt decryptData:data];
            }
            _videoImageView.image = [UIImage imageWithData:data];
        }
        
        return;
    }else{
        _videoImageView.image = [UIImage imageNamed:@"empty_background"];
    }
    
    if (self.isFromSelf)
    {
        [self captureVideoFrame:captrueExist saveFilePath:filepath];
    }else
    {
        if (self.contentModel.isFileReceive)
        {
            [self captureVideoFrame:captrueExist saveFilePath:filepath];
        }else
        {
            if (self.contentModel.thumbnail)
            {
                UIImage *thumbImage = [UIImage imageFromBase64String:self.contentModel.thumbnail];
                [_videoImageView setImage:thumbImage];
            }
            //download
            self.downloadProgress = self.contentModel.progress;
        }
    }
    
}


- (void)captureVideoFrame:(BOOL)fileExist saveFilePath:(NSString *)filePath
{
    self.progressView.progress = 0.0f;
    self.progressView.hidden = YES;

    if (fileExist)
    {
        return;
    }
    //获取视频截图
    dispatch_async(dispatch_get_global_queue(DISPATCH_TARGET_QUEUE_DEFAULT, 0), ^{
        NSString *filePath = [[olym_FileCenter documentPrefix]stringByAppendingPathComponent:self.contentModel.filePath];

        NSURL *url = [NSURL fileURLWithPath:filePath];
        BOOL filein = [[NSFileManager defaultManager]fileExistsAtPath:filePath];
        AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:url options:nil];
        
        AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:urlAsset];
        
        generator.appliesPreferredTrackTransform = YES;
        
        generator.maximumSize = CGSizeMake(360, 480);
        
        NSError *error = nil;
        
        CGImageRef img = [generator copyCGImageAtTime:CMTimeMake(1, 10) actualTime:NULL error:&error];
        UIImage *videoImage = [UIImage imageWithCGImage: img];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (videoImage) {
                self.videoImageView.image = videoImage;
            }else
            {
                if (self.contentModel.isAESEncrypt)
                {
                    UIImage *thumbImage = [UIImage imageFromBase64String:self.contentModel.thumbnail];
                    [_videoImageView setImage:thumbImage];
                }
            }
        });
        
        if (videoImage)
        {
            //存到本地
            NSData *data;
            filePath = [NSString stringWithFormat:@"%@.jpg",[filePath stringByDeletingPathExtension]];
            
            data = UIImageJPEGRepresentation(videoImage, 0.1);
            if (self.contentModel.isAESEncrypt)
            {
                [OLYMAESCrypt encryptFileData:data saveFilePath:filePath];
            }else
            {
                [data writeToFile:filePath atomically:YES];
            }
        }

    });
}


- (void)changeVideoLayout
{
    self.contentSize = CGSizeMake(100, 150);
    self.bubbleBackImageView.gjcf_width = 100;
    self.bubbleBackImageView.gjcf_height = 150;
    
    WeakSelf(ws);
    [self.bubbleBackImageView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(150);
        make.width.mas_equalTo(100);
    }];

    [_messageContentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.centerY.equalTo(ws.bubbleBackImageView);
        make.width.height.equalTo(ws.bubbleBackImageView);
    }];
    [_videoImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerX.centerY.equalTo(ws.messageContentView);
        make.width.height.equalTo(ws.messageContentView);

    }];
    [_playBtnImgView mas_remakeConstraints:^(MASConstraintMaker *make) {
        
        make.centerX.equalTo(ws.videoImageView);
        make.centerY.equalTo(ws.videoImageView);
        make.width.mas_equalTo(28);
        make.height.mas_equalTo(28);
    }];
    
    [_progressView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerX.centerY.equalTo(ws.videoImageView);
        make.width.height.equalTo(ws.videoImageView);
    }];


    self.messageContentView.gjcf_size = self.contentSize;
    NSString *imageName = self.isFromSelf ? @"bubbly_chat_right" : @"bubbly_chat_left";
    [self addmask:imageName onView:self.messageContentView];
}

#pragma mark - Init
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self createSubViews];
    }
    return self;
}

- (void)createSubViews
{
    [self.bubbleBackImageView addSubview:self.messageContentView];
    [self.messageContentView addSubview:self.videoImageView];
    [self.videoImageView addSubview:self.playBtnImgView];
    [self.videoImageView addSubview:self.progressView];
}


- (UIImageView *)messageContentView
{
    if (!_messageContentView)
    {
        _messageContentView = [[UIImageView alloc]init];
    }
    return _messageContentView;
}

- (UIImageView *)videoImageView
{
    if (!_videoImageView)
    {
        _videoImageView = [[UIImageView alloc]init];
    }
    return _videoImageView;
}

- (UIImageView *)playBtnImgView
{
    if (!_playBtnImgView)
    {
        _playBtnImgView = [[UIImageView alloc]init];
        _playBtnImgView.image = [UIImage imageNamed:@"playvideo_btn"];
    }
    return _playBtnImgView;
}

- (UCZProgressView *)progressView{
    if(!_progressView){
        _progressView = [[UCZProgressView alloc]init];
        _progressView.translatesAutoresizingMaskIntoConstraints = NO;
        _progressView.showsText = YES;
        _progressView.hidden = YES;
        _progressView.tintColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];

    }
    return _progressView;
}


@end
