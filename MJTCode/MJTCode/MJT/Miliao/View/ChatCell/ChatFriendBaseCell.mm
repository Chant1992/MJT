//
//  ChatFriendBaseCell.m
//  MJT_APP
//
//  Created by Donny on 2017/9/5.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "ChatFriendBaseCell.h"
#import "OLYMMessageObject.h"
#import "OLYMUserBaseObj.h"
#import "UIView+Layer.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "UIImage+Image.h"
#import "UIImageView+CornerRadius.h"
#import "UIImage+LYColor.h"
#import "TimeUtil.h"
#import "OLYMUserObject.h"

@interface ChatFriendBaseCell ()

@property (nonatomic, strong) UIImageView *checkImageView;

@end

@implementation ChatFriendBaseCell
@synthesize cellMargin = _cellMargin;
@synthesize contentSize = _contentSize;
@synthesize downloadProgress = _downloadProgress;

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])
    {
        self.multipleSelectionBackgroundView = [UIView new];
        UIView *bgColorView = [[UIView alloc] init];
        bgColorView.backgroundColor = [UIColor clearColor];
        [self setSelectedBackgroundView:bgColorView];

        self.cellMargin = 20;
        
        self.contentBordMargin = 13.f;
        
        [self addSubViews];
        
        [self addLongPress];
        
        [self addTapGesture];
        
        @weakify(self);
        [[self.resentButton rac_signalForControlEvents:UIControlEventTouchUpInside]subscribeNext:^(__kindof UIControl * _Nullable x) {
            @strongify(self);
            [self resendTheMsg];
        }];
    }
    return self;
}


- (void)setContentModel:(OLYMMessageObject *)contentModel
{
    [super setContentModel:contentModel];
    self.isFromSelf = contentModel.isMySend;
//    self.sendStatus = chatContentModel.sendStatus;
    self.isGroupChat = contentModel.isGroup;
    //self.faildType = chatContentModel.faildType;
    //self.faildReason = chatContentModel.faildReason;
    //self.talkType = chatContentModel.talkType;
    //self.contentType = chatContentModel.contentType;
    
    self.showTimeShaft = contentModel.isShowTime;
//    [self.headView setHeadUrl:chatContentModel.headUrl];
    
    //这里设置用户头像
    if (self.isGroupChat && !self.isFromSelf) {
        self.nickNameLabel.hidden = NO;
        self.nickNameLabel.text = contentModel.fromUserName;
        
        //设置未知用户的昵称
        OLYMUserObject *user = [[OLYMUserObject alloc]init];
        user.userId = contentModel.fromUserId;
        user.userNickname = contentModel.fromUserName;
        NSString *displayName = [user getDisplayName];
        
        if ([displayName isEqualToString:_T(@"未知用户")] &&
            [user.userNickname isEqualToString:user.telephone] ) {
            
            //只有当备注改了的情况下，才显示未知用户
            self.nickNameLabel.text = _T(@"未知用户");
        }
        
    }else{
        self.nickNameLabel.hidden = YES;
    }

    [self judgeMessageStatus];
    NSString *domain = contentModel.domain;
    if ([domain containsString:@"muc."])
    {
        domain = [domain stringByReplacingOccurrencesOfString:@"muc." withString:@""];
    }
    NSString *userHeaderUrl =  [HeaderImageUtils getHeaderImageUrl:contentModel.fromUserId withDomain:domain];
    
    [self.headerView setImageUrl:userHeaderUrl withDefault:@"chat_groups_header"];
}

- (CGFloat)heightForContentModel:(OLYMMessageObject *)contentModel
{
    return self.bubbleBackImageView.gjcf_bottom + self.cellMargin;
}




- (int)judgeMessageStatus
{
    [self updateSendStatus:self.contentModel.isSend];
    return self.contentModel.isSend;
}

