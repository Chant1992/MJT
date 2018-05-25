//
//  ChatRemindMsgCell.m
//  MJT_APP
//
//  Created by Donny on 2017/9/14.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "ChatRemindMsgCell.h"
#import "UIView+Layer.h"

@interface ChatRemindMsgCell ()

// 系统提醒
@property (nonatomic, strong) UILabel *remindText;
// 提醒背景
@property (nonatomic, strong) UIView *bgView;

@end

@implementation ChatRemindMsgCell

- (CGFloat)heightForContentModel:(OLYMMessageObject *)contentModel
{
    return 40;
}
#pragma mark - 设置数据源
- (void)setContentModel:(OLYMMessageObject *)contentModel
{
    NSString *dateStr;
    if (contentModel.type == kWCMessageTypeRemind)
    {
        dateStr = [NSString stringWithFormat:@"%@", contentModel.content];
        
    }else if (contentModel.type == kWCMessageTypeReCall)
    {
        if(contentModel.isMySend)
        {
            //我发送的
            dateStr = _T(@"你撤回了一条消息");
        }else
        {
            dateStr = [NSString stringWithFormat:_T(@"%@撤回了一条消息"),contentModel.fromUserName];;
        }
    }
    // Creat attribute string
    NSDictionary *attrs = @{NSFontAttributeName:[UIFont systemFontOfSize:12]};
    NSAttributedString *attStr = [[NSAttributedString alloc] initWithString:dateStr attributes:attrs];
    
    _remindText.attributedText = attStr;

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
    
    WeakSelf(ws);
    [_remindText mas_remakeConstraints:^(MASConstraintMaker *make) {
        
        make.centerX.equalTo(ws.contentView);
        make.centerY.equalTo(ws.contentView);
        make.width.lessThanOrEqualTo(ws.contentView).offset(-80);
    }];
    [_bgView mas_remakeConstraints:^(MASConstraintMaker *make) {
        
        make.top.equalTo(ws.remindText).offset(-3);
        make.left.equalTo(ws.remindText).offset(-3);
        make.right.equalTo(ws.remindText.mas_right).offset(3);
        make.bottom.equalTo(ws.remindText.mas_bottom).offset(3);
    }];
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
