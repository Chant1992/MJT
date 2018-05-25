//
//  ChatCardViewModel.h
//  MJT_APP
//
//  Created by Donny on 2017/9/12.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "OLYMListViewModel.h"

typedef NS_ENUM(NSInteger, ChatCardType);

@class OLYMUserObject;

@interface ChatCardViewModel : OLYMListViewModel

/* 搜索状态下保存的原来数组 */
@property(nonatomic,strong) NSMutableArray* previousArray;
@property(nonatomic,readonly) NSMutableArray* allContacts;


- (instancetype)initWithUser:(OLYMUserObject *)currentChatUser chatCardType:(ChatCardType)chatCardType;

- (void)sendCardMessagetoUser:(OLYMUserObject *)userObj;

@end
