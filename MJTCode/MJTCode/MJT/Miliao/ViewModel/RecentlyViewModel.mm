//
//  RecentlyViewModel.m
//  MJT_APP
//
//  Created by Donny on 2017/9/11.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "RecentlyViewModel.h"
#import "OLYMUserObject.h"
#import "OLYMMessageObject.h"
#import "GJCFUploadFileModel.h"
#import "FileCenter.h"
#import "SendFileHelper.h"
#import "OLYMAESCrypt.h"
#import "OLYMUserObject+Pinyin.h"
#import "NSString+PinYin.h"

@interface RecentlyViewModel ()


@end

@implementation RecentlyViewModel


-(void)olym_initialize{
    
    int pageCount = INT_MAX;
    
    NSArray *fetchArray = [OLYMUserObject fetchRecentChatByPage:pageCount];
    if(fetchArray){
        [self.dataArray addObjectsFromArray:fetchArray];
        NSMutableArray *systemUsers = [NSMutableArray array];
        for (OLYMUserObject *userObj in self.dataArray)
        {
            if([userObj.userId isEqualToString:SYSTEM_CENTER_USERID]
               || [userObj.userId isEqualToString:FRIEND_CENTER_USERID]
               || [userObj.userId isEqualToString:ROOM_CENTER_USERID]
               || [userObj.userId isEqualToString:LocalContact_CENTER_USERID])
            {
                [systemUsers addObject:userObj];
            }
#if MJTDEV
            NSString *nickName = userObj.userNickname;
            NSString *remarkName = userObj.userRemarkname;
            
            NSString *nickNameLetters = [nickName getFirstLetters];
            NSString *remakeLetters = [remarkName getFirstLetters];
            userObj.nameLetters = nickNameLetters;
            userObj.remarkLetters = remakeLetters;
#endif
        }
        [self.dataArray removeObjectsInArray:systemUsers];
    }
    
    
}

- (void)forwardMessages:(NSArray *)messages toUser:(OLYMUserObject *)userObj
{
    for(OLYMMessageObject *message in messages)
    {
        NSString *filePath = message.filePath;
        filePath = [[olym_FileCenter documentPrefix]stringByAppendingPathComponent:filePath];
        if (message.type == kWCMessageTypeVideo || message.type == kWCMessageTypeFile || message.type == kWCMessageTypeImage)
        {
            if (![FileCenter fileExistAt:filePath])
            {
                continue;
            }
        }
        [self forwardMessage:message toUser:userObj];
    }
}

- (void)forwardMessage:(OLYMMessageObject *)message toUser:(OLYMUserObject *)userObj
{
    NSString *filePath = message.filePath;
    filePath = [[olym_FileCenter documentPrefix]stringByAppendingPathComponent:filePath];
    switch (message.type) {
        case kWCMessageTypeText:
        {
            [self transpondTextMessage:message.content filePath:message.filePath isAppoint:message.isAppoint  toUser:userObj];
        }
            break;
        case kWCMessageTypeImage:
        {
            NSString *fileName = [message.filePath lastPathComponent];
            NSString *toPath = [NSString stringWithFormat:@"%@/%ld%@",[olym_FileCenter getMyFileLocalPath:userObj.userId],(long)[[NSDate date]timeIntervalSince1970],fileName];
            if (message.isAESEncrypt)
            {
                [FileCenter copyFileAtPath:filePath toPath:toPath];
            }else
            {
                //文件未进行AES加密，转发的文件需要加密保存
                [OLYMAESCrypt encryptFileData:[NSData dataWithContentsOfFile:filePath] saveFilePath:toPath];
            }
            [self transpondImage:toPath imageWidth:message.imageWidth imageHeight:message.imageHeight thumbnail:message.thumbnail toUser:userObj];
        }
            break;
        case kWCMessageTypeFile:
        {
            NSString *fileName = message.fileName;
            NSString *toPath = [NSString stringWithFormat:@"%@/%ld%@",[olym_FileCenter getMyFileLocalPath:userObj.userId],(long)[[NSDate date]timeIntervalSince1970],fileName];
            
            if (message.isAESEncrypt)
            {
                [FileCenter copyFileAtPath:filePath toPath:toPath];
            }else
            {
                //文件未进行AES加密，转发的文件需要加密保存
                [OLYMAESCrypt encryptFileData:[NSData dataWithContentsOfFile:filePath] saveFilePath:toPath];
            }
            [self transpondFileMessage:toPath fileSize:message.fileSize fileName:fileName toUser:userObj];
        }
            break;
        case kWCMessageTypeVideo:
        {
            NSString *fileName = [message.filePath lastPathComponent];
            NSString *toPath = [NSString stringWithFormat:@"%@/%ld%@",[olym_FileCenter getMyFileLocalPath:userObj.userId],(long)[[NSDate date]timeIntervalSince1970],fileName];
            if (message.isAESEncrypt)
            {
                [FileCenter copyFileAtPath:filePath toPath:toPath];
            }else
            {
                //文件未进行AES加密，转发的文件需要加密保存
                [OLYMAESCrypt encryptFileData:[NSData dataWithContentsOfFile:filePath] saveFilePath:toPath];
            }
            [self transpondVideoMessage:toPath fileSize:message.fileSize thumbnail:message.thumbnail toUser:userObj];
        }
            break;
        default:
            break;
    }

}

