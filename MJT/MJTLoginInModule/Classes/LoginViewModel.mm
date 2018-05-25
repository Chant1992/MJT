//
//  LoginViewModel.m
//  MJT_APP
//
//  Created by olymtech on 2017/8/22.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "LoginViewModel.h"
#import "NSDictionary+KeySafe.h"
#import "SecurityEngineHelper.h"
#import "RandomPasswordTool.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import "JsonUtils.h"
#import "ConfigsManager.h"
#import "UserCenter.h"
#import "ErrorMessage.h"
#import "LoginRequest.h"
//#import "JMTKeyHepler.h"
#define _T(o)   NSLocalizedString(o,nil)

#define FirstIpAddress @"202.181.150.5"
#define SecondIpAddress @"202.74.3.141"

@implementation LoginViewModel

-(void)olym_initialize{
    
    @weakify(self);
    
#ifdef XJT
    
    //如果是香江通，则不执行查询domain、ip、port操作,直接使用固定ip，port，domain登录
    NSString *port = @"443";
    self.loginDomain = @"xjt";
    NSString *ip = FirstIpAddress;
    NSString *ipStr = [NSString stringWithFormat:@"%@:%@",ip,port];

    //设置默认ip
    [[ConfigsManager sharedConfigsManager] setServerUrl:ip];
    [[SecurityEngineHelper getInstance] setIbcserver:ipStr];
    //设置默认端口
    [[ConfigsManager sharedConfigsManager] setServerPort:port];
    
#endif
    
    ////////////////////查询用户 1 /////////////////////////
    
    [self.loginCommand.executionSignals.switchToLatest subscribeNext:^(NSDictionary *dict) {
        
        if(!dict){
            [self.loginFaileSubject sendNext:_T(@"未知错误")];
            self.failedBlock(_T(@"未知错误"));
            return;
        }
        
        @strongify(self);
        
        int code = [[dict objectForKey:@"code"] intValue];
        
        if(code == 0) {
            NSLog(@"用户中心查询到此用户信息...");
            
            NSString *dataValue = [dict objectForKeySafe:@"data"];
            NSArray *dataArr = [JsonUtils jsonStringToArray:dataValue];
            NSMutableArray *domainArr = [[NSMutableArray alloc] init];
            for (int i = 0; i < dataArr.count; i++) {
                NSMutableDictionary *tempDict = [[NSMutableDictionary alloc] init];
                tempDict = dataArr[i];
                NSString *domain = [tempDict objectForKeySafe:@"domain"];
                // 获取前缀
                NSArray *fileSuffix = [domain componentsSeparatedByString:@"."];
                NSString *domainSuffix = [NSString stringWithFormat:@"%@", fileSuffix.firstObject];
                [domainArr addObject:domainSuffix];
            }
            
            if (domainArr.count == 0) {
                
                NSLog(@"此用户查询不到域,需要用户手动输入域...");
                [self.needDomainSubject sendNext:nil];
                
            }else{
                
                self.loginDomain = domainArr[domainArr.count - 1];
                
                [self.getDomainInfoCommand execute:nil];
                
                return;
            }
            
        }else if(code == 13){
            
#if JiaMiTong || XJT || XYT
            NSLog(@"用户中心不存在此用户...默认设置服务器");
            self.loginDomain = DEFUALT_SIP_COMPANY_DOMAIN;
            [self.getDomainInfoCommand execute:nil];
#else
            NSLog(@"用户中心不存在此用户...需要用户手动设置服务器");
            self.failedBlock(@"用户中心不存在此用户...需要用户手动设置服务器");
//            [self.needDomainSubject sendNext:nil];
#endif
            
        }else{
            NSLog(@"用户中心无法获取已注册的服务域信息...");
//            [self.loginFaileSubject sendNext:_T(@"无法获取已注册的服务域信息")];
            self.failedBlock(_T(@"无法获取已注册的服务域信息"));
        }
        
        [SVProgressHUD dismiss];
    }];
    
    [self.loginCommand.executing  subscribeNext:^(id x) {
        
        if ([x isEqualToNumber:@(YES)]) {
            
            [SVProgressHUD showWithStatus:_T(@"正在执行")];
        }
    }];
    
    
    ///////////////查询用户 2 ////////////////////
    
    [self.getDomainInfoCommand.executionSignals.switchToLatest subscribeNext:^(NSDictionary *responseDic) {
        
        @strongify(self);
       
        if(!responseDic){
            NSLog(@"域信息设置异常...");
            [self.loginFaileSubject sendNext:_T(@"域信息异常")];
            self.failedBlock(_T(@"域信息异常"));
        }else{
            NSString *ipStr = [responseDic objectForKey:@"respData"];
            if(ipStr != nil){
                NSArray *serverArray=[ipStr componentsSeparatedByString:@":"];
                NSString *ip = serverArray[0];
                NSString *port = serverArray[1];
                
                [[ConfigsManager sharedConfigsManager] setServerUrl:ip];
                [[ConfigsManager sharedConfigsManager] setServerPort:port];
                
#ifdef XYT

                [[ConfigsManager sharedConfigsManager] setIMPort:port];
#endif

                
                [[SecurityEngineHelper getInstance] setIbcserver:ipStr];
                
                switch (self.actionType) {
                    case Login:
                        
                        [self.checktUserCommand execute:nil];
                        
                        break;
                    case Register:
                        
                        [self.checktUserCommand execute:nil];
                        [SVProgressHUD dismiss];
                        break;
                    case Forget:
                        
                        [self forgetPasswordGetCode];
//                        [self.loginEndSubject sendNext:nil];
                        [SVProgressHUD dismiss];
                        break;
                }
                return;
            }else{
                NSLog(@"找不到这个企业域名 %@",self.loginDomain);
                [self.loginFaileSubject sendNext:_T(@"企业域名不存在")];
                self.failedBlock(_T(@"企业域名不存在"));
            }
        }
        [SVProgressHUD dismiss];
        
    }];
    
    ////////////////查询用户 3 ////////////////////
    
    [self.checktUserCommand.executing  subscribeNext:^(id x) {
        
        if ([x isEqualToNumber:@(YES)]) {
            
            [SVProgressHUD showWithStatus:_T(@"正在执行")];
        }
    }];
    
    [self.checktUserCommand.executionSignals.switchToLatest subscribeNext:^(NSDictionary *responseDic) {
        
        
        NSString *contentData = [responseDic objectForKey:@"data"];
        NSArray *domainArray = nil;
        NSArray *responseList = [JsonUtils jsonStringToArray:contentData];
        if(responseList && responseList.count > 0){
            for (NSMutableDictionary *dict in responseList) {
                NSString *domainStr = [dict objectForKey:@"domain"];
                
                // 获取前缀
                NSArray *fileSuffix = [domainStr componentsSeparatedByString:@"."];
                NSString *domainSuffix = [NSString stringWithFormat:@"%@", fileSuffix.firstObject];
                domainArray = [[NSArray alloc]initWithObjects:domainSuffix, nil];
            }
        }
        
        if(domainArray){
            int userState;
            //判断用户是否注册
            userState = [[SecurityEngineHelper getInstance] checkUserExist:self.loginAccount];
            
            switch (userState) {
                case 0:{
#if  XYT
                    //获取服务器配置
                    [self.getServerConfigCommand execute:nil];
#else
                    
                    //获取服务器配置
                    [self.getServerConfigCommand execute:nil];
                    
//                    NSLog(@"用户已经注册");
//                    //直接获取验证码
//                    [[SecurityEngineHelper getInstance] getCode:self.loginAccount withPass:self.loginPassword withCallBack:^(int ret) {
//
//                        if(ret == 1){
//                            [self.loginEndSubject sendNext:nil];
//                        }else{
//                            NSString *errorMsg = [ErrorMessage errorMessage:ret];
//                            [self.loginFaileSubject sendNext:errorMsg];
//                        }
//                    }];
                    //直接return 是为了旋转框继续转
#endif
                    return;
                }
                case 1:
                case 3: {
                    NSLog(@"用户未注册");
//                    [self.loginFaileSubject sendNext:_T(@"用户未注册")];
                    //未注册直接去注册界面
#if  XYT
                    if (_actionType == Register)
                    {
                        //获取服务器配置
                        [self.getServerConfigCommand execute:nil];
                    }else
                    {
                        [self.gotoRegisterSubject sendNext:nil];
                    }
#else
                    if (self.actionType == Register)
                    {
                        //获取服务器配置
                        [self.getServerConfigCommand execute:nil];
                    }else
                    {
                        //未注册，调取失败block
                        [self.gotoRegisterSubject sendNext:nil];
                        self.failedBlock(@"该用户未注册");
                    }
#endif
                    break;
                }
                case 2: {
                    NSLog(@"用户已被禁用");
                    [self.loginFaileSubject sendNext:_T(@"用户已被禁用")];
                    self.failedBlock(_T(@"用户已被禁用"));
                    break;
                }
                default: {
                    NSLog(@"用户账号异常");
                    [self.loginFaileSubject sendNext:_T(@"用户账号异常")];
                    self.failedBlock(_T(@"用户账号异常"));
                    break;
                }
            }
        }else{
            int code = [[responseDic objectForKey:@"code"] intValue];
            if(code == 3){
                [self.loginFaileSubject sendNext:_T(@"本地时间与服务器时间不一致")];
                self.failedBlock(_T(@"本地时间与服务器时间不一致"));
            }else{
                [self.loginFaileSubject sendNext:_T(@"用户不存在,请联系管理员添加")];
                self.failedBlock(_T(@"用户不存在,请联系管理员添加"));
            }
            
        }
        [SVProgressHUD dismiss];
    }];
    
    //////////////////////////////获取验证码/////////////////////////////////////
    
    [self.getCodeCommand.executionSignals.switchToLatest subscribeNext:^(NSNumber *ret) {
        
        @strongify(self);
       [SVProgressHUD dismiss];
        
        if([ret intValue] != 1){
            [self.getCodeBtnSubject sendNext:[ErrorMessage errorMessage:[ret intValue]]];
        }else{
            [self.getCodeBtnSubject sendNext:nil];
        }
    }];
    
    [self.getCodeCommand.executing  subscribeNext:^(id x) {
        
        if ([x isEqualToNumber:@(YES)]) {
            
            [SVProgressHUD showWithStatus:_T(@"正在获取验证码")];
        }
    }];
    
    /////////获取token /////////////
    
    [self.getTokenCommand.executionSignals.switchToLatest subscribeNext:^(id x) {
        
        if(!x){
            return;
        }
        
        if([x isKindOfClass:[NSNumber class]]){
            
            [SVProgressHUD dismiss];
            
            NSNumber *errorNumber = (NSNumber *)x;
            [self.getTokenBtnSubject sendNext:[ErrorMessage errorMessage:errorNumber.intValue]];
        }else{
            @strongify(self);
            
            int code = [[x objectForKey:@"code"] intValue];
            
            if(code == 0){
                
                NSString *data = [x objectForKeySafe:@"data"];
                
                data = [[SecurityEngineHelper getInstance] decryptSignDataEx:data withUserId:self.loginAccount];
                
                NSDictionary *dic = [JsonUtils dictionaryWithJsonString:data];
                
                NSString *sip_pass = [dic objectForKeySafe:@"sip_pass"];
                NSString *im_token = [dic objectForKeySafe:@"token"];
                NSString *sip_domian =  [dic objectForKeySafe:@"domain"];
                
                //加密并修改本地的密码
                NSString *loginRandomCipherText = [RandomPasswordTool encryptPassword:self.loginAccount withPass:self.loginPassword];
                if(loginRandomCipherText != nil){
                    self.loginPassword = loginRandomCipherText;
                }
                
                [[ConfigsManager sharedConfigsManager] setXMPPDomain:sip_domian];
        
                [[UserCenter sharedUserCenter] setUserAccount:self.loginAccount];
                [[UserCenter sharedUserCenter] setUserPassword:self.loginPassword];
                [[UserCenter sharedUserCenter] setUserDomain:sip_domian];
                [[UserCenter sharedUserCenter] setAccessToken:im_token];
                [[UserCenter sharedUserCenter] setUserSipPassword:sip_pass];
                [[UserCenter sharedUserCenter] setIsFirstLogin:YES];
                
#if JiaMiTong
//                dispatch_async(dispatch_get_global_queue(0, 0), ^{
//
//                    NSString *keySN = [[JMTKeyHepler getInstance] getKeySN];
//                    if(keySN){
//                        [[UserCenter sharedUserCenter] saveKeySn:keySN];
//                    }
//
                    [self.loginImCommand execute:nil];
//
//                });
#else
                
                [self.loginImCommand execute:nil];
#endif
            }else{
                
                [SVProgressHUD dismiss];
                if(code == 3){
                    [self.getTokenBtnSubject sendNext:_T(@"本地时间与服务器时间不一致")];
                }else if(code == 21){
                    
                    [self.getTokenBtnSubject sendNext:_T(@"用户已被禁用")];
                }else{
                    [self.getTokenBtnSubject sendNext:_T(@"登录失败")];
                }
            }
        }

    }];
    
    
    [self.getTokenCommand.executing subscribeNext:^(id x) {
        
        if ([x isEqualToNumber:@(YES)]) {
            
//            ShowMaskStatus(@"正在登录");
            [SVProgressHUD showWithStatus:_T(@"正在登录")];
        }
    }];
    
    //////////////////////////////登录IM平台/////////////////////////////////////
    
    [self.loginImCommand.executionSignals.switchToLatest subscribeNext:^(NSDictionary *responseDic) {
        
        [SVProgressHUD dismiss];
        
        NSLog(@"登陆业务平台返回成功 %@",responseDic);
        
        [[UserCenter sharedUserCenter] doSaveUserInfo:responseDic];
        
        [self.loginImSubject sendNext:nil];
        
    }];
    
    ////获取服务器配置/////
    [self.getServerConfigCommand.executionSignals.switchToLatest subscribeNext:^(NSDictionary *responseDic) {
        int code = [[responseDic objectForKey:@"code"] intValue];
        if(code == 0)
        {
            //服务器配置信息
            
            NSDictionary *data = [JsonUtils dictionaryWithJsonString:[responseDic objectForKey:@"data"]];
            [[ConfigsManager sharedConfigsManager] setP2pStatus:[[data objectForKey:@"p2p_status"]boolValue]];
            [[ConfigsManager sharedConfigsManager] setIosVersion:[data objectForKey:@"ios_version"]];
            [[ConfigsManager sharedConfigsManager] setUsercenterIp:[data objectForKey:@"usercenter_ip"]];
            [[ConfigsManager sharedConfigsManager] setP2pIp:[data objectForKey:@"p2p_ip"]];
            [[ConfigsManager sharedConfigsManager] setP2pPort:[data objectForKey:@"p2p_port"]];
            [[ConfigsManager sharedConfigsManager] setBindDevice:[[data objectForKey:@"bind_status"]boolValue]];
            [[ConfigsManager sharedConfigsManager] setOrganModel:[[data objectForKey:@"organ_model"]boolValue]];
#if XYT
            
#else
            NSLog(@"im_port : %@",[data objectForKey:@"im_port"]);
            if (![data objectForKey:@"im_port"]) {
                
                [[ConfigsManager sharedConfigsManager] setIMPort:Config_DEFUALT_IM_Port];
                NSLog(@"[[ConfigsManager sharedConfigsManager] setIMPort:Config_DEFUALT_IM_Port];");
            }else if([[data objectForKey:@"im_port"] isEqualToString:@""]){
                
                //空值的时候也要跟错值一样
                [[ConfigsManager sharedConfigsManager] setIMPort:@"65535"];
                NSLog(@"[[ConfigsManager sharedConfigsManager] setIMPort:65535];");
            }else{
            
                [[ConfigsManager sharedConfigsManager] setIMPort:[data objectForKey:@"im_port"]];
                NSLog(@"[[ConfigsManager sharedConfigsManager] setIMPort:[data objectForKey: “im_port”]");
            }
#endif
            if ([[data objectForKey:@"api_version"] isEqualToString:@"v1"]) {
      
                [[ConfigsManager sharedConfigsManager] setApiVersion:API_Version_V1];
            }else if([[data objectForKey:@"api_version"] isEqualToString:@"v2"]){
                
                [[ConfigsManager sharedConfigsManager] setApiVersion:API_Version_V2];
            }
            
            //服务器组织架构修改时间
            NSString *creatAt = [data objectForKey:@"created_at"];
            [[NSUserDefaults standardUserDefaults] setObject:creatAt forKey:@"created_at"];

            if ([data objectForKey:@"free_port"])
            {
                [[ConfigsManager sharedConfigsManager] setSipPort:[[data objectForKey:@"free_port"]integerValue]];
            }
            if ([data objectForKey:@"tigase_port"])
            {
                [[ConfigsManager sharedConfigsManager] setXMPPPort:[[data objectForKey:@"tigase_port"]integerValue]];
            }
            
            //设置是否绑定设备
            [[SecurityEngineHelper getInstance] setIfBindDevice:[ConfigsManager sharedConfigsManager].bindDevice];
            
            if (_actionType == Register) {
//                [self.loginEndSubject sendNext:nil];
                NSMutableDictionary *dic = [NSMutableDictionary dictionary];
                [dic setValue:@"0" forKey:@"code"];
                self.successBlock(dic);
                return;
            }else
            {
                NSLog(@"用户已经注册");
                //直接获取验证码
                [[SecurityEngineHelper getInstance] getCode:self.loginAccount withPass:self.loginPassword withCallBack:^(int ret) {
                    
                    if(ret == 1){
//                        [self.loginEndSubject sendNext:nil];
                        NSMutableDictionary *dic = [NSMutableDictionary dictionary];
                        [dic setValue:@"0" forKey:@"code"];
                        self.successBlock(dic);
                    }else{
                        NSString *errorMsg = [ErrorMessage errorMessage:ret];
//                        [self.loginFaileSubject sendNext:errorMsg];
                        self.failedBlock(errorMsg);
                    }
                }];
            }
         }else
        {
            int code = [[responseDic objectForKey:@"code"] intValue];
            if(code == 3){
//                [self.loginFaileSubject sendNext:_T(@"本地时间与服务器时间不一致")];
                NSString *str = [NSString stringWithFormat:@"%d",code];
                self.failedBlock(str);
            }else if(code == 2){
                [self.getServerConfigSubject sendNext:nil];
            }else
            {
//                [self.loginFaileSubject sendNext:[responseDic objectForKey:@"message"]];
                
                NSString *str = [NSString stringWithFormat:@"%d",code];
                self.failedBlock(str);
            }
        }

    }];
    
    
    [self.getServerConfigSubject subscribeNext:^(NSString *error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            @strongify(self);
            if (self.actionType == Register) {
//                [self.loginEndSubject sendNext:nil];
                NSMutableDictionary *dic = [NSMutableDictionary dictionary];
                [dic setValue:@"0" forKey:@"code"];
                self.successBlock(dic);
                return;
            }else
            {
                NSLog(@"用户已经注册");
                //直接获取验证码
                [[SecurityEngineHelper getInstance] getCode:self.loginAccount withPass:self.loginPassword withCallBack:^(int ret) {
                    
                    if(ret == 1){
//                        [self.loginEndSubject sendNext:nil];
                        NSMutableDictionary *dic = [NSMutableDictionary dictionary];
                        [dic setValue:@"0" forKey:@"code"];
                        self.successBlock(dic);
                    }else{
                        NSString *errorMsg = [ErrorMessage errorMessage:ret];
//                        [self.loginFaileSubject sendNext:errorMsg];
                        self.failedBlock(errorMsg);
                    }
                }];
            }
        });
        
    }];
    
}

