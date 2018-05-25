//
//  GroupInfoView.m
//  MJT_APP
//
//  Created by olymtech on 2017/9/13.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "GroupInfoView.h"
#import "GroupInfoModel.h"
#import "UserInfoCell.h"
#import "UIView+Layer.h"
#import "GroupHeaderView.h"
#import "OLYMUserObject.h"
#import "OLYMRoomDataObject.h"
#import "OLYMMessageObject.h"
#import "AlertViewManager.h"
#import "UIButton+EdgeInsets.h"

@interface GroupInfoView()<GroupHeaderViewDelegate>

@property(strong,nonatomic) GroupInfoModel *groupInfoModel;

@property(strong,nonatomic) OLYMRoomDataObject *roomDataObject;

@property(strong,nonatomic) UIView *headerView;

@property(nonatomic,strong) UIView *tableFootView;
/* 底部按钮 */
@property(nonatomic,strong) UIButton *footerBtn;

@end


@implementation GroupInfoView

- (instancetype)initWithViewModel:(id<OLYMViewModelProtocol>)viewModel {
    self.groupInfoModel = (GroupInfoModel *)viewModel;
    [self.tableView registerClass:[UserInfoCell class] forCellReuseIdentifier:[NSString stringWithUTF8String:object_getClassName([UserInfoCell class])]];
    return [super initWithViewModel:viewModel];
}

- (void)updateConstraints {
    
    WeakSelf(ws);
    
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(ws);
    }];
    
    [self.footerBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(ws.tableFootView.mas_centerY);
        make.left.mas_equalTo(ws.tableFootView).offset(20);
        make.right.mas_equalTo(ws.tableFootView).offset(-20);
        make.height.mas_equalTo(50);
    }];

    [super updateConstraints];
}

- (void)olym_setupViews {
    
    
    self.tableView.tableHeaderView = self.headerView;
    self.tableView.tableFooterView = self.tableFootView;
    
    [self addSubview:self.tableView];
    
    [self.tableFootView addSubview:self.footerBtn];
    
    [self setNeedsUpdateConstraints];
    [self updateConstraintsIfNeeded];
    
}

-(void)olym_bindViewModel{
    @weakify(self);
    [self.groupInfoModel.groupInfoSubject subscribeNext:^(OLYMRoomDataObject *data) {
        @strongify(self);
        
        self.roomDataObject = data;
        
        [self getMemberView];
        
        [self setButtonStyle];
    }];
    
    
    [self.groupInfoModel.groupInfoRefreshSubject subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        self.roomDataObject.name = self.userObject.userNickname;
        self.roomDataObject.note = self.userObject.userDescription;
        self.roomDataObject.myNickName = self.userObject.userRemarkname;
        [self.tableView reloadData];
    }];
    
    //TODO:退出
    [[self.footerBtn rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(__kindof UIControl * _Nullable x) {
        @strongify(self);
        
        BOOL isOwener = NO;
        if([olym_UserCenter.userId isEqualToString:self.roomDataObject.userId]){
            isOwener = YES;
        }else{
            isOwener = NO;
        }
        
        NSString *message = nil;
        
        if(isOwener){

             message = [NSString stringWithFormat:_T(@"确定删除并退出群聊:%@"),self.roomDataObject.name];

        }else{
             message = [NSString stringWithFormat:_T(@"确定退出群聊:%@"),self.roomDataObject.name];
        }
        

        [AlertViewManager alertWithTitle:_T(@"提示") message:message textFieldNumber:0 actionNumber:2 actionTitles:@[_T(@"取消"),_T(@"确定")] textFieldHandler:nil actionHandler:^(UIAlertAction *action, NSUInteger index) {

            
            if(index == 1){
                if(isOwener){
                    [self.groupInfoModel.groupDelRoomCommond execute:self.userObject];
                }else{
                    [self.groupInfoModel.groupQuitRoomCommond execute:self.userObject];
                }
                
            }
            
        }];
    }];
    

    [[olym_Nofity rac_addObserverForName:kInviteUserFromRoomNotifaction object:nil] subscribeNext:^(NSNotification *notification){
        
        @strongify(self);
        
        OLYMUserObject *userObject = notification.object;
        
        [self refreshMemberView:userObject withAdd:YES];
    }];
    

    [[olym_Nofity rac_addObserverForName:kDeleteUserFromRoomNotifaction object:nil] subscribeNext:^(NSNotification *notification){
        
        @strongify(self);
        
        OLYMUserObject *userObject = notification.object;
        
        [self refreshMemberView:userObject withAdd:NO];
    }];
}

