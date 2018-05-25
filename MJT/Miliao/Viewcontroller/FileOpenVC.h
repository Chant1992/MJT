//
//  FileOpenVC.h
//  MJT_APP
//
//  Created by Donny on 2017/9/11.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "OLYMViewController.h"

@interface FileOpenVC : OLYMViewController

@property (strong, nonatomic) NSString *urlPath;

@property (assign, nonatomic) int type;

@property (nonatomic, assign) BOOL isFileAESEncrypt;
@end