-(void)configurateDefaultParameter{
    
    NSString *ip = FirstIpAddress;
    NSString *ipStr = [NSString stringWithFormat:@"%@:%@",ip,[ConfigsManager sharedConfigsManager].serverPort];
    [[ConfigsManager sharedConfigsManager] setServerUrl:ip];
    [[SecurityEngineHelper getInstance] setIbcserver:ipStr];
    [self performSelector:@selector(next) withObject:nil afterDelay:0.5];
}

-(void)configurateSecondParameter{
    
    NSString *ip = SecondIpAddress;
    NSString *ipStr = [NSString stringWithFormat:@"%@:%@",ip,[ConfigsManager sharedConfigsManager].serverPort];
    [[ConfigsManager sharedConfigsManager] setServerUrl:ip];
    [[SecurityEngineHelper getInstance] setIbcserver:ipStr];
    
    [self performSelector:@selector(next) withObject:nil afterDelay:0.5];
}

-(void)next{
    
    [self.loginCommand execute:nil];
}

-(void)forgetPasswordGetCode{
    
    //发送验证码
    NSString *userName = self.loginAccount;
    [[SecurityEngineHelper getInstance] forgetPassword:userName withCallBack:^(int ret) {
        
        dispatch_async(dispatch_get_main_queue(), ^{

            switch (ret) {
                case 1: {
                    
                    self.successBlock(@{@"code" : @"0"});
//                    [self.vCodeBtn setEnabled:NO];
//                    [self.timer fire];
                    break;
                }
                case 20020: {
                    [SVProgressHUD showInfoWithStatus:_T(@"用户不存在,请注册")];
                    break;
                }
                default: {
                    [SVProgressHUD showInfoWithStatus:_T(@"发生错误,请稍后重试")];
                }
                    break;
            }
        });
    }];
}

