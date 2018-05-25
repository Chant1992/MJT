//
//  ChatBaseCell.m
//  MJT_APP
//
//  Created by olymtech on 2017/8/29.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "ChatBaseCell.h"
#import "UIView+Layer.h"
#import "OLYMMessageObject.h"

@interface ChatBaseCell()



@end

@implementation ChatBaseCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
//        self.backgroundColor = [UIColor clearColor];
        
    }
    
    return self;
}

/* 虚方法 */
- (void)setContentModel:(OLYMMessageObject *)contentModel
{
    if (!contentModel) {
        return;
    }
    _contentModel = contentModel;
}

- (CGFloat)heightForContentModel:(OLYMMessageObject *)contentModel
{
    return 0.f;
}
/*
#pragma mark 《$ ---------------- createSuperViews ---------------- $》
- (void)createSuperViews {
    
    [self.contentView addSubview:self.headerView];
    [self.contentView addSubview:self.timerBgNode];
    [self.contentView addSubview:self.timerShaft];
    [self.contentView addSubview:self.timerContain];
    [self.contentView addSubview:self.nickNameLabel];
    
}


#pragma mark 《$ ---------------- Action ---------------- $》
// 设置位置
- (void)changeSuperLayout {
    
    //如果有时间轴,整体下移
    NSInteger height = 0;
    if (YES) {
        height = 45;
    }
    
    WeakSelf(ws);
    
    if (_contentModel.isMySend) {
        // 自己
        [_nickNameLabel setHidden:NO];
        
        [_headerView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.right.mas_equalTo(ws.contentView.mas_right).offset(-10);
            make.top.mas_equalTo(ws.contentView.mas_top).offset(height);
            make.width.height.mas_equalTo(40);
        }];
        
    }else{
        
        // 对方
        [_headerView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(ws.contentView).offset(10);
            make.top.mas_equalTo(ws.contentView).offset(height);
            make.width.height.mas_equalTo(40);
        }];
        
        // 如果是群聊添加昵称
        if(_contentModel.isGroup) {
            [_nickNameLabel setHidden:NO];
            [_nickNameLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.top.mas_equalTo(ws.headerView.mas_top);
                make.left.mas_equalTo(ws.headerView.mas_right).offset(10);
            }];
        } else {
            [_nickNameLabel setHidden:YES];
        }
    }
}

// 添加时间轴
- (void)addTimerShaft {
    
    NSString *timeStr = GJCFDateToString(self.contentModel.timeSend);
    
    WeakSelf(ws);
    if (YES) {
        
        _timerShaft.hidden = NO;
        _timerBgNode.hidden = NO;
        _timerContain.hidden = NO;
        _timerShaft.text = timeStr;
        
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
    } else {
        
        _timerShaft.hidden = YES;
        _timerBgNode.hidden = YES;
        _timerContain.hidden = YES;
    }
}
*/





#pragma mark 《$ ---------------- Setter/Getter ---------------- $》
/*

- (UIImageView *)headerView {
    
    if (!_headerView) {
        
        _headerView = [[UIImageView alloc] init];
        _headerView.userInteractionEnabled = YES;
        _headerView.layer.cornerRadius= _headerView.frame.size.width/2;//裁成圆角
        _headerView.layer.masksToBounds=YES;//隐藏裁剪掉的部分
        // 添加长按手势
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressOnHeadView:)];
        longPress.numberOfTouchesRequired = 1;
        longPress.minimumPressDuration = 0.5;
        [_headerView addGestureRecognizer:longPress];
        
        //点击手势
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapOnHeadView:)];
        
        [_headerView addGestureRecognizer:tap];
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
        [_timerBgNode setLayerCornerRadius:5 borderWidth:0 borderColor:nil];
       
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
*/
@end
