//
//  MessageSessionCell.m
//  MJT_APP
//
//  Created by olymtech on 2017/8/28.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "MessageSessionCell.h"
#import "UIView+Layer.h"
@interface MessageSessionCell ()

@property (nonatomic, strong) UIImageView *chatMuteView;
@property (nonatomic, strong) UIView *disturbCornerNode;
@property (nonatomic, assign) NSInteger unReadCount;

@end

@implementation MessageSessionCell

#pragma mark 《$ ---------------- LifeCycle ---------------- $》
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        
        [self createSubViews];
    }
    
    return self;
}

- (void)setIsAppoint:(BOOL)isAppoint
{
    _isAppoint = isAppoint;
    NSString *atString = @"";
    //设置了消息免打扰
    if (self.isDontdisturb && self.unReadCount > 1) {
        atString = [NSString stringWithFormat:_T(@"[%lu条]"),self.unReadCount];
    }
    //被人@了
    if (isAppoint) {
        atString = _T(@"[有人@我]");
    }
    NSString *originText = self.textNode.text;
    if (!originText) {
        originText = @"";
    }
    //有草稿
    if (self.draftMessage && self.draftMessage.length > 0)
    {
        atString = _T(@"[草稿]");
        originText = self.draftMessage;
        isAppoint = YES;
    }
    NSString *totalString = [NSString stringWithFormat:@"%@%@",atString,originText];
    NSDictionary *textAttrs = @{NSFontAttributeName: _textNode.font, NSForegroundColorAttributeName: kSubContentColor};
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc]initWithString:totalString attributes:textAttrs];
    if (atString.length > 0 && isAppoint)
    {
        NSDictionary *atTextAttrs = @{NSFontAttributeName: _textNode.font, NSForegroundColorAttributeName: OLYMHEXCOLOR(0xff3d30)};
        NSRange atRange = [totalString rangeOfString:atString];
        [attributedString addAttributes:atTextAttrs range:atRange];
    }
    self.textNode.attributedText = attributedString;
}

- (void)setIsDontdisturb:(BOOL)isDontdisturb
{
    _isDontdisturb = isDontdisturb;
    if (isDontdisturb) {
        if(self.unReadCount == 0){
            self.disturbCornerNode.hidden = YES;
        }else{
            self.disturbCornerNode.hidden = NO;
        }
        self.cornerNode.hidden = YES;
        self.chatMuteView.hidden = NO;
    }else
    {
        self.disturbCornerNode.hidden = YES;
        self.chatMuteView.hidden = YES;
        if(self.unReadCount == 0){
            self.cornerNode.hidden = YES;
        }else{
            self.cornerNode.hidden = NO;
        }
    }
}


#pragma mark 《$ ---------------- Layout ---------------- $》
- (void)createSubViews {
    
    [self.contentView addSubview:self.photoNode];
    [self.contentView addSubview:self.cornerNode];
    [self.contentView addSubview:self.titleNode];
    [self.contentView addSubview:self.textNode];
    [self.contentView addSubview:self.timeNode];
    [self.contentView addSubview:self.disturbCornerNode];
    [self.contentView addSubview:self.chatMuteView];
    
    WeakSelf(ws);
    
    [_photoNode mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.top.mas_equalTo(ws.contentView.mas_top).offset(8);
        make.left.mas_equalTo(ws.contentView.mas_left).offset(10);
        make.width.height.mas_equalTo(50);
        make.bottom.mas_equalTo(ws.contentView.mas_bottom).offset(-8);
    }];
    [_cornerNode mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.top.mas_equalTo(ws.photoNode.mas_top);
        make.right.mas_equalTo(ws.photoNode.mas_right).offset(10);
        make.width.height.mas_equalTo(20);
    }];
    
    [_timeNode mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.top.mas_equalTo(ws.photoNode.mas_top).offset(2);
        make.right.mas_equalTo(ws.contentView.mas_right).offset(-5);
        make.height.mas_equalTo(20);
        make.width.mas_equalTo(70);
    }];
    
    [_titleNode mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.top.mas_equalTo(ws.photoNode.mas_top).offset(2);
        make.left.mas_equalTo(ws.photoNode.mas_right).offset(10);
        make.right.mas_equalTo(ws.timeNode.mas_left).offset(-5);
        make.height.mas_equalTo(20);
    }];
    [_textNode mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.mas_equalTo(ws.photoNode.mas_bottom).offset(-2);
        make.left.mas_equalTo(ws.titleNode.mas_left);
        make.right.mas_equalTo(ws.chatMuteView.mas_left).offset(-10);
        make.height.mas_equalTo(20);
    }];
    [_disturbCornerNode mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.top.mas_equalTo(ws.photoNode.mas_top);
        make.right.mas_equalTo(ws.photoNode.mas_right).offset(5);
        make.width.height.mas_equalTo(10);
    }];
    
    [_chatMuteView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(ws.contentView).offset(-5);
        make.centerY.mas_equalTo(ws.textNode);
        make.width.height.mas_equalTo(16);
    }];
    
    
}

