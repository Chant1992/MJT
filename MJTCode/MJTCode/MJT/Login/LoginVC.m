//
//  LoginVC.m
//  MJT_APP
//
//  Created by olymtech on 2017/8/17.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "LoginVC.h"
//#import "LoginViewModel.h"
#import "LoginTextFieldView.h"
#import "UIView+Layer.h"
#import "ValidateViewController.h"
#import "RegisterViewController.h"
#import "ForgetViewController.h"
#import "AlertViewManager.h"
#import "ZoneSelectViewController.h"
#import "SecurityEngineHelper.h"
#import <MJTLoginInModule/LoginManager.h>
//#import <MJTLoginInModule/LoginViewModel.h>

@interface LoginVC ()<UITableViewDelegate, LoginTFViewDelegate>

@property(nonatomic,strong) LoginViewModel *loginViewModel;
// 容器列表
@property (nonatomic, strong) UITableView *containList;
// App logo
@property (nonatomic, strong) UIImageView *logoImgView;
// 账号输入框
@property (nonatomic, strong) LoginTextFieldView *usernameTF;
// 密码输入框
@property (nonatomic, strong) LoginTextFieldView *passwordTF;
// 登录按钮
@property (nonatomic, strong) UIButton *loginBtn;
// 忘记密码按钮
@property (nonatomic, strong) UIButton *forgetBtn;
// 注册按钮
@property (nonatomic, strong) UIButton *registeBtn;

@end

@implementation LoginVC

#pragma mark - private
- (void)olym_bindViewModel{
#if XJT
    [olym_Default setObject:@1 forKey:ZoneAcronymArrayIndex];
    [olym_Securityengine setCodeZone:zoneCodeArray[1]];
#endif
    
    @weakify(self);
    
    RAC(self.loginBtn,enabled) = [RACSignal combineLatest:@[[self.usernameTF.textField rac_textSignal],[self.passwordTF.textField rac_textSignal]] reduce:^id(NSString *name,NSString *pass){
        return @(name.length > 7 && pass.length > 5);
    }];
    
    //登录
    [[self.loginBtn rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x ){
        @strongify(self);
        self.loginViewModel.loginAccount = self.usernameTF.text;
        self.loginViewModel.loginPassword = self.passwordTF.text;
#ifdef XJT
      
        [self.loginViewModel.checktUserCommand execute:nil];
#else
        
//        [self.loginViewModel.loginCommand execute:nil];
        
        //封装的代码
        LoginManager *loginmanager = [LoginManager sharedManager];
        [loginmanager loginWithAccount:self.usernameTF.text password:self.passwordTF.text Success:^(NSDictionary *dic) {
            @strongify(self);
            
            [SVProgressHUD dismiss];
            dispatch_async(dispatch_get_main_queue(), ^{
                
                ValidateViewController *validateViewController = [[ValidateViewController alloc]init];
                validateViewController.loginViewModel = loginmanager.loginViewModel;
                [self.navigationController pushViewController:validateViewController animated:YES];
            });
            
        } Failure:^(NSString *error) {
            
            [SVProgressHUD dismiss];
            if ([error isEqualToString:@"该用户未注册"]) {
                
                //跳转到注册
                GJCFAsyncMainQueue(^(void){
                    @strongify(self);
                    [SVProgressHUD showInfoWithStatus:_T(@"用户初次使用，请设置初始密码")];
                    RegisterViewController *vc = [[RegisterViewController alloc]init];
                    [self.navigationController pushViewController:vc animated:YES];
                });
            }
            
            if ([error isEqualToString:@"用户中心不存在此用户...需要用户手动设置服务器"]) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    @strongify(self);
                    
                    UIAlertController *alert = [UIAlertController
                                                alertControllerWithTitle:_T(@"提示")
                                                message:_T(@"请输入您所在的机构名称")
                                                preferredStyle:UIAlertControllerStyleAlert];
                    
                    UIAlertAction *ok = [UIAlertAction actionWithTitle: _T(@"确定") style: UIAlertActionStyleDefault handler:^(UIAlertAction *action){
                        
                        UITextField *alertTextField = alert.textFields.firstObject;
                        
                        NSString *domain = [alertTextField text];
                        if(GJCFStringIsNull(domain)){
                            [AlertViewManager alertWithTitle:_T(@"机构名称不能为空")];
                            return;
                        }
                        
                        [loginmanager.loginViewModel  setDomain:domain];
                        
                    }];
                    
                    UIAlertAction *cancel = [UIAlertAction actionWithTitle:_T(@"取消") style:UIAlertActionStyleCancel handler: nil];
                    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
                        textField.placeholder = _T(@"企业机构名称");
                    }];
                    
                    [alert addAction:ok];
                    [alert addAction:cancel];
                    
                    [self.navigationController presentViewController:alert animated:YES completion:nil];
                    
                });
            }else{
                
                [AlertViewManager alertWithTitle:error];
            }
            NSLog(@"error");
        }];
