//
//  ChatAudioMessageCell.h
//  MJT_APP
//
//  Created by Donny on 2017/9/5.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "ChatFriendBaseCell.h"

@interface ChatAudioMessageCell : ChatFriendBaseCell

/* 播放动画 */
@property (nonatomic,strong)UIImageView *audioPlayIndicatorView;

//语音长度
@property (nonatomic,strong)UILabel *audioTimeLabel;

@property (nonatomic,strong)UIImageView *blankImageView;
// 未读提示
@property (nonatomic, strong) UIImageView *unreadPrompt;

- (void)hiddenUnreadPrompt;

@end
