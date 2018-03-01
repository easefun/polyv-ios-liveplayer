//
//  PLVLiveManager.h
//  IJKLivePlayer
//
//  Created by ftao on 05/01/2018.
//  Copyright © 2018 easefun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PLVSocketAPI/PLVSocketAPI.h>

@interface PLVLiveManager : NSObject

/// Socket 登录对象
@property (nonatomic, strong) PLVSocketObject *login;

/// 聊天室对象数据源(PLVSocketChatRoomObject, NSString)
@property (nonatomic, strong) NSMutableArray *chatroomObjects;
/// 咨询提问对象数据源
@property (nonatomic, strong) NSMutableArray<PLVSocketChatRoomObject *> *privateChatObjects;

/// 聊天室在线列表数据源
@property (nonatomic, strong) NSArray<NSDictionary *> *onlineList;

+ (instancetype)sharedLiveManager;

/**
 处理聊天室信息
 
 @param chatroomObject 聊天室信息
 @param completion 处理成功，不能为nil（isChatroom：YES，公共聊天室信息；NO，私有聊天室信息）
 @return 聊天室信息（弹幕信息）
 */
- (NSString *)handleChatroomObject:(PLVSocketChatRoomObject *)chatroomObject completion:(void(^)(BOOL isChatroom))completion;

/**
 生成在线用户列表
 
 @param jsonDict 服务器返回json数据
 */
+ (NSArray *)handleOnlineListWithJsonDictionary:(NSDictionary *)jsonDict;

/// 重置数据
- (void)resetData;

@end
