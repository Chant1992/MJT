//
//  GroupMemberViewController.h
//  MJT_APP
//
//  Created by olymtech on 2017/9/14.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "OLYMViewController.h"
#import "GroupMemberModel.h"

@class GroupMemberViewController;
@class OLYMUserObject;

@protocol GroupMemberViewControllerDelegate <NSObject>

@optional

- (void)groupMemberViewController:(GroupMemberViewController *)groupMemberController willEnterChatController:(UIViewController *)controller;

@end

@interface GroupMemberViewController : OLYMViewController

@property(strong,nonatomic) NSString *currentRoomJid;
@property(strong,nonatomic) NSString *currentRoomId;
@property(strong,nonatomic) NSString *currentRoomOwnerId;

@property(assign,nonatomic) PersonSelectType type;

@property (nonatomic,strong) OLYMUserObject *currentChatUser;

@property(nonatomic,weak) id<GroupMemberViewControllerDelegate> delegate;

-(instancetype)initWithArray:(NSArray *)memberArray withType:(PersonSelectType)type;

-(instancetype)initWithType:(PersonSelectType)type;



@end
