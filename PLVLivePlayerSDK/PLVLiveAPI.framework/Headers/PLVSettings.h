//
//  PLVSettings.h
//  PLVLiveAPI
//
//  Created by ftao on 2017/1/19.
//  Copyright © 2017年 easefun. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PLVSettings : NSObject

+ (instancetype)sharedInstance;

- (void)setAppId:(NSString *)appId appSecret:(NSString *)appSecret;

- (NSString *)getAppId;
- (NSString *)getAppSecret;

@end
