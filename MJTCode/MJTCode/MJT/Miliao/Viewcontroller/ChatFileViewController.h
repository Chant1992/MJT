//
//  ChatFileViewController.h
//  MJT_APP
//
//  Created by Donny on 2017/9/11.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "OLYMViewController.h"
#import "OperationFileType.h"
@class OLYMUserObject;



@interface ChatFileViewController : OLYMViewController

@property (nonatomic, strong) OLYMUserObject *currentChatUser;
@property (nonatomic, assign) OperationFileType operationFileType;

@property (nonatomic, copy) void (^pickFilePathBlock) (NSString *pickFilePath,NSString *pickFileName,float fileSize,NSString *thumbnail,BOOL isAESEncrypt);

@end
