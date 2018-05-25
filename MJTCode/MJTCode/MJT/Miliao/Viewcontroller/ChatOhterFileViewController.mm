//
//  ChatOhterFileViewController.m
//  MJT_APP
//
//  Created by Donny on 2017/12/26.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "ChatOhterFileViewController.h"
#import "ChatFileViewModel.h"
#import "OLYMMessageObject.h"
#import "FileOpenVC.h"
#import "ChatDocumentCell.h"
#import "TableEditView.h"
#import "RecentlyChatListViewController.h"
#import "UIScrollView+EmptyDataSet.h"
#import "AlertViewManager.h"

#define InputPanelBottomMargin (GJCFSystemiPhoneX ? 34 : 0)

@interface ChatOhterFileViewController ()<UITableViewDataSource,UITableViewDelegate,DZNEmptyDataSetSource, DZNEmptyDataSetDelegate>

@property (nonatomic, strong) UITableView *documentTableView;


@property (nonatomic, strong) TableEditView *editView;

@end

@implementation ChatOhterFileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)olym_addSubviews
{
    [self.view addSubview:self.documentTableView];
    [self.view addSubview:self.editView];
    if (self.showEdit)
    {
        [self setRightItem:NO];
    }
    
    WeakSelf(weakSelf);
    [self.documentTableView mas_makeConstraints:^(MASConstraintMaker *make) {
        if (@available(iOS 11, *)) {
            make.top.mas_equalTo(weakSelf.view.safeAreaInsets.top);
        }else{
            make.top.mas_equalTo(weakSelf.view);
        }
        make.left.right.equalTo(self.view);
        make.bottom.equalTo(self.editView.mas_top);
    }];
    [self.editView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.height.mas_equalTo((50+InputPanelBottomMargin));
        make.bottom.equalTo(self.view).offset(50+InputPanelBottomMargin);
    }];


}
- (void)olym_bindViewModel
{
    [self.chatFileViewModel getDocumentFiles];
    [self.documentTableView reloadData];
}

- (void)olym_layoutNavigation
{
    
}



- (void)showEitingView:(BOOL)isShow{
    [self.editView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view).offset(isShow?0:50+InputPanelBottomMargin);
    }];
    [UIView animateWithDuration:0.3 animations:^{
        [self.view layoutIfNeeded];
    }];
}

