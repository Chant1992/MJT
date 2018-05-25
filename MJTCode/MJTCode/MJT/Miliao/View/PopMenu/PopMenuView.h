//
//  PopMenuView.h
//  MJT_APP
//
//  Created by olymtech on 2017/9/12.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PopMenuViewDelegate <NSObject>

-(void)popViewCellClick:(NSInteger)index;

@end


@interface PopMenuView : UIView

// 数据数组
@property (nonatomic, strong) NSArray *sourceArr;
// 列表
@property (nonatomic, strong) UITableView *containList;

@property (nonatomic, assign) BOOL isShow;

@property (nonatomic, weak) id<PopMenuViewDelegate> delegate;

- (instancetype)init;

@end
