//
//  CreateNewChatViewModel.h
//  MJT_APP
//
//  Created by Donny on 2017/12/27.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "OLYMListViewModel.h"

@interface CreateNewChatViewModel : OLYMListViewModel

@property(nonatomic,readonly) NSMutableArray* allContacts;

@property(nonatomic,strong) RACSubject *roomlistSubject;
@property(nonatomic,strong) RACSubject *organizationlistSubject;

@end
