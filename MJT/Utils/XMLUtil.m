//
//  XMLUtil.m
//  MJT_APP
//
//  Created by Chant on 2018/3/12.
//  Copyright © 2018年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "XMLUtil.h"

@implementation XMLUtil

//几个代理方法的实现，是按逻辑上的顺序排列的，但实际调用过程中中间三个可能因为循环等问题乱掉顺序
//开始解析
- (void)parserDidStartDocument:(NSXMLParser *)parser{
    NSLog(@"parserDidStartDocument...");
    self.url = @"";
}
//准备节点
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(nullable NSString *)namespaceURI qualifiedName:(nullable NSString *)qName attributes:(NSDictionary<NSString *, NSString *> *)attributeDict{
    
    self.currentElement = elementName;
    
}
//获取节点内容
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string{
    /*
     @property (nonatomic, copy) NSString *ios_version;
     @property (nonatomic, copy) NSString *ios_name;
     @property (nonatomic, copy) NSString *ios_url;
     @property (nonatomic, copy) NSString *ios_resultCode;
     @property (nonatomic, copy) NSString *ios_resultDesc;
     @property (nonatomic, copy) NSString *ios_mustupdate;
     */
    if ([self.currentElement isEqualToString:@"ios_version"]) {
        [self.versionModel setIos_version:string];
    }else if ([self.currentElement isEqualToString:@"ios_name"]){
        [self.versionModel setIos_name:string];
    }else if ([self.currentElement isEqualToString:@"ios_url"]){
        self.url = [self.url stringByAppendingString:string];
        [self.versionModel setIos_url:self.url];
    }else if ([self.currentElement isEqualToString:@"ios_resultCode"]){
        [self.versionModel setIos_resultCode:string];
    }else if ([self.currentElement isEqualToString:@"ios_resultDesc"]){
        [self.versionModel setIos_resultDesc:string];
    }else if ([self.currentElement isEqualToString:@"ios_mustupdate"]){
        [self.versionModel setIos_mustupdate:string];
    }
}

//解析完一个节点
- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(nullable NSString *)namespaceURI qualifiedName:(nullable NSString *)qName{
    
    self.currentElement = nil;
}

//解析结束
- (void)parserDidEndDocument:(NSXMLParser *)parser{
    
    [olym_Nofity postNotificationName:kVersionUpdateNotification object:self.versionModel];
    self.par = nil;
}

//外部调用接口
-(void)parse{
    [self.par parse];
    
}

-(void)setPar:(NSXMLParser *)par{
    
    _par = par;
    _par.delegate = self;
}

-(VersionModel *)versionModel{
    
    if (!_versionModel) {
        
        _versionModel = [[VersionModel alloc]init];
    }
    
    return _versionModel;
}

@end

