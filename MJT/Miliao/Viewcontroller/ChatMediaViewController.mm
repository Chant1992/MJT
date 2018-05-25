//
//  ChatMediaViewController.m
//  MJT_APP
//
//  Created by Donny on 2017/12/26.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "ChatMediaViewController.h"
#import "ChatFileViewModel.h"
#import "ChatFileCell.h"
#import "OLYMHeaderFlowLayout.h"
#import "TableEditView.h"
#import "RecentlyChatListViewController.h"
#import "UIScrollView+EmptyDataSet.h"
#import "AlertViewManager.h"

#define InputPanelBottomMargin (GJCFSystemiPhoneX ? 34 : 0)

@interface ChatMediaViewController ()<UICollectionViewDelegateFlowLayout,UICollectionViewDataSource,DZNEmptyDataSetSource, DZNEmptyDataSetDelegate>

@property(nonatomic,strong) OLYMHeaderFlowLayout *layout;
@property(nonatomic,strong) UICollectionView *collectionView;

@property (nonatomic, strong) TableEditView *editView;

@property (nonatomic,assign) BOOL editing;

@end

@implementation ChatMediaViewController

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
    [self createSubview];
}


- (void)olym_layoutNavigation
{
    
}


- (void)olym_bindViewModel
{
    [self.chatFileViewModel getImageAndVideoFiles];
    [self.collectionView reloadData];
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
    [tmpRightButton addTarget:self action:@selector(rightButtonAction1) forControlEvents:UIControlEventTouchUpInside];

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

- (void)rightButtonAction1
{
    if (self.editing)
    {
        //退出编辑模式
        [self setRightItem:NO];
        [self showEitingView:NO];
        [self.editView setAllSelected:NO];
    }else
    {
        //进入编辑模式
        [self setRightItem:YES];
        [self showEitingView:YES];
    }
    [self.collectionView reloadData];
    self.editing = !self.editing;
}

- (void)reserveState
{
    if (!self.showEdit)
    {
        return;
    }
    [self setRightItem:self.editing];
    [self showEitingView:self.editing];
}


- (void)selectAllFiles
{
    if ([self checkIfAllSelected])
    {
        //全不选
        [_editView setEdit:NO];
        [self.collectionView reloadData];
    }else
    {
        //全选
        [_editView setEdit:YES];
        for (int i = 0; i < [self.collectionView numberOfSections]; i++)
        {
            for (int j = 0; j < [self.collectionView numberOfItemsInSection:i]; j++)
            {
                [self.collectionView selectItemAtIndexPath:[NSIndexPath indexPathForRow:j inSection:i] animated:YES scrollPosition:UICollectionViewScrollPositionNone];
            }
        }
    }
}

- (void)deleteSelectedFiles
{
    [self.chatFileViewModel deleteSelectedImageAndVideos:self.collectionView.indexPathsForSelectedItems];
    [self.collectionView reloadData];
}

- (void)forwardSelectedFiles
{
    NSArray *messages = [self.chatFileViewModel messagesForSelectedRows:self.collectionView.indexPathsForSelectedItems dataSource:self.chatFileViewModel.imageVideos];
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
    NSInteger section = [self.collectionView numberOfSections];
    for (int i = 0; i < section; i++)
    {
        for (int j = 0; j < [self.collectionView numberOfItemsInSection:i]; j++)
        {
            total ++;
        }
    }
    if (self.collectionView.indexPathsForSelectedItems)
    {
        if (total == self.collectionView.indexPathsForSelectedItems.count) {
            return YES;
        }
    }
    
    return NO;
}


#pragma mark <------------------- UICollectionViewDataSource ------------------->
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    
    return self.chatFileViewModel.imageVideos.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    
    NSDictionary *dict = [self.chatFileViewModel.imageVideos objectAtIndex:section];
    NSArray *fileMessages = [dict objectForKey:@"files"];
    return fileMessages.count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    ChatFileCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([ChatFileCell class]) forIndexPath:indexPath];
    cell.checkView.hidden = !self.editing;
    
    NSDictionary *dict = [self.chatFileViewModel.imageVideos objectAtIndex:indexPath.section];
    NSArray *fileMessages = [dict objectForKey:@"files"];
    OLYMMessageObject *fileObj = fileMessages[indexPath.row];
    
    cell.fileObj = fileObj;
    
    return cell;
}