#pragma mark 《$ ---------------- Private ---------------- $》
- (void)changeCornerView:(int)unReadCount {
    
    self.unReadCount = unReadCount;
    
    if(unReadCount == 0){
        _cornerNode.hidden = YES;
        return;
    }
    
    _cornerNode.hidden = NO;
    [_cornerNode setCornerNum:@""];
    if (unReadCount > 99) {
        [_cornerNode setCornerNum:@"..."];
    }else{
        [_cornerNode setCornerNum:[NSString stringWithFormat:@"%d",unReadCount]];
    }
    
}


#pragma mark 《$ ---------------- Getter ---------------- $》
- (CornerDisNode *)cornerNode {
    
    if (!_cornerNode) {
        
        _cornerNode = [[CornerDisNode alloc] init];
        _cornerNode.hidden = YES;
        [_cornerNode setLayerCornerRadius:10 borderWidth:0 borderColor:nil];
    }
    
    return _cornerNode;
}

- (UIImageView *)photoNode {
    
    if (!_photoNode) {
        
        _photoNode = [[UIImageView alloc] init];
        [_photoNode setLayerCornerRadius:25 borderWidth:0 borderColor:nil];
    }
    
    return _photoNode;
}

- (UILabel *)titleNode {
    
    if (!_titleNode) {
        _titleNode = [[UILabel alloc] init];
    }
    
    return _titleNode;
}

- (UILabel *)textNode {
    
    if (!_textNode) {
        
        _textNode = [[UILabel alloc] init];
        _textNode.font = [UIFont systemFontOfSize:14];
        _textNode.textColor = kSubContentColor;
        [_textNode setText:@"这是内容"];
    }
    
    return _textNode;
}

- (UILabel *)timeNode {
    
    if (!_timeNode) {
        _timeNode = [[UILabel alloc] init];
        [_timeNode setTextAlignment:NSTextAlignmentRight];
        _timeNode.font = [UIFont systemFontOfSize:14];
        _timeNode.textColor = kSubContentColor;
        [_timeNode setText:@"10:02"];
    }
    
    return _timeNode;
}

- (UIView *)disturbCornerNode
{
    if (!_disturbCornerNode) {
        _disturbCornerNode = [[UIView alloc]init];
        _disturbCornerNode.backgroundColor = OLYMHEXCOLOR(0xF22125);
        [_disturbCornerNode setLayerCornerRadius:5 borderWidth:0 borderColor:nil];
        _disturbCornerNode.hidden = YES;
    }
    return _disturbCornerNode;
}

- (UIImageView *)chatMuteView
{
    if (!_chatMuteView) {
        _chatMuteView = [[UIImageView alloc]init];
        UIImage *muteImage = [UIImage imageNamed:@"chatMuteOn"];
        muteImage = [muteImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        _chatMuteView.image = muteImage;
        _chatMuteView.hidden = YES;
        _chatMuteView.tintColor = [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1];
        
    }
    return _chatMuteView;
}
@end
