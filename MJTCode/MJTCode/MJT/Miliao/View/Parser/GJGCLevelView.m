//
//  GJGCLevelView.m
//  ZYChat
//
//  Created by ZYVincent QQ:1003081775 on 14-11-3.
//  Copyright (c) 2014年 ZYProSoft. All rights reserved.
//

#import "GJGCLevelView.h"
#import "GJCFCoreTextFrame.h"
#import "GJCFCoreTextContentView.h"
@interface GJGCLevelView ()

@property (nonatomic,strong)UIImageView *backImagView;

@property (nonatomic,strong)GJCFCoreTextContentView *textLabel;

@end

@implementation GJGCLevelView

- (instancetype)init
{
    if (self = [super init]) {
     
        [self setupStyle];
        
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        
        [self setupStyle];

    }
    return self;
}

- (void)setupStyle
{
    self.backgroundColor = [UIColor clearColor];
    self.frame = CGRectMake(0, 0, 100, 20);
    
    self.backImagView = [[UIImageView alloc]init];
    [self addSubview:self.backImagView];
    
    /* 绘制背景 */
    UIImage *backImage = GJCFQuickImage(@"标签-bg-等级.png");
    backImage = GJCFImageStrecth(backImage,3,3);
    self.backImagView.image = backImage;
    
    /* textLabel */
    self.textLabel = [[GJCFCoreTextContentView alloc]init];
    self.textLabel.gjcf_left = 1.5;
    self.textLabel.gjcf_width = 100;
    self.textLabel.gjcf_top = 1;
    self.textLabel.gjcf_height = 20;
    self.textLabel.contentBaseWidth = self.textLabel.gjcf_width;
    self.textLabel.contentBaseHeight = self.textLabel.gjcf_height;
    self.textLabel.backgroundColor = [UIColor clearColor];
    [self addSubview:self.textLabel];
}


- (void)setLevel:(NSAttributedString *)level
{
    if ([_level isEqualToAttributedString:level]) {
        return;
    }
    _level = nil;
    _level = [level copy];
    
    self.textLabel.gjcf_size = [GJCFCoreTextContentView contentSuggestSizeWithAttributedString:_level forBaseContentSize:self.textLabel.contentBaseSize];
    self.textLabel.contentAttributedString = _level;
    self.gjcf_width = self.textLabel.gjcf_width+2;
    self.gjcf_height = self.textLabel.gjcf_height+2;
    self.backImagView.gjcf_size = self.gjcf_size;
    self.textLabel.gjcf_centerY = self.gjcf_height/2;
    self.textLabel.gjcf_centerX = self.gjcf_width/2;
    self.backImagView.gjcf_size = self.gjcf_size;

}


@end