- (void)updateSendStatus:(NSInteger)status
{
    if (_indicator && _indicator.isAnimating)
    {
        [_indicator stopAnimating];
    }
    if (self.isFromSelf)
    {
        _statusView.hidden = YES;
        _resentButton.hidden = YES;
    }else
    {
        [_indicator stopAnimating];
    }
    
    //在非群聊状态下显示我发送的消息状态
    if(self.isFromSelf)
    {
        if (!self.isGroupChat)
        {
            switch (status) {
                    
                case transfer_status_yes: {
#if MESSAGESTATEOFF
                    _statusView.hidden = NO;
#elif JiaMiTong
                    _statusView.hidden = YES;
#else
                    _statusView.hidden = ![olym_UserCenter getMessageSentOn];
#endif
                    _statusView.image = [UIImage imageNamed:_T(@"msg_chat_send")];
                    _resentButton.hidden = YES;
                    [_indicator stopAnimating];
                    
                    break;
                }
                case transfer_status_send: {
#if MESSAGESTATEOFF
                    _statusView.hidden = NO;
#elif JiaMiTong
                    _statusView.hidden = YES;
#else
                    _statusView.hidden = ![olym_UserCenter getMessageRecivedOn];
#endif
                    _statusView.image = [UIImage imageNamed:_T(@"msg_receive_chat")];
                    _resentButton.hidden = YES;
                    [_indicator stopAnimating];
                    
                    break;
                }
                    
                case transfer_status_read:  {
#if MESSAGESTATEOFF
                    _statusView.hidden = NO;
#elif JiaMiTong
                    _statusView.hidden = YES;
#else
                    _statusView.hidden = ![olym_UserCenter getMessageReadedOn];
#endif
                    _statusView.image = [UIImage imageNamed:_T(@"msg_read_chat")];
                    _resentButton.hidden = YES;
                    [_indicator stopAnimating];
                    break;
                }
                    //正在发送
                case transfer_status_ing:
                    _statusView.hidden = YES;
                    _resentButton.hidden = YES;
                    [_indicator startAnimating];
                    break;
                case transfer_status_no:
                    _statusView.hidden = YES;
                    _resentButton.hidden = NO;
                    [_indicator stopAnimating];
                    break;
                default:
                    break;
            }
            
        }else
        {
            if (status == transfer_status_ing)
            {
                _statusView.hidden = YES;
                _resentButton.hidden = YES;
                [_indicator startAnimating];
            }else if(status == transfer_status_no)
            {
                _statusView.hidden = YES;
                _resentButton.hidden = NO;
                [_indicator stopAnimating];
            }else
            {
                _statusView.hidden = YES;
                _resentButton.hidden = YES;
                [_indicator stopAnimating];
            }
        }
    }else
    {
        _statusView.hidden = YES;
        if (self.isFromSelf && self.isGroupChat && status == transfer_status_no)
        {
            _resentButton.hidden = NO;
        }else
        {
            _resentButton.hidden = YES;
        }
    }

}


#pragma mark - Action

- (void)goToShowLongPressMenu:(UILongPressGestureRecognizer *)sender
{
    
    [self becomeFirstResponder];
    
    UIMenuController *popMenu = [UIMenuController sharedMenuController];
    if (popMenu.isMenuVisible) {
        return;
    }
    BOOL canRecall = [self messageCanRecall];
#if MJTDEV
    NSArray *menuItems = [self menuSourceForDeveloper:canRecall];
#else
    NSArray *menuItems = [self menuItemSource:canRecall];
#endif
    [popMenu setMenuItems:menuItems];
    [popMenu setArrowDirection:UIMenuControllerArrowDown];
    
    [popMenu setTargetRect:self.bubbleBackImageView.frame inView:self];
    [popMenu setMenuVisible:YES animated:YES];

}

- (void)tapOnBubbleView:(UITapGestureRecognizer *)gesture
{
    if(self.contentModel.isReadburn)
    {
        if ([self.delegate respondsToSelector:@selector(chatCellDidTapBurnAfterReadMessage:)]) {
            [self.delegate chatCellDidTapBurnAfterReadMessage:self];
        }
        return;
    }
    int type = self.contentModel.type;
    switch (type) {
            break;
        case kWCMessageTypeVoice:
        {
            if ([self.delegate respondsToSelector:@selector(chatCellDidTapAudioMessage:)]) {
                [self.delegate chatCellDidTapAudioMessage:self];
            }
        }
            break;
        case kWCMessageTypeImage:
        {
            if ([self.delegate respondsToSelector:@selector(chatCellDidTapImageMessage:)]) {
                [self.delegate chatCellDidTapImageMessage:self];
            }
        }
            break;
        case kWCMessageTypeVideo:
        {
            if ([self.delegate respondsToSelector:@selector(chatCellDidTapVideoMessage:)]) {
                [self.delegate chatCellDidTapVideoMessage:self];
            }
        }
            break;
        case kWCMessageTypeFile:
        {
            if ([self.delegate respondsToSelector:@selector(chatCellDidTapFileMessage:)]) {
                [self.delegate chatCellDidTapFileMessage:self];
            }
        }
            break;
        case kWCMessageTypeCard:
        {
            if ([self.delegate respondsToSelector:@selector(chatCellDidTapCardMessage:)]) {
                [self.delegate chatCellDidTapCardMessage:self];
            }
        }
            break;
            
        default:
            break;
    }

}

