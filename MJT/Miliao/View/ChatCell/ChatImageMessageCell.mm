//
//  ChatImageMessageCell.m
//  MJT_APP
//
//  Created by olymtech on 2017/8/30.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "ChatImageMessageCell.h"
#import "UCZProgressView.h"
#import "UIImageView+ImageViewCell.h"
#import "OLYMMessageObject.h"
#import "UIImage+Image.h"
#import "FLAnimatedImageView.h"
#import "FLAnimatedImage.h"
#import <YYImage/YYImage.h>
#import "UIImage+Image.h"
#import <SDWebImage/SDImageCache.h>
#import "OLYMAESCrypt.h"

@interface ChatImageMessageCell()

@property (nonatomic,strong)YYAnimatedImageView *contentImageView;

@property (nonatomic,strong)UCZProgressView *progressView;

@property (nonatomic,strong)UIImageView *blankImageView;

@end

@implementation ChatImageMessageCell
@synthesize downloadProgress = _downloadProgress;

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        
        [self createSubViews];
    }
    
    return self;
}
 


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
        self.blankImageView.hidden = YES;
        self.progressView.hidden = YES;
    }
}



#pragma mark - 设置数据源
/* 虚方法 */
- (void)setContentModel:(OLYMMessageObject *)contentModel
{
    if (!contentModel) {
        return;
    }
    
    [super setContentModel:contentModel];
    
    
    if(contentModel.contentSize.height > 0){
        self.contentSize = contentModel.contentSize;
    }else{
        [self resetMaxContentImageViewSize];
    }
 
    //TODO 图片显示
    if (self.isFromSelf)
    {
        [self showImageFromDisk];
    }else
    {
        if(contentModel.isFileReceive){

            [self showImageFromDisk];
        }else{
            if(contentModel.thumbnail){
                UIImage *thumbImage = [UIImage imageFromBase64String:contentModel.thumbnail];
                [self.contentImageView setImage:thumbImage];
            }else
            {
                UIEdgeInsets insets = UIEdgeInsetsMake(25, 10, 10, 10);
                UIImage *bubbleImg = [UIImage imageWithSpecialStretch:insets imageStr:@"img_chat_msg_loading"];
                [self.contentImageView setImage:bubbleImg];
            }
            self.downloadProgress = self.contentModel.progress;
        }

    }
}


- (void)showImageFromDisk
{
    self.progressView.progress = 0.0f;
    self.progressView.hidden = YES;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        YYImage *image;// = (YYImage *)[[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:[NSString stringWithFormat:@"%ld%@",(long)[self.contentModel.timeSend timeIntervalSince1970],self.contentModel.filePath]];
        if (image)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.contentImageView.image = image;
            });
        }else
        {
            NSString *filePath = [[olym_FileCenter documentPrefix]stringByAppendingPathComponent:self.contentModel.filePath];
            NSError *error;
            NSData *data = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:&error];
            
            if(data){
                //先判断是否经过AES加密
                if (self.contentModel.isAESEncrypt)
                {
                    data = [OLYMAESCrypt decryptData:data];
                }
                YYImage *gifImage = [YYImage imageWithData:data];
//                [[SDImageCache sharedImageCache]storeImage:gifImage imageData:nil forKey:[NSString stringWithFormat:@"%ld%@",(long)[self.contentModel.timeSend timeIntervalSince1970],self.contentModel.filePath] toDisk:NO completion:NULL];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.contentImageView.image = gifImage;
                });
            }
            
        }
    });

}

#pragma mark - 计算显示宽高度
- (void)resetMaxContentImageViewSize
{
    double imgWidth = 0.0;
    double imgHeight = 0.0;
    
    if (self.contentModel.imageWidth > self.contentModel.imageHeight) {
        
        // 如果图片宽,以宽度为基准比例
        imgWidth = 200;
        imgHeight = self.contentModel.imageHeight * (200 / self.contentModel.imageWidth);
        // 如果图片横向拉长
        if (imgHeight < 90) {
            
            imgHeight = 90;
        }
        
    } else {
        
        // 如果图片高,以高度为基准比例
        imgHeight = 200;
        imgWidth = ((200 / self.contentModel.imageHeight) * self.contentModel.imageWidth);
        // 如果图片纵向拉长
        if (imgWidth < 90) {
            imgWidth = 90;
        }
    }
    
    if (self.contentModel.imageWidth == 0 || self.contentModel.imageHeight == 0)
    {
        imgHeight = 200;
        imgWidth = 90;

    }
    
    self.contentSize = CGSizeMake(imgWidth, imgHeight);
    
    
    [self resetLayoutWithWidth:imgWidth height:imgHeight];

}


#pragma mark - calculat bubble size

- (void)resetLayoutWithWidth:(NSInteger)width height:(NSInteger)height
{
    if(width <= 0){
        width = 100;
    }
    
    if(height <= 0 ){
        height = 100;
    }
    
    WeakSelf(ws);
    if (self.isFromSelf) {
   
        [_progressView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.centerX.centerY.equalTo(ws.contentImageView);
            make.width.height.equalTo(ws.contentImageView);
        }];
        
    } else {
        
        [self.indicator stopAnimating];
        
        [_progressView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.centerX.centerY.equalTo(ws.contentImageView);
            make.width.height.equalTo(ws.contentImageView);
        }];
        
    }
    
    
    self.contentImageView.gjcf_size = self.contentSize;
    /* 重设气泡 */
    self.bubbleBackImageView.gjcf_height = self.contentImageView.gjcf_height;
    self.bubbleBackImageView.gjcf_width = self.contentImageView.gjcf_width;
    
    [self adjustLayout];
    
    [self.contentImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.centerY.equalTo(ws.bubbleBackImageView);
        make.width.height.equalTo(ws.bubbleBackImageView);
    }];
    
    [self.bubbleBackImageView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(ws.contentSize.width);
        make.height.mas_equalTo(ws.contentSize.height);
    }];

    NSString *imageName = self.isFromSelf ? @"bubbly_chat_right" : @"bubbly_chat_left";
    [self addmask:imageName onView:self.contentImageView];

}

#pragma mark - setup
- (void)createSubViews {
    
    [self.bubbleBackImageView addSubview:self.contentImageView];
    
    [self.contentImageView addSubview:self.progressView];
    
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.contentImageView.image = nil;
}

#pragma mark - Property
- (UIImageView *)contentImageView {
    if(!_contentImageView){
        _contentImageView = [[YYAnimatedImageView alloc]init];
        _contentImageView.userInteractionEnabled = YES;
        _contentImageView.runloopMode = NSDefaultRunLoopMode;
        _contentImageView.autoPlayAnimatedImage = YES;
    }
    
    return _contentImageView;
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


- (UIImageView *)blankImageView
{
    if (!_blankImageView)
    {
        _blankImageView = [[UIImageView alloc]init];
    }
    return _blankImageView;
}

@end