- (RACCommand *)loginCommand {
    
    if (!_loginCommand) {
        
        @weakify(self);
        _loginCommand = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
            
            return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
                @strongify(self);
                
#ifdef XJT
                //香江通直接使用固定参数登录
                [self.checktUserCommand execute:nil];
                return nil;
#endif
                [[LoginRequest sharedManager] checkUserFromFusionServer:self.loginAccount Success:^(NSDictionary *responseDic) {

                    [subscriber sendNext:responseDic];
                    [subscriber sendCompleted];

                } Failure:^(NSString *error) {

                    [self.loginFaileSubject sendNext:_T(@"网络异常,请稍后重试")];
                    [subscriber sendNext:nil];
                    [subscriber sendCompleted];

                }];
                return nil;
            }];
        }];
    }
    
    return _loginCommand;
}

-(RACCommand *)getDomainInfoCommand{
    if(!_getDomainInfoCommand){
        @weakify(self);
        _getDomainInfoCommand = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
            
            return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
                
                @strongify(self);
                //获取域信息
                [[LoginRequest sharedManager] getDomainInfo:self.loginDomain withVersion:Config_DEFUALT_DOMAIN_VERSION Success:^(NSDictionary *responseDic) {

                    [subscriber sendNext:responseDic];
                    [subscriber sendCompleted];

                } Failure:^(NSString *error) {

                    [self.loginFaileSubject sendNext:_T(@"网络异常,请稍后重试")];
                    [subscriber sendNext:nil];
                    [subscriber sendCompleted];

                }];
                return nil;
            }];
        }];
    }
    
    return _getDomainInfoCommand;
}

