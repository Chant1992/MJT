//
//  ForwardAlertView.h
//  MJT_APP
//
//  Created by Donny on 2017/12/15.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, ContentType){
    /** 图片*/
    Content_Image,
    /** 文字*/
    Content_Text
};

/** 点击按钮回调*/
typedef void (^completionHandlerBlock)(NSInteger buttonClickIndex);


@interface ForwardAlertView : UIView

/**
 *  初始化Alert
 *  @param title 转发用户名称
 *  @param images 用户头像
 *  @param content 转发内容
 *  @param completionHandler 点击回调Block
 */
- (instancetype)initWithTitle:(NSString *)title images:(NSArray *)images content:(id)content contentType:(ContentType)type buttonHandler:(completionHandlerBlock)completionHandler;


/** 显示*/
- (void)show;

@end
