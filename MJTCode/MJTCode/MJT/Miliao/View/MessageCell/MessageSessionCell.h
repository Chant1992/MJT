//
//  MessageSessionCell.h
//  MJT_APP
//
//  Created by olymtech on 2017/8/28.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CornerDisNode.h"

@interface MessageSessionCell : UITableViewCell
// 头像
@property (nonatomic, strong) UIImageView *photoNode;
// 园点
@property (nonatomic, strong) CornerDisNode *cornerNode;
// 标题
@property (nonatomic, strong) UILabel *titleNode;
// 聊天详情
@property (nonatomic, strong) UILabel *textNode;
// 时间
@property (nonatomic, strong) UILabel *timeNode;
//是否被@
@property (nonatomic)       BOOL      isAppoint;

//是否消息免打扰
@property (nonatomic)       BOOL      isDontdisturb;

//是否有草稿
@property (nonatomic, strong) NSString * draftMessage;

- (void)changeCornerView:(int)unReadCount;

@end