- (void)resendTheMsg {
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatCellResendMessage:)]) {
        [self.delegate chatCellResendMessage:self];
    }
}

- (void)longPressOnHeadView:(id)gesture
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatCellDidLongPressHeader:)]) {
        [self.delegate chatCellDidLongPressHeader:self];
    }
}

- (void)tapOnHeadView:(id)gesture
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatCellDidTapHeader:)]) {
        [self.delegate chatCellDidTapHeader:self];
    }

}

- (void)addLongPress
{
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(goToShowLongPressMenu:)];
    longPress.minimumPressDuration = 0.5;
    
    self.bubbleBackImageView.userInteractionEnabled = YES;
    [self.bubbleBackImageView addGestureRecognizer:longPress];
}


- (void)addTapGesture
{
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapOnBubbleView:)];
    tap.numberOfTapsRequired = 1;
    [self.bubbleBackImageView addGestureRecognizer:tap];

}


- (BOOL)canBecomeFirstResponder {
    return true;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    if (action == @selector(copyContent:) || action == @selector(deleteMessage:) || action == @selector(transpondContent:)|| action == @selector(decodeContent:) || action == @selector(referenceMessage:)|| action == @selector(recallMessage:) || action == @selector(mutilSelectMessage:)) {
        return YES;
    }
    return NO; //隐藏系统默认的菜单项
}


#pragma mark - Menu Response
- (void)deleteMessage:(UIMenuItem *)item
{
    /* 删除消息会导致正在发送消息的请求结果返回时候更新不了本地库 */
    if (self.contentModel.isSend <= 0) {
        
//        [self.bubbleBg setHighlighted:NO];
        return;
    }
    
    //handle delete message
    if ([self.delegate respondsToSelector:@selector(chatCellDeleteMessage:)])
    {
        [self.delegate chatCellDeleteMessage:self];
    }
}

- (void)copyContent:(UIMenuItem *)item
{
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    [pasteboard setString:self.contentModel.content];
}

- (void)transpondContent:(UIMenuItem *)item
{
    if ([self.delegate respondsToSelector:@selector(chatCellTranspondMessage:)])
    {
        [self.delegate chatCellTranspondMessage:self];
    }
}


- (void)decodeContent:(UIMenuItem *)item
{
    if (self.contentModel.isEncrypt && !self.isFromSelf)
    {
        if ([self.delegate respondsToSelector:@selector(chatCellDecodeMessage:)]) {
            [self.delegate chatCellDecodeMessage:self];
        }
    }else
    {
#if XYT
#else
        [SVProgressHUD showSuccessWithStatus:_T(@"该消息未加密")];
#endif
    }
}

- (void)reDowmload:(UIMenuItem *)item
{
    if([self.delegate respondsToSelector:@selector(chatCellReDownload:)]){
        [self.delegate chatCellReDownload:self];
    }
}

- (void)referenceMessage:(UIMenuItem *)item
{
    if([self.delegate respondsToSelector:@selector(chatCellReferenceMessage:)]){
        [self.delegate chatCellReferenceMessage:self];
    }
}

- (void)recallMessage:(UIMenuItem *)item
{
    if([self.delegate respondsToSelector:@selector(chatCellReCallMessage:)]){
        [self.delegate chatCellReCallMessage:self];
    }
}

- (void)mutilSelectMessage:(UIMenuItem *)item
{
    if([self.delegate respondsToSelector:@selector(chatCellMutiSelectMessage:)]){
        [self.delegate chatCellMutiSelectMessage:self];
    }
}

#pragma mark - Menu Source
- (BOOL)messageCanRecall
{
    BOOL canRecall = NO;
    if (self.contentModel.isMySend && self.contentModel.isSend != transfer_status_ing && self.contentModel.isSend != transfer_status_no)
    {
        NSTimeInterval now = [[NSDate date]timeIntervalSince1970];
        NSTimeInterval timeSend = [self.contentModel.timeSend timeIntervalSince1970];
        if (now - timeSend < 120)
        {
            canRecall = YES;
        }
    }
    return canRecall;
}

