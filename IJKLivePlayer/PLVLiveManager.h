//
//  PLVLiveManager.h
//  IJKLivePlayer
//
//  Created by ftao on 05/01/2018.
//  Copyright © 2018 easefun. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PLVSocketChatRoomObject;
@interface PLVLiveManager : NSObject

/// 当前房间号/频道号
@property (nonatomic, strong, readonly) NSString *channelId;
/// 当前用户Id
@property (nonatomic, strong, readonly) NSString *userId;

/// 聊天室对象数据源
@property (nonatomic, strong) NSMutableArray<PLVSocketChatRoomObject *> *chatRoomObjects;
/// 咨询提问对象数据源
@property (nonatomic, strong) NSMutableArray<PLVSocketChatRoomObject *> *privateChatObjects;

+ (instancetype)sharedLiveManager;

- (void)setupChannelId:(NSString *)channelId userId:(NSString *)userId;

@end
