//
//  ChatFileViewController.m
//  MJT_APP
//
//  Created by Donny on 2017/9/11.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "ChatFileViewController.h"
#import "ChatFileCell.h"
#import "ChatFileViewModel.h"
#import "OLYMUserObject.h"
#import "OLYMMessageObject.h"
#import "FileOpenVC.h"
#import "GJCUImageBrowserViewController.h"
#import "OLYMMoviePlayerViewController.h"

#define ChatFileCellIdentify @"ChatFileCellIdentify"
#define UICollectionReusableViewIdentifier @"UICollectionReusableViewIdentifier"


@interface ChatFileViewController ()<UICollectionViewDelegateFlowLayout,UICollectionViewDataSource>

@property(nonatomic,strong) UICollectionViewFlowLayout *layout;
@property(nonatomic,strong) UICollectionView *collectionView;

// 返回按钮
@property (nonatomic, strong) UIBarButtonItem *backBtn;

@property (nonatomic, strong) ChatFileViewModel *chatFileViewModel;

@end

@implementation ChatFileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

-(void)viewWillAppear:(BOOL)animated{
    
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}


- (void)olym_addSubviews{
    [self createSubview];
}

- (void)olym_bindViewModel{
    @weakify(self);
}

- (void)olym_layoutNavigation{
    switch (_operationFileType) {
        case 0:
        {

            [self setStrNavTitle:_T(@"聊天文件")];

        }
            break;
        case 1:
        {

            [self setStrNavTitle:_T(@"选择文件")];

        }
            break;
            
        default:
            break;
    }

}


#pragma mark -  Action
-(void)back{
    
    if (_operationFileType == ReadFile) {
        
        [self.navigationController popViewControllerAnimated:YES];
    }else{
        
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    
}


#pragma mark <------------------- UICollectionViewDataSource ------------------->

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    
    return self.chatFileViewModel.dataArray.count;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    
    NSArray *array = self.chatFileViewModel.dataArray[section];
    
    return array.count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    ChatFileCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:ChatFileCellIdentify forIndexPath:indexPath];
    
    NSArray *array = self.chatFileViewModel.dataArray[indexPath.section];
    OLYMMessageObject *fileObj = array[indexPath.row];
    
    cell.fileObj = fileObj;
    
    return cell;
}

//  四周缩进
- ( UIEdgeInsets )collectionView:( UICollectionView *)collectionView layout:( UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:( NSInteger )section {
    
    return UIEdgeInsetsMake ( 15, 15 , 15 , 15 );
}

//  返回头视图
- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    
    //如果是头视图
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        UICollectionReusableView *header = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:UICollectionReusableViewIdentifier forIndexPath:indexPath];
        //添加头视图的内容
        UILabel *headerLabel = [[UILabel alloc]init];
        headerLabel.frame = CGRectMake( 0, 0, CGRectGetWidth([UIScreen mainScreen].bounds), 30);
        headerLabel.font = [UIFont systemFontOfSize:16];
        headerLabel.backgroundColor = OLYMHEXCOLOR(0xefefef);
        NSArray *array = self.chatFileViewModel.dataArray[indexPath.section];
        OLYMMessageObject *fileObj = array[0];
        
        //格式转换
        NSDateFormatter *formater = [[NSDateFormatter alloc] init];
        formater.dateFormat = @"yyyy-MM-dd HH:mm:ss";
        NSDate *dateStr = fileObj.timeSend;
        
        NSString *fileDate = [self.chatFileViewModel compareDate:dateStr];
        headerLabel.text = [NSString stringWithFormat:@"   %@",fileDate];
        
        //头视图添加view
        [header addSubview:headerLabel];
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

