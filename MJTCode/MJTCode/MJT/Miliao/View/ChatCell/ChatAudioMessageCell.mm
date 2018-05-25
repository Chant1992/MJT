//
//  ChatAudioMessageCell.m
//  MJT_APP
//
//  Created by Donny on 2017/9/5.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "ChatAudioMessageCell.h"
#import "UIImage+Image.h"
#import "UIView+Layer.h"
#import "UIImageView+CornerRadius.h"
#import "UIImage+LYColor.h"

#define HEAD_SIZE 40.0f//头像大小
#define ALIAS_SIZE_WIDTH 100.0f//别名宽度
#define ALIAS_SIZE_HEIGHT 15.0f//别名高度

#define TEXT_MAX_HEIGHT 500.0f

#define INSETS 10//间距

#define GJCFSystemScreenWidth [UIScreen mainScreen].bounds.size.width


@interface ChatAudioMessageCell ()

/* 动画数组 */
@property(nonatomic,strong) NSMutableArray *animationArray;


@end



@implementation ChatAudioMessageCell
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])
    {
        [self createSubViews];
    }
    return self;
}


- (void)startVoiceAnimation
{
    if(self.audioPlayIndicatorView.animating)
    {
        return;
    }
    [self.audioPlayIndicatorView startAnimating];
}

- (void)stopVoiceAnimation
{
    [self.audioPlayIndicatorView stopAnimating];
}

- (void)hiddenUnreadPrompt
{
    self.unreadPrompt.hidden = YES;
}


#pragma mark - set Data
- (void)setContentModel:(OLYMMessageObject *)contentModel
{
    [super setContentModel:contentModel];
    
    _audioTimeLabel.text = [NSString stringWithFormat:@"%d''",(int)self.contentModel.fileSize];
    
    [self changeLayout];
}

- (void)changeLayout
{
    float w = (GJCFSystemScreenWidth - HEAD_SIZE-INSETS * 2 - 70) / 30;
    w = 70 + w * (int)self.contentModel.fileSize;
    if(w < 70)
        w = 70;
    if(w > 200)
        w = 200;
    
    WeakSelf(ws);
    
    if (_animationArray == nil) {
        
        _animationArray = [NSMutableArray array];
    }
    
    [_animationArray removeAllObjects];
    
    [self adjustLayout];
    if(self.isFromSelf)
    {
        _unreadPrompt.hidden = YES;
        _audioTimeLabel.textColor = [UIColor whiteColor];

    }else
    {
        // 如果是未读消息显示未读提示
        if(self.contentModel.isRead) {
            _unreadPrompt.hidden = YES;
        } else {
            
            _unreadPrompt.hidden = NO;
        }
        
        _audioTimeLabel.textColor = OLYMHEXCOLOR(0x999999);
        
    }
    
    //语音播放
    //更改播放语音动画的图片
    NSString *file,*s;
    file = self.isFromSelf ? @"voice_paly_right_" : @"voice_paly_left_";
    for(int i=1;i<=3;i++){
        s = [NSString stringWithFormat:@"%@%d",file,i];
        [_animationArray addObject:[UIImage imageNamed:s]];
    }
    _audioPlayIndicatorView.image = [UIImage imageNamed:s];
    _audioPlayIndicatorView.animationImages = _animationArray;
    _audioPlayIndicatorView.animationDuration = 1;

    
    [self.bubbleBackImageView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(w);
        make.height.mas_equalTo(40);
    }];

    [_audioTimeLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        
        if(ws.isFromSelf)
        {
            make.right.mas_equalTo(ws.audioPlayIndicatorView.mas_left).offset(-15);
        }else
        {
            make.left.mas_equalTo(ws.audioPlayIndicatorView.mas_right).offset(15);
        }
        make.centerY.mas_equalTo(ws.bubbleBackImageView.mas_centerY);
    }];
    [_audioPlayIndicatorView mas_remakeConstraints:^(MASConstraintMaker *make) {
        
        if(ws.isFromSelf)
        {
            make.right.equalTo(ws.bubbleBackImageView).offset(-15);
        }else
        {
            make.left.equalTo(ws.bubbleBackImageView).offset(15);
        }
        make.centerY.mas_equalTo(ws.bubbleBackImageView.mas_centerY);
        make.width.height.mas_equalTo(24);
    }];
    [_unreadPrompt mas_remakeConstraints:^(MASConstraintMaker *make) {
        
        make.left.equalTo(ws.bubbleBackImageView.mas_right).offset(5);
        make.centerY.equalTo(ws.bubbleBackImageView);
        make.height.width.mas_equalTo(10);
    }];
    
}


- (void)createSubViews
{
    [self.bubbleBackImageView addSubview:self.audioPlayIndicatorView];
    [self.contentView addSubview:self.audioTimeLabel];
    [self.contentView addSubview:self.unreadPrompt];

}

#pragma mark - property

- (UIImageView *)audioPlayIndicatorView
{
    if (!_audioPlayIndicatorView)
    {
        _audioPlayIndicatorView = [[UIImageView alloc]init];
        _audioPlayIndicatorView.userInteractionEnabled = YES;
    }
    return _audioPlayIndicatorView;
}

- (UIImageView *)unreadPrompt
{
    if (!_unreadPrompt)
    {
        _unreadPrompt = [[UIImageView alloc]init];
        _unreadPrompt.backgroundColor = [UIColor redColor];
        _unreadPrompt.layer.cornerRadius = 5;
    }
    return _unreadPrompt;
}

- (UILabel *)audioTimeLabel
{
    if (!_audioTimeLabel) {
        _audioTimeLabel = [[UILabel alloc]init];
        _audioTimeLabel.backgroundColor = [UIColor clearColor];
        _audioTimeLabel.textColor = [UIColor blackColor];
        _audioTimeLabel.font = [UIFont systemFontOfSize:13];
        _audioTimeLabel.userInteractionEnabled = NO;
        _audioTimeLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _audioTimeLabel;
}




@end