-(RACCommand *)checktUserCommand{
    if(!_checktUserCommand){
        @weakify(self);
        _checktUserCommand = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
            
            return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
                
                @strongify(self);
                
                NSLog(@"%@",[ConfigsManager sharedConfigsManager].serverUrl);
                //获取域信息
                [[LoginRequest sharedManager] checktMjtUserExit:self.loginAccount Success:^(NSDictionary *responseDic) {
                    
                    [subscriber sendNext:responseDic];
                    [subscriber sendCompleted];
                    
                } Failure:^(NSString *error) {
                    
#ifdef XJT
                    NSString *s = [ConfigsManager sharedConfigsManager].serverUrl;
                    if ([[ConfigsManager sharedConfigsManager].serverUrl isEqualToString:FirstIpAddress]) {
                        
                        [self configurateSecondParameter];
                        NSString *string = [NSString stringWithFormat:@"登录%@失败，正在尝试登录%@",FirstIpAddress,SecondIpAddress];
                        [SVProgressHUD showInfoWithStatus:string];
                    }else{
                        
                        [self configurateDefaultParameter];
                        NSString *string = [NSString stringWithFormat:@"登录%@失败，正在尝试登录%@",SecondIpAddress,FirstIpAddress];
                        [SVProgressHUD showInfoWithStatus:string];
                    }
                    
#else
                    
                    [self.loginFaileSubject sendNext:_T(@"网络异常,请稍后重试")];
#endif

                    [subscriber sendCompleted];
                    
                }];

                return nil;
            }];
        }];
    }
    
    return _checktUserCommand;
}

