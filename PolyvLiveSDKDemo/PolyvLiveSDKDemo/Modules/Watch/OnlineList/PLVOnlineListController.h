//
//  PLVOnlineListController.h
//  IJKLivePlayer
//
//  Created by ftao on 11/01/2018.
//  Copyright © 2018 easefun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PLVSocketAPI/PLVSocketAPI.h>

@protocol PLVOnlineListDelegate <NSObject>

- (void)emitLinkMicObject:(PLVSocketLinkMicObject *)linkMicObject;

@end

@interface PLVOnlineListController : UIViewController

@property (nonatomic, assign) NSUInteger channelId;

@property (nonatomic, weak) id<PLVOnlineListDelegate> delegate;

@property (nonatomic, strong) PLVSocketLinkMicObject *linkMicObject;

/**
 销毁当前对象需前调用
 */
- (void)clearController;

@end
