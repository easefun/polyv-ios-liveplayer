//
//  PLVChatRoomManager.h
//  PolyvIJKLivePlayer
//
//  Created by ftao on 2017/1/6.
//  Copyright © 2017年 easefun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol PLVChatRoomDelegate <NSObject>

- (void)receiveMessage:(NSString *)message;

@end

@interface PLVChatRoomManager : NSObject

@property (nonatomic, strong, readonly) UIView *view;           // 聊天室视图
@property (nonatomic, weak) id<PLVChatRoomDelegate> delegate;   // 代理
@property (nonatomic, weak) UIViewController *currentCrl;       // 当前控制

/** 设置请求参数*/
@property (nonatomic, strong) NSString *channelId;              // 房间号
@property (nonatomic, strong) NSString *nickName;               // 用户昵称
@property (nonatomic, strong) NSString *userPic;                // 用户图片


/** 聊天室初始化方法*/
- (instancetype)initWithFrame:(CGRect)frame;

/** 退出聊天室时调用*/
- (void)closeChatRoom;

// 隐藏视图
- (void)setHiddenView:(BOOL)hidden;

/** 退出键盘*/
- (void)returnKeyBoard;

@end
