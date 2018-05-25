//
//  ChatDocumentCell.h
//  MJT_APP
//
//  Created by Donny on 2017/12/26.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>
@class OLYMMessageObject;
@interface ChatDocumentCell : UITableViewCell

/* 文件消息 */
@property(nonatomic,strong) OLYMMessageObject *fileObj;

@property (nonatomic) BOOL mutiSelecting;
@end
