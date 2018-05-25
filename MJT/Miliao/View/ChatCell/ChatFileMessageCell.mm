//
//  ChatFileMessageCell.m
//  MJT_APP
//
//  Created by Donny on 2017/9/6.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "ChatFileMessageCell.h"
#import "UIView+Layer.h"
#import "UCZProgressView.h"
#import "UIImageView+CornerRadius.h"
#import "UIImage+Image.h"

#define WIDTHSCALE [UIScreen mainScreen].bounds.size.width / 375.0

@interface ChatFileMessageCell ()

// 文件名
@property (nonatomic, strong) UILabel *fileNameLabel;
// 文件头像
@property (nonatomic, strong) UIImageView *fileIconNode;
// 文件大小
@property (nonatomic, strong) UILabel *fileSizeLabel;
// 分割线
@property (nonatomic, strong) UIView *sepLineView;

@property (nonatomic,strong) UCZProgressView *progressView;

@end



@implementation ChatFileMessageCell
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
    return [super heightForContentModel:contentModel];
}

- (void)setContentModel:(OLYMMessageObject *)contentModel
{
    [super setContentModel:contentModel];
    
    self.contentSize = CGSizeMake(240 * WIDTHSCALE, 100);
    
    [self adjustLayout];
    
    [self changeLayout];
    
    
    [self fillContent];
}


- (void)fillContent
{
    // 获取不带前缀地址的文件名
    NSArray *fileNameArr = [self.contentModel.fileName componentsSeparatedByString:@"/"];
    NSString *realFileName = [NSString stringWithFormat:@"%@", fileNameArr.lastObject];
    _fileNameLabel.text = realFileName;
    
    // 获取后缀
    NSArray *fileSuffix = [self.contentModel.fileName componentsSeparatedByString:@"."];
    NSString *realFileSuffix = [NSString stringWithFormat:@"%@", fileSuffix.lastObject];
    
    UIImage *fileImg = nil;
    if ([realFileSuffix isEqualToString:@"txt"]) {
        
        fileImg = [UIImage imageNamed:@"txt_icon"];
    } else if ([realFileSuffix isEqualToString:@"png"] || [realFileSuffix isEqualToString:@"PNG"]) {
        
        fileImg = [UIImage imageNamed:@"png_icon"];
    } else if ([realFileSuffix isEqualToString:@"pdf"]) {
        
        fileImg = [UIImage imageNamed:@"pdf_icon"];
    } else if ([realFileSuffix isEqualToString:@"doc"] || [realFileSuffix isEqualToString:@"docx"]) {
        
        fileImg = [UIImage imageNamed:@"doc_icon"];
    } else if ([realFileSuffix isEqualToString:@"xls"] || [realFileSuffix isEqualToString:@"xlsx"]) {
        
        fileImg = [UIImage imageNamed:@"excel_icon"];
    } else if ([realFileSuffix isEqualToString:@"ppt"] || [realFileSuffix isEqualToString:@"pptx"]) {
        
        fileImg = [UIImage imageNamed:@"ppt_icon"];
    } else {
        
        fileImg = [UIImage imageNamed:@"icon_file_chat"];
    }
    
    _fileIconNode.image = fileImg;
    if (self.contentModel.fileSize > 0)
    {
        _fileSizeLabel.text = [self transformedfileSize:self.contentModel.fileSize];
    }
    
    if (!self.isFromSelf && !self.contentModel.isFileReceive)
    {
        //download
        self.downloadProgress = self.contentModel.progress;
    }else
    {
        self.progressView.progress = 0.0f;
        self.progressView.hidden = YES;
    }

}