- (void)transpondTextMessage:(NSString *)content filePath:(NSString *)filePath isAppoint:(BOOL)isAppoint toUser:(OLYMUserObject *)userObj
{
    dispatch_async(XmppSendQueue, ^{
        OLYMMessageObject *msg = [[OLYMMessageObject alloc]init];
        [msg setMessageId];
        msg.toUserIbcKey = userObj.telephone;
        msg.isReadburn = NO;
        msg.timeSend = [NSDate date];
        msg.toUserId = userObj.userId;
        msg.fromUserId = olym_UserCenter.userId;
        msg.domain = userObj.domain;
        msg.type = kWCMessageTypeText;
        msg.isGroup = userObj.roomFlag == 1 ? YES:NO;
        //群聊里面如果修改了群昵称，需要放到消息里面去，对方才能显示出来
        if(msg.isGroup){
            NSString *fromUserName;
            if (userObj.userRemarkname)
            {
                msg.fromUserName = userObj.userRemarkname;
            }else
            {
                msg.fromUserName = olym_UserCenter.userName;
            }
        }

        if(GJCFStringIsNull(content))
        {
            msg.content = [msg getLastContent];
        }
        else{
            msg.content = content;
        }
        
        if (filePath) {
            msg.filePath = filePath;
        }
        
        
        msg.isSend = transfer_status_ing;
        msg.isRead = YES;
        msg.isMySend = YES;
        msg.isEncrypt = YES;
        
        [msg insert];
        
        [msg updateLastSend:YES];
        if(msg.isGroup)
        {
            NSTimeInterval now = [[NSDate date]timeIntervalSince1970];
            if (userObj.isSilence)
            {
                if (userObj.talkTime > now)
                {
                    msg.isSlience = YES;
                    msg.isSend = transfer_status_no;
                    [msg updateSendStatus:msg.isSend];
                }else
                {
                    //禁言时间结束
                    userObj.isSilence = NO;
                    userObj.talkTime = 0;
                    [userObj updateUserSlienceStatus];
                }
            }
        }
        [msg sendMessage];
        
        [olym_Nofity postNotificationName:kXMPPRefreshMsgListNotifaction object:msg];

    });
    
}

