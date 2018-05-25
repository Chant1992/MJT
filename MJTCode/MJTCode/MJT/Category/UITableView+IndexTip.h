//
//  UITableView+IndexTip.h
//  MJT_APP
//
//  Created by Chant on 2017/12/29.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UITableView (IndexTip)

/**
 <#Description#>

 @param indexArray <#indexArray description#>
 @param dataTitleArray <#dataTitleArray description#>
 */
-(void)addIndexTipLabel:(NSArray *)indexArray dataTitleArray:(NSArray *)dataTitleArray;
-(NSArray *)getAllIndexArray;

@end

@interface OLYMTableIndexManager: NSObject

@property (nonatomic, strong)UILabel *indexTipLabel;
@property(nonatomic,strong) NSArray *indexArray;
@property(nonatomic,strong) NSArray *dataTitleArray;
/** 触感反馈 */
@property (nonatomic, strong) UIImpactFeedbackGenerator *generator NS_AVAILABLE_IOS(10_0);
@end
