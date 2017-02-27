//
//  PLVSettings.h
//  PLVLiveAPI
//
//  Created by ftao on 2017/1/19.
//  Copyright © 2017年 easefun. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  直播相关配置
 */
@interface PLVSettings : NSObject

// 获取配置相关实例
+ (instancetype)sharedInstance;

// 配置appId和appSecret(POLYV直播后台获取)
- (void)setAppId:(NSString *)appId appSecret:(NSString *)appSecret;

// 获取配置的appId
- (NSString *)getAppId;

// 获取配置的appSecret
- (NSString *)getAppSecret;

@end