-(RACCommand *)getCodeCommand
{
    if(!_getCodeCommand){
        @weakify(self);
        _getCodeCommand = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
            
            return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
                
                @strongify(self);
                
                [[SecurityEngineHelper getInstance] getCode:self.loginAccount withPass:self.loginPassword withCallBack:^(int ret) {
                    
                    [subscriber sendNext:@(ret)];
                    [subscriber sendCompleted];

                }];
               
                
                return nil;
            }];
        }];
    }
    
    return _getCodeCommand;
}

-(RACCommand *)getTokenCommand
{
    if(!_getTokenCommand){
        @weakify(self);
        _getTokenCommand = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
            
            return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
                
#if JiaMiTong
                
//                if([JMTKeyHepler getInstance].isDeviceExit){
//
//                    dispatch_async(dispatch_get_global_queue(0, 0), ^{
//
//                         @strongify(self);
//
//                        //[[JMTKeyHepler getInstance] deleteData];
//                        [self startDownLoadPrivateKey:subscriber];
//
//                    });
//
//                }else{
//                    @strongify(self);
//                    [self.getTokenBtnSubject sendNext:_T(@"请连接硬件加密设备")];
//                    [subscriber sendCompleted];
//                }
                
#else
                @strongify(self);
                [self startDownLoadPrivateKey:subscriber];
#endif
                
                
                
                return nil;
            }];
        }];
    }
    
    return _getTokenCommand;
}

