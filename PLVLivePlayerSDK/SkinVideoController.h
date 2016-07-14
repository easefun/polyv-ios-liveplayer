//
//  SkinVideoViewController.h
//  polyvSDK
//
//  Created by seanwong on 8/17/15.
//  Copyright (c) 2015 easefun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PLVChannel/PLVChannel.h>

@import MediaPlayer;
typedef void(^PLVPlayerGoBackBlock)(void);

typedef NS_ENUM(NSUInteger, SkinVideoLiveType) {
    SkinVideoLiveTypeContinuing,                                                                // 不断流直播类型(电视直播类型)
    SkinVideoLiveTypeWillStop                                                                   // 会断流直播类型(课堂、会议、演讲等)
};


@interface SkinVideoController : MPMoviePlayerController

@property (nonatomic, assign) SkinVideoLiveType videoLiveType;                                  // 直播类型，默认为不断流直播类型
@property (nonatomic, strong) PLVChannel* channel;                                              // 频道信息(强引用，防止被提前释放)
@property (nonatomic, assign) CGRect frame;                                                     // 播放控制器的frame
@property (nonatomic, copy) void(^dimissCompleteBlock)(void);                                   // dismiss播放器控制器回调block
@property (nonatomic, copy) PLVPlayerGoBackBlock  goBackBlock;                                   // 使用此属性或者调用setParentViewController:方法设置俯视图


/* -------- 初始化方法 -------- */
- (instancetype)initWithFrame:(CGRect)frame;
- (instancetype)initWithFrame:(CGRect)frame videoLiveType:(SkinVideoLiveType)videoliveType;

- (void)showInWindow;                                                                           // 使用窗、口模式(播放器加载window层上)
- (void)dismiss;
- (void)setHeadTitle:(NSString*)headtitle;                                                      // 设置视频标题信息
- (void)setNavigationController:(UINavigationController*)navigationController;                  // 设置导航控制器
- (void)setParentViewController:(UIViewController*)viewController;                              // 设置父控制器

// 额外参数，用来跟踪出错用户
- (void)setParam1:(NSString*)param1;








@end