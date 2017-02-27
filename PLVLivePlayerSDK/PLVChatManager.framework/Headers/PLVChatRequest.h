//
//  PLVChatRequest.h
//  PLVLiveAPI
//
//  Created by ftao on 2017/2/22.
//  Copyright © 2017年 easefun. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PLVChatRequest : NSObject

/**
 *  异步请求chatToken（适用于直播观看客户端及SDK的聊天室）
 *
 *  @param appId        保利威视后台获取的参数
 *  @praam appSecret    保利威视后台获取的参数
 *  @param success      成功获取结果的回调（主线程中）
 *  @param failure      失败获取结果的回调（主线程中）
 */
+ (void)getChatTokenWithAppid:(NSString *)appId
                    appSecret:(NSString *)appSecret
                      success:(void (^)(NSString *chatToken))success
                      failure:(void (^)(NSString *errorName, NSString *errorDescription))failure;

/**
 *  异步请求chatToken（无参，适用于直播推流客户端及SDK的聊天室）
 *
 *  @param success  成功获取结果的回调（主线程中）
 *  @param failure  失败获取结果的回调（主线程中）
 */
+ (void)getChatTokenSuccess:(void (^)(NSString *chatToken))success
                    failure:(void (^)(NSString *errorName, NSString *errorDescription))failure;

/**
 *  带socketId参数的聊天室请求（定时刷新，防止被后台终止连接）
 */
+ (void)requestWithSocketId:(NSString *)socketId
                    failure:(void (^)(NSInteger responseCode, NSString *errorReason))failure;


@end
