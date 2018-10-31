//
//  PLVChatroomController.h
//  IJKLivePlayer
//
//  Created by ftao on 08/01/2018.
//  Copyright © 2018 easefun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PLVSocketAPI/PLVSocketAPI.h>

/// 聊天室类型
typedef NS_ENUM(NSInteger, PLVChatroomType) {
    PLVChatroomTypePublic   = 1,  // 公共聊天
    PLVChatroomTypePrivate  = 2,  // 私有聊天(咨询提问)
};

/// 聊天室错误码
typedef NS_ENUM(NSInteger, PLVChatroomErrorCode) {
    PLVChatroomErrorCodeBeKicked    = -100,   // 无访问权限
    PLVChatroomErrorCodeRoomClose   = -111,   // 房间关闭
    PLVChatroomErrorCodeBanned      = -122,   // 被禁言
};

@class PLVChatroomController;

@protocol PLVChatroomDelegate <NSObject>
@required
- (void)chatroom:(PLVChatroomController *)chatroom didOpenError:(PLVChatroomErrorCode)code;

@optional
- (void)emitChatroomObject:(PLVSocketChatRoomObject *)chatRoomObject withMessage:(NSString *)message;

@end

@interface PLVChatroomController : UIViewController

@property (nonatomic, weak) id<PLVChatroomDelegate> delegate;
/// 私有聊天室模式(咨询提问)
@property (nonatomic, getter=isPrivateChatMode) BOOL privateChatMode;

/// 是否有观看直播权限
+ (BOOL)havePermissionToWatchLive:(NSNumber *)roomId;

- (instancetype)initWithFrame:(CGRect)frame;

/// 加载子视图
- (void)loadSubViews;

- (void)updateChatroom;

/// 添加新事件
- (void)addNewChatroomObject:(PLVSocketChatRoomObject *)object;

@end