#endif
        
    }];
    
    
    [self.loginViewModel.loginEndSubject subscribeNext:^(id x) {
        GJCFAsyncMainQueue(^(void){
            @strongify(self);
            [SVProgressHUD dismiss];
            ValidateViewController *validateViewController = [[ValidateViewController alloc]init];
            validateViewController.loginViewModel = self.loginViewModel;
            [self.navigationController pushViewController:validateViewController animated:YES];
            
        });
    }];
    
    //未注册直接跳转去注册界面
    [self.loginViewModel.gotoRegisterSubject subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        GJCFAsyncMainQueue(^(void){
            [SVProgressHUD showInfoWithStatus:_T(@"用户初次使用，请设置初始密码")];
            RegisterViewController *vc = [[RegisterViewController alloc]init];
            [self.navigationController pushViewController:vc animated:YES];
        });
    }];
    
    [self.loginViewModel.loginFaileSubject subscribeNext:^(NSString *error) {
        
        GJCFAsyncMainQueue(^(void){
            @strongify(self);
        
            [SVProgressHUD dismiss];
            if(error){
                [AlertViewManager alertWithTitle:error];
            }
        });
    }];
    
    [self.loginViewModel.needDomainSubject subscribeNext:^(id x) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            @strongify(self);
            
            UIAlertController *alert = [UIAlertController
                                        alertControllerWithTitle:_T(@"提示")
                                        message:_T(@"请输入您所在的机构名称")
                                        preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *ok = [UIAlertAction actionWithTitle: _T(@"确定") style: UIAlertActionStyleDefault handler:^(UIAlertAction *action){
                
               UITextField *alertTextField = alert.textFields.firstObject;
                
                NSString *domain = [alertTextField text];
                if(GJCFStringIsNull(domain)){
                    [AlertViewManager alertWithTitle:_T(@"机构名称不能为空")];
                    return;
                }
                [self.loginViewModel setDomain:domain];
                
            }];
            
            UIAlertAction *cancel = [UIAlertAction actionWithTitle:_T(@"取消") style:UIAlertActionStyleCancel handler: nil];
            [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
                textField.placeholder = _T(@"企业机构名称");
            }];
            
            [alert addAction:ok];
            [alert addAction:cancel];
            
            [self.navigationController presentViewController:alert animated:YES completion:nil];
           
        });
      
    }];
    
    //注册
    [[self.registeBtn rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(__kindof UIControl * _Nullable x) {
        @strongify(self);
       
        RegisterViewController *vc = [[RegisterViewController alloc]init];
        [self.navigationController pushViewController:vc animated:YES];
    }];
    
    //忘记密码
    [[self.forgetBtn rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(__kindof UIControl * _Nullable x) {
        
        ForgetViewController *vc = [[ForgetViewController alloc]init];
        [self.navigationController pushViewController:vc animated:YES];
    }];
}
- (void)olym_addSubviews{
    [self.view setBackgroundColor:white_color];
    
    [self.view addSubview:self.containList];
    [self.containList.tableHeaderView addSubview:self.logoImgView];
    [self.containList.tableHeaderView addSubview:self.usernameTF];
    [self.containList.tableHeaderView addSubview:self.passwordTF];
    [self.containList.tableHeaderView addSubview:self.loginBtn];
    [self.containList.tableHeaderView addSubview:self.forgetBtn];
    [self.containList.tableHeaderView addSubview:self.registeBtn];
    
    WeakSelf(ws);
    [_containList mas_makeConstraints:^(MASConstraintMaker *make) {
        
        if (@available(iOS 11, *)) {
            make.edges.mas_equalTo(ws.view.safeAreaInsets);
        }else{
            make.edges.mas_equalTo(ws.view);
        }

    }];
    [_logoImgView mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.top.mas_equalTo(ws.containList.tableHeaderView).offset(45);
        make.centerX.mas_equalTo(ws.containList.tableHeaderView);
        make.width.mas_equalTo(100);
        make.height.mas_equalTo(100);
    }];
    
    [_usernameTF mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.top.mas_equalTo(ws.logoImgView.mas_bottom).offset(45);
        make.left.mas_equalTo(ws.containList.tableHeaderView).offset(15);
        make.right.mas_equalTo(ws.containList.tableHeaderView.mas_right).offset(-15);
    }];
    
    [_passwordTF mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.top.mas_equalTo(ws.usernameTF.mas_bottom).offset(15);
        make.left.right.mas_equalTo(ws.usernameTF);
    }];
    
    [_forgetBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.top.mas_equalTo(ws.passwordTF.mas_bottom).offset(15);
        make.right.mas_equalTo(ws.passwordTF);
    }];
    [_loginBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.top.mas_equalTo(ws.passwordTF.mas_bottom).offset(60);
        make.left.right.mas_equalTo(ws.passwordTF);
        make.height.mas_equalTo(45);
    }];
    [_registeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.top.mas_equalTo(ws.loginBtn.mas_bottom).offset(30);
        make.centerX.mas_equalTo(ws.containList.tableHeaderView);
    }];
    
}
- (void)olym_layoutNavigation{
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

-(void)zoneSelectAction:(UIButton *)sender{
    ZoneSelectViewController *zoneSelectViewController = [[ZoneSelectViewController alloc]init];
    zoneSelectViewController.target = self;
    zoneSelectViewController.didSelectAction = @selector(didSelectZone:);
    [self.navigationController pushViewController:zoneSelectViewController animated:YES];
}

-(void)didSelectZone:(NSString *)zone{
    if(GJCFStringIsNull(zone)){
        return;
    }
    
    
    [self setUserName:zone];
}


#pragma mark - public
- (void)viewDidLoad {
    [super viewDidLoad];

    
#ifdef DEBUG
  
    [self.usernameTF setText:@"19999000034"];
    [self.passwordTF setText:@"123456"];
 
#endif
   
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - 《$---------------- KeyboardAction -----------------$》
- (void)hideKeyboard {
    
    [self.view endEditing:YES];
}

#pragma mark 《$ ---------------- LoginTFViewDelegate ---------------- $》
- (void)clearPasswordWhileAccountIsEditting:(LoginTextFieldView *)textField {
    
    if (textField == _usernameTF) {
        
        [_passwordTF clearLoginTextField];
    }
}

#pragma mark 《$ ---------------- Setter/Getter ---------------- $》
- (UITableView *)containList {
    
    if (!_containList) {
        
        _containList = [[UITableView alloc] initWithFrame:CGRectZero];
        _containList.backgroundColor = [UIColor whiteColor];
        _containList.delegate = self;
        _containList.separatorStyle = NO;
        _containList.showsVerticalScrollIndicator = NO;
        _containList.backgroundColor = [UIColor whiteColor];
        
        // 添加headerView
        UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, GJCFSystemScreenWidth, GJCFSystemScreenHeight - 20)];
        _containList.tableHeaderView = headerView;
        
        // 添加点击隐藏键盘手势
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
        [_containList addGestureRecognizer:tap];
    }
    
    return _containList;
    
}
- (UIImageView *)logoImgView {
    
    if (!_logoImgView) {
        NSString *s = GJCFAppConfigRead(@"AboutLogo");
        _logoImgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:GJCFAppConfigRead(@"AboutLogo")]];
        
    }
    
    return _logoImgView;
}
- (LoginTextFieldView *)usernameTF {
    
    if (!_usernameTF) {
        
        _usernameTF = [[LoginTextFieldView alloc] initWithFrame:CGRectZero];
        _usernameTF.delegate = self;
        
        [_usernameTF setTextFieldKeyboardType:UIKeyboardTypeNumberPad];
#if XJT
        [self setUserName:zoneNumberArray[1]];
#else
        [self setUserName:zoneNumberArray[0]];
#endif
        [_usernameTF.itemBtn addTarget:self action:@selector(zoneSelectAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _usernameTF;
}
-(void)setUserName:(NSString *)userName{
    [self.usernameTF setTextFieldStyle:_T(@"请输入账号") itemStrEx:[NSString stringWithFormat:@"%@:",userName]];
}

- (LoginTextFieldView *)passwordTF {
    
    if (!_passwordTF) {
        
        _passwordTF = [[LoginTextFieldView alloc] initWithFrame:CGRectZero];
        [_passwordTF setTextFieldStyle:_T(@"首次使用请设置初始密码") itemStr:_T(@"密   码:")];
        [_passwordTF setTextFieldSecure];
        
    }
    
    return _passwordTF;
}
// 登录按钮
- (UIButton *)loginBtn {
    
    if (!_loginBtn) {
        
        _loginBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _loginBtn.titleLabel.font = [UIFont systemFontOfSize:16];
        // Label
        [_loginBtn setTitle:_T(@"登录") forState:UIControlStateNormal];
        // Label color
        [_loginBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_loginBtn setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
        // Background
        [_loginBtn setBackgroundImage:[UIImage imageNamed:@"login_dologin_normal"] forState:UIControlStateNormal];
        [_loginBtn setBackgroundImage:[UIImage imageNamed:@"login_dologin_height"] forState:UIControlStateHighlighted];
        // fillet
        [_loginBtn setLayerCornerRadius:5 borderWidth:0 borderColor:nil];
    }
    
    return _loginBtn;
}
// 忘记密码按钮
- (UIButton *)forgetBtn {
    
    if (!_forgetBtn) {
        
        _forgetBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _forgetBtn.titleLabel.font = [UIFont systemFontOfSize:14.f];
        // Label
        [_forgetBtn setTitle:_T(@"忘记密码") forState:UIControlStateNormal];
        // Label color
        [_forgetBtn setTitleColor:OLYMHEXCOLOR(0x888888) forState:UIControlStateNormal];
        [_forgetBtn setTitleColor:[UIColor darkGrayColor] forState:UIControlStateHighlighted];
        
    }
    
    return _forgetBtn;
}
- (UIButton *)registeBtn {
    
    if (!_registeBtn) {
        
        _registeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _registeBtn.titleLabel.font = [UIFont systemFontOfSize:18.f];
        // Label
#if JiaMiTong
        
        [_registeBtn setTitle:_T(@"新用户注册") forState:UIControlStateNormal];
#else
        
        [_registeBtn setTitle:_T(@"设置初始密码") forState:UIControlStateNormal];
#endif
        
        // Label color
        [_registeBtn setTitleColor:OLYMHEXCOLOR(0x008eff) forState:UIControlStateNormal];
        [_registeBtn setTitleColor:[UIColor darkGrayColor] forState:UIControlStateHighlighted];
        
    }
    
    return _registeBtn;
}

//-(LoginViewModel *)loginViewModel{
//    if(!_loginViewModel){
//        _loginViewModel = [[LoginViewModel alloc]init];
//        _loginViewModel.actionType = Login;
//    }
//    return _loginViewModel;
//}

@end
