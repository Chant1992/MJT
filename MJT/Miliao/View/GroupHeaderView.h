//
//  GroupHeaderView.h
//  MJT_APP
//
//  Created by olymtech on 2017/9/13.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>
@class OLYMUserObject;
@class GroupHeaderView;

@protocol GroupHeaderViewDelegate <NSObject>

- (void)groupHeaderViewDidTapDelete:(GroupHeaderView *)view;
- (void)groupHeaderViewDidTapBan:(GroupHeaderView *)view;


@end

@interface GroupHeaderView : UIView

@property (nonatomic, weak) id<GroupHeaderViewDelegate> delegate;

@property(nonatomic,strong) UIImageView *headerView;

@property(nonatomic,strong) UILabel *nickNameLabel;

@property(strong,nonatomic) OLYMUserObject *userObject;

@property (nonatomic, assign) BOOL showDelete;

@property (nonatomic, assign) BOOL showBan;

@end

