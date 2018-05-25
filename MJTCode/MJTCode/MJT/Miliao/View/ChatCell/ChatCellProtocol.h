//
//  ChatCellProtocol.h
//  MJT_APP
//
//  Created by Donny on 2017/9/6.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#ifndef ChatCellProtocol_h
#define ChatCellProtocol_h


#endif /* ChatCellProtocol_h */

@protocol ChatCellProtocol <NSObject>

//cell上下间隔
@property (nonatomic,assign) CGFloat cellMargin;

@property (nonatomic,assign) CGSize contentSize;

@property (nonatomic,assign) CGFloat downloadProgress;

- (void)pause;

- (void)resume;


- (void)startVoiceAnimation;

- (void)stopVoiceAnimation;

- (void)updateSendStatus:(NSInteger)status;

@end
