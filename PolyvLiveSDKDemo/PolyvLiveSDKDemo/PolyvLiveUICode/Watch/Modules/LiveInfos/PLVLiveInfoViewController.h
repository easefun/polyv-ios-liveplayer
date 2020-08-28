//
//  PLVLiveInfoViewController.h
//  PolyvLiveSDKDemo
//
//  Created by zykhbl(zhangyukun@polyv.net) on 2018/7/18.
//  Copyright © 2018年 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PLVLiveAPI/PLVLiveChannel.h>
#import <PLVLiveAPI/PLVChannelMenuInfo.h>

@interface PLVLiveInfoViewController : UIViewController

@property (nonatomic, strong) PLVChannelMenuInfo *channelMenuInfo;
@property (nonatomic, strong) PLVChannelMenu *menu;

@end