- (NSArray *)menuItemSource:(BOOL)canRecall
{
    int type = self.contentModel.type;
    if(self.contentModel.isReadburn)
    {
        UIMenuItem *item = [self deleteMenuItem];
        NSArray *menuItems = @[item];
        return menuItems;
    }
    
    NSArray *menuItems;
    switch (type) {
        case kWCMessageTypeText:
            //
        {
            UIMenuItem *item1 = [self copyMenuItem];
            UIMenuItem *item2 = [self deleteMenuItem];
            UIMenuItem *item3 = [self forwordMenuItem];
            UIMenuItem *item4 = [self decryptMenuItem];

            UIMenuItem *item5 = [[UIMenuItem alloc] initWithTitle:_T(@"引用") action:@selector(referenceMessage:)];
            if (canRecall)
            {
                menuItems = @[item1,item5,[self recallMenuItem],item2,item3,item4];
            }else
            {
                menuItems = @[item1,item5,item2,item3,item4];
            }

        }
            break;
        case kWCMessageTypeVoice:
        {

            UIMenuItem *item2 = [self deleteMenuItem];
            UIMenuItem *item4 = [self decryptMenuItem];

            if (canRecall)
            {
                menuItems = @[[self recallMenuItem],item2,item4];
            }else
            {
                menuItems = @[item2,item4];
            }

        }
            break;
        case kWCMessageTypeImage:
        {

            UIMenuItem *item2 = [self deleteMenuItem];
            UIMenuItem *item3 = [self forwordMenuItem];
            UIMenuItem *item4 = [self decryptMenuItem];

            if (canRecall)
            {
                menuItems = @[[self recallMenuItem],item2,item3,item4];
            }else
            {
                menuItems = @[item2,item3,item4];
            }

        }
            break;
        case kWCMessageTypeVideo:
        {

            UIMenuItem *item2 = [self deleteMenuItem];
            UIMenuItem *item3 = [self forwordMenuItem];
            UIMenuItem *item4 = [self decryptMenuItem];

            if (canRecall)
            {
                menuItems = @[[self recallMenuItem],item2,item3,item4];
            }else
            {
                menuItems = @[item2,item3,item4];
            }

        }
            break;
        case kWCMessageTypeFile:
        {
            UIMenuItem *item2 = [self deleteMenuItem];
            UIMenuItem *item3 = [self forwordMenuItem];
            UIMenuItem *item4 = [self decryptMenuItem];
            UIMenuItem *item5 = [self redownloadMenuItem];

            if (canRecall)
            {
                menuItems = @[[self recallMenuItem],item2,item3,item4,item5];
            }else
            {
                menuItems = @[item2,item3,item4,item5];
            }

        }
            break;
        case kWCMessageTypeCard:
        {

            UIMenuItem *item2 = [self deleteMenuItem];
            UIMenuItem *item4 = [self decryptMenuItem];

            if (canRecall)
            {
                menuItems = @[[self recallMenuItem],item2,item4];
            }else
            {
                menuItems = @[item2,item4];
            }

        }
            break;
        default:
            
            UIMenuItem *item1 = [self copyMenuItem];
            UIMenuItem *item2 = [self deleteMenuItem];

            if (canRecall)
            {
                menuItems = @[item1,[self recallMenuItem],item2];
            }else
            {
                menuItems = @[item1,item2];
            }

            break;
    }
    return menuItems;
    
}

