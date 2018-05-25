//
//  RemindViewModel.m
//  MJT_APP
//
//  Created by Donny on 2017/9/14.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "RemindViewModel.h"
#import "OLYMRoomDataObject.h"
#import "OLYMUserObject.h"
#import "NSString+PinYin.h"
#import "OLYMUserObject+Pinyin.h"

@interface RemindViewModel ()

@property (nonatomic, strong) NSArray *allReminders;

@end

@implementation RemindViewModel


- (void)olym_initialize
{
    WeakSelf(ws);
    [self.membersCommand.executionSignals.switchToLatest subscribeNext:^(id  _Nullable dic) {
        StrongSelf(ss);
        
        [SVProgressHUD dismiss];
        
        OLYMRoomDataObject *roomDataObject = [[OLYMRoomDataObject alloc]init];
        [roomDataObject fromDictionary:dic];
        
        [self.dataArray removeAllObjects];
        
        //移除自己
        NSInteger index = NSNotFound;
        for (OLYMUserObject *userObj in roomDataObject.roomMembersArray)
        {
            if([[NSString stringWithFormat:@"%@",userObj.userId]  isEqualToString: [NSString stringWithFormat:@"%@",olym_UserCenter.userId]])
            {
                index = [roomDataObject.roomMembersArray indexOfObject:userObj];
            }else
            {
                //添加拼音首字母
                NSString *nickName = userObj.userNickname;
                NSString *remarkName = userObj.userRemarkname;
                
                NSString *nickNameLetters = [nickName getFirstLetters];
                userObj.nameLetters = nickNameLetters;

            }
        }
        if (index != NSNotFound)
        {
            [roomDataObject.roomMembersArray removeObjectAtIndex:index];
        }
        
        self.allReminders = roomDataObject.roomMembersArray;
        [self.dataArray addObjectsFromArray:[roomDataObject.roomMembersArray arrayWithPinYinFirstLetterFormat]];

        [self.membersSubject sendNext:roomDataObject];
    }];
    [[[self.membersCommand.executing skip:1]take:1]subscribeNext:^(NSNumber * _Nullable x) {
        if ([x isEqualToNumber:@(YES)]) {
            
            [SVProgressHUD showWithStatus:_T(@"正在获取信息")];
        }
    }];
}

- (void)showError
{
    [SVProgressHUD dismiss];
    [SVProgressHUD showInfoWithStatus:_T(@"获取群聊信息失败")];
}


- (RACCommand *)membersCommand
{
    if (!_membersCommand) {
        @weakify(self);
        _membersCommand = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(OLYMUserObject *userObject) {
            
            @strongify(self);
            return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
                
                @strongify(self);
                __weak typeof (userObject) weakUserObject = userObject;
                [olym_IMRequest getRoomInfo:userObject.roomId Success:^(NSDictionary *dic) {
                    [subscriber sendNext:dic];
                    [subscriber sendCompleted];
                } Failure:^(NSString *error) {
                    [self showError];
                    [subscriber sendCompleted];
                }];
                
                return nil;
            }];
        }];

     }
    return _membersCommand;
}


- (RACSubject *)membersSubject
{
    if (!_membersSubject)
    {
        _membersSubject = [RACSubject subject];
    }
    return _membersSubject;
}
@end
