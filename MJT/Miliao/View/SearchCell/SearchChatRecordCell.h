//
//  SearchChatRecordCell.h
//  MJT_APP
//
//  Created by Donny on 2017/12/18.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>
@class OLYMUserObject;

@interface SearchChatRecordCell : UITableViewCell

@property(nonatomic,strong) OLYMUserObject *userObj;
@property(nonatomic,strong) NSString *searchKeyword;
@property(nonatomic,strong) NSArray *searchResults;

@end
