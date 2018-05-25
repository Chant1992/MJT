//
//  CornerDisNode.m
//  MJT_APP
//
//  Created by olymtech on 2017/8/28.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "CornerDisNode.h"

@interface CornerDisNode()

// 角标数字
@property (nonatomic, strong) UILabel *numTextNode;
// 背景图
@property (nonatomic, strong) UIImageView *numImgNode;

@end

@implementation CornerDisNode

#pragma mark 《$ ---------------- LiftCycle ---------------- $》
- (instancetype)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        [self createSubViews];
    }
    
    return self;
}

- (void)createSubViews {
    
    [self addSubview:self.numImgNode];
    [self addSubview:self.numTextNode];
    
    WeakSelf(ws);
    [_numImgNode mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.edges.mas_equalTo(ws);
    }];
    
    [_numTextNode mas_makeConstraints:^(MASConstraintMaker *make) {
    
        make.centerX.centerY.mas_equalTo(ws);
  
    }];
    
}

#pragma mark 《$ ---------------- Public ---------------- $》
- (void)setCornerNum:(NSString *)numStr {
    
    NSDictionary *attrs = @{NSFontAttributeName: [UIFont systemFontOfSize:12], NSForegroundColorAttributeName: [UIColor whiteColor]};
    NSAttributedString *attStr = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@", numStr] attributes:attrs];
    _numTextNode.attributedText = attStr;
    
}
#pragma mark 《$ ---------------- Getter ---------------- $》
- (UILabel *)numTextNode {
    
    if (!_numTextNode) {
        
        _numTextNode = [[UILabel alloc] init];
        NSDictionary *attrs = @{NSFontAttributeName: [UIFont systemFontOfSize:12], NSForegroundColorAttributeName: [UIColor whiteColor]};
        NSAttributedString *attStr = [[NSAttributedString alloc] initWithString:@"99" attributes:attrs];
        _numTextNode.attributedText = attStr;
    }
    
    return _numTextNode;
}
- (UIImageView *)numImgNode {
    
    if (!_numImgNode) {
        
        _numImgNode = [[UIImageView alloc] init];
        _numImgNode.image = [UIImage imageNamed:@"corner_view_msg"];
        _numImgNode.frame = self.frame;
    }
    
    return _numImgNode;
}


@end