- (NSArray *)menuSourceForDeveloper:(BOOL)canRecall
{
    int type = self.contentModel.type;
    if(self.contentModel.isReadburn)
    {
        UIMenuItem *item = [self deleteMenuItem];
        NSArray *menuItems = @[item];
        return menuItems;
    }
    BOOL isEncrypt = self.contentModel.isEncrypt && !self.isFromSelf;
    NSMutableArray *menuItems = [NSMutableArray array];
    switch (type) {
        case kWCMessageTypeText:
            //
        {
            UIMenuItem *item1 = [self copyMenuItem];
            UIMenuItem *item2 = [self deleteMenuItem];
            UIMenuItem *item3 = [self forwordMenuItem];
            UIMenuItem *item4 = [self decryptMenuItem];
            UIMenuItem *item5 = [[UIMenuItem alloc] initWithTitle:_T(@"引用") action:@selector(referenceMessage:)];
            [menuItems addObject:item1];
            [menuItems addObject:item2];
            [menuItems addObject:item3];
            [menuItems addObject:item5];
            if (isEncrypt)
            {
                [menuItems addObject:item4];
            }
            if (canRecall)
            {
                [menuItems insertObject:[self recallMenuItem] atIndex:2];
            }
            [menuItems addObject:[self multiSelectMenuItem]];
        }
            break;
        case kWCMessageTypeVoice:
        {
            
            UIMenuItem *item2 = [self deleteMenuItem];
            UIMenuItem *item4 = [self decryptMenuItem];
            [menuItems addObject:item2];
            if (isEncrypt)
            {
                [menuItems addObject:item4];
            }
            if (canRecall)
            {
                [menuItems insertObject:[self recallMenuItem] atIndex:0];
            }
        }
            break;
        case kWCMessageTypeImage:
        {
            
            UIMenuItem *item2 = [self deleteMenuItem];
            UIMenuItem *item3 = [self forwordMenuItem];
            UIMenuItem *item4 = [self decryptMenuItem];
            [menuItems addObject:item2];
            [menuItems addObject:item3];
            if (isEncrypt)
            {
                [menuItems addObject:item4];
            }
            if (canRecall)
            {
                [menuItems insertObject:[self recallMenuItem] atIndex:0];
            }
            [menuItems addObject:[self multiSelectMenuItem]];
        }
            break;
        case kWCMessageTypeVideo:
        {
            
            UIMenuItem *item2 = [self deleteMenuItem];
            UIMenuItem *item3 = [self forwordMenuItem];
            UIMenuItem *item4 = [self decryptMenuItem];
            [menuItems addObject:item2];
            [menuItems addObject:item3];
            if (isEncrypt)
            {
                [menuItems addObject:item4];
            }
            if (canRecall)
            {
                [menuItems insertObject:[self recallMenuItem] atIndex:0];
            }
            [menuItems addObject:[self multiSelectMenuItem]];
        }
            break;
        case kWCMessageTypeFile:
        {
            UIMenuItem *item2 = [self deleteMenuItem];
            UIMenuItem *item3 = [self forwordMenuItem];
            UIMenuItem *item4 = [self decryptMenuItem];
            UIMenuItem *item5 = [self redownloadMenuItem];
            [menuItems addObject:item2];
            [menuItems addObject:item3];
            if (isEncrypt)
            {
                [menuItems addObject:item4];
            }
            [menuItems addObject:item5];
            if (canRecall)
            {
                [menuItems insertObject:[self recallMenuItem] atIndex:0];
            }
            [menuItems addObject:[self multiSelectMenuItem]];
        }
            break;
        case kWCMessageTypeCard:
        {
            
            UIMenuItem *item2 = [self deleteMenuItem];
            UIMenuItem *item4 = [self decryptMenuItem];
            [menuItems addObject:item2];
            if (isEncrypt)
            {
                [menuItems addObject:item4];
            }
            if (canRecall)
            {
                [menuItems insertObject:[self recallMenuItem] atIndex:0];
            }
        }
            break;
        default:
            
            UIMenuItem *item1 = [self copyMenuItem];
            UIMenuItem *item2 = [self deleteMenuItem];
            [menuItems addObject:item1];
            [menuItems addObject:item2];
            if (canRecall)
            {
                [menuItems insertObject:[self recallMenuItem] atIndex:1];
            }
            break;
    }
    return menuItems;
}

- (UIMenuItem *)copyMenuItem
{
    return [[UIMenuItem alloc] initWithTitle:_T(@"复制") action:@selector(copyContent:)];
}

- (UIMenuItem *)forwordMenuItem
{
    return [[UIMenuItem alloc] initWithTitle:_T(@"转发") action:@selector(transpondContent:)];
}

- (UIMenuItem *)deleteMenuItem
{
    return [[UIMenuItem alloc] initWithTitle:_T(@"删除") action:@selector(deleteMessage:)];;
}

- (UIMenuItem *)decryptMenuItem
{
#if XYT
    NSString *menuTitle = _T(@"解密_xyt");
#else
    NSString *menuTitle = _T(@"解密");
#endif
    return [[UIMenuItem alloc] initWithTitle:menuTitle action:@selector(decodeContent:)];
}

- (UIMenuItem *)multiSelectMenuItem
{
    return [[UIMenuItem alloc] initWithTitle:_T(@"多选") action:@selector(mutilSelectMessage:)];
}

- (UIMenuItem *)redownloadMenuItem
{
    return [[UIMenuItem alloc] initWithTitle:_T(@"重新下载") action:@selector(reDowmload:)];
}


