//
//  LoginRequest.m
//  Pods
//
//  Created by Chant on 2018/5/15.
//

#import "LoginRequest.h"
#import <MJTCommon/MJTCommon.h>
#import <SecurityEngine/SecurityEngineHelper.h>
#import <MJTUserInfoModule/UserCenter.h>

//业务平台接口信息
#define act_Register @"user/register" //注册
#define act_UserLogin @"user/login" //登录
#define act_UserLogout @"user/logout" //登出

@implementation LoginRequest

+ (LoginRequest *)sharedManager
{
    static dispatch_once_t      onceToken;
    static LoginRequest *instance;
    
    dispatch_once(&onceToken, ^{
        instance = [[LoginRequest alloc] init];
    });
    return instance;
}

-(void)loginToImServer:(void (^)(NSDictionary *dic))success failure:(void (^)(NSString *error))failure{
    
    NSMutableDictionary *paramsDic = [[NSMutableDictionary alloc]init];
    [paramsDic setValue:GJCFStringToMD5([UserCenter sharedUserCenter].userAccount) forKey:@"telephone"];
    [paramsDic setValue:[UserCenter sharedUserCenter].accessToken forKey:@"access_token"];
    
    NSString *macAddress = [[UIDevice currentDevice] uuid];
    NSString *osVersion = [NSString stringWithFormat:@"IOS %.02f",[[UIDevice currentDevice].systemVersion floatValue]];
    [paramsDic setValue:osVersion forKey:@"osVersion"];
    [paramsDic setValue:macAddress forKey:@"serial"];
    [paramsDic setValue:@(-1) forKey:@"seconds"];
    
    [self imPost:act_UserLogin parameters:paramsDic success:^(NSDictionary *dic) {
        success(dic);
    } failure:^(NSString *error) {
        failure(error);
    }];
}

#pragma mark - 下载登录的token
-(void)getLoginToken:(NSString *)userId Success:(void (^)(NSDictionary *dic))success failure:(void (^)(NSString *error))failure{
    
    NSString *tag = @"retr_sip_auth_key";
    NSString *alg = @"SM9_SM3";
    NSDate *currentDate = [[NSDate alloc] init];
    NSString *time = [self getTimeString];
    NSString *sign_value = [NSString stringWithFormat:@"%@%@%@",tag,userId,time];
    
    sign_value = [[SecurityEngineHelper getInstance] cryptSignDataEx:sign_value withUserId:userId];
    
    NSMutableDictionary *dic = [[NSMutableDictionary alloc]init];
    [dic setValue:tag forKey:@"op"];
    [dic setValue:userId forKey:@"id"];
    [dic setValue:time forKey:@"ts"];
    [dic setValue:alg forKey:@"alg"];
    [dic setValue:sign_value forKey:@"sig"];
    //获取服务器配置之前都用V1接口
    [self post:Request_Soap_Url parameters:dic success:success failure:failure];
}

