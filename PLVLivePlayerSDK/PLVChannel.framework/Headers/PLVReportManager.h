//
//  PvReportManager.h
//  liveplayer
//
//  Created by seanwong on 10/27/15.
//  Copyright © 2015 easefun. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PLVReportManager : NSObject

// 播放id
+(NSString*)getPid;

// MARK: - Qos
+(void)reportLoading:(NSString*)pid uid:(NSString*)uid channelId:(NSString*)channelId time:(double)time param1:(NSString*)param1 param2:(NSString*)param2 param3:(NSString*)param3 param4:(NSString*)param4 param5:(NSString*)param5;

+(void)reportBuffer:(NSString*)pid uid:(NSString*)uid channelId:(NSString*)channelId time:(double)time param1:(NSString*)param1 param2:(NSString*)param2 param3:(NSString*)param3 param4:(NSString*)param4 param5:(NSString*)param5;

+(void)reportError:(NSString*)pid uid:(NSString*)uid channelId:(NSString*)channelId error:(NSString*)error param1:(NSString*)param1 param2:(NSString*)param2 param3:(NSString*)param3 param4:(NSString*)param4 param5:(NSString*)param5;

+(void)stat:(NSString*)pid uid:(NSString*)uid cid:(NSString*)cid flow:(long)flow pd:(int)pd sd:(int)sd cts:(NSTimeInterval)cts duration:(int)duration;


@end
