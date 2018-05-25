//
//  ChatFileCell.m
//  MJT_APP
//
//  Created by Donny on 2017/9/13.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "ChatFileCell.h"
#import <MediaPlayer/MediaPlayer.h>
#import "OLYMAESCrypt.h"

@interface ChatFileCell ()

/* 图片 */
@property(nonatomic,strong) UIImageView *imageView;
/* 播放图标 */
@property(nonatomic,strong) UIImageView *playIcon;
/* 时间 */
@property(nonatomic,strong) UILabel *durationLabel;

@property(nonatomic,strong) UIImageView *checkView;

@end



@implementation ChatFileCell

-(instancetype)initWithFrame:(CGRect)frame{
    
    self = [super initWithFrame:frame];
    
    if (self) {
        
        [self creatSubview];
    }
    
    return self;
}


- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    if (selected)
    {
        _checkView.image = [UIImage imageNamed:@"cell_check"];
    }else
    {
        _checkView.image = [UIImage imageNamed:@"cell_uncheck"];
    }
}


#pragma mark <------------------- Getter/Setter ------------------->
-(void)setFileObj:(OLYMMessageObject *)fileObj{
    
    _fileObj = fileObj;
    _playView.hidden = YES;
    
    NSString *lastPath = _fileObj.filePath;
    
    NSString *extension = [lastPath pathExtension];
    
    if ([extension isEqualToString:@"mp4"]) {
        
        //视频的话添加播放按钮
        lastPath = [NSString stringWithFormat:@"%@.jpg",[lastPath stringByDeletingPathExtension]];
        _playView.hidden = NO;
        
    }
    
    NSString *filePath = [[olym_FileCenter documentPrefix]stringByAppendingPathComponent:lastPath];
    
    UIImage *image;
    
    if (self.fileObj.isAESEncrypt)
    {
        NSData *data = [OLYMAESCrypt decryptFile:filePath];
        image = [UIImage imageWithData:data];
    }else
    {
        image = [UIImage imageWithContentsOfFile:filePath];
    }
    
    if ([extension isEqualToString:@"txt"]) {
        
        image = [UIImage imageNamed:@"txt_icon"];
    } else if ([extension isEqualToString:@"png"] || [extension isEqualToString:@"PNG"]) {
        
        image = [UIImage imageNamed:@"png_icon"];
    } else if ([extension isEqualToString:@"pdf"]) {
        
        image = [UIImage imageNamed:@"pdf_icon"];
    } else if ([extension isEqualToString:@"doc"] || [extension isEqualToString:@"docx"]) {
        
        image = [UIImage imageNamed:@"doc_icon"];
    } else if ([extension isEqualToString:@"xls"] || [extension isEqualToString:@"xlsx"]) {
        
        image = [UIImage imageNamed:@"excel_icon"];
    } else if ([extension isEqualToString:@"ppt"] || [extension isEqualToString:@"pptx"]) {
        
        image = [UIImage imageNamed:@"ppt_icon"];
    }else
    {
        if(!image)
        {
            image = [UIImage imageNamed:@"icon_file_chat"];
        }
    }
    
    
    _imageView.image = image;
}

#pragma mark - setup
-(void)creatSubview{
    
    [self.contentView addSubview:self.imageView];
    [_imageView addSubview:self.playView];
    [_playView addSubview:self.playIcon];
    [_playView addSubview:self.durationLabel];
    [_imageView addSubview:self.checkView];
    
    WeakSelf(ws);
    
    [_imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.edges.mas_equalTo(ws.contentView);
    }];
    
    [_playView mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.left.right.bottom.mas_equalTo(ws.contentView);
        make.height.mas_equalTo(18);
    }];
    
    [_playIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.centerY.mas_equalTo(_playView);
        make.left.mas_equalTo(_playView.mas_left).offset(9);
    }];
    
    [_durationLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.center.mas_equalTo(_playView);
    }];
    
    [_checkView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(_imageView).offset(2);
        make.right.mas_equalTo(_imageView).offset(-2);
        make.width.height.mas_equalTo(@25);
    }];
    
}


-(UIImageView *)imageView{
    
    if (!_imageView) {
        
        _imageView = [[UIImageView alloc]init];
        
        //图片自适应只显示中间部分
        [_imageView setContentScaleFactor:[[UIScreen mainScreen] scale]];
        _imageView.contentMode =  UIViewContentModeScaleAspectFill;
        _imageView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        _imageView.clipsToBounds  = YES;
        _imageView.tag = 100;
    }
    
    return _imageView;
}

-(UIView *)playView{
    
    if (!_playView) {
        
        _playView = [[UIView alloc]init];
        _playView.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.5];
        
    }
    
    return _playView;
}

-(UIImageView *)playIcon{
    
    if (!_playIcon) {
        
        _playIcon = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"video"]];
        
    }
    
    return _playIcon;
}

-(UILabel *)durationLabel{
    
    if (!_durationLabel) {
        
        _durationLabel = [[UILabel alloc]init];
        
        _durationLabel.font = [UIFont systemFontOfSize:8];
        _durationLabel.textColor = [UIColor whiteColor];
    }
    
    return _durationLabel;
}

- (UIImageView *)checkView
{
    if (!_checkView)
    {
        _checkView = [[UIImageView alloc]init];
        _checkView.hidden = YES;
        _checkView.image = [UIImage imageNamed:@"cell_uncheck"];
    }
    return _checkView;
}


@end
