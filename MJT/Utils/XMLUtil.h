//
//  XMLUtil.h
//  MJT_APP
//
//  Created by Chant on 2018/3/12.
//  Copyright © 2018年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VersionModel.h"
//声明代理
@interface XMLUtil : NSObject<NSXMLParserDelegate>
//添加属性
@property (nonatomic, strong) NSXMLParser *par;
@property (nonatomic, strong) VersionModel *versionModel;
//标记当前标签，以索引找到XML文件内容
@property (nonatomic, copy) NSString *currentElement;
/* url */
@property(nonatomic,copy) NSString *url;
//声明parse方法，通过它实现解析
-(void)parse;
@end

