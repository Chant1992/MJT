//
//  GroupInfoMemberController.h
//  MJT_APP
//
//  Created by Donny on 2017/11/9.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>
@class OLYMUserObject;
@class OLYMRoomDataObject;
@class GroupInfoModel;

@interface GroupInfoMemberController : OLYMViewController

@property(strong,nonatomic)OLYMUserObject *userObject;

@property(strong,nonatomic) OLYMRoomDataObject *roomDataObject;

@property (nonatomic, strong) GroupInfoModel* groupInfoModel;

@end
