//
//  NewFriendListView.m
//  MJT_APP
//
//  Created by olymtech on 2017/9/4.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "NewFriendListView.h"
#import "NewFriendModel.h"
#import "NewFriendViewCell.h"
#import "OLYMNewFriendObj.h"
#import "AlertViewManager.h"
#import "OLYMUserObject.h"
#import "UIButton+IndexPath.h"

@interface NewFriendListView ()

@property(strong,nonatomic) NewFriendModel *friendModel;


@end


@implementation NewFriendListView


- (instancetype)initWithViewModel:(id<OLYMViewModelProtocol>)viewModel {
    self.friendModel = (NewFriendModel *)viewModel;
    return [super initWithViewModel:viewModel];
}

- (void)updateConstraints {
    
    WeakSelf(weakSelf);
    
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(weakSelf);
    }];
    
    [super updateConstraints];
}

#pragma mark - private
- (void)olym_setupViews {
    
    [self addSubview:self.tableView];
    [self setNeedsUpdateConstraints];
    [self updateConstraintsIfNeeded];
    
    WeakSelf(weakSelf);
    
    self.tableView.backgroundColor = white_color;
    [self.tableView registerClass:[NewFriendViewCell class] forCellReuseIdentifier:[NSString stringWithUTF8String:object_getClassName([NewFriendViewCell class])]];
  
}

- (void)olym_bindViewModel {
    
    [self addNotifacationObserver];
    
    @weakify(self);
    [self.friendModel.refreshUI subscribeNext:^(id x) {
        @strongify(self);
        [self.tableView reloadData];
    }];
    
    [[olym_Nofity rac_addObserverForName:kXMPPNewFriendNotifaction object:nil] subscribeNext:^(NSNotification * _Nullable x) {
        
        [self processNewFriendObj:x];
        
    }];

    
    [self.friendModel.addNewFriendSubject subscribeNext:^(id x) {
        @strongify(self);
        
        
    }];
}

-(void)processNewFriendObj:(NSNotification *)notification{
    
    dispatch_async(dispatch_get_main_queue(), ^{
      
#if ThirdlyVersion
        
        [self.friendModel.refreshDataSubject sendNext:nil];
        return ;
#else
        
#endif
        OLYMNewFriendObj *newFriedObj = notification.object;
        
        if(newFriedObj){
            //如果在列表中
            for(int i = 0 ; i < self.friendModel.dataArray.count ; i ++){
                OLYMNewFriendObj *friedObj = [self.friendModel.dataArray objectAtIndex:i];
                if([friedObj.userId isEqualToString:newFriedObj.userId]
                   && [friedObj.domain isEqualToString:newFriedObj.domain]){
                    
                    [self.friendModel.dataArray replaceObjectAtIndex:i withObject:newFriedObj];
                    
                    NSIndexPath *reloadPath = [NSIndexPath indexPathForRow:i inSection:0];
                    
                    [self.tableView beginUpdates];
                    [self.tableView reloadRowsAtIndexPaths:@[reloadPath] withRowAnimation:UITableViewRowAnimationNone];
                    [self.tableView endUpdates];
                    
                    return;
                }
            }
            //如果不在列表中
            [self.friendModel.dataArray addObject:newFriedObj];
            
            [self.tableView reloadData];
        }
    });
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
#if ThirdlyVersion
    
    return 2;
#else
    
    return 1;
#endif
    
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
#if ThirdlyVersion
    
    if (section == 0) return self.friendModel.recentlyFriends.count;
    
    return self.friendModel.beforeFriends.count;
#else
    
    return self.friendModel.dataArray.count;
#endif
    

}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
#if ThirdlyVersion
    
    NewFriendViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[NSString stringWithUTF8String:object_getClassName([NewFriendViewCell class])] forIndexPath:indexPath];
    
    OLYMNewFriendObj *newFriendObj = [self.friendModel.dataArray objectAtIndex:indexPath.row];
    
    [cell setFriendObj:newFriendObj];
    cell.indexPath = indexPath;
//    [cell.sayHiButton addTarget:self action:@selector(sayHiAcction:) forControlEvents:UIControlEventTouchUpInside];
    
    return cell;
#else
    
    NewFriendViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[NSString stringWithUTF8String:object_getClassName([NewFriendViewCell class])] forIndexPath:indexPath];
    
    int row = indexPath.row;
    
    [cell setButtonActionTarget:self];
    [cell setTag:row];
    
    OLYMNewFriendObj *newFriendObj = [self.friendModel.dataArray objectAtIndex:row];
    
    [cell setFriendObj:newFriendObj];
    
    return cell;
#endif

}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return 66.0f;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    
#if ThirdlyVersion
    return 22;
