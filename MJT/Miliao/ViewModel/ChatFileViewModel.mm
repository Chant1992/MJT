//
//  ChatFileViewModel.m
//  MJT_APP
//
//  Created by Donny on 2017/9/12.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "ChatFileViewModel.h"
#import "OLYMMessageObject.h"
#import "OLYMUserObject.h"
#import "OLYMMessageObject.h"
#import "GJCUImageBrowserModel.h"

#define FILE_PREFIX @"local_file_"

@interface ChatFileViewModel()

@property(strong,nonatomic) OLYMUserObject *currentChatUser;

@property (nonatomic, strong) NSArray *images;


@end

@implementation ChatFileViewModel

- (instancetype)initWithUser:(OLYMUserObject *)currentChatUser{
    
    self = [super init];
    if(self){
        self.currentChatUser = currentChatUser;
        self.currentChatUserId = self.currentChatUser.userId;
        self.currentChatUserDomain = self.currentChatUser.domain;
        
        [self getData];
    }
    return self;
}

- (void)olym_initialize{
    
}



- (void)getData
{
    NSArray *allFileMessages = [OLYMMessageObject fetchAllFileMessageByUser:self.currentChatUserId withDomain:self.currentChatUserDomain];
    
    NSMutableArray *todayDatas = [NSMutableArray array];
    NSMutableArray *yesterdayDatas = [NSMutableArray array];
    NSMutableArray *earlyDatas = [NSMutableArray array];

    //格式转换
    NSDateFormatter *formater = [[NSDateFormatter alloc] init];
    formater.dateFormat = @"yyyy-MM-dd HH:mm:ss";

    for(OLYMMessageObject *message in allFileMessages)
    {
        NSDate *d = message.timeSend;
        NSString *fileDate = [self compareDate:d];
        
        if ([fileDate isEqualToString:_T(@"今天")]) {
            
            //今天
            [todayDatas addObject:message];
        }else if ([fileDate isEqualToString:_T(@"昨天")]){
            
            //昨天
            [yesterdayDatas addObject:message];
        }else{
            
            //比昨天还早
            [earlyDatas addObject:message];
        }
    }
    
    //有值才加进数组
    if (todayDatas.count > 0) {
        
        [self.dataArray addObject:todayDatas];
    }
    
    if (yesterdayDatas.count > 0) {
        
        [self.dataArray addObject:yesterdayDatas];
    }
    if (earlyDatas.count > 0) {
        
        [self.dataArray addObject:earlyDatas];
    }
}

- (void)getImageAndVideoFiles
{
    
    NSArray *allFileMessages = [OLYMMessageObject fetchPictureAndVideoByUser:self.currentChatUserId withDomain:self.currentChatUserDomain];
    NSDate *now = [NSDate date];
    NSTimeInterval nowInterval = [now timeIntervalSince1970];
    NSDateComponents *nowCom = [self dateComponentFrom:now];
    
    NSMutableArray *tmpArray = [NSMutableArray array];
    OLYMMessageObject *lastMsg;
    for(NSInteger i = 0;i < allFileMessages.count;i++)
    {
        OLYMMessageObject *message = [allFileMessages objectAtIndex:i];
        NSDate *d = message.timeSend;
        NSTimeInterval fileInterval = [d timeIntervalSince1970];
        NSTimeInterval interval = nowInterval - fileInterval;
        if (interval < 7 * 24 * 60 * 60)
        {
            //7天内
            [tmpArray addObject:message];
     
        }else
        {
            NSDateComponents *com = [self dateComponentFrom:d];
            if (lastMsg)
            {
                NSDateComponents *lastCom = [self dateComponentFrom:lastMsg.timeSend];
                if ([lastCom year] == [com year] && [lastCom month] == [com month])
                {
                    //同一个月的
                    [tmpArray addObject:message];
                   
                }else
                {
                    //不是同一个月的
                    lastMsg = message;
                    //加入到数组
                    [self.imageVideos addObject:@{@"time":[NSString stringWithFormat:@"%ld-%ld",[lastCom year],[lastCom month]],@"files":[tmpArray mutableCopy]}];
                    [tmpArray removeAllObjects];
                    
                    [tmpArray addObject:message];
                 
                }
            }else
            {
                lastMsg = message;
                //加入到数组
                if (tmpArray.count > 0)
                {
                    [self.imageVideos addObject:@{@"time":@"7天内",@"files":[tmpArray mutableCopy]}];
                }
                [tmpArray removeAllObjects];
                
                [tmpArray addObject:message];
             
            }
        }
    }
    if (tmpArray && tmpArray.count > 0)
    {
        OLYMMessageObject *lastMsg = [tmpArray lastObject];
        NSTimeInterval fileInterval = [lastMsg.timeSend timeIntervalSince1970];
        NSTimeInterval interval = nowInterval - fileInterval;
        if (interval < 7 * 24 * 60 * 60)
        {
            [self.imageVideos addObject:@{@"time":@"7天内",@"files":tmpArray}];
        }else
        {
            NSDateComponents *com = [self dateComponentFrom:lastMsg.timeSend];
            [self.imageVideos addObject:@{@"time":[NSString stringWithFormat:@"%ld-%ld",[com year],[com month]],@"files":tmpArray}];
        }
    }
}

