//
//  PLVChat.h
//  PolyvIJKLivePlayer
//
//  Created by ftao on 2017/1/9.
//  Copyright © 2017年 easefun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PLVChatObject.h"

typedef NS_ENUM(NSInteger, PLVChatRoomState) {
    PLVChatRoomStateConnected = 0,      // 聊天室连接成功
    PLVChatRoomStateDisconnected,       // 聊天室失去连接
    PLVChatRoomStateConnectError,       // 聊天室连接出错
    PLVChatRoomStateReconnect,          // 聊天室重连
    PLVChatRoomStateReconnectAttempt    // 聊天室连接开始重新连接
};

@protocol SocketIODelegate;
@interface PLVChatSocket : NSObject

@property (nonatomic, weak) id <SocketIODelegate> delegate;                 // 代理人

@property (nonatomic, strong, readonly) NSString *socketId;                 // socket id
@property (nonatomic, strong, readonly) NSString *channelId;                // 房间号
@property (nonatomic, assign, readonly) PLVChatRoomState chatRoomState;     // 聊天室状态


// 初始化聊天室连接
- (instancetype)initChatSocketWithConnectParams:(NSDictionary *)params
                                      enableLog:(BOOL)enableLog;

// 打开聊天室连接
- (void)connect;
// 重新连接聊天室
- (void)reconnect;
// 关闭聊天室连接
- (void)disconnect;
// 移除所有监听事件
- (void)removeAllHandlers;


// 登录观看端聊天室接口
- (void)loginChatRoomWithChannelId:(NSString *)channelId userId:(NSString *)userId nickName:(NSString *)nickName avatar:(NSString *)avatar;

// 登录推流端聊天室接口
- (void)loginStreamerChatRoomWithChannelId:(NSString *)channelId userId:(NSString *)userId nickName:(NSString *)nickName avatar:(NSString *)avatar;

// 提交发言
- (void)sendMessageWithContent:(NSString *)content;

@end


@protocol SocketIODelegate <NSObject>

@required
/** socket成功连接上聊天室*/
- (void)socketIODidConnect:(PLVChatSocket *)chatSocket;

@optional
/** socket收到聊天室信息*/
- (void)socketIODidReceiveMessage:(PLVChatSocket *)chatSocket withChatObject:(PLVChatObject *)chatObject;

/** socket和聊天室失去连接*/
- (void)socketIODidDisconnect:(PLVChatSocket *)chatSocket;

/** socket连接聊天室出错*/
- (void)socketIOConnectOnError:(PLVChatSocket *)chatSocket;

/** socket尝试重新连接聊天室时*/
- (void)socketIOReconnect:(PLVChatSocket *)chatSocket;

/** 当socket连接开始重新连接聊天室*/
- (void)socketIOReconnectAttempt:(PLVChatSocket *)chatSocket;

@end

