//
//  UITableView+IndexTip.m
//  MJT_APP
//
//  Created by Chant on 2017/12/29.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "UITableView+IndexTip.h"
#import "UIView+Layer.h"

@implementation OLYMTableIndexManager
-(UILabel *)indexTipLabel{
    if(!_indexTipLabel){
        
        _indexTipLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 40, 40)];
        _indexTipLabel.font = [UIFont systemFontOfSize:30];
        _indexTipLabel.textAlignment = NSTextAlignmentCenter;
        _indexTipLabel.textColor = white_color;
        _indexTipLabel.backgroundColor = Global_Theme_Color;
        _indexTipLabel.hidden = YES;
        [_indexTipLabel setLayerCornerRadius:20 borderWidth:0 borderColor:nil];
    }
    return _indexTipLabel;
}

- (UIImpactFeedbackGenerator *)generator {
    if (!_generator) {
        _generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
    }
    return _generator;
}

@end

@interface UITableView ()
@property(strong,nonatomic) OLYMTableIndexManager * manager;
@end

@implementation UITableView (IndexTip)

-(void)addIndexTipLabel:(NSArray *)indexArray dataTitleArray:(NSArray *)dataTitleArray{
    
    if (!self.manager) {
        self.manager = [[OLYMTableIndexManager alloc]init];
    }
    self.manager.indexArray = indexArray;
    self.manager.dataTitleArray = dataTitleArray;
    [self performSelector:@selector(addPanGesture) withObject:nil afterDelay:0.1];

}

-(void)addPanGesture{
    
    for (UIView *view in self.subviews) {
        
        if ([view isKindOfClass:NSClassFromString(@"UITableViewIndex")]) {
            
            view.gestureRecognizers = nil;
            UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(indexTitlesPan:)];
            [view addGestureRecognizer:pan];
            
//            CGPoint center = CGPointZero;
//            center.x = -(self.frame.size.width - 15)/2.0;
//            center.y = view.frame.size.height/2.0;
//            //添加索引提示视图到UITableViewIndex上
//            self.manager.indexTipLabel.center = center;
            
            [view addSubview:self.manager.indexTipLabel];
        }
    }
}

-(void)indexTitlesPan:(UIPanGestureRecognizer *)pan{
    
    CGFloat indexHeight = self.manager.indexArray.count * 14.5;
    CGFloat bottomHeight = 0;
    CGFloat tableviewHeight = self.gjcf_height;
    if (tableviewHeight > 720) {
        //tabbar隐藏的时候，iPhone X 底部会有空隙
        bottomHeight = 37.333;
    }
    
    NSInteger tableHeaderHeight = self.tableHeaderView? 0 : 25;
    
    CGFloat startY = (tableviewHeight - indexHeight - bottomHeight)/2 + tableHeaderHeight;
    CGFloat locationY = [pan locationInView:pan.view].y ;
    NSInteger seleteIndex = (locationY - startY)/14;
    
    if (seleteIndex < 0) {
        
        seleteIndex = 0;
    }else if(seleteIndex > self.manager.indexArray.count - 1){
        
        seleteIndex = self.manager.indexArray.count - 1;
    }
    
    NSString *touchTitle = self.manager.indexArray[seleteIndex];
    
    for (NSInteger i = 0; i < self.manager.dataTitleArray.count; i++) {
        
        NSString *myTitle = self.self.manager.dataTitleArray[i];
        if ([myTitle isEqualToString:touchTitle]) {
            
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:i];
            [self scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
            
        }
    }
    
    self.manager.indexTipLabel.hidden = NO;
    if (seleteIndex == 0 && touchTitle.length > 1) {
        //放大镜的时候不显示文字
        self.manager.indexTipLabel.text = self.manager.indexArray[1];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        [self scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }else{
        
        if (![self.manager.indexTipLabel.text isEqualToString:touchTitle]) {
            //字母不一样了才移动动画
            CGFloat y = locationY;
            self.manager.indexTipLabel.frame =  CGRectMake(-65, seleteIndex * 14 - 7 + startY, 40, 40);
            self.manager.indexTipLabel.text = touchTitle;
            if (@available(iOS 10.0, *)) {
                [self.manager.generator prepare];
                [self.manager.generator impactOccurred];
            }
        }
    }
    
    if (pan.state == UIGestureRecognizerStateEnded) {
        
        self.manager.indexTipLabel.hidden = YES;
    }else{
        
        self.manager.indexTipLabel.hidden = NO;
    }
    
}

- (void)setManager:(OLYMTableIndexManager *)manager
{
    [self willChangeValueForKey:NSStringFromSelector(@selector(manager))];
    objc_setAssociatedObject(self, @selector(manager), manager, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self didChangeValueForKey:NSStringFromSelector(@selector(manager))];
}

- (OLYMTableIndexManager *)manager
{
    return objc_getAssociatedObject(self, _cmd);
}

-(NSArray *)getAllIndexArray{
    
    NSMutableArray *resultArray =[NSMutableArray arrayWithObject:UITableViewIndexSearch];
    // acsii码 A-Z  65开始
    for (NSInteger  i = 'A'; i <= 'Z'; i++)
    {
        int asciiCode = i;
        NSString *title = [NSString stringWithFormat:@"%c",asciiCode];
        [resultArray addObject:title];
    }
    [resultArray addObject:@"#"];
    
    return resultArray;
}
@end
