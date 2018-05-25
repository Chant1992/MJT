//
//  GroupMemberViewController.m
//  MJT_APP
//
//  Created by olymtech on 2017/9/14.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "GroupMemberViewController.h"
#import "GroupPersonView.h"
#import "OLYMRoomDataObject.h"
#import "AlertViewManager.h"
#import "ChatViewController.h"

@interface GroupMemberViewController ()

@property(retain,nonatomic) GroupPersonView  *groupPersonView;
@property(retain,nonatomic) GroupMemberModel *groupMemberModel;

@end

@implementation GroupMemberViewController

-(instancetype)initWithArray:(NSArray *)memberArray withType:(PersonSelectType)type{
    self = [super init];
    if(self){
        self.type = type;
        self.groupMemberModel = [[GroupMemberModel alloc]initWithType:type withMemberArray:memberArray];
    }
    return self;
}

-(instancetype)initWithType:(PersonSelectType)type{
    self = [super init];
    if(self){
        self.type = type;
        self.groupMemberModel = [[GroupMemberModel alloc]initWithType:type];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

-(void)olym_layoutNavigation{

    [self setStrNavTitle:_T(@"选择联系人")];
#if ThirdlyVersion
    
    [self setLeftButtonWithImageName:@"back" bgImageName:@"back_pre"];
#else
    
    [self setLeftButtonWithImageName:@"title-icon-back" bgImageName:nil];
#endif
    [self setRightButtonWithTitle:_T(@"确定")];
    
//    [self setLeftButtonWithTitle:_T(@"取消")];
}

-(void)leftButtonPressed:(UIButton *)sender{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)rightButtonPressed:(UIButton *)sender{
    
    OLYMRoomDataObject *roomDataObject = [self.groupMemberModel getSumbitRoomDataObject];
    roomDataObject.roomJid = self.currentRoomJid;
    roomDataObject.roomId = self.currentRoomId;
    if (roomDataObject.roomMembersArray.count <= 0)
    {
        [SVProgressHUD showInfoWithStatus:_T(@"请至少选择一个联系人")];
        return;
    }
    if(self.type == groupPersonSelectTypeNew){
        //防止多次点击建群
//        sender.userInteractionEnabled = NO;
        //只选择一个人直接进入单聊，2人以上则建群
        if(roomDataObject.roomMembersArray.count <= 1)
        {
            [self dismissViewControllerAnimated:YES completion:nil];
            OLYMUserObject *userObj = [roomDataObject.roomMembersArray lastObject];
            ChatViewController *chatViewController = [[ChatViewController alloc]init];
            chatViewController.currentChatUser = userObj;
            if ([self.delegate respondsToSelector:@selector(groupMemberViewController:willEnterChatController:)])
            {
                [self.delegate groupMemberViewController:self willEnterChatController:chatViewController];
            }

        }else
        {
            [self.groupMemberModel createNewRoom];
        }
        
        //加入提示框
        /*FIXME:仿微信，新建不需要自定义群组名称
        NSString *roomName = [self.groupMemberModel generatorRoomName:roomDataObject.roomMembersArray];
        UIAlertController *alertViewController = [AlertViewManager alertWithTitle:@"群名称" message:nil actionTitles:@[NSLocalizedString(@"cancel", nil),@NSLocalizedString(@"sure", nil)] textFieldHandler:^(UITextField *textField) {
            textField.text = roomName;
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldTextDidChange:) name:UITextFieldTextDidChangeNotification object:textField];

        } actionHandler:^(UIAlertAction *action, NSUInteger index) {
            if (index == 1)
            {
                [self.groupMemberModel createNewRoom];
            }
        }];
        [self.navigationController presentViewController:alertViewController animated:YES completion:NULL];
         */
        return;
    }else if(self.type == groupPersonSelectTypeSilence)
    {
        [self showSlienceAlert:roomDataObject];
    }
    //确保群ID一定获取到了
    if(!self.currentRoomId){
        return;
    }
    
    switch (self.type) {
        case groupPersonSelectTypeInvite:
            roomDataObject.userId = self.currentRoomOwnerId;
            [self.groupMemberModel.invateMemberCommond execute:@{@"room":roomDataObject}];
            break;
        case groupPersonSelectTypeDelete:
            [self.groupMemberModel.deleteMemberCommond execute:@{@"room":roomDataObject,@"roomUser":self.currentChatUser}];
            break;
        default:
            break;
    }
}

-(void)olym_addSubviews{
    [self.view addSubview:self.groupPersonView];
    WeakSelf(ws);
    
    [self.groupPersonView mas_makeConstraints:^(MASConstraintMaker *make) {
        if (@available(iOS 11, *)) {
            make.edges.mas_equalTo(ws.view.safeAreaInsets);
        }else{
            make.edges.mas_equalTo(ws.view);
        }
    }];
    
}
-(void)olym_bindViewModel{
    @weakify(self);

    [self.groupMemberModel.refreshEndSubject subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        
        [self dismissViewControllerAnimated:YES completion:nil];

        //TODO:如果是创新新群，跳转进群聊页面
        if(self.type == groupPersonSelectTypeNew){
            NSLog(@"跳转进群聊页面");
            OLYMUserObject *roomUser = x;
            ChatViewController *chatViewController = [[ChatViewController alloc]init];
            chatViewController.currentChatUser = roomUser;
            if ([self.delegate respondsToSelector:@selector(groupMemberViewController:willEnterChatController:)])
            {
                [self.delegate groupMemberViewController:self willEnterChatController:chatViewController];
            }
            
            return;
        }

    }];
    
    [self.groupMemberModel.membersCountRACSubject subscribeNext:^(NSNumber *count) {
        @strongify(self);
        
        NSString *string = [NSString stringWithFormat:@"%@(%@)",_T(@"确定"),count];
        [self setRightButtonWithTitle:string];
    }];
    
}


- (void)showSlienceAlert:(OLYMRoomDataObject *)roomDataObject
{
    NSArray *titles = @[
                        _T(@"禁言1天"),
                        _T(@"禁言3天"),
                        _T(@"禁言1周"),
                        _T(@"禁言1月"),
                        _T(@"永久禁言")];
    NSArray *slienceDays = @[@1,@3,@7,@30,@3000];
    [AlertViewManager actionSheettWithTitle:nil message:nil actionNumber:titles.count actionTitles:titles actionHandler:^(UIAlertAction *action, NSUInteger index) {
        NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
        NSInteger time = [[slienceDays objectAtIndex:index]integerValue] * 24 * 3600 + now;
        [self.groupMemberModel slienceRoomUser:roomDataObject timeInterval:time];

    } cancleTitle:_T(@"取消禁言") cancleActionHandler:^(UIAlertAction *action, NSUInteger index) {
        [self.groupMemberModel slienceRoomUser:roomDataObject timeInterval:0];
    }];
}


#pragma mark - UITextField Notification
-(void)textFieldTextDidChange:(NSNotification *)noti{
    
    UITextField *textField = noti.object;
    
    if (textField.text.length > 18) {
        
        textField.text = [textField.text substringWithRange:NSMakeRange(0, 17)];
    }
    
}


-(GroupPersonView *)groupPersonView{
    if(!_groupPersonView){
        _groupPersonView = [[GroupPersonView alloc]initWithViewModel:self.groupMemberModel];
    }
    
    return _groupPersonView;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