- (void)transpondImage:(NSString *)imagePath imageWidth:(float)width imageHeight:(float)height thumbnail:(NSString *)thumbnail toUser:(OLYMUserObject *)userObj
{
    dispatch_async(XmppSendQueue, ^{
        NSString *uploadFilePath = imagePath;
        
        NSString *filePath = [imagePath stringByReplacingOccurrencesOfString:[[FileCenter sharedFileCenter]documentPrefix] withString:@""];
        
        OLYMMessageObject *msg = [[OLYMMessageObject alloc]init];
        [msg setMessageId];
        msg.toUserIbcKey = userObj.telephone;
        msg.timeSend = [NSDate date];
        msg.toUserId = userObj.userId;
        msg.fromUserId = olym_UserCenter.userId;
        msg.domain = userObj.domain;
        msg.type = kWCMessageTypeImage;
        msg.content = [msg getLastContent];
        msg.filePath = filePath;
        msg.fileName = [filePath lastPathComponent];
        msg.imageWidth = width;
        msg.imageHeight = height;
        msg.isSend = transfer_status_ing;
        msg.isRead = YES;
        msg.isMySend = YES;
        msg.isEncrypt = YES;
        //文件进行了AES加密
        msg.isAESEncrypt = YES;


        if (thumbnail) {
            msg.thumbnail = thumbnail;
        }


        //通过roomflag 0为单聊 1为群聊
        msg.isGroup = userObj.roomFlag == 1 ? YES:NO;
        //群聊里面如果修改了群昵称，需要放到消息里面去，对方才能显示出来
        if(msg.isGroup){
            NSString *fromUserName;
            if (userObj.userRemarkname)
            {
                msg.fromUserName = userObj.userRemarkname;
            }else
            {
                msg.fromUserName = olym_UserCenter.userName;
            }
        }

        msg.uploadFileModel = [GJCFUploadFileModel fileModelWithFileName:[uploadFilePath lastPathComponent] withFilePath:uploadFilePath withFormName:@"file"];
        
        [msg insert];
        
        [msg updateLastSend:YES];
        
        if(msg.isGroup)
        {
            NSTimeInterval now = [[NSDate date]timeIntervalSince1970];
            if (userObj.isSilence)
            {
                if (userObj.talkTime > now)
                {
                    msg.isSlience = YES;
                    msg.isSend = transfer_status_no;
                    [msg updateSendStatus:msg.isSend];
                }else
                {
                    //禁言时间结束
                    userObj.isSilence = NO;
                    userObj.talkTime = 0;
                    [userObj updateUserSlienceStatus];
                }
            }
        }
        
        [olym_Nofity postNotificationName:kXMPPRefreshMsgListNotifaction object:msg];
        if (!msg.isSlience)
        {
            [[SendFileHelper shareInstance]uploadFile:msg];
        }
    });

}


- (void)transpondVideoMessage:(NSString *)filePath fileSize:(unsigned long long)fileSize  thumbnail:(NSString *)thumbnail toUser:(OLYMUserObject *)userObj
{
    dispatch_async(XmppSendQueue, ^{
        NSString *uploadFilePath = filePath;
        
        NSString *path = [filePath stringByReplacingOccurrencesOfString:[[FileCenter sharedFileCenter]documentPrefix] withString:@""];
        
        OLYMMessageObject *msg = [[OLYMMessageObject alloc]init];
        [msg setMessageId];
        msg.toUserIbcKey = userObj.telephone;
        msg.timeSend = [NSDate date];
        msg.toUserId = userObj.userId;
        msg.fromUserId = olym_UserCenter.userId;
        msg.domain = userObj.domain;
        msg.type = kWCMessageTypeVideo;
        msg.isGroup = userObj.roomFlag == 1 ? YES:NO;
        //群聊里面如果修改了群昵称，需要放到消息里面去，对方才能显示出来
        if(msg.isGroup){
            NSString *fromUserName;
            if (userObj.userRemarkname)
            {
                msg.fromUserName = userObj.userRemarkname;
            }else
            {
                msg.fromUserName = olym_UserCenter.userName;
            }
        }

        msg.isSend = transfer_status_ing;
        msg.isRead = YES;
        msg.isMySend = YES;
        msg.isEncrypt = YES;
        //文件进行了AES加密
        msg.isAESEncrypt = YES;
        //video msg
        msg.content = [[path lastPathComponent] stringByDeletingPathExtension];
        msg.filePath = path;
        msg.fileName = [path lastPathComponent];
        msg.fileSize = fileSize;
        if (thumbnail) {
            msg.thumbnail = thumbnail;
        }
        msg.uploadFileModel = [GJCFUploadFileModel fileModelWithFileName:[uploadFilePath lastPathComponent] withFilePath:uploadFilePath withFormName:@"file"];
        
        [msg insert];
        
        [msg updateLastSend:YES];
        
        
        if(msg.isGroup)
        {
            NSTimeInterval now = [[NSDate date]timeIntervalSince1970];
            if (userObj.isSilence)
            {
                if (userObj.talkTime > now)
                {
                    msg.isSlience = YES;
                    msg.isSend = transfer_status_no;
                    [msg updateSendStatus:msg.isSend];
                }else
                {
                    //禁言时间结束
                    userObj.isSilence = NO;
                    userObj.talkTime = 0;
                    [userObj updateUserSlienceStatus];
                }
            }
        }
        
        [olym_Nofity postNotificationName:kXMPPRefreshMsgListNotifaction object:msg];
        if (!msg.isSlience)
        {
            [[SendFileHelper shareInstance]uploadFile:msg];
        }
    });
    
}

