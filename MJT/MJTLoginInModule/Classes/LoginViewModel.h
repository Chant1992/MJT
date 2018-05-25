//
//  LoginViewModel.h
//  MJT_APP
//
//  Created by olymtech on 2017/8/22.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "OLYMViewModel.h"
#import <ReactiveObjC/ReactiveObjC.h>

//默认服务器地址和端口
#define Config_DEFUALT_DOMAIN @"olym"
#define Config_DEFUALT_DOMAIN_VERSION @"1"

typedef enum : NSUInteger {
    LoginResult_Success = 1, //正常成功流程
    LoginResult_Faile, //网络请求异常
    LoginResult_Domain, //需要手动设置域信息
    LoginResult_WithError, //带错误信息
   
} LoginResultStatus;

typedef enum : NSUInteger {
    Login = 1,  //登录
    Register,   //注册
    Forget      //忘记密码
    
} ActionType;

typedef void(^SuccessBlock)(NSDictionary *resultDic);
typedef void(^FailedBlock)(NSString *error);

@interface LoginViewModel : OLYMViewModel

@property (nonatomic, strong) NSString *loginAccount;

@property (nonatomic, strong) NSString *loginPassword;

@property (nonatomic, strong) NSString *loginDomain;

@property (nonatomic, strong) NSString *loginValidCode;

@property(nonatomic,assign) ActionType actionType;

@property (nonatomic, strong) RACCommand *loginCommand;

@property (nonatomic, strong) RACCommand *getDomainInfoCommand;

@property (nonatomic, strong) RACCommand *checktUserCommand;

@property (nonatomic, strong) RACCommand *getCodeCommand;

@property (nonatomic, strong) RACCommand *getTokenCommand;

@property (nonatomic, strong) RACCommand *loginImCommand;

@property (nonatomic, strong) RACCommand *bleKeyCommand;

@property (nonatomic, strong) RACCommand *getServerConfigCommand;

@property (nonatomic, strong) RACSubject *loginBtnSubject;

@property (nonatomic, strong) RACSubject *needDomainSubject;

@property (nonatomic, strong) RACSubject *loginEndSubject;

@property (nonatomic, strong) RACSubject *loginFaileSubject;

@property (nonatomic, strong) RACSubject *getCodeBtnSubject;

@property (nonatomic, strong) RACSubject *getTokenBtnSubject;

@property (nonatomic, strong) RACSubject *loginImSubject;

@property (nonatomic, strong) RACSubject *registerBtnSubject;

@property (nonatomic, strong) RACSubject *forgetPassBtnSubject;

@property (nonatomic, strong) RACSubject *bleKeySubject;

@property (nonatomic, strong) RACSubject *gotoRegisterSubject;

@property (nonatomic, strong) RACSubject *getServerConfigSubject;

-(void)setDomain:(NSString *)domain;


@property(nonatomic,copy) SuccessBlock successBlock;
@property(nonatomic,copy) FailedBlock failedBlock;
@end