//  四周缩进
- ( UIEdgeInsets )collectionView:( UICollectionView *)collectionView layout:( UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:( NSInteger )section {
    
    return UIEdgeInsetsMake ( 5, 0 , 5 , 0 );
}

//  返回头视图
- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    
    //如果是头视图
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        UICollectionReusableView *header = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:NSStringFromClass([UICollectionReusableView class]) forIndexPath:indexPath];
        header.backgroundColor = [UIColor whiteColor];
        UILabel *headerLabel = [header viewWithTag:10086];
        if (!headerLabel)
        {
            headerLabel = [[UILabel alloc]init];
            headerLabel.frame = CGRectMake(15, 0, CGRectGetWidth([UIScreen mainScreen].bounds), 30);
            headerLabel.font = [UIFont systemFontOfSize:14];
            headerLabel.textColor = OLYMHEXCOLOR(0x7b7b7b);
            headerLabel.tag = 10086;
            //头视图添加view
            [header addSubview:headerLabel];
        }
        
        NSDictionary *dict = [self.chatFileViewModel.imageVideos objectAtIndex:indexPath.section];
        NSString *time = [dict objectForKey:@"time"];
        headerLabel.text = time;

        return header;
    }
    //如果底部视图
    //    if([kind isEqualToString:UICollectionElementKindSectionFooter]){
    //
    //    }
    return nil;
}

//组视图size
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section{
    
    return CGSizeMake( CGRectGetWidth([UIScreen mainScreen].bounds), 30);
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

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

#pragma mark <------------------- UICollectionViewDelegate ------------------->

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.editing)
    {
        BOOL checked = [self checkIfAllSelected];
        [self.editView setAllSelected:checked];
        [_editView setEdit:YES];
        return;
    }

    NSDictionary *dict = [self.chatFileViewModel.imageVideos objectAtIndex:indexPath.section];
    NSArray *fileMessages = [dict objectForKey:@"files"];
    OLYMMessageObject *fileObj = fileMessages[indexPath.row];
    
    [self.chatFileViewModel.cellClickSubject sendNext:fileObj];

}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    //
    if (self.editing)
    {
        BOOL checked = [self checkIfAllSelected];
        [self.editView setAllSelected:checked];
        if (!self.collectionView.indexPathsForSelectedItems || self.collectionView.indexPathsForSelectedItems.count == 0)
        {
            [_editView setEdit:NO];
        }
        return;
    }
}


#pragma mark -  setup
- (void)createSubview
{
    if (self.showEdit)
    {
        [self setRightItem:NO];
    }
    [self.view addSubview:self.collectionView];
    [self.view addSubview:self.editView];
    WeakSelf(weakSelf);
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        if (@available(iOS 11, *)) {
            make.edges.mas_equalTo(weakSelf.view.safeAreaInsets);
        }else{
            make.edges.mas_equalTo(weakSelf.view);
        }
    }];
    [self.editView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.height.mas_equalTo((50+InputPanelBottomMargin));
        make.bottom.equalTo(self.view).offset(50+InputPanelBottomMargin);
    }];

}


#pragma mark <------------------- Getter/Setter ------------------->
-(UICollectionView *)collectionView{
    
    if (!_collectionView) {
        CGFloat WIDTH_SCALE = CGRectGetWidth([UIScreen mainScreen].bounds) / 375.0;
        _layout = [[OLYMHeaderFlowLayout alloc]init];
        _layout.naviHeight = 0;
        _layout.minimumLineSpacing = 5;
        _layout.minimumInteritemSpacing = 1;
        _layout.itemSize = CGSizeMake(92 * WIDTH_SCALE, 92 * WIDTH_SCALE);
        
        _collectionView = [[UICollectionView alloc]initWithFrame:self.view.frame collectionViewLayout:_layout];;
        
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        
        _collectionView.emptyDataSetSource = self;
        _collectionView.emptyDataSetDelegate = self;
        
        _collectionView.backgroundColor = [UIColor whiteColor];
        _collectionView.allowsMultipleSelection = YES;
        [_collectionView registerClass:[ChatFileCell class] forCellWithReuseIdentifier:NSStringFromClass([ChatFileCell class])];
        
        [_collectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:NSStringFromClass([UICollectionReusableView class])];
        
    }
    
    return _collectionView;
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
