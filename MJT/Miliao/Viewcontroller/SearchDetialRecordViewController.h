//
//  SearchRecordViewController.h
//  MJT_APP
//
//  Created by Donny on 2017/12/20.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "OLYMViewController.h"
@class OLYMSearchObject;

@interface SearchDetialRecordViewController : OLYMViewController

@property (nonatomic, strong) OLYMSearchObject *searchObject;

@property (nonatomic, strong) NSString *keyword;

@end
