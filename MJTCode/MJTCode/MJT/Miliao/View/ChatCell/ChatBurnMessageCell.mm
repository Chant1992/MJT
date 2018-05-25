//
//  ChatBurnMessageCell.m
//  MJT_APP
//
//  Created by Donny on 2017/9/6.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "ChatBurnMessageCell.h"
#import "UCZProgressView.h"

@interface ChatBurnMessageCell ()

@property (nonatomic, strong) UIImageView *messgeContentView;
// 图片下载动画
@property (nonatomic,strong) UCZProgressView *progressView;

@end

@implementation ChatBurnMessageCell
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


- (CGFloat)heightForContentModel:(OLYMMessageObject *)contentModel
{
    self.cellMargin = 40;
    return self.bubbleBackImageView.gjcf_bottom + self.cellMargin;
}


- (void)setContentModel:(OLYMMessageObject *)contentModel
{
    [super setContentModel:contentModel];
    
    self.contentSize = CGSizeMake(107, 70);
    
    self.bubbleBackImageView.gjcf_height = self.contentSize.height;
    
    
    [self adjustLayout];
    
    WeakSelf(ws);
    [_messgeContentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.centerY.equalTo(ws.bubbleBackImageView);
        make.width.height.equalTo(ws.bubbleBackImageView);
    }];
    [_progressView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerX.centerY.equalTo(ws.messgeContentView);
        make.width.height.equalTo(ws.messgeContentView);
    }];

    
    [self chooseImage];
    
    
    if (!contentModel.isMySend) {
        
        if(contentModel.type == kWCMessageTypeText
           || contentModel.type == kWCMessageTypeVoice){
            //文本 语音不需要显示
            return;
        }
        if (contentModel.isFileReceive) {
            self.downloadProgress = self.contentModel.progress;
        }else
        {
            self.progressView.progress = 0.0f;
            self.progressView.hidden = YES;
        }
    }

}

- (void)updateSendStatus:(NSInteger)status
{
    [super updateSendStatus:status];
    self.contentModel.isSend = status;
    [self chooseImage];
}



- (void)chooseImage{
    
    self.bubbleBackImageView.image = nil;
    //显示相应图片
    
    if (self.contentModel.isMySend) {
        
        /*
         kWCMessageTypeText = 1,//文本
         kWCMessageTypeImage = 2,//图片
         kWCMessageTypeVoice = 3,//语音
         kWCMessageTypeVideo=6,//视频
         */
        if (self.contentModel.isSend == transfer_status_read)
        {
            self.messgeContentView.image = [UIImage imageNamed:@"burn_message_right"];
        }else
        {
            switch (self.contentModel.type) {
                case kWCMessageTypeText:
                    
                    self.messgeContentView.image = [UIImage imageNamed:@"burn_text_right"];
                    break;
                case kWCMessageTypeImage:
                    
                    self.messgeContentView.image = [UIImage imageNamed:@"burn_photo_right"];
                    break;
                case kWCMessageTypeVoice:
                    
                    self.messgeContentView.image = [UIImage imageNamed:@"burn_voice_right"];
                    break;
                case kWCMessageTypeVideo:
                    
                    self.messgeContentView.image = [UIImage imageNamed:@"burn_video_right"];
                    break;
                case kWCMessageTypeGif:
                    
                    break;
                default:
                    //type出错了
                    if (self.contentModel.filePath)
                    {
                        //图片或视频
                        NSString *fileExtension = [[self.contentModel.filePath componentsSeparatedByString:@"."]lastObject];
                        if ([fileExtension isEqualToString:@"mp4"] || [fileExtension isEqualToString:@"MP4"] || [fileExtension isEqualToString:@"MOV"])
                        {
                            self.messgeContentView.image = [UIImage imageNamed:@"burn_video_right"];
                        }
                        else if([fileExtension isEqualToString:@"amr"] || [fileExtension isEqualToString:@"wav"])
                        {
                            self.messgeContentView.image = [UIImage imageNamed:@"burn_voice_right"];
                        }else
                        {
                            self.messgeContentView.image = [UIImage imageNamed:@"burn_photo_right"];
                        }
                    }else
                    {
                        //语音或文字
                        if(self.contentModel.fileSize > 0)
                        {
                            self.messgeContentView.image = [UIImage imageNamed:@"burn_voice_right"];
                        }else
                        {
                            self.messgeContentView.image = [UIImage imageNamed:@"burn_text_right"];
                        }
                    }
                    break;
            }

        }
        
        
    }else{
        
        switch (self.contentModel.type) {
            case kWCMessageTypeText:
                
                self.messgeContentView.image = [UIImage imageNamed:@"burn_text_left"];
                break;
            case kWCMessageTypeImage:
                
                self.messgeContentView.image = [UIImage imageNamed:@"burn_photo_left"];
                
                break;
            case kWCMessageTypeVoice:
                
                self.messgeContentView.image = [UIImage imageNamed:@"burn_voice_left"];
                break;
            case kWCMessageTypeVideo:
                
                self.messgeContentView.image = [UIImage imageNamed:@"burn_video_left"];
                break;
                
            default:
                break;
        }
    }
    
    
}


#pragma mark - setup
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self createSubview];
    }
    return self;
}
- (void)createSubview
{
    [self.bubbleBackImageView addSubview:self.messgeContentView];
    [self.messgeContentView addSubview:self.progressView];
    
}

#pragma mark - Property
- (UCZProgressView *)progressView{
    if(!_progressView){
        _progressView = [[UCZProgressView alloc]init];
        _progressView.hidden = YES;
        _progressView.translatesAutoresizingMaskIntoConstraints = NO;
        _progressView.showsText = YES;
        _progressView.hidden = YES;
        _progressView.tintColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
    }
    return _progressView;
}

- (UIImageView *)messgeContentView
{
    if (!_messgeContentView) {
        _messgeContentView = [[UIImageView alloc]init];
    }
    return _messgeContentView;
}


@end
