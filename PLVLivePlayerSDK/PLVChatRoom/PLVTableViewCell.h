//
//  PLVTableViewCell.h
//  PolyvIJKLivePlayer
//
//  Created by ftao on 2017/1/9.
//  Copyright © 2017年 easefun. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PLVTableViewCell : UITableViewCell

// other message
@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UILabel *nickNameLable;
@property (weak, nonatomic) IBOutlet UILabel *contentLabel;

// my messgae
@property (weak, nonatomic) IBOutlet UILabel *mySpeakLabel;

// 聊天室状态
@property (weak, nonatomic) IBOutlet UILabel *roomStateLabel;

// 聊天室公告
@property (weak, nonatomic) IBOutlet UILabel *roomGongGaoLabel;

//@property (nonatomic, strong) Speaker *speaker;
//@property (nonatomic, strong) NSString *messageContent;

/** 初始化聊天室公告样式的cell*/
+ (instancetype)theMessageGongGaoTextCell;

/** 初始化聊天室状态（打开或关闭）样式的cell*/
+ (instancetype)theMessageStateCell;

/** 初始化其他发言者发言样式的cell*/
+ (instancetype)theMessageOtherTextCellWithTableView:(UITableView *)tableView;

/** 初始化自己发言样式的cell*/
+ (instancetype)theMessageOwnTextCellWithTableView:(UITableView *)tableView;


@end


///** 文本聊天内容样式一*/
//@interface PLVMessageTextCell : PLVTableViewCell
//
//@property (nonatomic, strong) UILabel *nickNameLable;       // 用户昵称
//@property (nonatomic, strong) UILabel *contentLabel;        // 聊天内容
//@property (nonatomic, strong) UIImageView *avatarImageView; // 用户头像
//
//@end
//
//
///** 文本聊天内容样式二*/
//@interface PLVMyMessagetextCell : PLVTableViewCell
//
//
//@end
