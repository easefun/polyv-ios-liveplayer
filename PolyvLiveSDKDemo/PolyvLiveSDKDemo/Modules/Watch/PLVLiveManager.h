//
//  PLVLiveManager.h
//  IJKLivePlayer
//
//  Created by ftao on 05/01/2018.
//  Copyright © 2018 easefun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PLVSocketAPI/PLVSocketAPI.h>

NSString *NameStringWithUserType(NSString *actor, NSString *userType);

@interface PLVLiveManager : NSObject

/// 当前房间号/频道号
@property (nonatomic, assign) NSUInteger channelId;
/// Socket 登录对象
@property (nonatomic, strong) PLVSocketObject *login;

/// 聊天室消息数据源(PLVSocketChatRoomObject, NSString)
@property (nonatomic, strong) NSMutableArray *chatroomObjects;
/// 咨询提问消息数据源
@property (nonatomic, strong) NSMutableArray<PLVSocketChatRoomObject *> *privateChatObjects;

/// 连麦相关参数
@property (nonatomic, strong) NSDictionary *linkMicParams;

/// 聊天室在线人数（实时）
@property (nonatomic, readonly) NSUInteger onlineCount;

+ (instancetype)sharedLiveManager;

/**
 处理聊天室消息
 
 @param chatroomObject 聊天室消息
 @param completion 处理成功，不能为nil（isChatroom：YES，公共聊天室信息；NO，私有聊天室信息）
 @return 聊天室信息（弹幕信息）
 */
- (NSString *)handleChatroomObject:(PLVSocketChatRoomObject *)chatroomObject completion:(void(^)(BOOL isChatroom))completion;

/**
 处理聊天室历史消息

 @param historyList 历史消息
 */
- (void)handleChatRoomHistoryMessage:(NSArray *)historyList;

/**
 重置数据
 */
- (void)resetData;

@end
