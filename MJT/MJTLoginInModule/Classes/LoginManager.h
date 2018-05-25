//
//  LoginManager.h
//  MJTLoginInModule
//
//  Created by Chant on 2018/5/21.
//

#import <Foundation/Foundation.h>
#import "LoginViewModel.h"

@interface LoginManager : NSObject

/* 登录视图模型 */
@property(nonatomic,strong) LoginViewModel *loginViewModel;

+ (LoginManager *)sharedManager;

/**
 登录

 @param account 电话号码
 @param password 密码
 @param success 成功的回调
 @param failure 失败的回调
 */
-(void)loginWithAccount:(NSString *)account
               password:(NSString *)password
                Success:(void (^)(NSDictionary *dic))success
                Failure:(void (^)(NSString *error))failure;

/**
 忘记密码

 @param account 电话号码
 @param success 成功的回调
 @param failure 失败的回调
 */
-(void)forgetWithAccount:(NSString *)account
                Success:(void (^)(NSDictionary *dic))success
                Failure:(void (^)(NSString *error))failure;

/**
 注册

 @param account 电话号码
 @param password 密码
 @param success 成功的回调
 @param failure 失败的回调
 */
-(void)registerWithAccount:(NSString *)account
               password:(NSString *)password
                Success:(void (^)(NSDictionary *dic))success
                Failure:(void (^)(NSString *error))failure;

-(void)logoutSuccess:(void (^)(NSDictionary *dic))success
             Failure:(void (^)(NSString *error))failure;
@end
