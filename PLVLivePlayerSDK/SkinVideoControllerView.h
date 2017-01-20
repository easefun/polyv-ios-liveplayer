//
//  SkinVideoControllerView.h
//  polyvSDK
//
//  Created by seanwong on 8/17/15.
//  Copyright (c) 2015 easefun. All rights reserved.
//

#import <UIKit/UIKit.h>

// 播放器皮肤
@interface SkinVideoControllerView : UIView

@property (nonatomic, strong, readonly) UIView          *topBar;                    // 上边栏view
@property (nonatomic, strong, readonly) UIButton        *backButton;                // 返回button
@property (nonatomic, strong, readonly) UIButton        *closeButton;               // 关闭button
@property (nonatomic, strong, readonly) UIButton        *settingButton;             // 设置button
@property (nonatomic, strong, readonly) UIView          *settingView;               // 设置view

@property (nonatomic, strong, readonly) UIActivityIndicatorView *indicatorView;     // 活动指示器

@property (nonatomic, strong, readonly) UIView          *bottomBar;                 // 下边栏view
@property (nonatomic, strong, readonly) UIButton        *playButton;                // 播放button
@property (nonatomic, strong, readonly) UIButton        *pauseButton;               // 暂停button
@property (nonatomic, strong, readonly) UILabel         *timeLabel;                 // 时间label
@property (nonatomic, strong, readonly) UISlider        *progressSlider;            // 进度条
@property (nonatomic, strong, readonly) UIButton        *muteButton;                // 静音button
@property (nonatomic, strong, readonly) UIImageView     *liveStateView;             // 播放状态labe
@property (nonatomic, strong, readonly) UIButton        *fullScreenButton;          // 全屏button
@property (nonatomic, strong, readonly) UIButton        *shrinkScreenButton;        // 缩屏button

@property (nonatomic, assign) BOOL showInWindowMode;                                // 窗口模式


/* ---------------------- 事件/方法 ------------------------ */

- (void)animateHide;                                // 隐藏view
- (void)animateShow;                                // 显示view
- (void)autoFadeOutControlBar;                      // 自动隐藏
- (void)cancelAutoFadeOutControlBar;                // 取消自动隐藏
- (void)changeToFullsreen;                          // 全屏模式
- (void)changeToSmallsreen;                         // 小屏模式
- (void)setHeadTitle:(NSString*)headtitle;          // 设置标题
//- (void)changeToMute;                               // 静音
//- (void)changeToUnMute;                             // 非静音模式


@end
