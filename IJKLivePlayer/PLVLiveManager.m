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
        liveManager.chatRoomObjects = [NSMutableArray array];
        liveManager.privateChatObjects = [NSMutableArray array];
    });
    return liveManager;
}

- (void)setupChannelId:(NSString *)channelId userId:(NSString *)userId {
    self.channelId = channelId;
    self.userId = userId;
}

@end
