//
//  MiLiaoViewModel.h
//  MJT_APP
//
//  Created by olymtech on 2017/8/28.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "OLYMListViewModel.h"

@interface MiLiaoViewModel : OLYMListViewModel

@property (nonatomic, strong) RACCommand *refreshDataCommand;
/* pcview点击 */
@property(nonatomic,strong) RACSubject *pcViewClickSubject;

- (void)replaceUser:(id)userObj;

@end
