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

/// 聊天室对象数据源(PLVSocketChatRoomObject, NSString)
@property (nonatomic, strong) NSMutableArray *chatroomObjects;
/// 咨询提问对象数据源
@property (nonatomic, strong) NSMutableArray<PLVSocketChatRoomObject *> *privateChatObjects;

/// 聊天室在线列表数据源
@property (nonatomic, strong) NSArray<NSDictionary *> *onlineList;

+ (instancetype)sharedLiveManager;

- (void)setupChannelId:(NSString *)channelId userId:(NSString *)userId;

/**
 生成在线用户列表
 
 @param jsonDict 服务器返回json数据
 */
+ (NSArray *)handleOnlineListWithJsonDictionary:(NSDictionary *)jsonDict;

/// 重置数据
- (void)resetData;

/**
 处理聊天室信息

 @param chatroomObject 聊天室对象
 @param message 回调的聊天室信息
 @return 是否处理，处理成功会添加至聊天室或咨询提问的数据源
 */
//- (BOOL)handleChatroomObject:(PLVSocketChatRoomObject *)chatroomObject messgae:(NSString **)message;

@end
