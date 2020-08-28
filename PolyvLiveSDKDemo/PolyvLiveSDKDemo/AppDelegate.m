//
//  AppDelegate.m
//  PolyvLiveSDKDemo
//
//  Created by ftao on 24/05/2018.
//  Copyright © 2018 easefun. All rights reserved.
//

#import "AppDelegate.h"
#import <PLVLiveAPI/PLVLiveConfig.h>
#import <SDWebImage/SDWebImageManager.h>

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    NSString *userId =
    NSString *appId =
    NSString *appSecret = 
    
    // 参数配置，登录保利威视频云直播后台，开发设置->身份认证 https://live.polyv.net/#/develop/appId
    [PLVLiveConfig liveConfigWithUserId:userId appId:appId appSecret:appSecret];
    
    // 直播统计后台参数：用户Id、用户昵称及自定义参数
    [PLVLiveConfig setViewLogParam:nil param2:nil param4:nil param5:nil];
    
    // API本地日志等级
    [PLVLiveConfig setLogLevel:k_PLV_LIVE_LOG_INFO];
    
    // SDWebImage 缓存清理
    //[[SDImageCache sharedImageCache] clearDiskOnCompletion:nil];
    
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
