//
//  PLVUtils.m
//  PolyvLiveSDKDemo
//
//  Created by ftao on 01/07/2018.
//  Copyright © 2018 easefun. All rights reserved.
//

#import "PLVUtils.h"
#import <AVFoundation/AVFoundation.h>

typedef NS_ENUM(NSInteger, PrivacySettingType) {
    PrivacySettingTypeSetting,
    PrivacySettingTypePhotos,
    PrivacySettingTypeCamera,
    PrivacySettingTypeMicrophone,
    PrivacySettingTypeMedia
};

NSURL *URLFromPrivacySettingType(PrivacySettingType type) {
    NSString *settingName = nil;
    NSString *url = nil;
    switch (type) {
        case PrivacySettingTypeSetting:{
            url = UIApplicationOpenSettingsURLString;
        }break;
        case PrivacySettingTypePhotos:{
            settingName = @"PHOTOS";
        }break;
        case PrivacySettingTypeCamera:{
            settingName = @"CAMERA";
        }break;
        case PrivacySettingTypeMicrophone:{
            settingName = @"MICROPHONE";
        }break;
        case PrivacySettingTypeMedia:{
            settingName = @"MEDIA";
        }break;
        default:{}break;
    }
    if (!url) {
        url = [NSString stringWithFormat:@"App-Prefs:root=Privacy&path=%@", settingName];
    }
    return [NSURL URLWithString:url];
}

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
    //NSString *title = [NSString stringWithFormat:@"无法获取权限"];
    NSString *message = [NSString stringWithFormat:@"应用无法获取您的%@权限，请前往设置", NSStringFromPrivacySettingType(type)];
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"去设置" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf openSettingWithType:PrivacySettingTypeSetting];
    }]];
    [viewController presentViewController:alertController animated:YES completion:nil];
}

+ (void)openSettingWithType:(PrivacySettingType)type {
    NSURL *settingURL = URLFromPrivacySettingType(type);
    if ([[UIApplication sharedApplication] canOpenURL:settingURL]) {
        [[UIApplication sharedApplication] openURL:settingURL];
    } else {
        NSLog(@"无法打开 URL: %@", settingURL);
    }
}

@end
