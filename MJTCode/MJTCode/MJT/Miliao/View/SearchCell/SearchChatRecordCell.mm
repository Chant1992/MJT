//
//  SearchChatRecordCell.m
//  MJT_APP
//
//  Created by Donny on 2017/12/18.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "SearchChatRecordCell.h"
#import "OLYMUserObject.h"
#import "OLYMMessageObject.h"
#import "UIView+Layer.h"

@interface SearchChatRecordCell ()

@property(nonatomic,strong) UIImageView *headerImageView;
@property(nonatomic,strong) UILabel *nickNameLabel;
@property(nonatomic,strong) UILabel *contentLabel;

@end


@implementation SearchChatRecordCell

-(void)setUserObj:(OLYMUserObject *)userObj{
    
    _userObj = userObj;
    self.nickNameLabel.text = userObj.userNickname;
    if (self.searchResults.count > 1)
    {
        self.contentLabel.text = [NSString stringWithFormat:@"%ld条相关聊天记录",self.searchResults.count];
    }else
    {
        OLYMMessageObject *messageObject = [self.searchResults firstObject];
        [self setSearchKeywordWithBlueColor:messageObject.content];
    }
    [self getHeaderImage];
    
}


-(void)setSearchKeywordWithBlueColor:(NSString *)string{
    
    NSMutableAttributedString *attrDescribeStr = [[NSMutableAttributedString alloc] initWithString:string];
    
    [attrDescribeStr addAttribute:NSForegroundColorAttributeName                            value:Global_Theme_Color
                            range:[string rangeOfString:self.searchKeyword]];
    
    self.contentLabel.attributedText = attrDescribeStr;
}



-(void)getHeaderImage{
    
    //如果userHead没有url 就重新拼接一个（搜索好友的时候都没有userHead）
    NSString *userHeader = nil;
    if(_userObj.userHead){
        userHeader = _userObj.userHead;
    }else{
        userHeader = [HeaderImageUtils getHeaderImageUrl:_userObj.userId withDomain:_userObj.domain];
    }
#if MJTDEV
    [self.headerImageView setImageUrl:userHeader withDefault:@"defaultheadv3"];
#else
    [self.headerImageView setImageUrl:userHeader withDefault:@"default_head"];
#endif
}


- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        
        [self createSubViews];
    }
    
    return self;
}

-(void)createSubViews{
    
    [self.contentView addSubview:self.headerImageView];
    [self.contentView addSubview:self.nickNameLabel];
    [self.contentView addSubview:self.contentLabel];
    
    WeakSelf(ws);
    
    [_headerImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.top.mas_equalTo(ws.contentView.mas_top).offset(8);
        make.left.mas_equalTo(ws.contentView.mas_left).offset(10);
        make.width.height.mas_equalTo(50);
        make.bottom.mas_equalTo(ws.contentView.mas_bottom).offset(-8);
    }];
 
    
    [_nickNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(ws.headerImageView.mas_top).offset(2);
        make.left.mas_equalTo(ws.headerImageView.mas_right).offset(10);
        make.right.mas_equalTo(ws.contentView).offset(-15);
        make.height.mas_equalTo(20);
    }];
    [_contentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.mas_equalTo(ws.headerImageView.mas_bottom).offset(-2);
        make.left.mas_equalTo(ws.nickNameLabel.mas_left);
        make.right.mas_equalTo(ws.contentView).offset(-5);
        make.height.mas_equalTo(20);
    }];
  

}
#pragma mark 《$ ---------------- Getter ---------------- $》

- (UIImageView *)headerImageView {
    
    if (!_headerImageView) {
        
        _headerImageView = [[UIImageView alloc] init];
        [_headerImageView setLayerCornerRadius:25 borderWidth:0 borderColor:nil];
    }
    
    return _headerImageView;
}

- (UILabel *)nickNameLabel {
    
    if (!_nickNameLabel) {
        _nickNameLabel = [[UILabel alloc] init];
    }
    
    return _nickNameLabel;
}

- (UILabel *)contentLabel {
    
    if (!_contentLabel) {
        
        _contentLabel = [[UILabel alloc] init];
        _contentLabel.font = [UIFont systemFontOfSize:14];
        _contentLabel.textColor = kSubContentColor;
        [_contentLabel setText:@"这是内容"];
    }
    
    return _contentLabel;
}


@end