-(void)refreshMemberView:(OLYMUserObject *)userObject withAdd:(BOOL)addValue{
    if(addValue){
        [self.groupInfoModel.groupMemberArray addObject:userObject];
    }else{
        for(OLYMUserObject *exitUserObject in self.groupInfoModel.groupMemberArray){
            if([exitUserObject.userId isEqualToString:userObject.userId]){
                [self.groupInfoModel.groupMemberArray removeObject:exitUserObject];
                break;
            }
        }
    }
    [self getMemberView];
}


-(void)setUserObject:(OLYMUserObject *)userObject{
    
    if(!userObject){
        return ;
    }
    _userObject = userObject;
    
    [self.groupInfoModel.groupInfoCommand execute:self.userObject];
}

-(void)setButtonStyle{
    NSString *title = nil;
    if([olym_UserCenter.userId isEqualToString:self.roomDataObject.userId]){
        title = _T(@"删除并退出");
    }else{
        title = _T(@"退出群组");
    }
    [self.footerBtn setTitle:title forState:UIControlStateNormal];
    [self.footerBtn setHidden:NO];
}


-(void)getMemberView{
    
    for (GroupHeaderView *subView in self.headerView.subviews) {
        [subView removeFromSuperview];
    }
    
    NSInteger imageWidth = 60;
    NSInteger numberOfRow = GJCFSystemScreenWidth > 320? 5 : 4;
    NSInteger margin = (GJCFSystemScreenWidth - (numberOfRow * imageWidth)) / (numberOfRow + 1);
    NSInteger imageHeight = 70;
    
    BOOL showCompleted = YES;
    int count = self.groupInfoModel.groupMemberArray.count;
    NSInteger maxowRow = 9;

    int totalViewCount = 0;
    //如果群主就是我
    if([self.roomDataObject.userId isEqualToString:olym_UserCenter.userId]){
        //开放邀请 删除按钮
        totalViewCount = count + 2;
    }else{
        //只开放邀请按钮
        totalViewCount = count + 1;
    }
    if ((1.0 * totalViewCount)/numberOfRow > maxowRow)
    {
        showCompleted = NO;
        if([self.roomDataObject.userId isEqualToString:olym_UserCenter.userId])
        {
            count = maxowRow * numberOfRow - 2;
        }else{
            count = maxowRow * numberOfRow - 1;
        }

    }

    //添加成员头像
    for (NSInteger i = 0; i < totalViewCount; i++) {
        
        NSInteger column = i % numberOfRow;
        
        NSInteger row = i / numberOfRow;
        if (row >= maxowRow) {
            break;
        }

        GroupHeaderView *view = [[GroupHeaderView alloc]initWithFrame:CGRectMake(margin + column * (imageWidth + margin), 15 + row * (imageHeight + 10), imageWidth, imageHeight)];
        
        view.tag = i;
        
        if(i == count)
        {
           [view.headerView setImage:GJCFQuickImage(@"add_message_info_nor")];
        }
        else if(i > count)
        {
           [view.headerView setImage:GJCFQuickImage(@"delete_message_info_nor")];
        }
        else{
            [view setUserObject:[self.groupInfoModel.groupMemberArray objectAtIndex:i]];
//            view.delegate = self;
        }
        
        @weakify(self);
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] init];
        [[tap rac_gestureSignal] subscribeNext:^(UITapGestureRecognizer * tap) {
            @strongify(self);
            GroupHeaderView *view = (GroupHeaderView *)tap.view;
            [self headerViewTapAction:view.tag];
        }];
        [view addGestureRecognizer:tap];
        
        [self.headerView addSubview:view];
    }
    
    NSInteger n =  ceil((totalViewCount * 1.0) /numberOfRow);
    
    //大于9行，显示更多
    if (!showCompleted) {
        UIButton *moreButton = [[UIButton alloc]initWithFrame:CGRectMake(20, maxowRow * 80 + 30, GJCFSystemScreenWidth - 2 * 20, 40)];
        [self.headerView addSubview:moreButton];
        UIImage *arrowImage = [UIImage imageNamed:@"more"];
        arrowImage = [arrowImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        moreButton.tintColor = OLYMHEXCOLOR(0x545454);
        [moreButton setTitle:_T(@"查看更多群成员") forState:UIControlStateNormal];
        [moreButton setImage:arrowImage forState:UIControlStateNormal];
        [moreButton setTitleColor:OLYMHEXCOLOR(0x545454) forState:UIControlStateNormal];
        moreButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        [moreButton horizontalCenterTitleAndImage:20];
        [moreButton addTarget:self action:@selector(showMoreMembersAction) forControlEvents:UIControlEventTouchUpInside];
        self.headerView.frame = CGRectMake(0, 0, GJCFSystemScreenWidth, CGRectGetMaxY(moreButton.frame) + 20);
    }else
    {
        // 80是每一个GroupHeaderView高度 + 上下边距
        // 30是 上下边距 15 + 15
        self.headerView.frame = CGRectMake(0, 0, GJCFSystemScreenWidth, n * 80 + 30);
    }
    [self.tableView reloadData];
    
}

