//
//  PLVUserTableViewCell.m
//  IJKLivePlayer
//
//  Created by ftao on 11/01/2018.
//  Copyright © 2018 easefun. All rights reserved.
//

#import "PLVUserTableViewCell.h"
#import <SDWebImage/UIImageView+WebCache.h>

#define CAMERA_IMAGE_PATH @"plv-camera"
#define MICPHONE_IMAGE_PATH @"plv-micphone"
#define USER_DEFAULT_IMAGE @"plv_default_user"

@interface PLVUserTableViewCell ()

@end

/// 返回用户头衔
NSString *NameStringWithUserType(NSString *actor, NSString *userType) {
    if (actor && actor.length) {
        return actor;
    }
    if (userType && userType.length) {
        if ([userType isEqualToString:@"teacher"]) {
            return @"讲师";
        }else if ([userType isEqualToString:@"manager"]) {
            return @"管理员";
        }else if ([userType isEqualToString:@"assistant"]) {
            return @"助教";
        //}else if ([userType isEqualToString:@"slice"]) {
        //    return @"云课堂学员";
        //}else if ([userType isEqualToString:@"student"]) {
        //    return @"学生";
        }else {
            return nil;
        }
    }else { // 不存在 userType 字段或为空
        return nil;
    }
}

@implementation PLVUserTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.backgroundColor = [UIColor clearColor];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

#pragma mark - Rewrite

- (void)setUserInfo:(NSDictionary *)userInfo {
    _userInfo = userInfo;
    if (userInfo && [userInfo isKindOfClass:[NSDictionary class]]) {
        NSString *avatarUrl = userInfo[@"pic"];
        if ([avatarUrl hasPrefix:@"//"]) { // 处理"//"类型开头的地址(其他非HTTPS如微信头像、static.live.polyv.net、live.polyv.cn使用原地址)
            avatarUrl = [@"https:" stringByAppendingString:avatarUrl];
        }
        [_avatarView sd_setImageWithURL:[NSURL URLWithString:avatarUrl] placeholderImage:[UIImage imageNamed:USER_DEFAULT_IMAGE]]; // use sdWebImage
        //[self updateAvatarViewWithPicStr:userInfo[@"pic"]];
        _nicknameLB.text = userInfo[@"nick"];
        NSString *userType = NameStringWithUserType(userInfo[@"actor"],userInfo[@"userType"]);
        if (userType) {
            _userTypeLB.text = userType;
            _userTypeLB.hidden = NO;
        }else {
            _userTypeLB.hidden = YES;
        }
        
        NSString *status = userInfo[@"status"];
        [_linkMicTypeView setHidden:YES];
        if (status) {   // link mic status
            [_linkMicStatusLB setHidden:NO];
            if ([status isEqualToString:@"join"]) {
                _linkMicStatusLB.text = @"发言中";
                [_linkMicTypeView setHidden:NO];
            }else if ([status isEqualToString:@"wait"]){
                _linkMicStatusLB.text = @"正等待发言";
            }else {
                _linkMicStatusLB.text = status; // exception
            }
        }else {
            [_linkMicStatusLB setHidden:YES];
        }
    }
}

- (void)setLinkMicType:(NSString *)linkMicType {
    _linkMicType = linkMicType;
    if (linkMicType && linkMicType.length) {
        if ([linkMicType isEqualToString:@"video"]) {
            _linkMicTypeView.image = [UIImage imageNamed:CAMERA_IMAGE_PATH];
        }else if ([linkMicType isEqualToString:@"audio"]) {
            _linkMicTypeView.image = [UIImage imageNamed:MICPHONE_IMAGE_PATH];
        }
    }
}

#pragma mark - Privates(Deprecated)

- (void)updateAvatarViewWithPicStr:(NSString *)picStr {
    NSString *imageUrl = [NSString new];
    // 头像地址处理
    if ([picStr isKindOfClass:[NSNull class]]) {                // null地址类型
        //imageUrl = @"https://live.polyv.cn/assets/wimages/missing_face.png";
        return;
    } else if ([picStr hasPrefix:@"http:"]) {                   // HTTP强转HTTPS(包括微信头像和"live.polyv.cn"域名)
        imageUrl = [picStr stringByReplacingOccurrencesOfString:@"http:" withString:@"https:"];
    } else if ([picStr hasPrefix:@"//"]) {                      // 处理"//"类型开头的地址
        imageUrl = [@"https:" stringByAppendingString:picStr];
    } else {
        imageUrl = picStr;
    }
    
    // 异步请求头像
    __weak typeof(self)weakSelf = self;
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:imageUrl] cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:6.0];
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                //NSLog(@"头像请求出错:%@",error.localizedDescription);
            }else {
                UIImage *image = [UIImage imageWithData:data];
                //NSLog(@"image:%@",image);
                if (image) {
                    [weakSelf.avatarView setImage:image];
                }
            }
        });
    }] resume];
}

- (void)clearSubViews {
    for (UIView *view in self.subviews) {
        if (![view isKindOfClass:[UIImageView class]] && [view isKindOfClass:[UILabel class]]) {
            [view removeFromSuperview];
        }
    }
}

@end
