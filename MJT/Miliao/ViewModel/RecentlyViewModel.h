//
//  RecentlyViewModel.h
//  MJT_APP
//
//  Created by Donny on 2017/9/11.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "OLYMListViewModel.h"

@class OLYMUserObject;
@class OLYMMessageObject;
@interface RecentlyViewModel : OLYMListViewModel

@property (nonatomic,strong,nullable) NSArray *previousArray;

- (void)forwardMessages:(NSArray *)messages toUser:(OLYMUserObject *)userObj;

- (void)forwardMessage:(OLYMMessageObject *)message toUser:(OLYMUserObject *)userObj;


/**
 transpond text messge to user

 @param content text message
 @param filePath @ userid array
 @param isAppoint if appoint
 @param userObj to user
 */
- (void)transpondTextMessage:(NSString *)content filePath:(NSString *)filePath isAppoint:(BOOL)isAppoint toUser:(OLYMUserObject *)userObj;




/**
 transpond image messge to user

 @param imagePath image pat
 @param width image width
 @param height image height
 @param thumbnail thumbnail
 @param userObj to user
 */
- (void)transpondImage:(NSString *)imagePath imageWidth:(float)width imageHeight:(float)height thumbnail:(NSString *)thumbnail toUser:(OLYMUserObject *)userObj;


/**
 transpond video messge to user

 @param filePath video path
 @param fileSize video filesize
 @param thumbnail thumbnail
 @param userObj to user
 */
- (void)transpondVideoMessage:(NSString *)filePath fileSize:(unsigned long long)fileSize  thumbnail:(NSString *)thumbnail toUser:(OLYMUserObject *)userObj;



/**
 transpond file messge to user
 
 @param filePath file path
 @param fileSize file filesize
 @param userObj to user
 */

- (void)transpondFileMessage:(NSString *)filePath fileSize:(unsigned long long)fileSize fileName:(NSString *)fileName toUser:(OLYMUserObject *)userObj;

/**
 * filter with keyword
 */
- (NSArray *)queryWithKeyword:(NSString *)keyword;

@end