#else
    
    return 0;
#endif
    
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    
#if ThirdlyVersion
    
    UIView *view = [[UIView alloc]initWithFrame:CGRectMake(0, 0, GJCFSystemScreenWidth, 22)];
    view.backgroundColor = kTableViewBackgroundColor;
    
    UILabel *label = [[UILabel alloc]init];
    label.font = [UIFont systemFontOfSize:14];
    if (section == 0) {
        
        label.text = @"近七天";
    }else{
        
        label.text = @"七天前";
    }
    
    [view addSubview:label];
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.edges.mas_equalTo(UIEdgeInsetsMake(0, 10, 0, 0));
    }];
    
    return view;
#else
    
    return nil;
#endif
    

}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [self.friendModel.cellClickSubject sendNext:indexPath];
}

#pragma mark - 按钮响应事件
-(void)sayHiAcction:(UIButton *)button{
    
#if ThirdlyVersion
    NSIndexPath *indexpath = button.indexPath;
    
    OLYMNewFriendObj *newFriendObj = nil;
    if (indexpath.section == 0) {
        
        newFriendObj = self.friendModel.recentlyFriends[indexpath.row];
    }else{
        
        newFriendObj = self.friendModel.beforeFriends[indexpath.row];
    }
    
    //打招呼按钮被点击
    [self.friendModel.waitVerificationBtnSubject sendNext:newFriendObj];
#else
    
    int buttonTag = button.tag;
    OLYMNewFriendObj *newFriendObj = [self.friendModel.dataArray objectAtIndex:buttonTag];
    __weak typeof (newFriendObj) weakFriendObj = newFriendObj;

    UIAlertController *replyAlertController = [UIAlertController alertControllerWithTitle:_T(@"打招呼") message:nil preferredStyle:UIAlertControllerStyleAlert];

    [replyAlertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.text = _T(@"您好,能加个好友吗?");
    }];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:_T(@"取消") style:UIAlertActionStyleDefault handler:nil];

    UIAlertAction *okAction = [UIAlertAction actionWithTitle:_T(@"确定") style:UIAlertActionStyleDefault handler:^(UIAlertAction*action) {

        OLYMUserObject *userObject = [[OLYMUserObject alloc]init];
        [userObject setUserId:weakFriendObj.userId];
        [userObject setDomain:weakFriendObj.domain];

        if ([userObject isFriend])
        {
            [SVProgressHUD showInfoWithStatus:_T(@"你们已经是好友")];
            return;
        }
        NSString *replyText = replyAlertController.textFields.firstObject.text;

        [weakFriendObj generaMessage:replyText withType:XMPP_TYPE_SAYHELLO];

    }];

    [replyAlertController addAction:cancelAction];
    [replyAlertController addAction:okAction];

    [[UIApplication sharedApplication].delegate.window.rootViewController presentViewController:replyAlertController animated:YES completion:nil];
#endif

}

-(void)replyAction:(UIButton *)button{
   
    int buttonTag = button.tag;
    OLYMNewFriendObj *newFriendObj = [self.friendModel.dataArray objectAtIndex:buttonTag];
    __weak typeof (newFriendObj) weakFriendObj = newFriendObj;
   
    UIAlertController *replyAlertController = [UIAlertController alertControllerWithTitle:_T(@"回复") message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    [replyAlertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.text = _T(@"请问您是?");
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:_T(@"取消") style:UIAlertActionStyleDefault handler:nil];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:_T(@"确定") style:UIAlertActionStyleDefault handler:^(UIAlertAction*action) {
        
        NSString *replyText = replyAlertController.textFields.firstObject.text;
        
        [weakFriendObj generaMessage:replyText withType:XMPP_TYPE_FEEDBACK];
        
    }];
    
    [replyAlertController addAction:cancelAction];
    [replyAlertController addAction:okAction];
    
    [[UIApplication sharedApplication].delegate.window.rootViewController presentViewController:replyAlertController animated:YES completion:nil];
}

-(void)acceptAction:(UIButton *)button{
    
    int buttonTag = button.tag;
    [self.friendModel.addNewFriendCommand execute:@(buttonTag)];
    
}

#pragma mark - 监听消息到来通知
-(void)addNotifacationObserver{
    @weakify(self);
    
    [[olym_Nofity rac_addObserverForName:kXMPPNewMsgNotifaction object:nil] subscribeNext:^(NSNotification *notification){
        @strongify(self);
        
    }];
    
    [[olym_Nofity rac_addObserverForName:kXMPPRefreshMsgListNotifaction object:nil] subscribeNext:^(NSNotification *notification){
        @strongify(self);
        
    }];
}


@end