- (UIMenuItem *)recallMenuItem
{
    UIMenuItem *recallItem = [[UIMenuItem alloc] initWithTitle:_T(@"撤回") action:@selector(recallMessage:)];
    return recallItem;
}

#pragma mark - virtual method
- (void)stopVoiceAnimation
{
    
}

- (void)startVoiceAnimation
{
    
}


#pragma mark - layout
- (void)adjustLayout
{
    //时间轴
    if(self.showTimeShaft)
    {
        [self layoutTimeShaftView];
    }else
    {
        _timerShaft.hidden = YES;
        _timerBgNode.hidden = YES;
        _timerContain.hidden = YES;
    }
    
    [self layoutHeader];
    
    [self layoutBubbleBackground];
}


- (void)layoutTimeShaftView
{
    NSString *timeStr;
#if XJT
    timeStr = [TimeUtil getTimeStrStyle3:[self.contentModel.timeSend timeIntervalSince1970]];
#else
    timeStr = [TimeUtil getTimeStrStyle1:[self.contentModel.timeSend timeIntervalSince1970]];
#endif
    _timerShaft.hidden = NO;
    _timerBgNode.hidden = NO;
    _timerContain.hidden = NO;
    _timerShaft.text = timeStr;
    
    WeakSelf(ws);
    [_timerContain mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.mas_equalTo(ws.contentView);
        make.height.mas_equalTo(30);
    }];
    
    [_timerShaft mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(ws.timerContain);
        make.centerY.mas_equalTo(ws.timerContain);
    }];
    [_timerBgNode mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(ws.timerShaft).offset(-3);
        make.left.mas_equalTo(ws.timerShaft).offset(-3);
        make.right.mas_equalTo(ws.timerShaft.mas_right).offset(3);
        make.bottom.mas_equalTo(ws.timerShaft.mas_bottom).offset(3);
    }];

}


- (void)layoutHeader{
    
    NSInteger height = 0;
    if (self.showTimeShaft)
    {
        height = 45;
    }
    WeakSelf(ws);

    if (self.contentModel.isMySend || ([self.contentModel.toUserId isEqualToString:olym_UserCenter.userId] && [self.contentModel.fromUserId isEqualToString:olym_UserCenter.userId])) {
        // 自己
        [self.nickNameLabel setHidden:NO];
        
        //头像
        [self.headerView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.right.mas_equalTo(ws.contentView.mas_right).offset(-10);
            make.top.mas_equalTo(ws.contentView.mas_top).offset(height);
            make.width.height.mas_equalTo(40);
        }];
        
    }else{
        
        // 对方
        //头像
        [self.headerView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(ws.contentView).offset(10);
            make.top.mas_equalTo(ws.contentView).offset(height);
            make.width.height.mas_equalTo(40);
        }];
        
        // 如果是群聊添加昵称
        if(self.contentModel.isGroup) {
            [self.nickNameLabel setHidden:NO];
            [self.nickNameLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.top.mas_equalTo(ws.headerView.mas_top);
                make.left.mas_equalTo(ws.headerView.mas_right).offset(10);
            }];
        } else {
            [self.nickNameLabel setHidden:YES];
        }
    }
}


