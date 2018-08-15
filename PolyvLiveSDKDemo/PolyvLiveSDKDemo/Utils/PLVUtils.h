//
//  PLVUtils.h
//  PolyvLiveSDKDemo
//
//  Created by ftao on 01/07/2018.
//  Copyright © 2018 easefun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface PLVUtils : NSObject

#pragma mark - HUD

+ (void)showHUDWithTitle:(nullable NSString * )title detail:(nullable NSString *)detail view:(nonnull UIView *)view;

#pragma mark - 授权管理
/**
 是否存在视频和音频授权
 */
+ (BOOL)hasVideoAndAudioAuthorization;

/**
 请求视频和音频授权
 */
+ (void)requestVideoAndAudioAuthorizationWithViewController:(nullable __weak UIViewController *)viewcontroller;

/**
 代码判断当前机器的类型是否iPhone X
 */
+ (BOOL)isPhoneX;

/**
 如果当前机器的类型是iPhone X，则返回statusBar的高度，否则返回0.0
 */
+ (CGFloat)statusBarHeight;

@end