- (void)setRightItem:(BOOL)editing
{
    UIButton *tmpRightButton = [UIButton buttonWithType:UIButtonTypeCustom];
    tmpRightButton.frame = CGRectMake(self.view.frame.size.width-35-10, 0, 40, 35);
    tmpRightButton.showsTouchWhenHighlighted = NO;
    tmpRightButton.exclusiveTouch = YES;
    
    [tmpRightButton addTarget:self action:@selector(rightButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [tmpRightButton.titleLabel setFont:[UIFont systemFontOfSize:16.0]];
    [tmpRightButton setTitleColor:Global_Theme_Color forState:UIControlStateNormal];
    [tmpRightButton addTarget:self action:@selector(rightButtonAction) forControlEvents:UIControlEventTouchUpInside];
    
    if (editing)
    {
        [tmpRightButton setTitle:_T(@"取消") forState:UIControlStateNormal];
        UIBarButtonItem *rightItem = [[UIBarButtonItem alloc]initWithCustomView:tmpRightButton];
        self.mParentController.navigationItem.rightBarButtonItem = rightItem;
    }else
    {
        [tmpRightButton setTitle:_T(@"选择") forState:UIControlStateNormal];
        UIBarButtonItem *rightItem = [[UIBarButtonItem alloc]initWithCustomView:tmpRightButton];
        self.mParentController.navigationItem.rightBarButtonItem = rightItem;
    }
}

- (void)rightButtonAction
{
    if (self.documentTableView.editing)
    {
        //退出编辑模式
        [self.documentTableView setEditing:NO animated:YES];
        [self setRightItem:NO];
        [self showEitingView:NO];
        [self.editView setAllSelected:NO];
    }else
    {
        //进入编辑模式
        [self.documentTableView setEditing:YES animated:YES];
        [self setRightItem:YES];
        [self showEitingView:YES];
    }
}

- (void)reserveState
{
    if(!self.showEdit)
    {
        return;
    }
    [self setRightItem:self.documentTableView.editing];
    [self showEitingView:self.documentTableView.editing];
}


- (void)selectAllFiles
{
    if ([self checkIfAllSelected])
    {
        //全不选
        [_editView setEdit:NO];
        [self.documentTableView reloadData];
    }else
    {
        //全选
        [_editView setEdit:YES];
        for (int i = 0; i < [self.documentTableView numberOfSections]; i++)
        {
            for (int j = 0; j < [self.documentTableView numberOfRowsInSection:i]; j++)
            {
                [self.documentTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:j inSection:i] animated:NO scrollPosition:UITableViewScrollPositionNone];
            }
        }
    }
}

- (void)deleteSelectedFiles
{
    [self.chatFileViewModel deleteSelectedDocuments:self.documentTableView.indexPathsForSelectedRows];
    [self.documentTableView reloadData];
}

- (void)forwardSelectedFiles
{
    NSArray *messages = [self.chatFileViewModel messagesForSelectedRows:self.documentTableView.indexPathsForSelectedRows dataSource:self.chatFileViewModel.otherFiles];
    RecentlyChatListViewController *controller = [[RecentlyChatListViewController alloc]init];
    if (messages.count == 1)
    {
        controller.messageObj = [messages firstObject];
    }else
    {
        controller.forwardMessages = messages;
    }
    OLYMBaseNavigationController *nav = [[OLYMBaseNavigationController alloc]initWithRootViewController:controller];
    [self.mParentController presentViewController:nav animated:YES completion:nil];
}

- (BOOL)checkIfAllSelected
{
    NSInteger total = 0;
    NSInteger section = [self.documentTableView numberOfSections];
    for (int i = 0; i < section; i++)
    {
        for (int j = 0; j < [self.documentTableView numberOfRowsInSection:i]; j++)
        {
            total ++;
        }
    }
    if (self.documentTableView.indexPathsForSelectedRows)
    {
        if (total == self.documentTableView.indexPathsForSelectedRows.count) {
            return YES;
        }
    }
    
    return NO;
}

#pragma mark - UITableView Delegate & DataSource
- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView.editing)
    {
        BOOL checked = [self checkIfAllSelected];
        [self.editView setAllSelected:checked];
        if (!self.documentTableView.indexPathsForSelectedRows || self.documentTableView.indexPathsForSelectedRows.count == 0) {
            [_editView setEdit:NO];
        }
        return;
    }
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView.editing)
    {
        BOOL checked = [self checkIfAllSelected];
        [self.editView setAllSelected:checked];
        [_editView setEdit:YES];
        return;
    }
    NSDictionary *dict = [self.chatFileViewModel.otherFiles objectAtIndex:indexPath.section];
    NSArray *fileMessages = [dict objectForKey:@"files"];
    OLYMMessageObject *message = [fileMessages objectAtIndex:indexPath.row];
    [self.chatFileViewModel.cellClickSubject sendNext:message];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.chatFileViewModel.otherFiles.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSDictionary *dict = [self.chatFileViewModel.otherFiles objectAtIndex:section];
    NSArray *fileMessages = [dict objectForKey:@"files"];
    return fileMessages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ChatDocumentCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([ChatDocumentCell class]) forIndexPath:indexPath];
    NSDictionary *dict = [self.chatFileViewModel.otherFiles objectAtIndex:indexPath.section];
    NSArray *fileMessages = [dict objectForKey:@"files"];
    OLYMMessageObject *message = [fileMessages objectAtIndex:indexPath.row];
    cell.fileObj = message;
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UITableViewHeaderFooterView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:NSStringFromClass([UITableViewHeaderFooterView class])];
    headerView.backgroundColor = [UIColor whiteColor];
    headerView.contentView.backgroundColor = [UIColor whiteColor];
    UILabel *headerLabel = [headerView viewWithTag:10086];
    if (!headerLabel)
    {
        headerLabel = [[UILabel alloc]init];
        headerLabel.frame = CGRectMake(15, 0, CGRectGetWidth([UIScreen mainScreen].bounds), 30);
        headerLabel.font = [UIFont systemFontOfSize:14];
        headerLabel.textColor = OLYMHEXCOLOR(0x7b7b7b);
        headerLabel.tag = 10086;
        //头视图添加view
        [headerView addSubview:headerLabel];
    }
    
    NSDictionary *dict = [self.chatFileViewModel.otherFiles objectAtIndex:section];
    NSString *time = [dict objectForKey:@"time"];
    headerLabel.text = time;
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 91;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 30;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return (UITableViewCellEditingStyle)(UITableViewCellEditingStyleInsert | UITableViewCellEditingStyleDelete);
}