- (void)changeLayout
{
    WeakSelf(ws);
    self.bubbleBackImageView.gjcf_height = 100;
    [self.bubbleBackImageView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(240 * WIDTHSCALE);
        make.height.mas_equalTo(100);
    }];
    [_fileIconNode mas_remakeConstraints:^(MASConstraintMaker *make) {
        if(ws.isFromSelf)
        {
            make.right.mas_equalTo(ws.bubbleBackImageView).offset(-18);
        }else
        {
            make.right.mas_equalTo(ws.bubbleBackImageView.mas_right).offset(-13);
        }
        make.top.equalTo(ws.bubbleBackImageView).offset(13);
        make.width.height.mas_equalTo(48);
    }];
    [_fileNameLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        if(ws.isFromSelf)
        {
            make.left.mas_equalTo(ws.bubbleBackImageView).offset(13);
        }else
        {
            make.left.mas_equalTo(ws.bubbleBackImageView).offset(18);
        }
        make.top.equalTo(ws.bubbleBackImageView).offset(13);
        make.right.equalTo(ws.fileIconNode.mas_left).offset(-13);
    }];
    [_sepLineView mas_remakeConstraints:^(MASConstraintMaker *make) {
        if(ws.isFromSelf)
        {
            make.left.equalTo(ws.bubbleBackImageView);
            make.right.equalTo(ws.bubbleBackImageView).offset(-7);
        }else
        {
            make.left.equalTo(ws.bubbleBackImageView).offset(7);
            make.right.equalTo(ws.bubbleBackImageView);
        }
        make.top.equalTo(ws.fileIconNode.mas_bottom).offset(13);
        make.height.mas_equalTo(1);
    }];
    [_fileSizeLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(ws.sepLineView.mas_bottom);
        make.left.equalTo(ws.fileNameLabel);
        make.bottom.equalTo(ws.bubbleBackImageView.mas_bottom);
    }];
    [_progressView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerX.centerY.equalTo(ws.bubbleBackImageView);
        make.width.height.equalTo(ws.bubbleBackImageView);
    }];
    
    // 更换聊天气泡
    UIEdgeInsets insets = UIEdgeInsetsMake(25, 10, 10, 10);
    if (self.isFromSelf)
    {
        UIImage *bubbleImg = [UIImage imageWithSpecialStretch:insets imageStr:@"bubbly_card_chat_right"];
        UIImage *bubbleImgHigh = [UIImage imageWithSpecialStretch:insets imageStr:@"bubbly_card_chat_right_pre"];
        
        self.bubbleBackImageView.image = bubbleImg;
        self.bubbleBackImageView.highlightedImage = bubbleImgHigh;
    }else
    {
        UIImage *bubbleImg = [UIImage imageWithSpecialStretch:insets imageStr:@"bubbly_card_chat_left"];
        UIImage *bubbleImgHigh = [UIImage imageWithSpecialStretch:insets imageStr:@"bubbly_card_chat_left_pre"];
        self.bubbleBackImageView.image = bubbleImg;
        self.bubbleBackImageView.highlightedImage = bubbleImgHigh;
    }

}

- (id)transformedfileSize:(CGFloat)filesize {
    
    double convertedValue = filesize;
    int multiplyFactor = 0;
    
    NSArray *tokens = [NSArray arrayWithObjects:@"bytes",@"KB",@"MB",@"GB",@"TB",nil];
    
    while (convertedValue > 1024) {
        convertedValue /= 1024;
        multiplyFactor++;
    }
    
    return [NSString stringWithFormat:@"%4.0f %@",convertedValue, [tokens objectAtIndex:multiplyFactor]];
}

#pragma mark - Init
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self createSubViews];
    }
    return self;
}


- (void)createSubViews {
    
    [self.bubbleBackImageView addSubview:self.fileNameLabel];
    [self.bubbleBackImageView addSubview:self.fileIconNode];
    [self.bubbleBackImageView addSubview:self.fileSizeLabel];
    [self.bubbleBackImageView addSubview:self.sepLineView];
    [self.bubbleBackImageView addSubview:self.progressView];
}

#pragma mark - property
- (UILabel *)fileNameLabel
{
    if(!_fileNameLabel)
    {
        _fileNameLabel = [[UILabel alloc]init];
        _fileNameLabel.text = @"我是文件名!";
        _fileNameLabel.numberOfLines = 2;
        _fileNameLabel.font = [UIFont systemFontOfSize:16];

    }
    return _fileNameLabel;
}

- (UIImageView *)fileIconNode
{
    if (!_fileIconNode)
    {
        _fileIconNode = [[UIImageView alloc]init];
        _fileIconNode.layer.cornerRadius = 5;
        _fileIconNode.layer.masksToBounds = YES;
//        [_fileIconNode zy_cornerRadiusAdvance:5 rectCornerType:UIRectCornerAllCorners];
    }
    return _fileIconNode;
}

- (UILabel *)fileSizeLabel
{
    if (!_fileSizeLabel)
    {
        _fileSizeLabel = [[UILabel alloc]init];
        _fileSizeLabel.textColor = OLYMHEXCOLOR(0x888888);
        _fileSizeLabel.font = [UIFont systemFontOfSize:14];

    }
    return _fileSizeLabel;
}

- (UIView *)sepLineView
{
    if (!_sepLineView)
    {
        _sepLineView = [[UIView alloc]init];
        _sepLineView.backgroundColor = OLYMHEXCOLOR(0xd0d0d0);

    }
    return _sepLineView;
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