-(void)headerViewTapAction:(int)index{
    int count = self.groupInfoModel.groupMemberArray.count;
    BOOL showCompleted = YES;
    NSInteger maxowRow = 9;
    NSInteger numberOfRow = GJCFSystemScreenWidth > 320? 5 : 4;
    int totalViewCount = 0;
    //如果群主就是我
    if([self.roomDataObject.userId isEqualToString:olym_UserCenter.userId]){
        //开放邀请 删除按钮
        totalViewCount = count + 2;
    }else{
        //只开放邀请按钮
        totalViewCount = count + 1;
    }
    if ((1.0 * totalViewCount)/numberOfRow > maxowRow)
    {
        showCompleted = NO;
        if([self.roomDataObject.userId isEqualToString:olym_UserCenter.userId])
        {
            count = maxowRow * numberOfRow - 2;
        }else{
            count = maxowRow * numberOfRow - 1;
        }
    }

    if(index == count)
    {
        [self.groupInfoModel.groupInviteSubject sendNext:self.roomDataObject.userId];
    }
    else if(index > count)
    {
        if (![self.roomDataObject.userId isEqualToString:olym_UserCenter.userId])
        {
            [AlertViewManager alertWithTitle:_T(@"您不是群主，不能删除群成员")];
            return;
        }
//        [self showHeaderDelete];
        [self.groupInfoModel.groupDeleteSubject sendNext:nil];
    }
    else{
        //显示用户信息
        OLYMUserObject *userObj = [self.groupInfoModel.groupMemberArray objectAtIndex:index];
        NSString *domain = userObj.domain;
        if (!domain)
        {
            domain = FULL_DOMAIN(olym_UserCenter.userDomain);
        }
        [self.groupInfoModel getUserInfoByUserId:userObj.userId domain:domain roomId:self.roomDataObject.roomId];
    }
}

- (void)showMoreMembersAction
{
    [self.groupInfoModel.showMoreMemberSubject sendNext:@{@"user":self.userObject,@"members":self.groupInfoModel,@"roomData":self.roomDataObject}];
}


#pragma mark - 显示用户头像上的删除或者禁言
- (void)showHeaderDelete
{
    for (UIView *subView in self.headerView.subviews)
    {
        if ([subView isKindOfClass:[GroupHeaderView class]])
        {
            if (subView.tag < self.groupInfoModel.groupMemberArray.count)
            {
                //这些是用户
                GroupHeaderView *groupHeaderView = (GroupHeaderView *)subView;
                groupHeaderView.showDelete = !groupHeaderView.showDelete;
            }
        }
    }
}




#pragma mark - GroupHeaderViewDelegate
- (void)groupHeaderViewDidTapDelete:(GroupHeaderView *)view
{
    //删除用户
    if (view.tag >= self.groupInfoModel.groupMemberArray.count)
    {
        return;
    }

    [AlertViewManager actionSheettWithTitle:_T(@"提示") message:_T(@"是否确定踢该成员出群") actionNumber:2 actionTitles:@[_T(@"取消"),_T(@"确定")] actionHandler:^(UIAlertAction *action, NSUInteger index) {

        if (index == 1)
        {
            //删除
            
        }
    }];
}

- (void)groupHeaderViewDidTapBan:(GroupHeaderView *)view
{
    //禁言用户
}

