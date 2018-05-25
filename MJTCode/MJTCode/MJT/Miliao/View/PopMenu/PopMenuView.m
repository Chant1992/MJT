//
//  PopMenuView.m
//  MJT_APP
//
//  Created by olymtech on 2017/9/12.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "PopMenuView.h"
#import "PopMenuCell.h"

@interface PopMenuView () <UITableViewDelegate, UITableViewDataSource>

// 背景
@property (nonatomic, strong) UIImageView *bgImgView;

@end
@implementation PopMenuView

- (instancetype)init {
    
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        [self createSubViews];
        
#if ThirdlyVersion
        
        if (ScanLogin) {
            
            self.sourceArr = @[@{@"icon":@"nav_creatgroup_nor", @"title":_T(@"发起群聊")},
                               @{@"icon":@"nav_addfriend_nor", @"title":_T(@"添加朋友")},
                               @{@"icon":@"scan", @"title":_T(@"扫一扫")}];
        }else{
            
            self.sourceArr = @[@{@"icon":@"nav_creatgroup_nor", @"title":_T(@"发起群聊")},
                               @{@"icon":@"nav_addfriend_nor", @"title":_T(@"添加朋友")}];
        }

#else
        
        self.sourceArr = @[@{@"icon":@"pop_btn_addgroup_nor", @"title":_T(@"发起群聊")}, @{@"icon":@"pop_btn_addfriend_nor", @"title":_T(@"添加朋友")}];
#endif

    }
    
    return self;
    
}

#pragma mark 《$ ---------------- CreateSubViews ---------------- $》
- (void)createSubViews {
    
    [self addSubview:self.bgImgView];
    [self.bgImgView addSubview:self.containList];
    
    WeakSelf(ws);
    [_bgImgView mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.edges.equalTo(ws);
    }];
    [_containList mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.top.equalTo(ws.bgImgView.mas_top).offset(10);
        make.left.equalTo(ws.bgImgView.mas_left).offset(5);
        make.right.equalTo(ws.bgImgView.mas_right).offset(-5);
        make.bottom.equalTo(ws.bgImgView.mas_bottom).offset(-5);
    }];
}

#pragma mark 《$ ---------------- UITableViewProtocol ---------------- $》
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return _sourceArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSDictionary *sourceDict = _sourceArr[indexPath.row];
    
    PopMenuCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PopMenuCell" forIndexPath:indexPath];
    
    [cell setItemIcon:sourceDict[@"icon"] title:sourceDict[@"title"]];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if(self.delegate){
        [self.delegate popViewCellClick:indexPath.row];
    }
}
#pragma mark 《$ ---------------- Setter/Getter ---------------- $》
- (UIImageView *)bgImgView {
    
    if (!_bgImgView) {
        
        _bgImgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"pop_bubbly"]];
        _bgImgView.userInteractionEnabled = YES;
    }
    
    return _bgImgView;
}
- (UITableView *)containList {
    
    if (!_containList) {
        
        _containList = [[UITableView alloc] initWithFrame:CGRectZero];
        _containList.backgroundColor = [UIColor whiteColor];
        _containList.dataSource = self;
        _containList.delegate = self;
        _containList.showsVerticalScrollIndicator = NO;
        _containList.scrollEnabled = NO;
        _containList.separatorStyle = UITableViewCellSeparatorStyleNone;
        _containList.backgroundColor = [UIColor whiteColor];
        
        [_containList registerClass:[PopMenuCell class] forCellReuseIdentifier:@"PopMenuCell"];
    }
    
    return _containList;
}

- (NSArray *)sourceArr {
    
    if (!_sourceArr) {
        
        _sourceArr = [NSMutableArray array];
    }
    
    return _sourceArr;
}

@end
