//
//  LoginRequest.h
//  Pods
//
//  Created by Chant on 2018/5/15.
//

#import <Foundation/Foundation.h>
#import <MJTUserInfoModule/ConfigsManager.h>
#import <MJTNetwork/OLYMBaseRequest.h>

//密九通服务器地址
#define Request_Soap_Url [NSString stringWithFormat:@"https://%@:%@/api/sipact.php",[ConfigsManager sharedConfigsManager].serverUrl,[ConfigsManager sharedConfigsManager].serverPort]
//业务平台服务器地址
#define Request_IM_Url [NSString stringWithFormat:@"https://%@:%@",[ConfigsManager sharedConfigsManager].serverUrl,[ConfigsManager sharedConfigsManager].IMPort]

//密九通测试服务器地址 V2版
#define V2Request_Soap_Url [NSString stringWithFormat:@"https://%@:%@/api/sipactV2.php",[ConfigsManager sharedConfigsManager].serverUrl,[ConfigsManager sharedConfigsManager].serverPort]
//参数交换中心查询地址
#define Request_Info_ByDomain_Url [NSString stringWithFormat:@"%@",@"https://x.mjt.net.cn"]

//用户中心查询地址
#define UserCenter_Server_Url [NSString stringWithFormat:@"https://mjt.net.cn:443/abcd"]

@interface LoginRequest : OLYMBaseRequest

+ (LoginRequest *)sharedManager;

-(void)checktMjtUserExit:(NSString *)phoneNumber Success:(void (^)(NSDictionary *dic))success Failure:(void (^)(NSString *error))failure;

-(void)getDomainInfo:(NSString *)domain withVersion:(NSString *)version  Success:(void (^)(NSDictionary *dic))success Failure:(void (^)(NSString *error))failure;

- (void)checkUserFromFusionServer:(NSString *)phoneNumber Success:(void (^)(NSDictionary *dic))success Failure:(void (^)(NSString *error))failure;

#pragma mark - 下载登录的token
-(void)getLoginToken:(NSString *)userId Success:(void (^)(NSDictionary *dic))success failure:(void (^)(NSString *error))failure;

-(void)loginToImServer:(void (^)(NSDictionary *dic))success failure:(void (^)(NSString *error))failure;
- (void)getServerConfigSuccess:(void (^)(NSDictionary *dic))success Failure:(void (^)(NSString *error))failure;
-(void)logoutServer:(void (^)(NSDictionary *dic))success Failure:(void (^)(NSString *error))failure;


-(void)post:(NSString *)URLString parameters:(NSDictionary *)parameters success:(void (^)(NSDictionary *dic))success failure:(void (^)(NSString *error))failure;
-(void)imPost:(NSString *)subRequestUrl parameters:(NSDictionary *)parameters success:(void (^)(id reponse))success failure:(void (^)(NSString *error))failure;
@end
