//
//  PvChannel.h
//  liveplayer
//
//  Created by seanwong on 10/27/15.
//  Copyright © 2015 easefun. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef DEBUG
#   define DLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#   define DLog(...)
#endif

@interface PLVChannel : NSObject

@property (nonatomic, copy) NSString *channelId;
@property (nonatomic, copy) NSString *userId;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *contentURL;
@property (nonatomic, copy) NSString *stream;
@property (nonatomic, copy) NSNumber *reportFreq;

/**
 *  加载视频信息
 *
 *  @param uid        user id
 *  @param cid        channel id
 *  @param completion 获得频道信息的block
 */
+(void)loadVideoUrl:(NSString*)uid channelId:(NSString*)cid completion:(void(^)(PLVChannel*))completion;

/* 是否正在直播*/
+(BOOL)isALive:(PLVChannel*)channel;

@end
