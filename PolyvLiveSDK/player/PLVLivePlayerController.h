//
//  PLVLivePlayerController.h
//  PolyvIJKLivePlayer
//
//  Created by ftao on 2016/12/16.
//  Copyright © 2016年 easefun. All rights reserved.
//

#import <IJKMediaFramework/IJKMediaFramework.h>
#import <PLVLiveAPI/PLVLiveAPI.h>

/** 播放器通知*/
extern NSString * const PLVLivePlayerReconnectNotification;                 // 播放器重连通知
extern NSString * const PLVLivePlayerWillChangeToFullScreenNotification;    // 播放器将要全屏通知
extern NSString * const PLVLivePlayerWillExitFullScreenNotification;        // 播放器将要退出全屏通知

/**
 * 更多方法可参看 IJKMediaFramework 中的IJKFFMoviePlayerController、IJKMediaPlayback 头文件
 */
@interface PLVLivePlayerController : IJKFFMoviePlayerController

// 当前播放器的frame值
@property (nonatomic, strong) PLVLiveChannel *channel;
@property (nonatomic, assign, readonly) CGRect frame;
@property (nonatomic, strong, readonly) NSURL *contentURL;
@property (nonatomic, assign, readonly) PLVLiveStreamState streamState;

/** 播放器点击事件回调*/
// ^returnButtonClickBlcok：小屏状态下点击reture按钮才会触发，全屏状态下点击return则回到小屏状态
@property (nonatomic, copy) void(^returnButtonClickBlcok)(void);
@property (nonatomic, copy) void(^playButtonClickBlcok)(void);
@property (nonatomic, copy) void(^pauseButtonClickBlcok)(void);
@property (nonatomic, copy) void(^fullScreenButtonClickBlcok)(void);
@property (nonatomic, copy) void(^smallScreenButtonClickBlcok)(void);


// 初始化方法 默认拉流地址为FLV 格式
- (instancetype)initWithChannel:(PLVLiveChannel *)channel displayView:(UIView *)displayView;
- (instancetype)initWithChannel:(PLVLiveChannel *)channel displayView:(UIView *)displayView playHLS:(BOOL)playHLS __deprecated;

- (instancetype)initWithContentURL:(NSURL *)aUrl displayView:(UIView *)displayView;
- (instancetype)initWithContentURLString:(NSString *)aUrlString displayView:(UIView *)displayView;

// 设置播放器的channel信息
- (void)setChannel:(PLVLiveChannel *)channel;

/** 直播服务质量相关 设置额外参数，用来提交更多信息*/
- (void)setParam1:(NSString *)param1;
- (void)setParam2:(NSString *)param2;
- (void)setParam3:(NSString *)param3;
- (void)setParam4:(NSString *)param4;
- (void)setParam5:(NSString *)param5;
// 设置播放场次
- (void)setSessionId:(NSString *)sessionId;

// 播放器销毁前须调用
- (void)clearPlayer;

// 插入弹幕层
- (void)insertDanmuView:(UIView *)danmuView;

// 获取SDK 版本
+ (NSArray *)getSDKVersion;

@end
