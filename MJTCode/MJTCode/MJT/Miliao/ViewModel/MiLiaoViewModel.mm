//
//  MiLiaoViewModel.m
//  MJT_APP
//
//  Created by olymtech on 2017/8/28.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "MiLiaoViewModel.h"
#import "OLYMMessageObject.h"
#import "OLYMUserObject.h"
@implementation MiLiaoViewModel

-(void)olym_initialize{

    @weakify(self);
    
    [self.refreshDataCommand.executionSignals.switchToLatest subscribeNext:^(NSDictionary *responseDic) {
        @strongify(self);
        [self.dataArray removeAllObjects];
        int pageCount = INT_MAX;
        NSArray *fetchArray = [OLYMUserObject fetchRecentChatByPage:pageCount];
        if(fetchArray){
            [self.dataArray addObjectsFromArray:fetchArray];
#if XYT
            NSMutableArray *systemUsers = [NSMutableArray array];
            for (OLYMUserObject *userObj in self.dataArray)
            {
                if([userObj.userId isEqualToString:FRIEND_CENTER_USERID])
                {
                    [systemUsers addObject:userObj];
                    break;
                }
            }
            [self.dataArray removeObjectsInArray:systemUsers];
#else
#if MJTDEV
            NSMutableArray *systemUsers = [NSMutableArray array];
            for (OLYMUserObject *userObj in fetchArray)
            {
                
                if([userObj.userId isEqualToString:SYSTEM_CENTER_USERID]
                   || [userObj.userId isEqualToString:FRIEND_CENTER_USERID])
                {
                    [systemUsers addObject:userObj];
                }

            }
            [self.dataArray removeObjectsInArray:systemUsers];
#endif
#endif
        }
        [self.refreshUI sendNext:nil];
    }];
}


- (void)replaceUser:(id)userObj
{
    OLYMUserObject *modifyUser = userObj;
    for (OLYMUserObject *user in self.dataArray)
    {
        if([user.userId isEqualToString:modifyUser.userId] && [user.domain isEqualToString:modifyUser.domain])
        {
            user.userNickname = modifyUser.userNickname;
            break;
        }
    }
}

- (RACCommand *)refreshDataCommand
{
    if (!_refreshDataCommand)
    {
        _refreshDataCommand = [[RACCommand alloc]initWithSignalBlock:^RACSignal * _Nonnull(id  _Nullable input) {
            return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
                
                [subscriber sendNext:nil];
                [subscriber sendCompleted];
                return nil;
                
            }];
        }];
    }
    return _refreshDataCommand;
}

-(RACSubject *)pcViewClickSubject{
    
    if (!_pcViewClickSubject) {
        
        _pcViewClickSubject = [[RACSubject alloc]init];
    }
    
    return _pcViewClickSubject;
}

@end