#pragma mark - 查询密九通服务器信息
-(void)checktMjtUserExit:(NSString *)phoneNumber Success:(void (^)(NSDictionary *dic))success Failure:(void (^)(NSString *error))failure{
    
    NSString *op = @"check_user";
    NSMutableDictionary *dic = [[NSMutableDictionary alloc]init];
    [dic setValue:op forKey:@"op"];
    [dic setValue:phoneNumber forKey:@"user"];
    
    //   sig
    //    ts
    //FIXME :加上验签
    //获取服务器配置之前都用V1接口
    NSString *time = [self getTimeString];
    NSString *secret_key = @"RLQ66CH5HJA7X2Y87H59ZMSAFASD9TGB";
    NSString *strUrl = [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@%@",@"POST",Request_Soap_Url,@"op=",op,@"ts=",time,@"user=",phoneNumber,secret_key];
    
    strUrl = [strUrl urlEncodedStringWithEncoding:NSUTF8StringEncoding];
    NSString *sign = [NSString stringWithFormat:@"%@",[strUrl sha1]];
    sign = [sign uppercaseString];
    [dic setValue:time forKey:@"ts"];
    [dic setValue:sign forKey:@"sig"];
    
    [self post:Request_Soap_Url parameters:dic success:success failure:failure];
}

#pragma mark - 设置域，获取相关信息
-(void)getDomainInfo:(NSString *)domain withVersion:(NSString *)version  Success:(void (^)(NSDictionary *dic))success Failure:(void (^)(NSString *error))failure{
    
    NSString *postDomain = [NSString stringWithFormat:@"%@.mjt.net",domain];
    NSMutableDictionary *dic = [[NSMutableDictionary alloc]init];
    [dic setValue:postDomain forKey:@"paramDomain"];
    [dic setValue:version forKey:@"paramVersion"];
    
    [self post:Request_Info_ByDomain_Url parameters:dic success:success failure:failure];
}

#pragma mark - 获取服务器配置
- (void)getServerConfigSuccess:(void (^)(NSDictionary *dic))success Failure:(void (^)(NSString *error))failure
{
    NSString *time = [self getTimeString];
    NSString *op = @"get_config";
    NSString *secret_key = @"RLQ66CH5HJA7X2Y87H59ZMSAFASD9TGB";
    
    //获取服务器配置用V1接口
    NSString *strUrl = [NSString stringWithFormat:@"%@%@%@%@%@%@%@",@"POST",Request_Soap_Url,@"op=",op,@"ts=",time,secret_key];
    
    strUrl = [strUrl urlEncodedStringWithEncoding:NSUTF8StringEncoding];
    NSString *sign = [NSString stringWithFormat:@"%@",[strUrl sha1]];
    sign = [sign uppercaseString];
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc]init];
    [params setValue:op forKey:@"op"];
    [params setValue:time forKey:@"ts"];
    [params setValue:sign forKey:@"sig"];
    
    NSData *dataFromDict = [NSJSONSerialization dataWithJSONObject:params
                                                           options:NSJSONWritingPrettyPrinted
                                                             error:nil];
    self.operationManager.requestSerializer = [AFHTTPRequestSerializer serializer];
    self.operationManager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", @"text/html", @"text/xml", @"text/plain", nil];
    
    NSMutableURLRequest *req = [[AFJSONRequestSerializer serializer] requestWithMethod:@"POST" URLString:Request_Soap_Url parameters:nil error:nil];
    [req setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [req setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [req setHTTPBody:dataFromDict];
    
    [[self.operationManager dataTaskWithRequest:req completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        if (!error) {
            if ([responseObject isKindOfClass:[NSData class]])
            {
                NSLog(@"[responseObject isKindOfClass:[NSData class],responseObject :%@",responseObject);
                NSString *responseStr = [[NSString alloc]initWithData:responseObject encoding:NSUTF8StringEncoding];
                
                NSDictionary *responseDic = [JsonUtils dictionaryWithJsonString:responseStr];
                success(responseDic);
            }else if([responseObject isKindOfClass:[NSString class]])
            {
                NSLog(@"[responseObject isKindOfClass:[NSString class],responseObject :%@",responseObject);
                NSDictionary *responseDic = [JsonUtils dictionaryWithJsonString:responseObject];
                success(responseDic);
            }else
            {
                NSLog(@"responseObject :%@",responseObject);
                success(responseObject);
            }
        } else {
            failure([error localizedDescription]);
        }
    }]resume];
}

