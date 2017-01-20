//
//  PLVChannel.h
//  PolyvIJKLivePlayer
//
//  Created by ftao on 2016/12/14.
//  Copyright © 2016年 easefun. All rights reserved.
//

#ifdef DEBUG
#   define DLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#   define DLog(...)
#endif

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, PLVLiveStreamState) {
    PLVLiveStreamStateUnknown = -1,     // 直播流状态未知
    PLVLiveStreamStateNoStream = 0,     // 没有流
    PLVLiveStreamStateLive = 1          // 直播中
};

@interface PLVChannel : NSObject

@property (nonatomic, copy, readonly) NSString *channelId;          // 直播频道ID
@property (nonatomic, copy, readonly) NSString *userId;             // 直播用户ID
@property (nonatomic, copy, readonly) NSString *name;               // 直播频道名称
@property (nonatomic, copy, readonly) NSString *flvUrl;             // 直播FLV 地址
@property (nonatomic, copy, readonly) NSString *m3u8Url;            // 直播M3U8 地址
@property (nonatomic, copy, readonly) NSString *stream;             // 直播流名称

@property (nonatomic, readonly) BOOL isNgbEnabled;                  // NGB 是否开启
@property (nonatomic, readonly) BOOL isUrlProtected;                // 防盗链是否开启
@property (nonatomic, copy, readonly) NSString *ngbUrl;             // NGB URL
@property (nonatomic, copy, readonly) NSString *bakUrl;             // bakUrl URL

@property (nonatomic, copy, readonly) NSNumber *reportFreq;


/**
 *  登录频道获取video json（回调都在主线程中进行）
 *
 *  @param userId               用户ID
 *  @param channelId            频道ID
 *  @param completionHandler    加载成功的回调
 *  @param failureHandler       加载失败的回调（频道号不存在：响应码500；用户名不正确：响应码403）
 */
+ (void)loadVideoJsonWithUserId:(NSString *)userId
                      channelId:(NSString *)channelId
              completionHandler:(void (^)(PLVChannel *channel))completionHandler
                 failureHandler:(void (^)(NSString *errorName, NSString *errorDescription))failureHandler;

/**
 * 当前流是否正在直播(此方法为同步线程)
 *
 * @param stream 直播流名
 *
 * @return PLVLiveStreamState 直播状态
 */
+ (PLVLiveStreamState)isLiveWithStreame:(NSString *)stream;


@end
