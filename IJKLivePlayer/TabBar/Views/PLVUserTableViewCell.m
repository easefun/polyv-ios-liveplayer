//
//  PLVUserTableViewCell.m
//  IJKLivePlayer
//
//  Created by ftao on 11/01/2018.
//  Copyright © 2018 easefun. All rights reserved.
//

#import "PLVUserTableViewCell.h"

@interface PLVUserTableViewCell ()

@end

@implementation PLVUserTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setImgUrl:(NSString *)imgUrl {
    // 头像地址处理
    if ([imgUrl isKindOfClass:[NSNull class]]) {                // null地址类型
        _imgUrl = @"https://live.polyv.cn/assets/wimages/missing_face.png";
    } else if ([imgUrl hasPrefix:@"http"]) {                    // HTTP强转HTTPS(包括微信头像和"live.polyv.cn"域名)
        _imgUrl = [imgUrl stringByReplacingOccurrencesOfString:@"http:" withString:@"https:"];
    } else if ([imgUrl hasPrefix:@"//"]) {                      // 处理"//"类型开头的地址
        _imgUrl = [@"https:" stringByAppendingString:imgUrl];
    } else {
        _imgUrl = imgUrl;
    }
    
    // 异步请求头像
    __weak typeof(self)weakSelf = self;
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:_imgUrl] cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:6.0];
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

@end
