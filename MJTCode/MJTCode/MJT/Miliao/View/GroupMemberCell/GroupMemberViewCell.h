//
//  GroupMemberViewCell.h
//  MJT_APP
//
//  Created by olymtech on 2017/9/14.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>
@class OLYMUserObject;
@interface GroupMemberViewCell : UITableViewCell

@property (nonatomic,strong) UIImageView *checkView;

@property (nonatomic,strong) UIImageView *iconView;

@property (nonatomic,strong) UILabel *nickNameLabel;

@property (nonatomic,strong) OLYMUserObject *userObj;

@end
