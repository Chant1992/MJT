//
//  ChatRecordViewModel.m
//  MJT_APP
//
//  Created by Donny on 2017/12/14.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "ChatRecordViewModel.h"
#import "OLYMUserObject.h"
#import "OLYMMessageObject.h"
#import "OLYMSearchObject.h"
#import "OLYMUserObject+Pinyin.h"
#import "NSString+PinYin.h"

@interface ChatRecordViewModel()

@property (nonatomic, strong) OLYMUserObject *currentChatUser;
@property (nonatomic, strong) NSArray *allRooms;
@property (nonatomic, strong) NSArray *allLocals;
@property (nonatomic, strong) NSArray *allFriends;
@end

@implementation ChatRecordViewModel

- (instancetype)initWithUser:(OLYMUserObject *)currentChatUser
{
    self = [super init];
    if(self){
        self.currentChatUser = currentChatUser;
    }
    return self;
}

- (instancetype)init
{
    if(self = [super init])
    {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            _allRooms = [OLYMUserObject fetchAllRooms];
            _allFriends = [OLYMUserObject fetchAllTureFriends];
            _allLocals = [OLYMUserObject fetchLocalContactsExceptFriends];
            for (OLYMUserObject *userObj in _allLocals) {
                NSString *nickName = userObj.userNickname;
                NSString *nickNameLetters = [nickName getFirstLetters];
                userObj.nameLetters = nickNameLetters;
            }
            for (OLYMUserObject *userObj in _allFriends) {
                NSString *nickName = userObj.userNickname;
                NSString *remarkName = userObj.userRemarkname;
                NSString *nickNameLetters = [nickName getFirstLetters];
                NSString *remakeLetters = [remarkName getFirstLetters];
                userObj.nameLetters = nickNameLetters;
                userObj.remarkLetters = remakeLetters;
            }
        });
    }
    return self;
}

- (void)olym_initialize
{
    WeakSelf(ws);
    
}


- (NSArray *)fillChatRecords:(NSArray *)messages
{
    for(OLYMMessageObject *message in messages)
    {
        if (message.isMySend)
        {
            message.fromUserName = olym_UserCenter.userName;
        }else
        {
            message.fromUserName = self.currentChatUser.userNickname;
        }
        message.domain = self.currentChatUser.domain;
        
    }
    return messages;
}

- (NSArray *)queryChatRecord:(NSString *)keyWord
{
    NSArray *array =  [OLYMMessageObject fetchMessagesByKeyWord:keyWord userId:self.currentChatUser.userId userDomain:self.currentChatUser.domain];
    return [self fillChatRecords:array];
}

- (NSArray *)queryFullRecordWith:(NSString *)keyword
{
    NSMutableArray *searchResults = [NSMutableArray array];
    
    NSTimeInterval time1 = [[NSDate date]timeIntervalSince1970];
    NSArray *contacts = [self queryAllContactsWith:keyword];
    
 
    if (contacts && contacts.count > 0)
    {
        OLYMSearchObject *contactObject = [[OLYMSearchObject alloc]init];
        contactObject.type = SearchRecordContactType;
        contactObject.searchArray = contacts;
        [searchResults addObject:contactObject];
    }
    NSArray *rooms = [self queryGroupWith:keyword];
    //群聊
    if (rooms && rooms.count > 0)
    {
        OLYMSearchObject *contactObject = [[OLYMSearchObject alloc]init];
        contactObject.type = SearchRecordGroupType;
        contactObject.searchArray = rooms;
        [searchResults addObject:contactObject];
    }
    
    NSArray *chatRecords = [self queryAllChatRecordWith:keyword];
    if (chatRecords && chatRecords.count > 0)
    {
        OLYMSearchObject *contactObject = [[OLYMSearchObject alloc]init];
        contactObject.type = SearchRecordChatType;
        contactObject.searchArray = chatRecords;
        [searchResults addObject:contactObject];
    }
    NSTimeInterval time2 = [[NSDate date]timeIntervalSince1970];
    NSLog(@"全局关键词查询耗时 :%lf",time2 - time1);
    return searchResults;
}


- (NSArray *)queryGroupWith:(NSString *)keyword
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.userNickname contains [cd] %@",keyword];
    NSArray *searchs = [self.allRooms  filteredArrayUsingPredicate:predicate];
    return searchs;
}