- (UITableViewCell *)cellAtIndexPath:(NSIndexPath *)indexPath
{
    UserInfoCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[NSString stringWithUTF8String:object_getClassName([UserInfoCell class])] forIndexPath:indexPath];
    
    NSArray *content = self.groupInfoModel.dataArray[indexPath.section];
    cell.contentLabel.text = content[indexPath.row];
    
    int section = indexPath.section;
    int row = indexPath.row;
    
    if(section == 0){
        NSString *value = nil;
        if(row == 0){
            value = self.roomDataObject.userNickName;
        }else if(row == 1){
            value = [self.roomDataObject.name stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        }else if(row == 2){
            value = self.roomDataObject.note;
        }else if(row == 3){
            value = [NSString stringWithFormat:@"%d",self.roomDataObject.maxCount];
        }
        cell.detailLabel.text = value;
    }
    
    else if(section == 2){
        if(row == 0){
            cell.detailLabel.text = self.roomDataObject.myNickName;
        }
#if DontDisturb
        else if (row == 2)
        {
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.fingerPrintSwitch.hidden = NO;
            cell.fingerPrintSwitch.on = self.userObject.isDontDisturb;
            @weakify(self);
            [[cell.fingerPrintSwitch rac_signalForControlEvents:UIControlEventValueChanged]subscribeNext:^(__kindof UIControl * _Nullable x) {
                @strongify(self);
                //消息免打扰
                [self.groupInfoModel setChatUser:self.userObject dontDisturb:cell.fingerPrintSwitch.on];
            }];
        }
#endif
    }else{
        cell.detailLabel.text = nil;
    }
    return cell;
}

- (UITableViewCell *)cellForDeveloperAtIndexPath:(NSIndexPath *)indexPath
{
    UserInfoCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[NSString stringWithUTF8String:object_getClassName([UserInfoCell class])] forIndexPath:indexPath];
    
    NSArray *content = self.groupInfoModel.dataArray[indexPath.section];
    cell.contentLabel.text = content[indexPath.row];
    
    int section = indexPath.section;
    int row = indexPath.row;
    if(section == 0){
        NSString *value = nil;
        if(row == 0){
            value = self.roomDataObject.name;
        }else if(row == 1){
            value = self.roomDataObject.note;
        }else if(row == 2){
            value = [NSString stringWithFormat:@"%d",self.roomDataObject.maxCount];
        }
        cell.detailLabel.text = value;
    }
    
    else if(section == 2){
        if(row == 0){
            cell.detailLabel.text = self.roomDataObject.myNickName;
        }
        else if (row == 1)
        {
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.fingerPrintSwitch.hidden = NO;
            cell.fingerPrintSwitch.on = self.userObject.isDontDisturb;
            @weakify(self);
            [[cell.fingerPrintSwitch rac_signalForControlEvents:UIControlEventValueChanged]subscribeNext:^(__kindof UIControl * _Nullable x) {
                @strongify(self);
                //消息免打扰
                [self.groupInfoModel setChatUser:self.userObject dontDisturb:cell.fingerPrintSwitch.on];
            }];
        }
    }else{
        cell.detailLabel.text = nil;
    }

    return cell;
}

#pragma mark - <------------------- UITableViewDataSource ------------------->

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    
    return self.groupInfoModel.dataArray.count;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    return [[self.groupInfoModel.dataArray objectAtIndex:section] count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
#if MJTDEV
    UITableViewCell * cell = [self cellForDeveloperAtIndexPath:indexPath];
#else
    UITableViewCell * cell = [self cellAtIndexPath:indexPath];
#endif
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    return 60;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    
    return 20;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    
    UIView *view = [[UIView alloc]initWithFrame:CGRectMake(0, 0, GJCFSystemScreenWidth, 20)];
    view.backgroundColor = kTableViewBackgroundColor;
    
    return view;
}

#pragma mark - <------------------- UITableViewDelegate ------------------->
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
#if MJTDEV
    [self tableDidSelectActionForDeveloper:indexPath];
#else
    [self tableDidSelectAction:indexPath];
#endif
    
}

- (void)tableDidSelectAction:(NSIndexPath *)indexPath
{
    int section = indexPath.section;
    int row = indexPath.row;
    
    if(section == 0){
        if(row == 1){
            if(![self.roomDataObject.userId isEqualToString:olym_UserCenter.userId])
            {
                
                [SVProgressHUD showInfoWithStatus:_T(@"群主才能修改群名称")];
                return;
            }
            [self.groupInfoModel.groupNameChangeSubject sendNext:nil];
        }else if(row == 2){
            if(![self.roomDataObject.userId isEqualToString:olym_UserCenter.userId])
            {
                [self.groupInfoModel.groupNoteWatchSubject sendNext:self.roomDataObject.note];
                return;
            }
            [self.groupInfoModel.groupNoteChangeSubject sendNext:self.roomDataObject.note];
        }
    }else if(section == 1){
        [self.groupInfoModel.groupFileSubject sendNext:nil];
    }else if(section == 2){
        if(row == 0){
            //我的群昵称
            [self.groupInfoModel.groupMyNickNameSubject sendNext:nil];
        }else if(row == 1){
            if(![self.roomDataObject.userId isEqualToString:olym_UserCenter.userId])
            {
                [SVProgressHUD showInfoWithStatus:_T(@"群主才能禁言")];
                return;
            }
            //禁言
            [self.groupInfoModel.groupSilenceSubject sendNext:nil];
        }
    }else {
        //清除聊天记录
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        
        if(GJCFSystemiPad){
            UIPopoverPresentationController *popPresenter = [alertController
                                                             popoverPresentationController];
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
            popPresenter.sourceView = cell;
            popPresenter.sourceRect = cell.bounds;
        }
        
        
        
        
        [alertController addAction:[UIAlertAction actionWithTitle:_T(@"取消") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            NSLog(@"点击取消");
        }]];
        
        [alertController addAction:[UIAlertAction actionWithTitle:_T(@"清除聊天记录") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            
            NSLog(@"点击确认");
            
            //删除本地聊天记录
            [OLYMMessageObject deleteMessage:self.userObject.userId withDomain:self.userObject.domain];
            //发送通知刷新界面
            [olym_Nofity postNotificationName:kDeleteMessageHistoryNotifaction object:nil];
            
        }]];
        
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alertController animated:YES completion:nil];
    }
}

