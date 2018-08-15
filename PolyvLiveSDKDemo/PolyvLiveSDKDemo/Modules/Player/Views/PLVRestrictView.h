//
//  PLVRestrictView.h
//  PolyvLiveSDKDemo
//
//  Created by ftao on 31/07/2018.
//  Copyright © 2018 easefun. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PLVRestrictView : UIView

@property (weak, nonatomic) IBOutlet UILabel *errorCodeLabel;

+ (instancetype)restrictViewFromXIB;

@end
