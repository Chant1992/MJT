//
//  ChatFriendBaseCell.h
//  MJT_APP
//
//  Created by Donny on 2017/9/5.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "ChatBaseCell.h"
@interface ChatFriendBaseCell : ChatBaseCell

// 头像
@property (nonatomic, strong) UIImageView *headerView;
// 时间轴
@property (nonatomic, strong) UILabel *timerShaft;
// 时间轴背景
@property (nonatomic, strong) UIImageView *timerBgNode;
// 时间轴容器
@property (nonatomic, strong) UIImageView *timerContain;
// 群组显示昵称
@property (nonatomic, strong) UILabel *nickNameLabel;

//聊天气泡
@property (nonatomic,strong) UIImageView *bubbleBackImageView;

//发送状态
@property (nonatomic,strong) UIImageView *statusView;

//重新发送按钮
@property (nonatomic,strong) UIButton *resentButton;

// 转动动画
@property (nonatomic, strong) UIActivityIndicatorView *indicator;

@property (nonatomic,assign) CGFloat contentBordMargin;

//是否为群聊
@property (nonatomic,assign) BOOL isGroupChat;

//是否是我发送的
@property (nonatomic,assign)BOOL isFromSelf;

//是否需要显示时间轴
@property (nonatomic, assign) BOOL showTimeShaft;


- (void)adjustLayout;

- (int)judgeMessageStatus;


- (void)addmask:(NSString *)maskImgStr onView:(UIView *)view;


@end
