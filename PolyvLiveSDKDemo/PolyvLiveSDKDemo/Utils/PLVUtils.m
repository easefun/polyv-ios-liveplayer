//
//  PLVUtils.m
//  PolyvLiveSDKDemo
//
//  Created by ftao on 01/07/2018.
//  Copyright © 2018 easefun. All rights reserved.
//

#import "PLVUtils.h"
#import <AVFoundation/AVFoundation.h>
#import <MBProgressHUD/MBProgressHUD.h>

typedef NS_ENUM(NSInteger, PrivacySettingType) {
    PrivacySettingTypeSetting,
    PrivacySettingTypePhotos,
    PrivacySettingTypeCamera,
    PrivacySettingTypeMicrophone,
    PrivacySettingTypeMedia
};

NSString *NSStringFromPrivacySettingType(PrivacySettingType type) {
    switch (type) {
        case PrivacySettingTypeSetting:{
            return @"隐私";
        }break;
        case PrivacySettingTypePhotos:{
            return @"照片";
        }break;
        case PrivacySettingTypeCamera:{
            return @"相机";
        }break;
        case PrivacySettingTypeMicrophone:{
            return @"麦克风";
        }break;
        case PrivacySettingTypeMedia:{
            return @"媒体";
        }break;
        default:{
            return nil;
        }break;
    }
}

@implementation PLVUtils

#pragma mark - HUD

+ (void)showHUDWithTitle:(NSString *)title detail:(NSString *)detail view:(UIView *)view {
    NSLog(@"HUD info title:%@,detail:%@",title,detail);
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
    hud.mode = MBProgressHUDModeText;
    hud.label.text = title;
    hud.detailsLabel.text = detail;
    [hud hideAnimated:YES afterDelay:3.0];
}

#pragma mark - 音视频授权
+ (BOOL)hasVideoAndAudioAuthorization {
    // 获取相机权限状态
    AVAuthorizationStatus videoStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    // 获取麦克风权限状态
    AVAuthorizationStatus audioStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    
    if (videoStatus == AVAuthorizationStatusAuthorized && audioStatus == AVAuthorizationStatusAuthorized) {
        return YES;
    }else {
        return NO;
    }
}

+ (void)requestVideoAndAudioAuthorizationWithViewController:(__weak UIViewController *)viewcontroller {
    AVAuthorizationStatus videoStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    AVAuthorizationStatus audioStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    
    // 视频权限不明，请求权限
    if (videoStatus == AVAuthorizationStatusNotDetermined) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            if (granted) NSLog(@"Authorized");
            else NSLog(@"Denied or Restricted");
        }];
    }
    if (audioStatus == AVAuthorizationStatusNotDetermined) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
            if (granted) NSLog(@"Authorized");
            else NSLog(@"Denied or Restricted");
        }];
    }
    
    // 权限拒绝，进入指定设置页
    if (videoStatus == AVAuthorizationStatusDenied) {
        [self showAlertWithType:PrivacySettingTypeCamera delegate:viewcontroller];
    }
    if (audioStatus == AVAuthorizationStatusDenied) {
        [self showAlertWithType:PrivacySettingTypeMicrophone delegate:viewcontroller];
    }
}

#pragma mark - Privates

+ (void)showAlertWithType:(PrivacySettingType)type delegate:(__weak UIViewController *)viewController {
    __weak typeof(self) weakSelf = self;
    NSString *message = [NSString stringWithFormat:@"应用无法获取您的%@权限，请前往设置", NSStringFromPrivacySettingType(type)];
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"去设置" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf openSettingWithType:PrivacySettingTypeSetting];
    }]];
    [viewController presentViewController:alertController animated:YES completion:nil];
}

+ (void)openSettingWithType:(PrivacySettingType)type {
    NSURL *settingURL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    if ([[UIApplication sharedApplication] canOpenURL:settingURL]) {
        [[UIApplication sharedApplication] openURL:settingURL];
    } else {
        NSLog(@"无法打开 URL: %@", settingURL);
    }
}

+ (BOOL)isPhoneX {
    return (CGSizeEqualToSize(CGSizeMake(375.f, 812.f), [UIScreen mainScreen].bounds.size) || CGSizeEqualToSize(CGSizeMake(812.f, 375.f), [UIScreen mainScreen].bounds.size));
}

+ (CGFloat)statusBarHeight {
    if ([PLVUtils isPhoneX]) {
        return 44.0;
    } else {
        return 0.0;
    }
}

#pragma mark - UIColor
+ (UIColor *)colorFromHexString:(NSString *)hexString {
    if (!hexString || hexString.length < 6) {
        return [UIColor whiteColor];
    }
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    if ([hexString rangeOfString:@"#"].location == 0) {
        [scanner setScanLocation:1]; // bypass '#' character
    }
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}

+ (UIColor *)colorWithHex:(u_int32_t)hex {
    // >> 右移运算; & 与运算, 相同为1 不同为0, FF: 1111 1111
    // 如:0xAABBCC:AA为red的值,BB为green的值,CC为blue的值
    // 通过&运算和>>运算, 分别计算出 red,green,blue的值
    int red = (hex & 0xFF0000) >> 16;
    int green = (hex & 0x00FF00) >> 8;
    int blue = hex & 0x0000FF;
    
    return [UIColor colorWithRed:red/255.0 green:green/255.0 blue:blue/255.0 alpha:1.0];
}

@end
