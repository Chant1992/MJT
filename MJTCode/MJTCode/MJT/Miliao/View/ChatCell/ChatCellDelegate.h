//
//  ChatCellDelegate.h
//  MJT_APP
//
//  Created by Donny on 2017/9/8.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

@class ChatBaseCell;
@protocol ChatCellDelegate <NSObject>

@optional

//点击头像
- (void)chatCellDidTapHeader:(ChatBaseCell *)chatBaseCell;
//长按头像
- (void)chatCellDidLongPressHeader:(ChatBaseCell *)chatBaseCell;
//音频播放
- (void)chatCellDidTapAudioMessage:(ChatBaseCell *)chatBaseCell;
//图片放大
- (void)chatCellDidTapImageMessage:(ChatBaseCell *)chatBaseCell;

//视频播放
- (void)chatCellDidTapVideoMessage:(ChatBaseCell *)chatBaseCell;

//查看名片
- (void)chatCellDidTapCardMessage:(ChatBaseCell *)chatBaseCell;

//查看文件
- (void)chatCellDidTapFileMessage:(ChatBaseCell *)chatBaseCell;


//查看阅后即焚
- (void)chatCellDidTapBurnAfterReadMessage:(ChatBaseCell *)chatBaseCell;

//删除
- (void)chatCellDeleteMessage:(ChatBaseCell *)chatBaseCell;

//转发
- (void)chatCellTranspondMessage:(ChatBaseCell *)chatBaseCell;

//解密
- (void)chatCellDecodeMessage:(ChatBaseCell *)chatBaseCell;
//引用
- (void)chatCellReferenceMessage:(ChatBaseCell *)chatBaseCell;
//撤回
- (void)chatCellReCallMessage:(ChatBaseCell *)chatBaseCell;
//多选
- (void)chatCellMutiSelectMessage:(ChatBaseCell *)chatBaseCell;

//重新下载
- (void)chatCellReDownload:(ChatBaseCell *)chatBaseCell;
//重新发送
- (void)chatCellResendMessage:(ChatBaseCell *)chatBaseCell;
//点击link
- (void)chatCellDidTapLink:(NSString *)urlString;
//点击link
- (void)chatCellDidTapPhoneNumber:(NSString *)phoneNumber;

@end
