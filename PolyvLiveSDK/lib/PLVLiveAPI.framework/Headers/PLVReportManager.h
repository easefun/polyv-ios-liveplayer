//
//  PLVReportManager.h
//  PolyvIJKLivePlayer
//
//  Created by ftao on 2016/12/27.
//  Copyright © 2016年 easefun. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * 直播服务质量统计
 */
@interface PLVReportManager : NSObject

// 获取SDK 版本
+ (NSString *)getSDKVersion;

// 播放器id
+ (NSString *)getPid;

// MARK: - 首次加载时长
+ (void)reportLoading:(NSString*)pid uid:(NSString*)uid channelId:(NSString*)channelId time:(int)time session_id:(NSString *)session_id param1:(NSString*)param1 param2:(NSString*)param2 param3:(NSString*)param3 param4:(NSString*)param4 param5:(NSString*)param5;

// MARK: - 二次缓冲时长
+ (void)reportBuffer:(NSString*)pid uid:(NSString*)uid channelId:(NSString*)channelId time:(int)time session_id:(NSString *)session_id param1:(NSString*)param1 param2:(NSString*)param2 param3:(NSString*)param3 param4:(NSString*)param4 param5:(NSString*)param5;

// MARK: - 直播出错
+ (void)reportError:(NSString *)pid uid:(NSString *)uid channelId:(NSString *)channelId session_id:(NSString *)session_id param1:(NSString *)param1 param2:(NSString *)param2 param3:(NSString *)param3 param4:(NSString *)param4 param5:(NSString *)param5 uri:(NSString *)uri status:(NSString *)status errorcode:(NSString *)errorcode errormsg:(NSString *)errormsg;

// MARK: - 播放中
+ (void)stat:(NSString*)pid uid:(NSString*)uid cid:(NSString*)cid flow:(long)flow pd:(int)pd sd:(int)sd cts:(NSTimeInterval)cts duration:(int)duration;

@end
