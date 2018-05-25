//
//  NewFriendModel.h
//  MJT_APP
//
//  Created by olymtech on 2017/9/4.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "OLYMListViewModel.h"

@interface NewFriendModel : OLYMListViewModel

@property (nonatomic, retain) NSString *friendContent;

/* 7天之内的好友申请 */
@property(nonatomic,strong) NSMutableArray *recentlyFriends;
/* 7天之前的好友申请 */
@property(nonatomic,strong) NSMutableArray *beforeFriends;

@property (nonatomic, strong) RACCommand *sendMessageCommand;

@property (nonatomic, strong) RACCommand *addNewFriendCommand;

@property (nonatomic, strong) RACSubject *addNewFriendSubject;
@property (nonatomic, strong) RACSubject *waitVerificationBtnSubject;
@property (nonatomic, strong) RACSubject *acceptBtnSubject;
@property (nonatomic, strong) RACSubject *refreshDataSubject;
@end
