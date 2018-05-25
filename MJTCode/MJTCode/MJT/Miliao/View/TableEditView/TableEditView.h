//
//  TableEditView.h
//  MJT_APP
//
//  Created by Donny on 2017/12/29.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, TableEditType)
{
    TableEditDeleteType =  1<<1,
    TableEditForwardType = 1<<2,
    TableEditAllSelectedType = 1<<3
};

@interface TableEditView : UIView

@property (nonatomic, strong) void (^editViewButtonClick)(TableEditType type);

- (instancetype)initWithFrame:(CGRect)frame editType:(TableEditType)type;

- (void)setEdit:(BOOL)edit;

- (void)setAllSelected:(BOOL)allSelected;

@end
