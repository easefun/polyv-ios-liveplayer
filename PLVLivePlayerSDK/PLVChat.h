//
//  PLVChat.h
//  PolyvIJKLivePlayer
//
//  Created by ftao on 2017/1/9.
//  Copyright © 2017年 easefun. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Speaker : NSObject

@property (nonatomic, strong) NSString *nickName;
@property (nonatomic, strong) NSString *nickImg;
@property (nonatomic, strong) NSString *clientIp;
@property (nonatomic, strong) NSString *type;

@end

@class PLVChat;
@protocol SocketIODelegate <NSObject>

@required
/** socket成功连接上聊天室*/
- (void)socketIODidConnect:(PLVChat *)chat;
/** socket收到聊天室信息*/
- (void)socketIODidReceiveMessage:(PLVChat *)chat;

@optional
/** socket和聊天室失去连接*/
- (void)socketIODidDisconnect:(PLVChat *)chat;
/** socket连接聊天室出错*/
- (void)socketIOConnectOnError:(PLVChat *)chat;
/** socket尝试重新连接聊天室时*/
- (void)socketIOReconnect:(PLVChat *)chat;
/** 当socket连接开始重新连接聊天室*/
- (void)socketIOReconnectAttempt:(PLVChat *)chat;

@end

typedef NS_ENUM(NSInteger, PLVChatRoomState) {
    PLVChatRoomStateConnected = 0,      // 聊天室连接成功
    PLVChatRoomStateDisconnected,       // 聊天室失去连接
    PLVChatRoomStateConnectError,       // 聊天室连接出错
    PLVChatRoomStateReconnect,          // 聊天室重连
    PLVChatRoomStateReconnectAttempt    // 聊天室连接开始重新连接
};

typedef NS_ENUM(NSInteger, PLVChatMessageType) {
    PLVChatMessageTypeCloseRoom = 0,    // 聊天室关闭
    PLVChatMessageTypeOpenRoom,         // 聊天室打开
    PLVChatMessageTypeGongGao,          // 系统公告
    PLVChatMessageTypeSpeak,            // 用户发言
    PLVChatMessageTypeOwnWords,         // 自己的发言
    PLVChatMessageTypeReward,           // 奖励信息
    PLVChatMessageTypeElse,             // 其他信息
    PLVChatMessageTypeError             // 聊天室出错
};

@interface PLVChat : NSObject

@property (nonatomic, weak) id <SocketIODelegate> delegate;

@property (nonatomic, assign, readonly) PLVChatRoomState chatRoomState;
@property (nonatomic, assign, readonly) PLVChatMessageType messageType;
@property (nonatomic, strong, readonly) NSString *messageContent;

// 聊天是其他成员信息
@property (nonatomic, strong, readonly) Speaker *speaker;

// 初始化连接
- (instancetype)initChatWithConnectParams:(NSDictionary *)params enableLog:(BOOL)enableLog;

// 初始化一个自己发言的样式
+ (instancetype)chatWithOwnMessageContent:(NSString *)messageContent;

- (void)connect;            // 打开聊天室连接
- (void)reconnect;          // 重新连接聊天室
- (void)disconnect;         // 关闭聊天室连接
- (void)removeAllHandlers;  // 移除所有监听事件

- (void)sendMessage:(NSDictionary *)jsonData;

@end