- (NSArray *)queryAllChatRecordWith:(NSString *)keyword
{
    NSMutableArray *chatRecords = [NSMutableArray array];
    //聊天记录
    for (OLYMUserObject *user in self.allFriends)
    {
        NSArray *array =  [OLYMMessageObject fetchMessagesByKeyWord:keyword userId:user.userId userDomain:user.domain];
        if (array && array.count > 0)
        {
            OLYMMessageSearchObject *messageSearchObject = [[OLYMMessageSearchObject alloc]init];
            messageSearchObject.userObject = user;
            messageSearchObject.searchArray = array;
            [chatRecords addObject:messageSearchObject];
        }
    }
    
    for (OLYMUserObject *user in self.allRooms)
    {
        NSArray *array =  [OLYMMessageObject fetchMessagesByKeyWord:keyword userId:user.userId userDomain:user.domain];
        if (array && array.count > 0)
        {
            OLYMMessageSearchObject *messageSearchObject = [[OLYMMessageSearchObject alloc]init];
            messageSearchObject.userObject = user;
            messageSearchObject.searchArray = array;
            [chatRecords addObject:messageSearchObject];
        }
    }
    return chatRecords;
}

- (NSArray *)queryAllContactsWith:(NSString *)keyword
{
    NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"SELF.userNickname contains [cd] %@ ||SELF.userRemarkname contains [cd] %@ || SELF.telephone contains [cd] %@ ||  SELF.nameLetters contains [cd] %@ || SELF.remarkLetters contains [cd] %@",keyword,keyword,keyword,keyword,keyword];
    NSArray *searchFirends = [self.allFriends  filteredArrayUsingPredicate:predicate1];
    
    NSPredicate *predicate2 = [NSPredicate predicateWithFormat:@"SELF.userNickname contains [cd] %@ || SELF.telephone contains [cd] %@ ||  SELF.nameLetters contains [cd] %@",keyword,keyword,keyword];
    NSArray *searchLocals = [self.allLocals  filteredArrayUsingPredicate:predicate2];

    NSMutableArray *contacts = [NSMutableArray array];
    
    //联系人
    [contacts addObjectsFromArray:searchFirends];
    [contacts addObjectsFromArray:searchLocals];
    return contacts;
}



- (CGFloat)heightForSingleChatRecord:(OLYMMessageObject *)messageObj
{
    NSString *content = messageObj.content;
    //
    return 0;
}
#pragma mark - Property

- (RACSubject *)miyouSubject
{
    if (!_miyouSubject) {
        _miyouSubject = [RACSubject subject];
    }
    return _miyouSubject;
}

- (RACSubject *)localContactSubject
{
    if (!_localContactSubject) {
        _localContactSubject = [RACSubject subject];
    }
    return _localContactSubject;
}
- (RACSubject *)groupSubject
{
    if (!_groupSubject) {
        _groupSubject = [RACSubject subject];
    }
    return _groupSubject;

}
- (RACSubject *)multiRecordSubject
{
    if (!_multiRecordSubject) {
        _multiRecordSubject = [RACSubject subject];
    }
    return _multiRecordSubject;

}

- (RACSubject *)singleRecordSubject
{
    if (!_singleRecordSubject) {
        _singleRecordSubject = [RACSubject subject];
    }
    return _singleRecordSubject;
    
}

- (RACSubject *)contactRecordSubject
{
    if (!_contactRecordSubject) {
        _contactRecordSubject = [RACSubject subject];
    }
    return _contactRecordSubject;

}

- (RACSubject *)moreContactsSubject
{
    if (!_moreContactsSubject) {
        _moreContactsSubject = [RACSubject subject];
    }
    return _moreContactsSubject;

}
- (RACSubject *)moreGroupsSubject
{
    if (!_moreGroupsSubject) {
        _moreGroupsSubject = [RACSubject subject];
    }
    return _moreGroupsSubject;

}
- (RACSubject *)moreFullRecordsSubject
{
    if (!_moreFullRecordsSubject) {
        _moreFullRecordsSubject = [RACSubject subject];
    }
    return _moreFullRecordsSubject;

}
@end
