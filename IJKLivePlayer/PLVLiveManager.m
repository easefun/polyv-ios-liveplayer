//
//  PLVLiveManager.m
//  IJKLivePlayer
//
//  Created by ftao on 05/01/2018.
//  Copyright © 2018 easefun. All rights reserved.
//

#import "PLVLiveManager.h"

static PLVLiveManager *liveManager = nil;

@interface PLVLiveManager ()

@property (nonatomic, strong) NSString *channelId;
@property (nonatomic, strong) NSString *userId;

@end

@implementation PLVLiveManager

+ (instancetype)sharedLiveManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        liveManager = [[PLVLiveManager alloc] init];
        liveManager.chatroomObjects = [NSMutableArray array];
        liveManager.privateChatObjects = [NSMutableArray array];
    });
    return liveManager;
}

- (void)setupChannelId:(NSString *)channelId userId:(NSString *)userId {
    self.channelId = channelId;
    self.userId = userId;
}

/// 处理聊天室信息
- (BOOL)handleChatroomObject:(PLVSocketChatRoomObject *)chatroomObject messgae:(NSString *__autoreleasing *)message {
    /*NSString *message;
    BOOL isHandle = [[PLVLiveManager sharedLiveManager] handleChatroomObject:chatObject messgae:&message];
    if (isHandle) {
        [self.chatroomController updateChatroom];
    }
    if (message) {
        [self.danmuLayer insertDML:message];
    }*/
    return NO;
}

/// 重置数据
- (void)resetData {
    self.chatroomObjects = [NSMutableArray array];
    self.privateChatObjects = [NSMutableArray array];
}

@end