- (void)transpondFileMessage:(NSString *)filePath fileSize:(unsigned long long)fileSize fileName:(NSString *)fileName toUser:(OLYMUserObject *)userObj
{
    dispatch_async(XmppSendQueue, ^{
        NSString *uploadFilePath = filePath;
        
        NSString *path = [filePath stringByReplacingOccurrencesOfString:[[FileCenter sharedFileCenter]documentPrefix] withString:@""];
        
        OLYMMessageObject *msg = [[OLYMMessageObject alloc]init];
        [msg setMessageId];
        msg.toUserIbcKey = userObj.telephone;
        msg.timeSend = [NSDate date];
        msg.toUserId = userObj.userId;
        msg.fromUserId = olym_UserCenter.userId;
        msg.domain = userObj.domain;
        msg.type = kWCMessageTypeFile;
        msg.isGroup = userObj.roomFlag == 1 ? YES:NO;
        
        msg.isSend = transfer_status_ing;
        msg.isRead = YES;
        msg.isMySend = YES;
        msg.isEncrypt = YES;
        //文件进行了AES加密
        msg.isAESEncrypt = YES;

        //群聊里面如果修改了群昵称，需要放到消息里面去，对方才能显示出来
        if(msg.isGroup){
            NSString *fromUserName;
            if (userObj.userRemarkname)
            {
                msg.fromUserName = userObj.userRemarkname;
            }else
            {
                msg.fromUserName = olym_UserCenter.userName;
            }
        }

        //file msg
        msg.content = [msg getLastContent];
        msg.filePath = path;
        msg.fileName = fileName;
        msg.fileSize = fileSize;
        
        msg.uploadFileModel = [GJCFUploadFileModel fileModelWithFileName:[uploadFilePath lastPathComponent] withFilePath:uploadFilePath withFormName:@"file"];
        
        [msg insert];
        
        [msg updateLastSend:YES];
        
        
        if(msg.isGroup)
        {
            NSTimeInterval now = [[NSDate date]timeIntervalSince1970];
            if (userObj.isSilence)
            {
                if (userObj.talkTime > now)
                {
                    msg.isSlience = YES;
                    msg.isSend = transfer_status_no;
                    [msg updateSendStatus:msg.isSend];
                }else
                {
                    //禁言时间结束
                    userObj.isSilence = NO;
                    userObj.talkTime = 0;
                    [userObj updateUserSlienceStatus];
                }
            }
        }
        
        [olym_Nofity postNotificationName:kXMPPRefreshMsgListNotifaction object:msg];
        if (!msg.isSlience)
        {
            [[SendFileHelper shareInstance]uploadFile:msg];
        }
    });

}


- (NSArray *)queryWithKeyword:(NSString *)keyword
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.userNickname contains [cd] %@ ||SELF.userRemarkname contains [cd] %@ || SELF.telephone contains [cd] %@ ||  SELF.nameLetters contains [cd] %@ || SELF.remarkLetters contains [cd] %@",keyword,keyword,keyword,keyword,keyword];
    NSArray *filterArray = [self.previousArray filteredArrayUsingPredicate:predicate];
    return filterArray;
}


@end
