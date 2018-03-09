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
 Polyv 直播播放器
 @discussion 更多方法参看 IJKFFMoviePlayerController、IJKMediaPlayback 头文件
 */
@interface PLVLivePlayerController : IJKFFMoviePlayerController

/// 直播频道信息
@property (nonatomic, strong) PLVLiveChannel *channel;
/// 当前播放器的 frame
@property (nonatomic, assign, readonly) CGRect frame;
/// 当前的资源地址
@property (nonatomic, strong, readonly) NSURL *contentURL;
/// 当期的直播流状态
@property (nonatomic, assign, readonly) PLVLiveStreamState streamState;

/** 播放器点击事件回调*/
// ^returnButtonClickBlcok：小屏状态下点击reture按钮才会触发，全屏状态下点击return则回到小屏状态
@property (nonatomic, copy) void(^returnButtonClickBlcok)(void);
@property (nonatomic, copy) void(^playButtonClickBlcok)(void);
@property (nonatomic, copy) void(^pauseButtonClickBlcok)(void);
@property (nonatomic, copy) void(^fullScreenButtonClickBlcok)(void);
@property (nonatomic, copy) void(^smallScreenButtonClickBlcok)(void);

/**
 初始化方法 默认拉流地址为FLV 格式
 */
- (instancetype)initWithChannel:(PLVLiveChannel *)channel displayView:(UIView *)displayView;
- (instancetype)initWithChannel:(PLVLiveChannel *)channel displayView:(UIView *)displayView playHLS:(BOOL)playHLS __deprecated;

- (instancetype)initWithContentURL:(NSURL *)aUrl displayView:(UIView *)displayView;
- (instancetype)initWithContentURLString:(NSString *)aUrlString displayView:(UIView *)displayView;

/**
 设置播放器的channel信息
 */
- (void)setChannel:(PLVLiveChannel *)channel;

/**
 播放器销毁前须调用
 */
- (void)clearPlayer;

/**
 插入弹幕层
 */
- (void)insertDanmuView:(UIView *)danmuView;

/**
 获取 SDK 版本
 */
+ (NSArray *)getSDKVersion;

@end
