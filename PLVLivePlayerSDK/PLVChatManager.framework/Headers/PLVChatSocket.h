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
    PLVChatRoomStateReconnectAttempt    // 聊天室开始重新连接
};

@protocol SocketIODelegate;
@interface PLVChatSocket : NSObject

@property (nonatomic, weak) id <SocketIODelegate> delegate;
@property (nonatomic, strong, readonly) NSString *socketId;
@property (nonatomic, strong, readonly) NSString *channelId;
@property (nonatomic, strong, readonly) NSString *userId;
// 聊天室连接状态
@property (nonatomic, assign, readonly) PLVChatRoomState chatRoomState;

/**
 *  初始化聊天室（连接聊天室需要调用-connect 方法）
 *
 *  @param token        连接聊天室的token(获取方法参看PLVChatRequest.h文件)
 *  @param enableLog    是否输出调试信息
 */
- (instancetype)initChatSocketWithConnectToken:(NSString *)token enableLog:(BOOL)enableLog;

/**
 *  **观看端**登录聊天室接口方法（此方法一般在socket成功连接上聊天室后-socketIODidConnect:调用）
 *
 *  @param channelId    聊天室的房间号
 *  @param nickName     用户昵称
 *  @param avatar       用户头像
 */
- (void)loginChatRoomWithChannelId:(NSString *)channelId nickName:(NSString *)nickName avatar:(NSString *)avatar;

/**
 *  **推流端**登录聊天室接口方法（此方法一般在socket成功连接上聊天室后-socketIODidConnect:调用）
 *
 *
 *  @param channelId    聊天室的房间号
 *  @param nickName     用户昵称
 *  @param avatar       用户头像
 */
- (void)loginStreamerChatRoomWithChannelId:(NSString *)channelId nickName:(NSString *)nickName avatar:(NSString *)avatar;

/**
 *  提交聊天室发言
 *
 *  @param content      发言内容
 */
- (void)sendMessageWithContent:(NSString *)content;

/** 打开聊天室连接 */
- (void)connect;

/** 重新连接聊天室 */
- (void)reconnect;

/** 关闭聊天室连接 */
- (void)disconnect;

/** 移除所有监听事件 */
- (void)removeAllHandlers;

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

