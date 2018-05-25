//
//  RemindViewModel.h
//  MJT_APP
//
//  Created by Donny on 2017/9/14.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "OLYMListViewModel.h"

@interface RemindViewModel : OLYMListViewModel

@property (nonatomic, readonly) NSArray *allReminders;

@property (nonatomic, strong) RACCommand *membersCommand;

@property (nonatomic, strong) RACSubject *membersSubject;


@end
