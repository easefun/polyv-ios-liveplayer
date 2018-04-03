//
//  PLVOnlineListController.h
//  IJKLivePlayer
//
//  Created by ftao on 11/01/2018.
//  Copyright © 2018 easefun. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PLVOnlineListController : UIViewController

@property (nonatomic, assign) NSUInteger channelId;

- (void)invalidateTimer;

@end
