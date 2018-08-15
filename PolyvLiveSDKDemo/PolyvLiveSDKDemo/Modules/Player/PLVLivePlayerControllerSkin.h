//
//  PLVMoviePlayerControllerSkin.h
//  PolyvIJKLivePlayer
//
//  Created by ftao on 2016/12/16.
//  Copyright © 2016年 easefun. All rights reserved.
//

#ifdef DEBUG
#   define DLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#   define DLog(...)
#endif

#define NOLIVE_BG_IMAGE @"plv_nolive"   // 播放器无直播背景占位图
#define RESTRICT_BG_IMAGE @"plv_xxxx"   // 人数超限背景占位图

#import <UIKit/UIKit.h>

@interface PLVLivePlayerControllerSkin : UIView

@property (nonatomic, assign, readonly) BOOL isSkinShowing;

@property (nonatomic, strong, readonly) UIView *topBar;
@property (nonatomic, strong, readonly) UIView *bottomBar;

@property (nonatomic, strong, readonly) UIButton *returnButton;

@property (nonatomic, strong, readonly) UIButton *playButton;
@property (nonatomic, strong, readonly) UIButton *pauseButton;
@property (nonatomic, strong, readonly) UIButton *definitionButton;
@property (nonatomic, strong, readonly) UIButton *fullScreenButton;
@property (nonatomic, strong, readonly) UIButton *smallScreenButton;

/// 无直播背景占位图
@property (nonatomic, strong, readonly) UIImageView *noLiveImageView;

@property (nonatomic, strong, readonly) UIActivityIndicatorView *indicatorView;

/// 默认清晰度
@property (nonatomic, strong) NSString *defaultDefinition;
/// 所有清晰度
@property (nonatomic, strong) NSArray *definitions;
/// 选择清晰度回调
@property (nonatomic, copy) void(^definitionsCallBack)(NSString *definition);

- (void)animateHideSkin;
- (void)animateShowSkin;

- (void)changeToFullScreen;
- (void)changeToSmallScreen;

/// 展示建议的清晰度提示
- (void)showRecommendedDefinition:(NSString *)definition;

/// 展示限制播放视图
- (void)showRestrictPlayViewWithErrorCode:(NSString *)errorCode;

/**
 添加视频信息视图
 @discussion 添加时会显示 videoInfo 视图
 */
- (void)addVideoInfoWithDescription:(NSString *)description;

/**
 隐藏/删除视频信息视图
 */
- (void)hideVideoInfo;

@end
