//
//  NewFriendModel.m
//  MJT_APP
//
//  Created by olymtech on 2017/9/4.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "NewFriendModel.h"
#import "OLYMNewFriendObj.h"

@implementation NewFriendModel

-(void)olym_initialize{
    [self.dataArray addObjectsFromArray:[OLYMNewFriendObj fetchAllNewFriends]];
    
#if ThirdlyVersion
    
    [self groupingTheNewFriend];
#else
    
#endif
    
    
    @weakify(self);
    [self.addNewFriendCommand.executionSignals.switchToLatest subscribeNext:^(OLYMNewFriendObj *weakFriendObj) {
        
        @strongify(self);
        
        [SVProgressHUD dismiss];
       
        [weakFriendObj generaMessage:_T(@"请求验证通过") withType:XMPP_TYPE_PASS];
        
        [weakFriendObj addNewFriend];
        
#if ThirdlyVersion

        [self.refreshDataSubject sendNext:nil];
#endif
    }];
    
    [self.addNewFriendCommand.executing  subscribeNext:^(id x) {
        
        if ([x isEqualToNumber:@(YES)]) {
            
            [SVProgressHUD showWithStatus:_T(@"正在发送")];
        }
    }];
    
    [self.refreshDataSubject subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        
        [self.dataArray removeAllObjects];
        [self.dataArray addObjectsFromArray:[OLYMNewFriendObj fetchAllNewFriends]];
        [self groupingTheNewFriend];
        [self.refreshUI sendNext:nil];
    }];
}

//分组
-(void)groupingTheNewFriend{
    
    [self.recentlyFriends removeAllObjects];
    [self.beforeFriends removeAllObjects];
    
    for (OLYMNewFriendObj *newFriend in self.dataArray) {
        
        if ([GJCFDateUitil calcDaysFromBegin:newFriend.updateTime end:[NSDate date]] > 7) {
            
            [self.beforeFriends addObject:newFriend];
        }else{
            
            [self.recentlyFriends addObject:newFriend];
        }
    }
    
}

-(RACCommand *)sendMessageCommand{
    if (!_sendMessageCommand) {
        
        @weakify(self);
        
        _sendMessageCommand = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
            
            @strongify(self);
            return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
                
                @strongify(self);
                
                
                return nil;
            }];
        }];
    }
    
    return _sendMessageCommand;
}

#if ThirdlyVersion

-(RACCommand *)addNewFriendCommand{
    if (!_addNewFriendCommand) {
        
        @weakify(self);
        
        _addNewFriendCommand = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(NSNumber * indexNumber) {
            
            @strongify(self);
            return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
                
                @strongify(self);
                int index = [indexNumber integerValue];
                
                OLYMNewFriendObj *newFriendObj = [self.dataArray objectAtIndex:index];
                __weak typeof (newFriendObj) weakFriendObj = newFriendObj;
                
                [olym_IMRequest addFriend:newFriendObj.userId domain:newFriendObj.domain attentionType:@"2" telephone:newFriendObj.telephone Success:^(NSDictionary *dic) {
                    
                    [subscriber sendNext:weakFriendObj];
                    [subscriber sendCompleted];
                } failure:^(NSString *error) {
                    
                    //发生错误了，隐藏hud
                    [SVProgressHUD dismiss];
                    
                    [subscriber sendCompleted];
                }];
                
                return nil;
            }];
        }];
    }
    
    return _addNewFriendCommand;
}

#else

-(RACCommand *)addNewFriendCommand{
    if (!_addNewFriendCommand) {
        
        @weakify(self);
        
        _addNewFriendCommand = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(NSNumber * indexNumber) {
            
            @strongify(self);
            return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
                
                @strongify(self);
                int index = [indexNumber integerValue];
                
                OLYMNewFriendObj *newFriendObj = [self.dataArray objectAtIndex:index];
                __weak typeof (newFriendObj) weakFriendObj = newFriendObj;
                
                [olym_IMRequest addFriend:newFriendObj.userId domain:newFriendObj.domain attentionType:@"2" telephone:newFriendObj.telephone Success:^(NSDictionary *dic) {
                    
                    [subscriber sendNext:weakFriendObj];
                    [subscriber sendCompleted];
                } failure:^(NSString *error) {
                    
                    //发生错误了，隐藏hud
                    [SVProgressHUD dismiss];
                    
                    [subscriber sendCompleted];
                }];
                
                return nil;
            }];
        }];
    }
    
    return _addNewFriendCommand;
}
#endif



-(RACSubject *)addNewFriendSubject{
    if(!_addNewFriendSubject){
        _addNewFriendSubject = [RACSubject subject];
    }
    return _addNewFriendSubject;
}

-(NSMutableArray *)recentlyFriends{
    
    if (!_recentlyFriends) {
        
        _recentlyFriends = @[].mutableCopy;
    }
    
    return _recentlyFriends;
}

-(NSMutableArray *)beforeFriends{
    
    if (!_beforeFriends) {
        
        _beforeFriends = @[].mutableCopy;
    }
    
    return _beforeFriends;
}

-(RACSubject *)acceptBtnSubject{
    
    if(!_acceptBtnSubject){
        _acceptBtnSubject = [RACSubject subject];
    }
    return _acceptBtnSubject;
}

-(RACSubject *)waitVerificationBtnSubject{
    
    if(!_waitVerificationBtnSubject){
        _waitVerificationBtnSubject = [RACSubject subject];
    }
    return _waitVerificationBtnSubject;
}

-(RACSubject *)refreshDataSubject{
    
    if(!_refreshDataSubject){
        _refreshDataSubject = [RACSubject subject];
    }
    return _refreshDataSubject;
}
@end