-(void)startDownLoadPrivateKey:(id<RACSubscriber>)subscriber{
    
    if ([ConfigsManager sharedConfigsManager].bindDevice)
    {
        [[SecurityEngineHelper getInstance] downloadPrivateKeyAndBindUser:self.loginAccount withPass:self.loginPassword withCode:self.loginValidCode withCallBack:^(int ret) {
            if(ret == 1){
                
                [[LoginRequest sharedManager] getLoginToken:self.loginAccount Success:^(NSDictionary *responseDic) {
                    
                    [subscriber sendNext:responseDic];
                    [subscriber sendCompleted];
                    
                } failure:^(NSString *error) {
                    
                    [self.getTokenBtnSubject sendNext:error];
                    [subscriber sendCompleted];
                    
                }];
            }else if(ret == 65){
                [self.getTokenBtnSubject sendNext:_T(@"下载失败，请重新获取验证码")];
                [subscriber sendCompleted];
            }else{
                
                
                [self.getTokenBtnSubject sendNext:[ErrorMessage errorMessage:ret]];
                [subscriber sendCompleted];
            }

        }];
    }else
    {
        [[SecurityEngineHelper getInstance] downloadPrivateKey:self.loginAccount withPass:self.loginPassword withCode:self.loginValidCode withCallBack:^(int ret) {
            
            if(ret == 1){
 
                [[LoginRequest sharedManager] getLoginToken:self.loginAccount Success:^(NSDictionary *responseDic) {
                    
                    [subscriber sendNext:responseDic];
                    [subscriber sendCompleted];
                    
                } failure:^(NSString *error) {
                    
                    [self.getTokenBtnSubject sendNext:error];
                    [subscriber sendCompleted];
                    
                }];
            }else if(ret == 65){
                [self.getTokenBtnSubject sendNext:_T(@"下载失败，请重新获取验证码")];
                [subscriber sendCompleted];
            }else{
                
                
                [self.getTokenBtnSubject sendNext:[ErrorMessage errorMessage:ret]];
                [subscriber sendCompleted];
            }
 
        }];
    }
    
    
}



