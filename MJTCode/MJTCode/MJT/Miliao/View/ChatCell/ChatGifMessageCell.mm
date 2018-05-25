//
//  CChaGifMessageCell.m
//  MJT_APP
//
//  Created by Donny on 2017/9/6.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "ChatGifMessageCell.h"
#import "UCZProgressView.h"
#import <YYImage/YYImage.h>

@interface ChatGifMessageCell ()

@property (nonatomic,strong) UCZProgressView *progressView;

@property (nonatomic,strong) YYAnimatedImageView *gifImgView;

@end


@implementation ChatGifMessageCell


- (void)setContentModel:(OLYMMessageObject *)contentModel
{
    [super setContentModel:contentModel];
 
    
    /* 重设气泡 */
    self.bubbleBackImageView.gjcf_height = self.gifImgView.gjcf_height;
    self.bubbleBackImageView.gjcf_width = self.gifImgView.gjcf_width;
    self.progressView.progress = 0.f;
    self.progressView.hidden = YES;
    
    
    self.gifImgView.image = nil;
    
    [self setGifImageContent];
    
    [self adjustLayout];
    
    WeakSelf(ws);
    [self.bubbleBackImageView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(ws.gifImgView.gjcf_width);
        make.height.mas_equalTo(ws.gifImgView.gjcf_height);
    }];

    self.bubbleBackImageView.image = nil;
    self.bubbleBackImageView.highlightedImage = nil;

}

- (void)setGifImageContent
{
    
}

#pragma mark - init
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])
    {
        [self createSubViews];
    }
    return self;
}

- (void)createSubViews
{
    [self.bubbleBackImageView addSubview:self.gifImgView];
    [self.gifImgView addSubview:self.progressView];
}

#pragma mark - property
- (YYAnimatedImageView *)gifImgView
{
    if (!_gifImgView)
    {
        _gifImgView = [[YYAnimatedImageView alloc]init];
        _gifImgView.autoPlayAnimatedImage = YES;
    }
    return _gifImgView;
}

- (UCZProgressView *)progressView
{
    if (!_progressView)
    {
        _progressView = [[UCZProgressView alloc]init];
        _progressView.frame = self.gifImgView.bounds;
        _progressView.hidden = YES;
    }
    return _progressView;
}

@end
