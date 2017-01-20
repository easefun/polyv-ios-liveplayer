//
//  PLVTableViewCell.m
//  PolyvIJKLivePlayer
//
//  Created by ftao on 2017/1/9.
//  Copyright © 2017年 easefun. All rights reserved.
//

#import "PLVTableViewCell.h"

@interface PLVTableViewCell ()

@end

@implementation PLVTableViewCell

+ (instancetype)theMessageGongGaoTextCell {
    return [[NSBundle mainBundle] loadNibNamed:@"PLVTableViewCell" owner:nil options:nil][3];
}

+ (instancetype)theMessageStateCell {
    return [[NSBundle mainBundle] loadNibNamed:@"PLVTableViewCell" owner:nil options:nil][2];
}

+ (instancetype)theMessageOtherTextCellWithTableView:(UITableView *)tableView {
    static NSString *ReuseIdentifier = @"OtherMessageCell";
    PLVTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ReuseIdentifier];
    if (!cell) {
        cell = [[NSBundle mainBundle] loadNibNamed:@"PLVTableViewCell" owner:nil options:nil][0];
    }
    return cell;
}

+ (instancetype)theMessageOwnTextCellWithTableView:(UITableView *)tableView {
    static NSString *ReuseIdentifier = @"OwnMessageCell";
    PLVTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ReuseIdentifier];
    if (!cell) {
        cell = [[NSBundle mainBundle] loadNibNamed:@"PLVTableViewCell" owner:nil options:nil][1];
    }
    return cell;
}

//- (void)setUser:(User *)user {
//    _user = user;
//    
//    _nickNameLable.text = user.nickName;
//    //_avatarImageView.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:user.nickImg]]];
//}

//- (void)setMessageContent:(NSString *)messageContent {
//    _messageContent = messageContent;
//    
//    _contentLabel.text = messageContent;
//}

//- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
//    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
//    if (self) {
//        self.backgroundColor = [UIColor clearColor];
//        self.selectionStyle = UITableViewCellSelectionStyleNone;
//    }
//    return self;
//}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end

/*
@implementation PLVMessageTextCell

- (UIImageView *)avatarImageView {
    if (!_avatarImageView) {
        _avatarImageView = [[UIImageView alloc]initWithFrame:CGRectMake(10, 10, 34, 34)];
        [self.contentView addSubview:_avatarImageView];
        //_avatarImageView.image = [UIImage imageNamed:@"plv_missing_face"];
        //设置圆角
        _avatarImageView.layer.cornerRadius = 17.0;
        _avatarImageView.layer.masksToBounds = YES;
    }
    return _avatarImageView;
}

- (UILabel *)nickNameLable {
    if (!_nickNameLable) {
        _nickNameLable = [[UILabel alloc]initWithFrame:CGRectMake(60, 5, CGRectGetWidth(self.frame)-120, 15)];
        [self.contentView addSubview:_nickNameLable];
        _nickNameLable.font = [UIFont systemFontOfSize:11.0];
        _nickNameLable.textColor = [UIColor grayColor];
        //_nickNameLable.backgroundColor = [UIColor colorWithRed:247/255.0 green:162/255.0 blue:120/255.0 alpha:1];
    }
    return _nickNameLable;
}

- (UILabel *)contentLabel {
    if (!_contentLabel) {
        _contentLabel = [[UILabel alloc]initWithFrame:CGRectMake(60, 25, CGRectGetWidth(self.frame)-120, 50)];
        [self.contentView addSubview:_contentLabel];
        _contentLabel.textColor = [UIColor grayColor];
        _contentLabel.backgroundColor = [UIColor whiteColor];
        //_contentLabel.backgroundColor =  [UIColor colorWithRed:200/255.0 green:233/255.0 blue:160/255.0 alpha:1];
        
        //设置行数，这里很重要，0意味着行数自适应
        _contentLabel.numberOfLines = 0;
        
        //设置字体
        _contentLabel.font = [UIFont systemFontOfSize:14.5];
    }
    
    // 根据cell重新调整label的高度
    CGRect labelRect = _contentLabel.frame;
    labelRect.size.height = CGRectGetHeight(self.frame)-25;
    _contentLabel.frame = labelRect;
    
    return _contentLabel;
}

@end

@implementation PLVMyMessagetextCell

@end
 */