-(RACCommand *)loginImCommand
{
    if(!_loginImCommand){
        @weakify(self);
        _loginImCommand = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
            
            return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
                
                @strongify(self);
                
                [[LoginRequest sharedManager] loginToImServer:^(NSDictionary *responseDic) {
                    
                    [subscriber sendNext:responseDic];
                    [subscriber sendCompleted];

                    
                } failure:^(NSString *error) {
                    
                    [self.getTokenBtnSubject sendNext:error];
                    
                    [subscriber sendCompleted];

                }];
                
                return nil;
            }];
        }];
    }
    
    return _loginImCommand;
}


-(RACCommand *)bleKeyCommand
{
    if(!_bleKeyCommand){
        @weakify(self);
        _bleKeyCommand = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {

            return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
                
                [subscriber sendNext:nil];
                [subscriber sendCompleted];
                
                
                return nil;
            }];
        }];
    }
    
    return _bleKeyCommand;
}


- (RACCommand *)getServerConfigCommand
{
    if (!_getServerConfigCommand)
    {
        @weakify(self);
        _getServerConfigCommand = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
            @strongify(self);

            return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
                
                [[LoginRequest sharedManager] getServerConfigSuccess:^(NSDictionary *responseDic) {
                    [subscriber sendNext:responseDic];
                    [subscriber sendCompleted];
                    
                } Failure:^(NSString *error) {
                    [self.loginFaileSubject sendNext:error];
                    [subscriber sendCompleted];
                }];
                
                
                return nil;
            }];
        }];
    }
    return _getServerConfigCommand;
}
 
