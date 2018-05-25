//
//  ActivityChatListView.m
//  MJT_APP
//
//  Created by Donny on 2017/11/14.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "ActivityChatListView.h"
#import "ContactFriendCell.h"
#import "RecentlyViewModel.h"

@interface ActivityChatListView ()

@property (nonatomic,strong) RecentlyViewModel *recentlyViewModel;

@end

@implementation ActivityChatListView

- (instancetype)initWithViewModel:(id<OLYMViewModelProtocol>)viewModel {
    self.recentlyViewModel = (RecentlyViewModel *)viewModel;
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
    
    [self.tableView registerClass:[ContactFriendCell class] forCellReuseIdentifier:[NSString stringWithUTF8String:object_getClassName([ContactFriendCell class])]];
    
    //    self.tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
    //        [weakSelf.miliaoViewModel.refreshDataCommand execute:nil];
    //    }];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    OLYMUserObject *user = (OLYMUserObject*) [self.recentlyViewModel.dataArray objectAtIndex:indexPath.row];
    [self.recentlyViewModel.cellClickSubject sendNext:user];
}

#pragma mark - <------------------- UITableViewDateSource ------------------->

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if(section == 0){
        //自定义Header标题
        UIView* myView = [[UIView alloc] init];
        myView.backgroundColor = OLYMHEXCOLOR(0xf2f2f2);
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 90, 22)];
        titleLabel.textColor= [UIColor blackColor];
        
        titleLabel.text = _T(@"最近聊天");
        titleLabel.font = [UIFont systemFontOfSize:14];
        titleLabel.textColor = [UIColor lightGrayColor];
        [myView  addSubview:titleLabel];
        
        return myView;
    }
    return nil;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    return 70.0f;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    
    return 22;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.recentlyViewModel.dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if(indexPath.section == 0){
        ContactFriendCell *cell = [tableView dequeueReusableCellWithIdentifier:[NSString stringWithUTF8String:object_getClassName([ContactFriendCell class])] forIndexPath:indexPath];
        cell.addButton.hidden = YES;
        
        OLYMUserObject *user = (OLYMUserObject*) [self.recentlyViewModel.dataArray objectAtIndex:indexPath.row];
        NSString *remarkName = user.userNickname;
        
        if(remarkName && ![remarkName isEqualToString:@""]){
            cell.nickNameLabel.text = remarkName;
        }else{
            cell.nickNameLabel.text = user.telephone;
        }
        if (user.roomFlag == 1)
        {
            //群聊
            [cell.iconView setImage:[UIImage imageNamed:@"chat_groups_header"]];
        }else
        {
            NSString *userHeaderUrl =  [HeaderImageUtils getHeaderImageUrl:user.userId withDomain:user.domain];
            [cell.iconView setImageUrl:userHeaderUrl withDefault:@"chat_groups_header"];
        }
        
        return cell;
    }
    return nil;
}


@end