- (void)layoutBubbleBackground
{
    WeakSelf(ws);
    if (self.contentModel.isMySend
        || ([self.contentModel.toUserId isEqualToString:olym_UserCenter.userId] && [self.contentModel.fromUserId isEqualToString:olym_UserCenter.userId])) {

        [self.bubbleBackImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(ws.headerView.mas_top).offset(0);
            make.right.mas_equalTo(ws.headerView.mas_left).offset(-10);
            make.width.mas_equalTo(ws.contentSize.width + 30);
            make.height.mas_equalTo(ws.contentSize.height + 20);
        }];
        
        //正在发送指示器
        [_indicator mas_remakeConstraints:^(MASConstraintMaker *make) {
            
            make.right.equalTo(ws.bubbleBackImageView.mas_left).offset(-15);
            make.centerY.equalTo(ws.bubbleBackImageView);
        }];

        //发送状态
        [_statusView mas_remakeConstraints:^(MASConstraintMaker *make) {
            
            make.right.equalTo(ws.bubbleBackImageView.mas_left).offset(-15);
            make.top.equalTo(ws.bubbleBackImageView);
            make.height.mas_equalTo(18);
            make.width.mas_equalTo(25);
        }];
        [_resentButton mas_remakeConstraints:^(MASConstraintMaker *make) {
            
            make.right.equalTo(ws.bubbleBackImageView.mas_left).offset(-15);
            make.centerY.equalTo(ws.bubbleBackImageView);
            make.height.mas_equalTo(20);
            make.width.mas_equalTo(20);
        }];

        
        // 更换聊天气泡
        UIEdgeInsets insets = UIEdgeInsetsMake(25, 10, 10, 10);
        UIImage *bubbleImg = [UIImage imageWithSpecialStretch:insets imageStr:@"content_rightchat"];
        [self.bubbleBackImageView setImage:bubbleImg];
        
    }else{
        
        CGFloat height = 0;
        if (self.isGroupChat) {
            height = 18;
        }
        [self.bubbleBackImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(ws.headerView.mas_top).offset(height);
            make.left.mas_equalTo(ws.headerView.mas_right).offset(10);
            make.width.mas_equalTo(ws.contentSize.width + 30);
            make.height.mas_equalTo(ws.contentSize.height + 20);
        }];
        
        [_statusView mas_remakeConstraints:^(MASConstraintMaker *make) {}];
        [_resentButton mas_remakeConstraints:^(MASConstraintMaker *make) {}];

        
        // 更换聊天气泡
        UIEdgeInsets insets = UIEdgeInsetsMake(25, 10, 10, 10);
        UIImage *bubbleImg = [UIImage imageWithSpecialStretch:insets imageStr:@"content_leftchat"];
        [self.bubbleBackImageView setImage:bubbleImg];
        
    }
    
    CGFloat paddingTop = 0;
    if (self.showTimeShaft)
    {
        paddingTop += 45;
    }
    if (self.isGroupChat)
    {
        paddingTop += 18;
    }
    self.bubbleBackImageView.gjcf_top = paddingTop;
    
}

- (void)addmask:(NSString *)maskImgStr onView:(UIView *)view
{
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.fillColor = [UIColor greenColor].CGColor;
    maskLayer.strokeColor = [UIColor redColor].CGColor;
    maskLayer.frame = view.bounds;
    
    /*
     0.1, 0.1
     |-------------|
     |'-----------'|
     |'           '|
     |'           '|
     |'           '|
     |'-----------'|
     |-------------|
     0.5, 0.5
     */
    maskLayer.contentsCenter = CGRectMake(0.5, 0.5, 0.1, 0.1);
    maskLayer.contentsScale = [UIScreen mainScreen].scale;
    maskLayer.contents = (id)[UIImage imageNamed:maskImgStr].CGImage;
    
    view.layer.mask = maskLayer;
}

#pragma mark - 修改选择框图标
- (void)layoutSubviews
{
    for (UIControl *control in self.subviews)
    {
        if ([control isKindOfClass:NSClassFromString(@"UITableViewCellEditControl")])
        {
            for (UIView *v in control.subviews)
            {
                if ([v isKindOfClass:[UIImageView class]])
                {
                    if (v.tag == 10086)
                    {
                        if (self.showTimeShaft)
                        {
                            CGRect headFrame = self.headerView.frame;
                            self.checkImageView.frame = CGRectMake((control.frame.size.width - 30)/2.0, 45, 22, 22);
                        }else
                        {
                            self.checkImageView.frame = CGRectMake((control.frame.size.width - 30)/2.0, 0, 22, 22);
                        }
                        if (!self.selected) {
                            self.checkImageView.image = [UIImage imageNamed:@"cell_uncheck"]; //未选中
                        }else
                        {
                            self.checkImageView.image = [UIImage imageNamed:@"cell_check"]; //选中
                        }

                    }else
                    {
                        v.hidden = YES;
                    }
                }
            }
        }
        
    }
    [super layoutSubviews];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    for (UIControl *control in self.subviews)
    {
        if ([control isKindOfClass:NSClassFromString(@"UITableViewCellEditControl")])
        {
            UIView *checkView = [control viewWithTag:10086];
            if(checkView)
            {
                for (UIView *v in control.subviews)
                {
                    if ([v isKindOfClass:[UIImageView class]])
                    {
                        if (v.tag == 10086)
                        {
                            if (!self.selected) {
                                self.checkImageView.image = [UIImage imageNamed:@"cell_uncheck"]; //未选中
                            }
                        }else
                        {
                            v.hidden = YES;
                        }
                    }
                }
            }else
            {
                [control addSubview:self.checkImageView];
            }
            break;
        }
        
    }
}

