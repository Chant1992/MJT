//
//  ChatRecordViewModel.h
//  MJT_APP
//
//  Created by Donny on 2017/12/14.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "OLYMListViewModel.h"
@class OLYMUserObject;

 

@interface ChatRecordViewModel : OLYMListViewModel

@property (nonatomic, strong) RACSubject *miyouSubject;
@property (nonatomic, strong) RACSubject *localContactSubject;

@property (nonatomic, strong) RACSubject *groupSubject;
@property (nonatomic, strong) RACSubject *multiRecordSubject;

@property (nonatomic, strong) RACSubject *singleRecordSubject;

@property (nonatomic, strong) RACSubject *contactRecordSubject;

@property (nonatomic, strong) RACSubject *moreContactsSubject;
@property (nonatomic, strong) RACSubject *moreGroupsSubject;
@property (nonatomic, strong) RACSubject *moreFullRecordsSubject;


- (instancetype)init;

- (instancetype)initWithUser:(OLYMUserObject *)currentChatUser;

- (NSArray *)queryChatRecord:(NSString *)keyWord;

- (NSArray *)fillChatRecords:(NSArray *)messages;

- (NSArray *)queryFullRecordWith:(NSString *)keyword;

- (NSArray *)queryGroupWith:(NSString *)keyword;

- (NSArray *)queryAllChatRecordWith:(NSString *)keyword;

- (NSArray *)queryAllContactsWith:(NSString *)keyword;


@end
