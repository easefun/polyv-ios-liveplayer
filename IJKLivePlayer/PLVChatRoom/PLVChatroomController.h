//
//  PLVChatroomController.h
//  IJKLivePlayer
//
//  Created by ftao on 08/01/2018.
//  Copyright © 2018 easefun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PLVSocketAPI/PLVSocketChatRoomObject.h>

@protocol PLVChatroomDelegate <NSObject>

- (void)sendMessage:(NSString *)message privateChatMode:(BOOL)privateChatMode;

@end

@interface PLVChatroomController : UIViewController

@property (nonatomic, weak) id<PLVChatroomDelegate> delegate;
@property (nonatomic, getter=isPrivateChatMode) BOOL privateChatMode;

- (instancetype)initWithFrame:(CGRect)frame;

- (void)updateChatroom;

@end