#pragma mark - private method
- (void)addSubViews
{
    [self.contentView addSubview:self.headerView];
    [self.contentView addSubview:self.timerBgNode];
    [self.contentView addSubview:self.timerShaft];
    [self.contentView addSubview:self.timerContain];
    [self.contentView addSubview:self.nickNameLabel];

    [self.contentView addSubview:self.bubbleBackImageView];
    [self.contentView addSubview:self.statusView];
    [self.contentView addSubview:self.resentButton];
    [self.contentView addSubview:self.indicator];
    
    self.checkImageView = [[UIImageView alloc]init];
    self.checkImageView.tag = 10086;

}



#pragma mark - Property

- (UIImageView *)headerView {
    
    if (!_headerView) {
        
        _headerView = [[UIImageView alloc] init];
        _headerView.userInteractionEnabled = YES;
        _headerView.layer.cornerRadius = 40/2.0;
        _headerView.layer.masksToBounds = YES;

//        [_headerView zy_cornerRadiusAdvance:40/2 rectCornerType:UIRectCornerAllCorners];
        //裁成圆角
        // 添加长按手势
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressOnHeadView:)];
        longPress.numberOfTouchesRequired = 1;
        longPress.minimumPressDuration = 0.5;
        [_headerView addGestureRecognizer:longPress];
        
        //点击手势
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapOnHeadView:)];
        
        [_headerView addGestureRecognizer:tap];
#if MJTDEV
        [_headerView setImage:GJCFQuickImage(@"defaultheadv3")];
#else
        [_headerView setImage:GJCFQuickImage(@"default_head")];
#endif
    }
    
    return _headerView;
}
- (UILabel *)timerShaft {
    
    if (!_timerShaft) {
        
        _timerShaft = [[UILabel alloc] init];
        _timerShaft.font = [UIFont systemFontOfSize:12];
        _timerShaft.text = @"我是时间轴!";
        _timerShaft.textColor = [UIColor whiteColor];
        _timerShaft.hidden = YES;
    }
    
    return _timerShaft;
}

- (UIImageView *)timerBgNode {
    
    if (!_timerBgNode) {
        _timerBgNode = [[UIImageView alloc] init];
        _timerBgNode.backgroundColor = OLYMHEXCOLOR(0xcecece);
        _timerBgNode.layer.cornerRadius = 5;
        
        _timerBgNode.hidden = YES;
    }
    
    return _timerBgNode;
}
- (UILabel *)nickNameLabel {
    
    if (!_nickNameLabel) {
        _nickNameLabel = [[UILabel alloc] init];
        _nickNameLabel.font = [UIFont systemFontOfSize:12];
        _nickNameLabel.textColor = [UIColor darkGrayColor];
        _nickNameLabel.text = @"我是昵称!";
    }
    
    return _nickNameLabel;
}
- (UIImageView *)timerContain {
    
    if (!_timerContain) {
        
        _timerContain = [[UIImageView alloc] init];
        
        _timerContain.hidden = YES;
    }
    
    return _timerContain;
}


- (UIImageView *)bubbleBackImageView
{
    if (!_bubbleBackImageView)
    {
        _bubbleBackImageView = [[UIImageView alloc]init];
        _bubbleBackImageView.gjcf_left = self.contentBordMargin;
        _bubbleBackImageView.gjcf_width = 5;
        _bubbleBackImageView.gjcf_height = 40;
        _bubbleBackImageView.userInteractionEnabled = YES;

    }
    return _bubbleBackImageView;
}

- (UIImageView *)statusView
{
    if (!_statusView)
    {
        _statusView = [[UIImageView alloc]init];
        [_statusView setLayerCornerRadius:2 borderWidth:0 borderColor:nil];
    }
    return _statusView;
}

- (UIButton *)resentButton
{
    if (!_resentButton)
    {
        _resentButton = [[UIButton alloc]init];
        [_resentButton setLayerCornerRadius:10 borderWidth:0 borderColor:nil];
        [_resentButton setImage:[UIImage imageNamed:@"unsend_msg_chat"] forState:UIControlStateNormal];
        [_resentButton setImage:[UIImage imageNamed:@"unsend_msg_chat"] forState:UIControlStateHighlighted];

    }
    return _resentButton;
}

- (UIActivityIndicatorView *)indicator
{
    if (!_indicator)
    {
        _indicator = [[UIActivityIndicatorView alloc]init];
        _indicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
        _indicator.hidesWhenStopped = YES;
    }
    return _indicator;
}

@end
