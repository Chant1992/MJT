//
//  ChatRecallCell.m
//  MJT_APP
//
//  Created by Donny on 2017/12/19.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "ChatRecallCell.h"
#import "UIView+Layer.h"
#import "TimeUtil.h"

@interface ChatRecallCell ()

// 系统提醒
@property (nonatomic, strong) UILabel *remindText;
// 提醒背景
@property (nonatomic, strong) UIView *bgView;

@end

@implementation ChatRecallCell

- (CGFloat)heightForContentModel:(OLYMMessageObject *)contentModel
{
    return 40;
}
#pragma mark - 设置数据源
- (void)setContentModel:(OLYMMessageObject *)contentModel
{
    NSString *dateStr;
    if(contentModel.isMySend)
    {
        //我发送的
        dateStr = _T(@"你撤回了一条消息");
    }else
    {
        dateStr = [NSString stringWithFormat:_T(@"%@撤回了一条消息"),contentModel.fromUserName];;
    }

    // Creat attribute string
    NSDictionary *attrs = @{NSFontAttributeName:[UIFont systemFontOfSize:12]};
    NSAttributedString *attStr = [[NSAttributedString alloc] initWithString:dateStr attributes:attrs];
    
    _remindText.attributedText = attStr;
    
    [self layoutRecall:contentModel];
}

- (void)layoutRecall:(OLYMMessageObject *)contentModel
{
    WeakSelf(ws);
    if (contentModel.isShowTime)
    {
        NSString *timeStr;
#if XJT
        timeStr = [TimeUtil getTimeStrStyle3:[contentModel.timeSend timeIntervalSince1970]];
#else
        timeStr = [TimeUtil getTimeStrStyle1:[contentModel.timeSend timeIntervalSince1970]];
#endif
        self.timerShaft.text = timeStr;

        self.timerContain.hidden = NO;
        self.timerShaft.hidden = NO;
        self.timerBgNode.hidden = NO;
        [self.timerContain mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.left.right.mas_equalTo(ws.contentView);
            make.height.mas_equalTo(30);
        }];
        
        [self.timerShaft mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.centerX.mas_equalTo(ws.timerContain);
            make.centerY.mas_equalTo(ws.timerContain);
        }];
        [self.timerBgNode mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(ws.timerShaft).offset(-3);
            make.left.mas_equalTo(ws.timerShaft).offset(-3);
            make.right.mas_equalTo(ws.timerShaft.mas_right).offset(3);
            make.bottom.mas_equalTo(ws.timerShaft.mas_bottom).offset(3);
        }];
    }
    
    [_bgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(ws.remindText).offset(-3);
        make.left.equalTo(ws.remindText).offset(-3);
        make.right.equalTo(ws.remindText.mas_right).offset(3);
        make.bottom.equalTo(ws.remindText.mas_bottom).offset(3);
    }];
    
    [_remindText mas_remakeConstraints:^(MASConstraintMaker *make) {
        if (contentModel.isShowTime)
        {
            make.top.mas_equalTo(ws.timerContain.mas_bottom).offset(10);
        }else
        {
            make.centerY.equalTo(ws.contentView);
        }
        make.centerX.equalTo(ws.contentView);
        make.width.lessThanOrEqualTo(ws.contentView).offset(-80);
    }];

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
                    UIImageView *imgV = (UIImageView *)v;
                    imgV.hidden = YES;

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
            for (UIView *v in control.subviews)
            {
                if ([v isKindOfClass:[UIImageView class]])
                {
                    UIImageView *imgV = (UIImageView *)v;
                    imgV.hidden = YES;
                }
            }
        }
        
    }
}

#pragma mark 《$ ---------------- CreateSubViews ---------------- $》
- (void)createSubViews {
    
    [self.contentView addSubview:self.bgView];
    [self.contentView addSubview:self.remindText];
    
    
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self createSubViews];
    }
    
    return self;
}


- (UILabel *)remindText {
    
    
    if (!_remindText) {
        
        _remindText = [[UILabel alloc] init];
        _remindText.textColor = [UIColor whiteColor];
        _remindText.numberOfLines = 0;
    }
    
    return _remindText;
}

- (UIView *)bgView {
    
    if (!_bgView) {
        
        _bgView = [[UIView alloc] init];
        _bgView.backgroundColor = OLYMHEXCOLOR(0xcecece);
        [_bgView setLayerCornerRadius:5 borderWidth:0 borderColor:nil];
    }
    
    return _bgView;
}

@end
