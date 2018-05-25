//
//  CreateNewChatViewModel.m
//  MJT_APP
//
//  Created by Donny on 2017/12/27.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "CreateNewChatViewModel.h"
#import "OLYMUserObject.h"
#import "NSString+PinYin.h"
#import "OLYMUserObject+Pinyin.h"

@interface CreateNewChatViewModel ()

@property(nonatomic,strong) NSMutableArray* allContacts;

@end

@implementation CreateNewChatViewModel


- (void)olym_initialize
{
    [self fetchAllContacts];
}


- (void)fetchAllContacts
{
    NSArray *fetchArray = [OLYMUserObject fetchAllFriends];
    
    NSMutableArray *tempFriends = [NSMutableArray array];
    for (OLYMUserObject *userObj in fetchArray)
    {
        if (userObj.status == 2)
        {
            //好友
            NSString *nickName = userObj.userNickname;
            userObj.nameLetters = [nickName getFirstLetters];
            [tempFriends addObject:userObj];
        }else
        {
            
        }
    }
    self.allContacts = tempFriends;
    [self.dataArray addObjectsFromArray:[tempFriends arrayWithPinYinFirstLetterFormat]];

}



- (RACSubject *)roomlistSubject
{
    if(!_roomlistSubject)
    {
        _roomlistSubject = [RACSubject subject];
    }
    return _roomlistSubject;
}

- (RACSubject *)organizationlistSubject
{
    if(!_organizationlistSubject)
    {
        _organizationlistSubject = [RACSubject subject];
    }
    return _organizationlistSubject;
}

@end
