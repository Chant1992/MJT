//
//  LoginManager.m
//  MJTLoginInModule
//
//  Created by Chant on 2018/5/21.
//

#import "LoginManager.h"
#import "LoginRequest.h"

static LoginManager *sharedManager;

@interface LoginManager()

@property(nonatomic,assign) ActionType actionType;

@end

@implementation LoginManager

+ (LoginManager *)sharedManager
{
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedManager = [[LoginManager alloc]init];
        sharedManager.loginViewModel = [[LoginViewModel alloc]init];
    });
    
    return sharedManager;
}

#pragma mark - 登录
-(void)loginWithAccount:(NSString *)account
               password:(NSString *)password
                Success:(void (^)(NSDictionary *dic))success
                Failure:(void (^)(NSString *error))failure{
    
    self.loginViewModel.actionType = Login;
    
    self.loginViewModel.loginAccount = account;
    self.loginViewModel.loginPassword = password;
    
    [self setSuccees:success Failure:failure];
}

#pragma mark - 忘记密码
-(void)forgetWithAccount:(NSString *)account
                 Success:(void (^)(NSDictionary *dic))success
                 Failure:(void (^)(NSString *error))failure{
    
    self.loginViewModel.actionType = Forget;
    self.loginViewModel.loginAccount = account;

    [self setSuccees:success Failure:failure];
}

#pragma mark - 注册
-(void)registerWithAccount:(NSString *)account
                  password:(NSString *)password
                   Success:(void (^)(NSDictionary *dic))success
                   Failure:(void (^)(NSString *error))failure{
    
    self.loginViewModel.actionType = Register;
    self.loginViewModel.loginAccount = account;
    [self setSuccees:success Failure:failure];
    
}

-(void)logoutSuccess:(void (^)(NSDictionary *dic))success
             Failure:(void (^)(NSString *error))failure{
    
    [[LoginRequest sharedManager] logoutServer:success Failure:failure];
};

#pragma mark - Private

/**
 设置成功与失败的block，并执行登录/注册/忘记密码逻辑

 @param success 成功block
 @param failure 失败block
 */
-(void)setSuccees:(void (^)(NSDictionary *dic))success
          Failure:(void (^)(NSString *error))failure{
    
    self.loginViewModel.successBlock = success;
    self.loginViewModel.failedBlock = failure;
    [self.loginViewModel.loginCommand execute:nil];
}



@end