- (void)getDocumentFiles
{
    NSArray *allFileMessages = [OLYMMessageObject fetchFilesByUser:self.currentChatUserId withDomain:self.currentChatUserDomain];
    NSDate *now = [NSDate date];
    NSTimeInterval nowInterval = [now timeIntervalSince1970];
    NSDateComponents *nowCom = [self dateComponentFrom:now];
    
    NSMutableArray *tmpArray = [NSMutableArray array];
    OLYMMessageObject *lastMsg;
    for(NSInteger i = 0;i < allFileMessages.count;i++)
    {
        OLYMMessageObject *message = [allFileMessages objectAtIndex:i];
        NSDate *d = message.timeSend;
        NSTimeInterval fileInterval = [d timeIntervalSince1970];
        NSTimeInterval interval = nowInterval - fileInterval;
        if (interval < 7 * 24 * 60 * 60)
        {
            //7天内
            [tmpArray addObject:message];
        }else
        {
            NSDateComponents *com = [self dateComponentFrom:d];
            if (lastMsg)
            {
                NSDateComponents *lastCom = [self dateComponentFrom:lastMsg.timeSend];
                if ([lastCom year] == [com year] && [lastCom month] == [com month])
                {
                    //同一个月的
                    [tmpArray addObject:message];
                }else
                {
                    //不是同一个月的
                    lastMsg = message;
                    //加入到数组
                    [self.otherFiles addObject:@{@"time":[NSString stringWithFormat:@"%ld-%ld",[lastCom year],[lastCom month]],@"files":[tmpArray mutableCopy]}];
                    [tmpArray removeAllObjects];
                    
                    [tmpArray addObject:message];
                }
            }else
            {
                lastMsg = message;
                //加入到数组
                if (tmpArray.count > 0)
                {
                    [self.otherFiles addObject:@{@"time":@"7天内",@"files":[tmpArray mutableCopy]}];
                }
                [tmpArray removeAllObjects];
                
                [tmpArray addObject:message];
            }
        }
    }
    if (tmpArray && tmpArray.count > 0)
    {
        OLYMMessageObject *lastMsg = [tmpArray lastObject];
        NSTimeInterval fileInterval = [lastMsg.timeSend timeIntervalSince1970];
        NSTimeInterval interval = nowInterval - fileInterval;
        if (interval < 7 * 24 * 60 * 60)
        {
            [self.otherFiles addObject:@{@"time":@"7天内",@"files":tmpArray}];
        }else
        {
            NSDateComponents *com = [self dateComponentFrom:lastMsg.timeSend];
            [self.otherFiles addObject:@{@"time":[NSString stringWithFormat:@"%ld-%ld",[com year],[com month]],@"files":tmpArray}];
        }
    }

}

