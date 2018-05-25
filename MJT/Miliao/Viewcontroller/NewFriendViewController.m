//
//  NewFriendViewController.m
//  MJT_APP
//
//  Created by olymtech on 2017/9/4.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "NewFriendViewController.h"
#import "NewFriendListView.h"
#import "NewFriendModel.h"

@interface NewFriendViewController ()

@property (strong,nonatomic) NewFriendListView *mainView;

@property (retain,nonatomic) NewFriendModel *friendModel;

@end

@implementation NewFriendViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (void)olym_addSubviews{
    [self.view addSubview:self.mainView];
    WeakSelf(weakSelf);
    [self.mainView mas_makeConstraints:^(MASConstraintMaker *make) {
        if (@available(iOS 11, *)) {
            make.edges.mas_equalTo(weakSelf.view.safeAreaInsets);
        }else{
            make.edges.mas_equalTo(weakSelf.view);
        }
    }];
}

-(void)olym_bindViewModel{
    @weakify(self);
    [[self.friendModel.cellClickSubject takeUntil:self.rac_willDeallocSignal] subscribeNext:^(id x) {
        
        @strongify(self);
        int index = [x row];
        
    }];
}

-(void)olym_layoutNavigation{
    [self setStrNavTitle:_T(@"新的朋友")];
}
#pragma mark - layzLoad
- (NewFriendListView *)mainView {
    
    if (!_mainView) {
        
        _mainView = [[NewFriendListView alloc] initWithViewModel:self.friendModel];
    }
    
    return _mainView;
}

- (NewFriendModel *)friendModel {
    
    if (!_friendModel) {
        
        _friendModel = [[NewFriendModel alloc] init];
    }
    
    return _friendModel;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
