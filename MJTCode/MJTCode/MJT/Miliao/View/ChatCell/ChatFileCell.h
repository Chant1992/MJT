//
//  ChatFileCell.h
//  MJT_APP
//
//  Created by Donny on 2017/9/13.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OLYMMessageObject.h"

@interface ChatFileCell : UICollectionViewCell


/* <#注释#> */
@property(nonatomic,strong) OLYMMessageObject *fileObj;
/* 如果是视频，下面的播放视图 */
@property(nonatomic,strong) UIView *playView;

@property(nonatomic,readonly) UIImageView *checkView;

@end