- (NSString *)absoluteFilePathfrom:(OLYMMessageObject *)message
{
    return [[olym_FileCenter documentPrefix]stringByAppendingPathComponent:message.filePath];
}

- (void)deleteSelectedImageAndVideos:(NSArray <NSIndexPath *> *)selectedIndexPaths
{
    [self deleteSelectedMessages:selectedIndexPaths isImagesAndVideos:YES];
}

- (void)deleteSelectedDocuments:(NSArray <NSIndexPath *> *)selectedIndexPaths
{
    [self deleteSelectedMessages:selectedIndexPaths isImagesAndVideos:NO];
}

- (void)deleteSelectedMessages:(NSArray<NSIndexPath *> *)selectedIndexPaths isImagesAndVideos:(BOOL)isImagesAndVideos
{
    NSMutableArray *totalFiles;
    if (isImagesAndVideos)
    {
        totalFiles = [self.imageVideos mutableCopy];
    }else
    {
        totalFiles = [self.otherFiles mutableCopy];
    }
    NSMutableArray *messages = [NSMutableArray array];
    for (NSIndexPath *indexPath in selectedIndexPaths)
    {
        NSDictionary *dict = [totalFiles objectAtIndex:indexPath.section];
        NSArray *fileMessages = [dict objectForKey:@"files"];
        OLYMMessageObject *message = [fileMessages objectAtIndex:indexPath.row];
        [messages addObject:message];

        [self deleteMessageByMessage:message];
        
        //修改数据源
        NSMutableArray *tempArray = [NSMutableArray array];
        [tempArray addObjectsFromArray:fileMessages];
        [tempArray removeObject:message];
        NSMutableDictionary *tmpDict = [NSMutableDictionary dictionary];
        [tmpDict addEntriesFromDictionary:dict];
        [tmpDict setObject:tempArray forKey:@"files"];
        [totalFiles replaceObjectAtIndex:indexPath.section withObject:tmpDict];
    }
    
    NSMutableIndexSet *set = [[NSMutableIndexSet alloc]init];
    for (NSIndexPath *indexPath in selectedIndexPaths)
    {
        NSDictionary *dict = [totalFiles objectAtIndex:indexPath.section];
        NSArray *fileMessages = [dict objectForKey:@"files"];
        if (fileMessages.count > 0)
        {
            if (isImagesAndVideos)
            {
                [self.imageVideos replaceObjectAtIndex:indexPath.section withObject:dict];
            }else
            {
                [self.otherFiles replaceObjectAtIndex:indexPath.section withObject:dict];
            }
        }else
        {
            [set addIndex:indexPath.section];
        }
    }
    if (set.count > 0)
    {
        if (isImagesAndVideos)
        {
            [self.imageVideos removeObjectsAtIndexes:set];
        }else
        {
            [self.otherFiles removeObjectsAtIndexes:set];
        }
    }
    
    //发送通知，更新聊天界面
    [olym_Nofity postNotificationName:kDeleteFileMessageNotifaction object:messages];
}

- (NSArray *)messagesForSelectedRows:(NSArray <NSIndexPath *> *)selectedIndexPaths dataSource:(NSArray *)dataSource
{
    NSMutableArray *messages = [NSMutableArray array];
    for (NSIndexPath *indexPath in selectedIndexPaths)
    {
        NSDictionary *dict = [dataSource objectAtIndex:indexPath.section];
        NSArray *fileMessages = [dict objectForKey:@"files"];
        OLYMMessageObject *message = [fileMessages objectAtIndex:indexPath.row];
        [messages addObject:message];
    }
    return messages;
}

