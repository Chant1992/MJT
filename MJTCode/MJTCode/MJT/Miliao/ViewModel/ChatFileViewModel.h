//
//  ChatFileViewModel.h
//  MJT_APP
//
//  Created by Donny on 2017/9/12.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "OLYMListViewModel.h"
@class OLYMUserObject;
@class OLYMMessageObject;

@interface ChatFileViewModel : OLYMListViewModel

@property (nonatomic, readonly) NSArray *images;

@property (nonatomic, strong) NSMutableArray *imageVideos;

@property (nonatomic, strong) NSMutableArray *otherFiles;

@property(strong,nonatomic) NSString *currentChatUserId;

@property(strong,nonatomic) NSString *currentChatUserDomain;

- (instancetype)initWithUser:(OLYMUserObject *)currentChatUser;

- (void)getImageAndVideoFiles;

- (void)getDocumentFiles;

- (NSString *)compareDate:(NSDate *)date;

- (NSString *)absoluteFilePathfrom:(OLYMMessageObject *)message;


- (void)deleteSelectedImageAndVideos:(NSArray <NSIndexPath *> *)selectedIndexPaths;

- (void)deleteSelectedDocuments:(NSArray <NSIndexPath *> *)selectedIndexPaths;

- (NSArray *)messagesForSelectedRows:(NSArray <NSIndexPath *> *)selectedIndexPaths dataSource:(NSArray *)dataSource;


@end