#pragma mark - 查询fusion上，用户是否存在
- (void)checkUserFromFusionServer:(NSString *)phoneNumber Success:(void (^)(NSDictionary *dic))success Failure:(void (^)(NSString *error))failure{
    
    NSString *time = [self getTimeString];
    
    NSString *strUrl = [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@%@",@"POST",UserCenter_Server_Url,@"apikey=",@"AESECCS5CZRHHGNEJFDB",@"timestamp=",time,@"user=",phoneNumber,@"T6TQK3XBRB54E4QSXBHXCRZZ3YQMSF9D"];
    
    strUrl = [strUrl urlEncodedStringWithEncoding:NSUTF8StringEncoding];
    NSString *sign = [NSString stringWithFormat:@"%@",[strUrl sha1]];
    
    NSMutableDictionary *paramsDic = [[NSMutableDictionary alloc]init];
    [paramsDic setValue:@"AESECCS5CZRHHGNEJFDB" forKey:@"apikey"];
    [paramsDic setValue:time forKey:@"timestamp"];
    [paramsDic setValue:sign forKey:@"sign"];
    //user为nil时是获取所有域
    [paramsDic setValue:phoneNumber forKey:@"user"];
    
    [self post:UserCenter_Server_Url parameters:paramsDic success:success failure:failure];
}

-(void)post:(NSString *)URLString parameters:(NSDictionary *)parameters success:(void (^)(NSDictionary *dic))success failure:(void (^)(NSString *error))failure{
    
    if([URLString isEqualToString:Request_Info_ByDomain_Url]
       || [URLString isEqualToString:Request_Soap_Url]
       || [URLString isEqualToString:V2Request_Soap_Url]){
        //设置会AFJSONRequestSerializer方式
        self.operationManager.requestSerializer = [AFJSONRequestSerializer serializer];
        
        [self.operationManager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    }else{
        //由于密九通服务器参数获取方式跟用户中心不一致，所以要设置会AFHTTPRequestSerializer方式
        self.operationManager.requestSerializer = [AFHTTPRequestSerializer serializer];
    }
    
    [self POST:URLString parameters:parameters success:^(OLYMBaseRequest *request, NSString *response) {
        
        NSDictionary *dic = [JsonUtils dictionaryWithJsonString:response];
        
        success(dic);
        
    } failure:^(OLYMBaseRequest *request, NSError *error) {
        
        failure(error.localizedDescription);
    }];
}

-(void)imPost:(NSString *)subRequestUrl parameters:(NSDictionary *)parameters success:(void (^)(id reponse))success failure:(void (^)(NSString *error))failure{
    NSLog(@"Request_IM_Url :%@",Request_IM_Url);
    NSString *requestUrl = [NSString stringWithFormat:@"%@/%@",Request_IM_Url,subRequestUrl];

    if([subRequestUrl isEqualToString:Request_Info_ByDomain_Url]
       || [subRequestUrl isEqualToString:Request_Soap_Url]
       || [subRequestUrl isEqualToString:V2Request_Soap_Url]){
        //设置会AFJSONRequestSerializer方式
        self.operationManager.requestSerializer = [AFJSONRequestSerializer serializer];
        
        [self.operationManager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    }else{
        //由于密九通服务器参数获取方式跟用户中心不一致，所以要设置会AFHTTPRequestSerializer方式
        self.operationManager.requestSerializer = [AFHTTPRequestSerializer serializer];
    }
    
    [self POST:requestUrl parameters:parameters success:^(OLYMBaseRequest *request, NSString *response) {

        NSDictionary *dic = [JsonUtils dictionaryWithJsonString:response];

        int resultCode = [[dic objectForKey:@"resultCode"] intValue];

        if(resultCode == 1){

            id resultObject = [dic objectForKey:@"data"];

            success(resultObject);

            return;
        }

        if(![subRequestUrl isEqualToString:act_UserLogout]){
            if(resultCode==0 || resultCode>=1000000)
            {
                if(resultCode == 1030101){
                    //未登陆时
                    //退出登录操作
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"kXMPPLogoutNotifaction" object:nil];
                    return;
                }else if(resultCode == 1030102){
                    //token过期 重新下载token
                    [self requestForToken];
                }
            }
        }

        NSString *error = [dic objectForKey:@"resultMsg"];
        failure(error);

    } failure:^(OLYMBaseRequest *request, NSError *error) {

        failure(error.localizedDescription);
        NSLog(@"网络请求发生错误 %@",error);
    }];
}

-(void)requestForToken{
    //token过期 重新下载token
    [[LoginRequest sharedManager] getLoginToken:[UserCenter sharedUserCenter].userAccount Success:^(NSDictionary *dic) {
        
        int code = [[dic objectForKey:@"code"] intValue];
        
        if(code == 0){
            
            NSString *data = [dic objectForKeySafe:@"data"];
            data = [[SecurityEngineHelper getInstance] decryptSignDataEx:data withUserId:[UserCenter sharedUserCenter].userAccount];
            NSDictionary *dic = [JsonUtils dictionaryWithJsonString:data];
            NSString *im_token = [dic objectForKeySafe:@"token"];
            [[UserCenter sharedUserCenter] setAccessToken:im_token];
            
            //token刷新了  重新执行一次自动登录的过程
            [[NSNotificationCenter defaultCenter] postNotificationName:@"kRefreshAccessTokenNotification" object:nil];
        }else{
            //退出登录操作
            [[NSNotificationCenter defaultCenter] postNotificationName:@"kXMPPLogoutNotifaction" object:nil];
        }
    } failure:^(NSString *error) {
        //退出登录操作
        [[NSNotificationCenter defaultCenter] postNotificationName:@"kXMPPLogoutNotifaction" object:nil];
    }];
}

-(void)logoutServer:(void (^)(NSDictionary *dic))success
            Failure:(void (^)(NSString *error))failure{
    
    NSMutableDictionary *paramsDic = [[NSMutableDictionary alloc]init];
    [paramsDic setValue:GJCFStringToMD5([UserCenter sharedUserCenter].userAccount)  forKey:@"telephone"];
    [paramsDic setValue:[UserCenter sharedUserCenter].accessToken forKey:@"access_token"];
    NSString *macAddress = [[UIDevice currentDevice] uuid];
    NSString *osVersion = [NSString stringWithFormat:@"IOS %.02f",[[UIDevice currentDevice].systemVersion floatValue]];
    [paramsDic setValue:osVersion forKey:@"osVersion"];
    [paramsDic setValue:macAddress forKey:@"serial"];
    
    [self imPost:act_UserLogout parameters:paramsDic success:^(id reponse) {
        
        success(reponse);
    } failure:^(NSString *error) {
        
        failure(error);
    }];
}


-(NSString *)getTimeString{
    NSTimeInterval secsUtc1970 = [[NSDate date] timeIntervalSince1970];
    NSString *time = [NSString stringWithFormat:@"%0.0f",secsUtc1970];
    return [NSString stringWithFormat:@"%@",@(time.integerValue)];
}

@end
