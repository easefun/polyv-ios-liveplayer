//
//  PLVUserTableViewCell.h
//  IJKLivePlayer
//
//  Created by ftao on 11/01/2018.
//  Copyright © 2018 easefun. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PLVUserTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *avatarView;
@property (weak, nonatomic) IBOutlet UILabel *nicknameLB;
@property (weak, nonatomic) IBOutlet UILabel *actorLB; // 用户头衔

@property (weak, nonatomic) IBOutlet UIImageView *linkMicTypeView;
@property (weak, nonatomic) IBOutlet UILabel *linkMicStatusLB;

@property (nonatomic, strong) NSDictionary *userInfo;
@property (nonatomic, strong) NSString *linkMicType;

@end