/*
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return self.canDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        NSDictionary *dict = [self.chatFileViewModel.otherFiles objectAtIndex:indexPath.section];
        NSArray *fileMessages = [dict objectForKey:@"files"];
        OLYMMessageObject *message = [fileMessages objectAtIndex:indexPath.row];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSString *fullPath = [self.chatFileViewModel absoluteFilePathfrom:message];
            [FileCenter deleteFile:fullPath];
        });
        
        //修改数据源
        NSMutableArray *tempArray = [NSMutableArray array];
        [tempArray addObjectsFromArray:fileMessages];
        [tempArray removeObject:message];
        NSMutableDictionary *tmpDict = [NSMutableDictionary dictionary];
        [tmpDict addEntriesFromDictionary:dict];
        [tmpDict setObject:tempArray forKey:@"files"];
        [self.chatFileViewModel.otherFiles replaceObjectAtIndex:indexPath.section withObject:tmpDict];
        
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];

    }
}
 */
- (UIImage *)imageForEmptyDataSet:(UIScrollView *)scrollView
{
    return GJCFQuickImage(@"emptyset");
}

- (CGFloat)verticalOffsetForEmptyDataSet:(UIScrollView *)scrollView
{
    return -self.view.frame.size.height/5.0f;
}

- (NSAttributedString *)descriptionForEmptyDataSet:(UIScrollView *)scrollView
{
    NSString *text = _T(@"暂无数据");
    
    NSMutableParagraphStyle *paragraph = [NSMutableParagraphStyle new];
    paragraph.lineBreakMode = NSLineBreakByWordWrapping;
    paragraph.alignment = NSTextAlignmentCenter;
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont systemFontOfSize:17.0f],
                                 NSForegroundColorAttributeName: [UIColor lightGrayColor],
                                 NSParagraphStyleAttributeName: paragraph};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (CGFloat)spaceHeightForEmptyDataSet:(UIScrollView *)scrollView
{
    return 20.0f;
}

#pragma mark - Property
- (UITableView *)documentTableView
{
    if (!_documentTableView) {
        _documentTableView = [[UITableView alloc]init];
        _documentTableView.estimatedRowHeight = 0;
        _documentTableView.estimatedSectionFooterHeight = 0;
        _documentTableView.estimatedSectionHeaderHeight = 0;
        _documentTableView.delegate = self;
        _documentTableView.dataSource = self;
        _documentTableView.emptyDataSetSource = self;
        _documentTableView.tableFooterView = [UIView new];
        [_documentTableView registerClass:[ChatDocumentCell class] forCellReuseIdentifier:NSStringFromClass([ChatDocumentCell class])];
        [_documentTableView registerClass:[UITableViewHeaderFooterView class] forHeaderFooterViewReuseIdentifier:NSStringFromClass([UITableViewHeaderFooterView class])];
    }
    return _documentTableView;
}

 - (TableEditView *)editView
{
    if (!_editView)
    {
        WeakSelf(weakSelf)
        _editView = [[TableEditView alloc]initWithFrame:CGRectMake(0, 0, GJCFSystemScreenWidth, 50+InputPanelBottomMargin) editType: (TableEditType)(TableEditDeleteType | TableEditForwardType | TableEditAllSelectedType)];
        [_editView setEdit:NO];
        _editView.editViewButtonClick = ^(TableEditType type) {
            if (type == TableEditAllSelectedType)
            {
                //全选
                [weakSelf selectAllFiles];
            }else if (type == TableEditDeleteType)
            {
                //删除
                [AlertViewManager actionSheettWithTitle:nil
                                                message:nil
                                           actionNumber:2
                                           actionTitles:@[@"删除",@"取消"]
                                          actionHandler:^(UIAlertAction *action, NSUInteger index) {
                                              if (index == 0)
                                              {
                                                  [weakSelf deleteSelectedFiles];
                                              }
                                          }];
            }else
            {
                //转发
                [weakSelf forwardSelectedFiles];
            }
        };
    }
    return _editView;
}

@end