- (void)tableDidSelectActionForDeveloper:(NSIndexPath *)indexPath
{
    int section = indexPath.section;
    int row = indexPath.row;
    if (section == 0)
    {
        if(row == 0){
            if(![self.roomDataObject.userId isEqualToString:olym_UserCenter.userId])
            {
                
                [SVProgressHUD showInfoWithStatus:_T(@"群主才能修改群名称")];
                return;
            }
            [self.groupInfoModel.groupNameChangeSubject sendNext:nil];
        }else if(row == 1){
            if(![self.roomDataObject.userId isEqualToString:olym_UserCenter.userId])
            {
                [self.groupInfoModel.groupNoteWatchSubject sendNext:self.roomDataObject.note];
                return;
            }
            [self.groupInfoModel.groupNoteChangeSubject sendNext:self.roomDataObject.note];
        }
    }else if (section == 1)
    {
        if (row == 0)
        {
            [self.groupInfoModel.groupFileSubject sendNext:nil];
        }else
        {
            //查看聊天记录
            [self.groupInfoModel.chatRecordClickSubject sendNext:nil];
        }
    }else if (section == 2)
    {
        if(row == 0){
            //我的群昵称
            [self.groupInfoModel.groupMyNickNameSubject sendNext:nil];
        }
    }else if (section == 3)
    {
        //清除聊天记录
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        
        if(GJCFSystemiPad){
            UIPopoverPresentationController *popPresenter = [alertController
                                                             popoverPresentationController];
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
            popPresenter.sourceView = cell;
            popPresenter.sourceRect = cell.bounds;
        }
        
        [alertController addAction:[UIAlertAction actionWithTitle:_T(@"取消") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            NSLog(@"点击取消");
        }]];
        
        [alertController addAction:[UIAlertAction actionWithTitle:_T(@"清除聊天记录") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            
            NSLog(@"点击确认");
            
            //删除本地聊天记录
            [OLYMMessageObject deleteMessage:self.userObject.userId withDomain:self.userObject.domain];
            //发送通知刷新界面
            [olym_Nofity postNotificationName:kDeleteMessageHistoryNotifaction object:nil];
            
        }]];
        
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alertController animated:YES completion:nil];
    }
}


-(OLYMRoomDataObject *)roomDataObject{
    if(!_roomDataObject){
        _roomDataObject = [[OLYMRoomDataObject alloc]init];
    }
    return _roomDataObject;
}


-(UIView *)headerView{
    if(!_headerView){
        _headerView = [[UIView alloc]init];
        [_headerView setBackgroundColor:white_color];
    }
    return _headerView;
}

-(UIView *)tableFootView{
    
    if (!_tableFootView) {
        CGFloat bottomMargin = 0;
        if(IS_IPHONE_X)
        {
            bottomMargin = 34;
        }
        _tableFootView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, GJCFSystemScreenWidth, 80 + bottomMargin)];
    }
    
    return _tableFootView;
}

-(UIButton *)footerBtn{
    
    if (!_footerBtn) {
        
        _footerBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _footerBtn.titleLabel.font = [UIFont systemFontOfSize:16];
        [_footerBtn setHidden:YES];
        [_footerBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_footerBtn setLayerCornerRadius:5 borderWidth:0 borderColor:nil];
        [_footerBtn setBackgroundImage:GJCFQuickImage(@"delete_message_info_btn") forState:UIControlStateNormal];
    }
    
    return _footerBtn;
}

@end
