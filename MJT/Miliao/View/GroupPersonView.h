//
//  GroupPersonView.h
//  MJT_APP
//
//  Created by olymtech on 2017/9/14.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

typedef NS_ENUM(NSInteger, GroupListType) {
    CraetNewGroupType, //创建群
    GroupListTypeeDelete //踢人
};

#import "OLYMBaseListView.h"
@class OLYMUserObject;
@class OLYMHeaderSearchBar;

@interface GroupPersonView : OLYMBaseListView

@property(nonatomic,assign) GroupListType groupListType;
@property(nonatomic,strong) OLYMHeaderSearchBar *searchBar;

-(void)deselectCell:(OLYMUserObject *)user isCheck:(BOOL)isCheck;
@end