#pragma mark <------------------- UICollectionViewDelegate ------------------->

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    
    NSArray *array = self.chatFileViewModel.dataArray[indexPath.section];
    OLYMMessageObject *fileObj = array[indexPath.row];
    
    
    NSString *lastPath = [fileObj.filePath lastPathComponent];
    NSString *extension = [lastPath pathExtension];
    NSString *filePath = [[olym_FileCenter documentPrefix]stringByAppendingPathComponent:fileObj.filePath];
    
    switch (_operationFileType) {
        case 0:
        {
            /*
             *  浏览聊天文件
             */
            if ([extension isEqualToString:@"mp4"]) {
                
                //视频的使用播放器
                OLYMMoviePlayerViewController *moviePlayer = [[OLYMMoviePlayerViewController alloc]init];
                moviePlayer.filePath = filePath;
                moviePlayer.isFileEncrypt = fileObj.isAESEncrypt;
                OLYMBaseNavigationController *nav = [[OLYMBaseNavigationController alloc]initWithRootViewController:moviePlayer];
                [self presentViewController:nav animated:YES completion:nil];
                
                 
                
            }else if([extension isEqualToString:@"jpg"] || [extension isEqualToString:@"png"] || [extension isEqualToString:@"gif"]){
                NSString *filePath = [[olym_FileCenter documentPrefix]stringByAppendingString:fileObj.filePath];
                NSInteger index = NSNotFound;
                
                GJCUImageBrowserModel *model = [[GJCUImageBrowserModel alloc]init];
                model.filePath = filePath;
                model.isAESEncrypt = fileObj.isAESEncrypt;
                
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.filePath == %@",filePath];
                NSArray *filterArray = [self.chatFileViewModel.images filteredArrayUsingPredicate:predicate];
                if (filterArray && filterArray.count > 0)
                {
                    index = [self.chatFileViewModel.images indexOfObject:[filterArray lastObject]];
                }
                
                NSArray *images = self.chatFileViewModel.images;
                if (index == NSNotFound)
                {
                    images = [NSArray arrayWithObject:model];
                    index = 0;
                }
                
                GJCUImageBrowserViewController *imageBrowser = [[GJCUImageBrowserViewController alloc]initWithImageModels:images];
                imageBrowser.pageIndex = index;
                imageBrowser.isPresentModelState = YES;
                [self presentViewController:imageBrowser animated:YES completion:nil];

            }else if ([extension isEqualToString:@"txt"] || [extension isEqualToString:@"doc"] || [extension isEqualToString:@"pdf"]){
                
                
                if([[NSFileManager defaultManager] fileExistsAtPath:filePath]){
                    FileOpenVC *mFileOpenVC = [[FileOpenVC alloc]init];
                    [mFileOpenVC setUrlPath:filePath];
                    mFileOpenVC.isFileAESEncrypt = fileObj.isAESEncrypt;
                    [self.navigationController pushViewController:mFileOpenVC animated:YES];
                    
                } else {
                    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"" message:_T(@"文件正在下载中") preferredStyle:UIAlertControllerStyleAlert];


                    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:_T(@"确定") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {

                        
                    }];
                    
                    [alertVC addAction:confirmAction];
                    [self presentViewController:alertVC animated:YES completion:nil];
                }
            }
            
            
            
        }
            break;
        case 1:
        {
            //选择文件发送

            UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:_T(@"提示") message:_T(@"是否发送此文件") preferredStyle:UIAlertControllerStyleAlert];

            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:_T(@"取消") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                
                return ;
            }];
            
            UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:_T(@"确定") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                
                self.pickFilePathBlock(fileObj.filePath,fileObj.fileName,fileObj.fileSize,fileObj.thumbnail,fileObj.isAESEncrypt);
                [self dismissViewControllerAnimated:YES completion:nil];
                
            }];
            
            [alertVC addAction:cancelAction];
            [alertVC addAction:confirmAction];
            [self presentViewController:alertVC animated:YES completion:nil];
            
        }
            break;
        default:
            break;
    }
    
}

-(void)backButtonClicked:(UIButton *)sender{
    
    if (_operationFileType == ReadFile) {
        
        [self.navigationController popViewControllerAnimated:YES];
        
        return;
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}




#pragma mark -  setup 
- (void)createSubview
{
    [self.view addSubview:self.collectionView];
    self.navigationItem.leftBarButtonItem = self.backBtn;
    
    WeakSelf(weakSelf);
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        if (@available(iOS 11, *)) {
            make.edges.mas_equalTo(weakSelf.view.safeAreaInsets);
        }else{
            make.edges.mas_equalTo(weakSelf.view);
        }
    }];
}


#pragma mark <------------------- Getter/Setter ------------------->
-(UICollectionView *)collectionView{
    
    if (!_collectionView) {
        CGFloat WIDTH_SCALE = CGRectGetWidth([UIScreen mainScreen].bounds) / 375.0;
        _layout = [[UICollectionViewFlowLayout alloc]init];
        _layout.minimumLineSpacing = 15;
        _layout.minimumInteritemSpacing = 15;
        _layout.itemSize = CGSizeMake(75 * WIDTH_SCALE, 75 * WIDTH_SCALE);
        
        _collectionView = [[UICollectionView alloc]initWithFrame:self.view.frame collectionViewLayout:_layout];;
        
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        
        _collectionView.backgroundColor = [UIColor whiteColor];
        
        [_collectionView registerClass:[ChatFileCell class] forCellWithReuseIdentifier:ChatFileCellIdentify];
        
        [_collectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:UICollectionReusableViewIdentifier];
        
    }
    
    return _collectionView;
}

// 返回按钮
- (UIBarButtonItem *)backBtn {
    
    if (!_backBtn) {
        
#if ThirdlyVersion
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(0, 0, 35, 35);
        [button setImage:[UIImage imageNamed:@"back"] forState:UIControlStateNormal];
        [button setImage:[UIImage imageNamed:@"back_pre"] forState:UIControlStateHighlighted];
        [button addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
        button.imageEdgeInsets = UIEdgeInsetsMake(0, -20, 0, 0);
        _backBtn = [[UIBarButtonItem alloc]initWithCustomView:button];
#else
        
        _backBtn = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"return"] style:UIBarButtonItemStylePlain target:self action:@selector(back)];
#endif
    }
    
    return _backBtn;
}


- (ChatFileViewModel *)chatFileViewModel
{
    if (!_chatFileViewModel) {
        _chatFileViewModel = [[ChatFileViewModel alloc]initWithUser:self.currentChatUser];
    }
    return _chatFileViewModel;
}

@end
