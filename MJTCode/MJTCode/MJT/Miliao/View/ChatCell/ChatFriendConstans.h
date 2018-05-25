//
//  ChatFriendConstans.h
//  MJT_APP
//
//  Created by olymtech on 2017/8/29.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ChatFriendConstans : NSObject

+ (Class)classForContentType:(int)contentType isReadBurn:(BOOL)isReadBurn;

+ (NSString *)identifierForContentType:(int)contentType isReadBurn:(BOOL)isReadBurn;

@end
