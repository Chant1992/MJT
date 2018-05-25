//
//  ChatDocumentCell.m
//  MJT_APP
//
//  Created by Donny on 2017/12/26.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "ChatDocumentCell.h"
#import "OLYMMessageObject.h"
#import "TimeUtil.h"

@interface ChatDocumentCell ()

@property (nonatomic, strong) UIImageView *iconImageView;

@property (nonatomic, strong) UILabel *nameLabel;

@property (nonatomic, strong) UILabel *fileSizeLabel;

@property (nonatomic, strong) UILabel *timeLabel;

@property (nonatomic, strong) UIImageView *checkImageView;

@end

@implementation ChatDocumentCell


- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self createSubviews];
    }
    return self;
}

- (void)createSubviews
{
    [self.contentView addSubview:self.iconImageView];
    [self.contentView addSubview:self.nameLabel];
    [self.contentView addSubview:self.fileSizeLabel];
    [self.contentView addSubview:self.timeLabel];
    
    WeakSelf(weakSelf);
    [self.iconImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(10);
        make.bottom.mas_equalTo(-10);
        make.left.mas_equalTo(15);
        make.width.mas_equalTo(weakSelf.iconImageView.mas_height);
    }];
    
    [self.nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(weakSelf.iconImageView.mas_top).offset(6);
        make.left.mas_equalTo(weakSelf.iconImageView.mas_right).offset(14);
        make.height.mas_equalTo(20);
    }];
    
    [self.fileSizeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(weakSelf.nameLabel.mas_bottom).offset(6);
        make.left.mas_equalTo(weakSelf.nameLabel.mas_left);
        make.height.mas_equalTo(11);
    }];
    
    [self.timeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(weakSelf.fileSizeLabel.mas_bottom).offset(10);
        make.left.mas_equalTo(weakSelf.nameLabel.mas_left);
        make.height.mas_equalTo(11);

    }];
}



- (void)setFileObj:(OLYMMessageObject *)fileObj
{
    _fileObj = fileObj;
    NSString *lastPath = _fileObj.filePath;
    
    NSString *extension = [lastPath pathExtension];
    UIImage *iconImage;
    if ([extension hasPrefix:@"doc"]) {
        //word
        iconImage = [UIImage imageNamed:@"Word"];
    }else if ([extension hasPrefix:@"ppt"])
    {
        //ppt
        iconImage = [UIImage imageNamed:@"PPT"];

    }else if ([extension hasPrefix:@"xls"])
    {
        //excel
        iconImage = [UIImage imageNamed:@"Excel"];

    }else if ([extension isEqualToString:@"pdf"])
    {
        //pdf
        iconImage = [UIImage imageNamed:@"PDF"];

    }else if([extension isEqualToString:@"zip"] || [extension isEqualToString:@"tar"])
    {
        //压缩包
        iconImage = [UIImage imageNamed:@"tar"];
    }else
    {
        //其他
        iconImage = [UIImage imageNamed:@"otherDoc"];
    }

    self.iconImageView.image = iconImage;
    self.nameLabel.text = self.fileObj.fileName;
    self.fileSizeLabel.text = [self transformedfileSize:self.fileObj.fileSize];
    self.timeLabel.text = [TimeUtil getDateStr:[self.fileObj.timeSend timeIntervalSince1970]];
    

}

- (id)transformedfileSize:(CGFloat)filesize {
    
    double convertedValue = filesize;
    int multiplyFactor = 0;
    
    NSArray *tokens = [NSArray arrayWithObjects:@"bytes",@"KB",@"MB",@"GB",@"TB",nil];
    
    while (convertedValue > 1024) {
        convertedValue /= 1024;
        multiplyFactor++;
    }
    
    return [NSString stringWithFormat:@"%4.0f %@",convertedValue, [tokens objectAtIndex:multiplyFactor]];
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

#pragma mark - 修改选择框图标
- (void)layoutSubviews
{
    for (UIControl *control in self.subviews)
    {
        if ([control isKindOfClass:NSClassFromString(@"UITableViewCellEditControl")])
        {
            for (UIView *v in control.subviews)
            {
                if ([v isKindOfClass:[UIImageView class]])
                {
                    if (v.tag == 10086)
                    {
                        self.checkImageView.frame = CGRectMake((control.frame.size.width - 30)/2.0, (control.frame.size.height - 30)/2.0, 30, 30);
                        if (!self.selected) {
                            self.checkImageView.image = [UIImage imageNamed:@"cell_uncheck"]; //未选中
                        }else
                        {
                            self.checkImageView.image = [UIImage imageNamed:@"cell_check"]; //选中
                        }
                        
                    }else
                    {
                        v.hidden = YES;
                    }
                }
            }
        }
        
    }
    [super layoutSubviews];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    for (UIControl *control in self.subviews)
    {
        if ([control isKindOfClass:NSClassFromString(@"UITableViewCellEditControl")])
        {
            UIView *checkView = [control viewWithTag:10086];
            if(checkView)
            {
                for (UIView *v in control.subviews)
                {
                    if ([v isKindOfClass:[UIImageView class]])
                    {
                        if (v.tag == 10086)
                        {
                            if (!self.selected) {
                                self.checkImageView.image = [UIImage imageNamed:@"cell_uncheck"]; //未选中
                            }
                        }else
                        {
                            v.hidden = YES;
                        }
                    }
                }
            }else
            {
                [control addSubview:self.checkImageView];
            }
            break;
        }
        
    }
}



#pragma mark - property
- (UIImageView *)iconImageView
{
    if (!_iconImageView) {
        _iconImageView = [[UIImageView alloc]init];
    }
    return _iconImageView;
}
- (UIImageView *)checkImageView
{
    if (!_checkImageView) {
        _checkImageView = [[UIImageView alloc]init];
        _checkImageView.tag = 10086;
    }
    return _checkImageView;
}

- (UILabel *)nameLabel
{
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc]init];
        _nameLabel.textColor = OLYMHEXCOLOR(0x333333);
        _nameLabel.font = [UIFont systemFontOfSize:17];
        _fileSizeLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _nameLabel;
}

- (UILabel *)fileSizeLabel
{
    if (!_fileSizeLabel) {
        _fileSizeLabel = [[UILabel alloc]init];
        _fileSizeLabel.textColor = OLYMHEXCOLOR(0x777777);
        _fileSizeLabel.font = [UIFont systemFontOfSize:13];
        _fileSizeLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _fileSizeLabel;

}

- (UILabel *)timeLabel
{
    if (!_timeLabel) {
        _timeLabel = [[UILabel alloc]init];
        _timeLabel.textColor = OLYMHEXCOLOR(0x777777);
        _timeLabel.font = [UIFont systemFontOfSize:13];
        _timeLabel.textAlignment = NSTextAlignmentLeft;

    }
    return _timeLabel;

}
@end