- (BOOL)deleteMessageByMessage:(OLYMMessageObject *)msgObj
{
    //先删除文件
    if (msgObj.type == kWCMessageTypeVideo || msgObj.type == kWCMessageTypeImage || msgObj.type == kWCMessageTypeFile) {
        NSString *uploadFilePath = [[olym_FileCenter documentPrefix]stringByAppendingPathComponent:msgObj.filePath];
        [FileCenter deleteFile:uploadFilePath];
        if(msgObj.type == kWCMessageTypeVideo)
        {
            //删除缩略图
            NSString *imagePath  = [NSString stringWithFormat:@"%@.jpg",[uploadFilePath stringByDeletingPathExtension]];
            [FileCenter deleteFile:imagePath];
        }
    }
    return [OLYMMessageObject deleteMessageByMessageId:msgObj.messageId inTableByUserId:self.currentChatUser.userId withDomain:self.currentChatUser.domain];
}

//判断文件是哪一天的
- (NSString *)compareDate:(NSDate *)date{
    
    NSTimeInterval secondsPerDay = 24 * 60 * 60;
    NSDate *today = [[NSDate alloc] init];
    NSDate *tomorrow, *yesterday;
    
    tomorrow = [today dateByAddingTimeInterval: secondsPerDay];
    yesterday = [today dateByAddingTimeInterval: -secondsPerDay];
    
    // 10 first characters of description is the calendar date:
    NSString * todayString = [[today description] substringToIndex:10];
    NSString * yesterdayString = [[yesterday description] substringToIndex:10];
    NSString * tomorrowString = [[tomorrow description] substringToIndex:10];
    
    NSString * dateString = [[date description] substringToIndex:10];
    
    if ([dateString isEqualToString:todayString])
    {
        return _T(@"今天");
    } else if ([dateString isEqualToString:yesterdayString])
    {
        return _T(@"昨天");
    }else if ([dateString isEqualToString:tomorrowString])
    {
        return _T(@"明天");
    }
    else
    {
        return _T(@"更早");
    }
}

- (NSDateComponents *)dateComponentFrom:(NSDate *)date
{
    NSCalendar * calendar=[[NSCalendar alloc]initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSInteger unitFlags = NSCalendarUnitMonth | NSCalendarUnitDay|NSCalendarUnitYear;
    NSDateComponents * component = [calendar components:unitFlags fromDate:date];
    return component;
}


- (NSArray *)images
{
    if(!_images)
    {
#if MJTDEV
        if (self.imageVideos.count > 0)
        {
            NSMutableArray *tempImages = [NSMutableArray array];
            for (NSDictionary *dict in self.imageVideos)
            {
                NSArray *files = [dict objectForKey:@"files"];
                for (OLYMMessageObject *message in files)
                {
                    if (message.type == kWCMessageTypeImage)
                    {
                        GJCUImageBrowserModel *model = [[GJCUImageBrowserModel alloc]init];
                        model.filePath = [[olym_FileCenter documentPrefix]stringByAppendingString:message.filePath];
                        model.isAESEncrypt = message.isAESEncrypt;
                        [tempImages addObject:model];
                    }
                }
            }
            _images = tempImages;
        }
#else
        if (self.dataArray.count > 0)
        {
            NSMutableArray *tempImages = [NSMutableArray array];
            for(NSArray *dayfiles in self.dataArray)
            {
                for(OLYMMessageObject *message in dayfiles)
                {
                    if (message.type == kWCMessageTypeImage)
                    {
                        GJCUImageBrowserModel *model = [[GJCUImageBrowserModel alloc]init];
                        model.filePath = [[olym_FileCenter documentPrefix]stringByAppendingString:message.filePath];
                        model.isAESEncrypt = message.isAESEncrypt;
                        [tempImages addObject:model];
                    }
                }
            }
            _images = tempImages;
        }
#endif
    }
    return _images;
}

- (NSMutableArray *)imageVideos
{
    if (!_imageVideos) {
        _imageVideos = [NSMutableArray array];
    }
    return _imageVideos;
}

- (NSMutableArray *)otherFiles
{
    if (!_otherFiles) {
        _otherFiles = [NSMutableArray array];
    }
    return _otherFiles;

}

@end
