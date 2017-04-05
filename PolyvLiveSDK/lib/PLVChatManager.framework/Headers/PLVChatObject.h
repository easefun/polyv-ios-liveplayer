//
//  PLVChatObject.h
//  PLVLiveAPI
//
//  Created by ftao on 2017/2/22.
//  Copyright © 2017年 easefun. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Speaker : NSObject

@property (nonatomic, strong) NSString *nickName;
@property (nonatomic, strong) NSString *nickImg;
@property (nonatomic, strong) NSString *clientIp;
@property (nonatomic, strong) NSString *type;

@end

typedef NS_ENUM(NSUInteger, PLVChatMessageType) {
    PLVChatMessageTypeCloseRoom = 0,    // 聊天室关闭
    PLVChatMessageTypeOpenRoom,         // 聊天室打开
    PLVChatMessageTypeGongGao,          // 系统公告
    PLVChatMessageTypeSpeak,            // 用户发言
    PLVChatMessageTypeOwnWords,         // 自己发言
    PLVChatMessageTypeReward,           // 奖励信息
    PLVChatMessageTypeKick,             // 用户被踢
    PLVChatMessageTypeError,            // 出错了
    PLVChatMessageTypeElse              // 其他信息
};

@interface PLVChatObject : NSObject

// 信息类型
@property (nonatomic, assign) PLVChatMessageType messageType;

// 信息内容
@property (nonatomic, strong) NSString *messageContent;

// messageContent转化为可带表情的属性字符串
@property (nonatomic, strong) NSAttributedString *messageAttributedContent;

// 聊天成员信息
@property (nonatomic, strong) Speaker *speaker;

// 初始化一个自己发言的样式
+ (instancetype)chatObjectWithOwnMessageContent:(NSString *)messageContent;

@end
