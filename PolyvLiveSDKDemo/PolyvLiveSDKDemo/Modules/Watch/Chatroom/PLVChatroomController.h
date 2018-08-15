//
//  PLVChatroomController.h
//  IJKLivePlayer
//
//  Created by ftao on 08/01/2018.
//  Copyright © 2018 easefun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PLVSocketAPI/PLVSocketAPI.h>

@protocol PLVChatroomDelegate <NSObject>

- (void)emitChatroomObject:(PLVSocketChatRoomObject *)chatRoomObject withMessage:(NSString *)message;

@end

@interface PLVChatroomController : UIViewController
/// 代理
@property (nonatomic, weak) id<PLVChatroomDelegate> delegate;
/// 私有聊天室模式(咨询提问)
@property (nonatomic, getter=isPrivateChatMode) BOOL privateChatMode;

- (instancetype)initWithFrame:(CGRect)frame;

- (void)updateChatroom;

@end
