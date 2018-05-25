//
//  NewFriendViewCell.h
//  MJT_APP
//
//  Created by olymtech on 2017/9/4.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NewFriendModel.h"
@class OLYMNewFriendObj;
@interface NewFriendViewCell : UITableViewCell

// 头像
@property (nonatomic, strong) UIImageView *photoNode;
// 标题
@property (nonatomic, strong) UILabel *titleNode;
// 聊天详情
@property (nonatomic, strong) UILabel *textNode;

// 时间
@property (nonatomic, strong) UILabel *timeLabel;

@property (nonatomic, strong) UIButton *replyButton;

@property (nonatomic, strong) UIButton *acceptButton;

@property (nonatomic, strong) UIButton *sayHiButton;

@property (nonatomic, strong) OLYMNewFriendObj *friendObj;

@property (nonatomic, strong) NewFriendModel *friendModel;

@property (nonatomic,retain) id buttonActionTarget;

@property(nonatomic,strong) NSIndexPath *indexPath;
@end
