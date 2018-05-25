//
//  UIButton+IndexPath.m
//  MJT_APP
//
//  Created by Chant on 2017/12/18.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "UIButton+IndexPath.h"

@implementation UIButton (IndexPath)

-(NSIndexPath *)indexPath
{
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setIndexPath:(NSIndexPath *)indexPath
{
    objc_setAssociatedObject(self, @selector(indexPath), indexPath, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
