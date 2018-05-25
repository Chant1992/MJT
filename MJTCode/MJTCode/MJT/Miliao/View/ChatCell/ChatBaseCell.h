//
//  ChatBaseCell.h
//  MJT_APP
//
//  Created by olymtech on 2017/8/29.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OLYMMessageObject.h"
#import "ChatCellDelegate.h"
#import "ChatCellProtocol.h"

@interface ChatBaseCell : UITableViewCell<ChatCellDelegate,ChatCellProtocol>


// 数据模型
@property (nonatomic, strong) OLYMMessageObject *contentModel;

@property (nonatomic, weak) id<ChatCellDelegate> delegate;


/* 虚方法 */
- (void)setContentModel:(OLYMMessageObject *)contentModel;

/* 高度 */
- (CGFloat)heightForContentModel:(OLYMMessageObject *)contentModel;

@end
