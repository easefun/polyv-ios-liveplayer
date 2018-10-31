//
//  PLVUserTableViewCell.m
//  IJKLivePlayer
//
//  Created by ftao on 11/01/2018.
//  Copyright © 2018 easefun. All rights reserved.
//

#import "PLVUserTableViewCell.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "PLVUtils.h"
#import "PLVLiveManager.h"

#define CAMERA_IMAGE_PATH @"plv_img_camera"
#define MICPHONE_IMAGE_PATH @"plv_img_micphone"
#define USER_DEFAULT_IMAGE @"plv_img_defaultUser"

@interface PLVUserTableViewCell ()

@end

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
        if ([avatarUrl hasPrefix:@"//"]) {
            avatarUrl = [@"https:" stringByAppendingString:avatarUrl];
        }else if ([avatarUrl hasPrefix:@"http:"]) {
            avatarUrl = [avatarUrl stringByReplacingOccurrencesOfString:@"http:" withString:@"https:"];
        }
        [_avatarView sd_setImageWithURL:[NSURL URLWithString:avatarUrl] placeholderImage:[UIImage imageNamed:USER_DEFAULT_IMAGE]]; // use sdWebImage
        _nicknameLB.text = userInfo[@"nick"];
        // 处理自定义 actor
        NSDictionary *authorization = userInfo[@"authorization"];
        if (authorization) {
            _actorLB.hidden = NO;
            _actorLB.text = [NSString stringWithFormat:@" %@      ",authorization[@"actor"]];
            _actorLB.textColor = [PLVUtils colorFromHexString:authorization[@"fColor"]];
            _actorLB.backgroundColor = [PLVUtils colorFromHexString:authorization[@"bgColor"]];
        }else {
            NSString *actor = NameStringWithUserType(userInfo[@"actor"],userInfo[@"userType"]);
            if (actor) {
                _actorLB.text = [NSString stringWithFormat:@" %@      ",actor];
                _actorLB.hidden = NO;
                CGSize size = [_actorLB sizeThatFits:CGSizeMake(MAXFLOAT, 18)];
                _actorLB.bounds = CGRectMake(0, 0, size.width, 18.0);
                [_actorLB layoutIfNeeded];
            }else {
                _actorLB.hidden = YES;
            }
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
