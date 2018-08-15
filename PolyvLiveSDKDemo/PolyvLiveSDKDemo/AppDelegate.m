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
#import <IJKMediaFramework/IJKMediaFramework.h>

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    // !!!: 保利威视后台“API设置中”获取 http://live.polyv.net/secure/user/app.htm
    NSString *appId = 
    NSString *appSecret =
    
    // 1.配置应用参数，聊天室及连麦功能必须配置该参数
    [PLVLiveConfig liveConfigWithAppId:appId appSecret:appSecret];
    // ** demo 使用上面方法配置参数（不同用户都可以登录），对于app来说，直接使用下面方法配置三个参数更便捷
    //[PLVLiveConfig liveConfigWithUserId:@"" appId:appId appSecret:appSecret];
    // 2.配置统计后台参数：用户Id、用户昵称及自定义参数
    [PLVLiveConfig setViewLogParam:nil param2:nil param4:nil param5:nil];
    // 3.设置接口本地日志输出等级
    [PLVLiveConfig setLogLevel:k_PLV_LIVE_LOG_INFO];
    // 4.播放器日志等级
    //[IJKFFMoviePlayerController setLogLevel:k_IJK_LOG_INFO];
    
    // 清除 SDWebImage 的磁盘缓存
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