-(void)setDomain:(NSString *)domain{
    [SVProgressHUD showWithStatus:_T(@"正在执行")];
    self.loginDomain = domain;
    [self.getDomainInfoCommand execute:nil];
}


- (RACSubject *)loginBtnSubject {
    
    if (!_loginBtnSubject) {
        
        _loginBtnSubject = [RACSubject subject];
    }
    
    return _loginBtnSubject;
}

- (RACSubject *)needDomainSubject {
    
    if (!_needDomainSubject) {
        
        _needDomainSubject = [RACSubject subject];
    }
    
    return _needDomainSubject;
}

- (RACSubject *)loginEndSubject {
    
    if (!_loginEndSubject) {
        
        _loginEndSubject = [RACSubject subject];
    }
    
    return _loginEndSubject;
}

-(RACSubject *)loginFaileSubject
{
    if (!_loginFaileSubject) {
        
        _loginFaileSubject = [RACSubject subject];
    }
    
    return _loginFaileSubject;
}

- (RACSubject *)gotoRegisterSubject
{
    if (!_gotoRegisterSubject) {
        
        _gotoRegisterSubject = [RACSubject subject];
    }
    return _gotoRegisterSubject;
}

-(RACSubject *)getCodeBtnSubject{
    if (!_getCodeBtnSubject) {
        
        _getCodeBtnSubject = [RACSubject subject];
    }
    
    return _getCodeBtnSubject;
}

-(RACSubject *)getTokenBtnSubject{
    
    if (!_getTokenBtnSubject) {
        
        _getTokenBtnSubject = [RACSubject subject];
    }
    
    return _getTokenBtnSubject;
}

- (RACSubject *)loginImSubject {
    
    if (!_loginImSubject) {
        
        _loginImSubject = [RACSubject subject];
    }
    
    return _loginImSubject;
}


- (RACSubject *)registerBtnSubject {
    
    if (!_registerBtnSubject) {
        
        _registerBtnSubject = [RACSubject subject];
    }
    
    return _registerBtnSubject;
}

- (RACSubject *)forgetPassBtnSubject {
    
    if (!_forgetPassBtnSubject) {
        
        _forgetPassBtnSubject = [RACSubject subject];
    }
    
    return _forgetPassBtnSubject;
}

- (RACSubject *)getServerConfigSubject
{
    if (!_getServerConfigSubject) {
        
        _getServerConfigSubject = [RACSubject subject];
    }
    
    return _getServerConfigSubject;
}


@end
