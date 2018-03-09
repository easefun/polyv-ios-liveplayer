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

#define NOLIVEIMAGE @"plv_nolive"           // 播放器无直播背景占位图地址
//#define RESTRICTIMAGE @"plv_xxxxxx"       // 人数超限背景占位图地址

#import <UIKit/UIKit.h>


@interface PLVLivePlayerControllerSkin : UIView

@property (nonatomic, assign, readonly) BOOL isSkinShowing;

@property (nonatomic, strong, readonly) UIView *topBar;
@property (nonatomic, strong, readonly) UIView *bottomBar;

@property (nonatomic, strong, readonly) UIButton *returnButton;

@property (nonatomic, strong, readonly) UIButton *playButton;
@property (nonatomic, strong, readonly) UIButton *pauseButton;
@property (nonatomic, strong, readonly) UIButton *fullScreenButton;
@property (nonatomic, strong, readonly) UIButton *smallScreenButton;

/// 无直播背景占位图
@property (nonatomic, strong, readonly) UIImageView *noLiveImageView;

@property (nonatomic, strong, readonly) UIActivityIndicatorView *indicatorView;

- (void)animateHideSkin;
- (void)animateShowSkin;

- (void)changeToFullScreen;
- (void)changeToSmallScreen;

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
