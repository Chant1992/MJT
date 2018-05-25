//
//  PopMenuCell.m
//  SM9
//
//  Created by JIA on 2017/3/27.
//  Copyright © 2017年 OLYM. All rights reserved.
//

#import "PopMenuCell.h"

@interface PopMenuCell ()

@property (nonatomic, strong) UIImageView *iconImgView;

@property (nonatomic, strong) UILabel *titleLabel;

@property (nonatomic, strong) UIView *sepLineView;

@end
@implementation PopMenuCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        
        [self createSubViews];
    }
    
    return self;
}

#pragma mark 《$ ---------------- CreateSubViews ---------------- $》
- (void)createSubViews {
    
    [self.contentView addSubview:self.iconImgView];
    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.sepLineView];
    
    WeakSelf(ws);
    [_iconImgView mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.left.equalTo(ws.contentView).offset(10);
        make.centerY.equalTo(ws.contentView);
        make.height.width.mas_equalTo(30);
    }];
    [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        
//        make.right.equalTo(ws.contentView.mas_right).offset(-5);
        make.centerY.equalTo(ws.contentView);
        make.left.mas_equalTo(ws.iconImgView.mas_right).offset(5);
    }];
    [_sepLineView mas_makeConstraints:^(MASConstraintMaker *make) {
#if MJTDEV
        make.left.equalTo(ws.contentView);
        make.right.equalTo(ws.contentView);
#else
        make.left.equalTo(ws.iconImgView);
        make.right.equalTo(ws.titleLabel);
#endif
        make.bottom.equalTo(ws.contentView.mas_bottom).offset(-1);
        make.height.mas_equalTo(.5);
    }];
    
}

#pragma mark 《$ ---------------- Public ---------------- $》
- (void)setItemIcon:(NSString *)imageName title:(NSString *)title {
    _iconImgView.image = [UIImage imageNamed:imageName];
    _titleLabel.text = title;
}

#pragma mark 《$ ---------------- Setter/Getter ---------------- $》
- (UIImageView *)iconImgView {
    
    if (!_iconImgView) {
        
        _iconImgView = [[UIImageView alloc] init];
        _iconImgView.contentMode = UIViewContentModeCenter;
    }
    
    return _iconImgView;
}

- (UILabel *)titleLabel {
    
    if (!_titleLabel) {
        
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.text = @"哦哦哦";
    }
    
    return _titleLabel;
}
- (UIView *)sepLineView {
    
    if (!_sepLineView) {
        
        _sepLineView = [[UIView alloc] init];
#if MJTDEV
        _sepLineView.backgroundColor = OLYMHEXCOLOR(0xe4e4e4);
#else
        _sepLineView.backgroundColor = [UIColor grayColor];
#endif
    }
    
    return _sepLineView;
}
@end
