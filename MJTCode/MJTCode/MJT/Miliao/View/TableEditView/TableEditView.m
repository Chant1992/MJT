//
//  TableEditView.m
//  MJT_APP
//
//  Created by Donny on 2017/12/29.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "TableEditView.h"
#import "UIButton+EdgeInsets.h"
#import "UIButton+LYButton.h"
#import "ALOCenteredButton.h"

@interface TableEditView ()

@property (nonatomic, strong) UIView *separateView;

@property (nonatomic, strong) UIView *editView;

@property (nonatomic, strong) UIButton *allButton;

@property (nonatomic, strong) NSMutableArray *otherButons;

@end

@implementation TableEditView


- (instancetype)initWithFrame:(CGRect)frame editType:(TableEditType)type
{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor whiteColor];
        [self getEditType:type];
        [self createSubView];
    }
    return self;
}


- (void)createSubView
{
    [self addSubview:self.editView];
    [self addSubview:self.separateView];
    BOOL hasAll = NO;
    if ([self.otherButons containsObject:@(TableEditAllSelectedType)])
    {
        hasAll = YES;
        [self.otherButons removeObject:@(TableEditAllSelectedType)];
    }
    
    if (hasAll)
    {
        [self.editView addSubview:self.allButton];
    }
    
    CGFloat spacing = 82 *GJCFSystemScreenWidth / 375.0;
    CGFloat width = 40;
    CGFloat margin = 50;
    if (!hasAll)
    {
        spacing = 100 *GJCFSystemScreenWidth / 375.0;
        margin = spacing;
    }
    for (int i = 0; i < self.otherButons.count; i++)
    {
        ALOCenteredButton *button = [ALOCenteredButton buttonWithType:UIButtonTypeCustom];
        [self.editView addSubview:button];
        
        TableEditType type = [[self.otherButons objectAtIndex:i]integerValue];
        NSString *title = [self titleForEditType:type];
        [button setTitle:title forState:UIControlStateNormal];
        [button setImage:[UIImage imageNamed:[self normalImageNameForEditType:type]] forState:UIControlStateNormal];
        [button setImage:[UIImage imageNamed:[self highlightImageNameForEditType:type]] forState:UIControlStateHighlighted];
        [button addTarget:self action:@selector(otherButtonClick:) forControlEvents:UIControlEventTouchUpInside];
        button.titleLabel.font = [UIFont systemFontOfSize:10];
        [button setTitleColor:OLYMHEXCOLOR(0x858998) forState:UIControlStateNormal];
        button.buttonOrientation = ALOCenteredButtonOrientationVertical;
        button.imageLabelSpacing = 3;
        button.tag = 10086 + type;
        
        button.frame = CGRectMake((GJCFSystemScreenWidth - margin) - (i+1) * width - spacing * i, (CGRectGetHeight(self.editView.frame) - width)/2.0, width, width);
    }
}


- (void)otherButtonClick:(UIButton *)button
{
    TableEditType type = button.tag - 10086;
    if (self.editViewButtonClick) {
        self.editViewButtonClick(type);
    }
}

- (void)allSelectedAction
{
    self.allButton.selected = !self.allButton.selected;
    if (self.editViewButtonClick) {
        self.editViewButtonClick(TableEditAllSelectedType);
    }

}

- (void)setEdit:(BOOL)edit
{
    for (UIView *subView in self.editView.subviews)
    {
        if ([subView isKindOfClass:[UIButton class]])
        {
            if (subView.tag >= 10086 && subView.tag != 10086 + TableEditAllSelectedType)
            {
                UIButton *button = subView;
                button.enabled = edit;
            }
        }
    }
}

- (void)setAllSelected:(BOOL)allSelected
{
    self.allButton.selected = allSelected;
}

- (void)getEditType:(TableEditType)type
{
    if (type&1<<1)
    {
        [self.otherButons addObject:@(TableEditDeleteType)];
    }
    if (type&1<<2)
    {
        [self.otherButons addObject:@(TableEditForwardType)];
    }
    if (type&1<<3)
    {
        [self.otherButons addObject:@(TableEditAllSelectedType)];
    }
}


- (NSString *)titleForEditType:(TableEditType)type
{
    NSString *title = @"";
    switch (type) {
        case TableEditDeleteType:
            title = _T(@"删除");
            break;
        case TableEditForwardType:
            title = _T(@"转发");
            break;
        default:
            break;
    }
    return title;
}
- (NSString *)normalImageNameForEditType:(TableEditType)type
{
    NSString *imageName = @"";
    switch (type) {
        case TableEditDeleteType:
            imageName = _T(@"delete_normal");
            break;
        case TableEditForwardType:
            imageName = _T(@"forward_normal");
            break;
        default:
            break;
    }
    return imageName;
}

- (NSString *)highlightImageNameForEditType:(TableEditType)type
{
    NSString *imageName = @"";
    switch (type) {
        case TableEditDeleteType:
            imageName = _T(@"delete_h");
            break;
        case TableEditForwardType:
            imageName = _T(@"forward_h");
            break;
        default:
            break;
    }
    return imageName;
}

#pragma mark - Property

- (UIButton *)allButton
{
    if (!_allButton)
    {
        _allButton = [[UIButton alloc]init];
        [_allButton setTitle:_T(@"全选") forState:UIControlStateNormal];
        [_allButton setImage:[UIImage imageNamed:@"cell_uncheck"] forState:UIControlStateNormal];
        [_allButton setImage:[UIImage imageNamed:@"cell_check"] forState:UIControlStateSelected];
        [_allButton addTarget:self action:@selector(allSelectedAction) forControlEvents:UIControlEventTouchUpInside];
        _allButton.titleLabel.font = [UIFont systemFontOfSize:15];
        [_allButton setTitleColor:OLYMHEXCOLOR(0x858E99) forState:UIControlStateNormal];
        [_allButton horizontalCenterImageAndTitle:6];
        _allButton.frame = CGRectMake(16, (CGRectGetHeight(self.editView.frame) - 40)/2.0, 90, 40);
        [_allButton addTarget:self action:@selector(allSelectedAction) forControlEvents:UIControlEventTouchUpInside];
        _allButton.tag = 10086 + TableEditAllSelectedType;
    }
    return _allButton;
}

- (UIView *)editView
{
    if (!_editView)
    {
        _editView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, GJCFSystemScreenWidth, 50)];
    }
    return _editView;
}

- (NSMutableArray *)otherButons
{
    if (!_otherButons)
    {
        _otherButons = [NSMutableArray array];
    }
    return _otherButons;
}


- (UIView *)separateView
{
    if (!_separateView)
    {
        _separateView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, GJCFSystemScreenWidth, 1)];
        _separateView.backgroundColor = OLYMHEXCOLOR(0xE8E9E8);
    }
    return _separateView;
}
@end
