//
//  ChatViewModel.h
//  MJT_APP
//
//  Created by olymtech on 2017/8/29.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "OLYMListViewModel.h"

@class OLYMUserObject;
@class OLYMMessageObject;

@interface ChatViewModel : OLYMListViewModel

@property(strong,nonatomic) NSString *currentChatUserId;

@property(strong,nonatomic) NSString *currentChatUserDomain;

@property(strong,nonatomic) NSString *currentChatRoomId;

@property(assign,nonatomic) BOOL isReadburn;

@property (nonatomic, strong) NSMutableArray *reminderArray;

@property (nonatomic) BOOL isSearchCondition;

@property (nonatomic) NSIndexPath *searchMessgeIndexPath;

@property (nonatomic, strong) RACSubject *transpondClickSubject;

@property (nonatomic, strong) RACSubject *headerLongPressSubject;

@property (nonatomic, strong) RACCommand *refreshDataCommand;

@property (nonatomic, strong) RACCommand *refreshFooterDataCommand;

@property (nonatomic, strong) RACCommand *getUserInfoCommand;

@property (nonatomic, strong) RACSubject *imageShowSubject;

@property (nonatomic, strong) RACSubject *videoShowSubject;

@property (nonatomic, strong) RACSubject *fileShowSubject;

@property (nonatomic, strong) RACSubject *textBurnShowSubject;

@property (nonatomic, strong) RACSubject *imageBurnShowSubject;

@property (nonatomic, strong) RACSubject *videoBurnShowSubject;

@property (nonatomic, strong) RACSubject *cardShowSubject;

@property (nonatomic, strong) RACSubject *getUserInfoSubject;

@property (nonatomic, strong) RACSubject *playAudioBeginSubject;

@property (nonatomic, strong) RACSubject *playAudioFinishedSubject;

@property (nonatomic, strong) RACSubject *linkClickedSubject;

@property (nonatomic, strong) RACSubject *referenceMsgSubject;

@property (nonatomic, strong) RACSubject *mutiSelectMsgSubject;

@property (nonatomic, strong) RACSubject *tablecellEditSubject;

@property (nonatomic, strong) RACSubject *fileDeleteSubject;

@property (nonatomic, strong) RACSubject *msgDeleteSubject;

- (instancetype)initWithUser:(OLYMUserObject *)currentChatUser;

- (instancetype)initWithUser:(OLYMUserObject *)currentChatUser searchMessage:(OLYMMessageObject *)searchMsg;

/**
 add a new message to list

 @param message new message
 */
- (void)addNewMessage:(OLYMMessageObject *)message;

/**
 send text message

 @param text text
 */
- (void)sendTextMessage:(NSString *)text;


/**
 send picture message

 @param path filepath of pic
 @param imageWidth width of pic
 @param imageHeight heiht of pic
 @param thumbnailBase64String thumbnail base64 string of pic
 */
-(void)sendImageMessage:(NSString *)path imageWidth:(float)width imageHeight:(float)height thumbnailString:(NSString *)thumbnailBase64String;


/**
 send audio message

 @param base64Audio  audio convert to base64String
 @param duration duration of audio
 */
- (void)sendAudioMessage:(NSString *)base64Audio  duration:(CGFloat)duration;


/**
 send video message

 @param filePath filePath of video
 @param fileSize fileSize of video
 @param thumbnailBase64String thumbnail base64 string of video
 */
- (void)sendVideoMessage:(NSString *)filePath fileSize:(unsigned long long)fileSize thumbnailString:(NSString *)thumbnailBase64String;



/**
 send file message

 @param filePath filePath
 @param fileSize fileSize
 @param fileName fileName
 */
- (void)sendFileMessage:(NSString *)filePath fileSize:(unsigned long long)fileSize fileName:(NSString *)fileName;


/**
 send card message

 @param userNickName nickname
 @param userDomain user domain
 @param telephone telephone
 */
- (void)sendCardMessage:(NSString *)userNickName userDomain:(NSString *)userDomain telephone:(NSString *)telephone ;


/**
 send message read receipt

 @param msgObj read message object
 */
- (void)sendReadedMessage:(OLYMMessageObject *)msgObj;

/**
 send message recall message
 
 @param msgObj recall message object
 */
- (void)sendRecallMesage:(OLYMMessageObject *)msgObj;

/**
 delete message

 @param msgObj message
 @return delete result
 */
- (BOOL)deleteMessageByMessage:(OLYMMessageObject *)msgObj;


/**
 get refrence message content from message
 
 @param msgObj message
 @return content
 */
- (NSString *)getReferenceContent:(OLYMMessageObject *)msgObj;

/**
 resend message when failed

 @param msgObj message
 @param uploadBlock block
 */
- (void)reSendMessage:(OLYMMessageObject *)msgObj uploadBlock:(void (^)())uploadBlock;


/**
 send message when user take screen
 */
- (void)sendTakeScreenshotMessage;

/**
 delete message of selected row
 */

- (void)deleteSelectedMessages:(NSArray <NSIndexPath *> *)selectedIndexPaths;

/**
 message of selected indexPaths
 */

- (NSArray *)messagesForSelectedRows:(NSArray <NSIndexPath *> *)selectedIndexPaths;

/**
 get userInfo , listen getUserInfoSubject to get result

 @param userId userid
 @param domain user domain
 @param roomId room id
 */
- (void)getUserInfoByUserId:(NSString *)userId domain:(NSString *)domain roomId:(NSString *)roomId;


- (void)playAudioByTurn:(NSInteger)startIndex;

- (void)stopAudioIfPlayInQueue:(OLYMMessageObject * )message;

/**
 play audio with base64String

 @param base64AudioString base64AudioString
 @param callback finish play
 */
- (void)playAudio:(NSString *)base64AudioString finished:(void (^)(void))callback;

/**
 get all image message from all messages

 @return image filepath array
 */
- (NSArray *)getAllMessageImages;

/**
 stop audio
 */
- (void)stopAudioPlay;


/**
 detect if audio is playing

 @return audio is playing
 */
- (BOOL)isAudioPlaying;

- (void)notifyBurnVideoFinished:(OLYMMessageObject *)msgObj;

/**
 解密消息
 */
- (NSString *)decryptMessage:(OLYMMessageObject *)messageObject;

@end
