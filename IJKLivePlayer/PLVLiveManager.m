//
//  PLVLiveManager.m
//  IJKLivePlayer
//
//  Created by ftao on 05/01/2018.
//  Copyright © 2018 easefun. All rights reserved.
//

#import "PLVLiveManager.h"
#import <PLVSocketAPI/PLVSocketAPI.h>

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
        liveManager.chatroomObjects = [NSMutableArray array];
        liveManager.privateChatObjects = [NSMutableArray array];
        liveManager.onlineList = [NSArray array];
        [liveManager.privateChatObjects addObject:createTeacherAnswerObject()];
    });
    return liveManager;
}

- (void)setupChannelId:(NSString *)channelId userId:(NSString *)userId {
    self.channelId = channelId;
    self.userId = userId;
}

/// 处理聊天室信息
- (BOOL)handleChatroomObject:(PLVSocketChatRoomObject *)chatroomObject messgae:(NSString *__autoreleasing *)message {
    /*NSString *message;
    BOOL isHandle = [[PLVLiveManager sharedLiveManager] handleChatroomObject:chatObject messgae:&message];
    if (isHandle) {
        [self.chatroomController updateChatroom];
    }
    if (message) {
        [self.danmuLayer insertDML:message];
    }*/
    return NO;
}

/// 生成在线用户列表
+ (NSArray *)handleOnlineListWithJsonDictionary:(NSDictionary *)jsonDict {
    if (!jsonDict) {
        return nil;
    }
    NSInteger count = [jsonDict[@"count"] integerValue];
    NSArray *userlist = jsonDict[@"userlist"];
    NSMutableArray *mArr = [NSMutableArray array];
    for (NSDictionary *userDict in userlist) {
        // 数据处理，teacher 重复问题
        if ([userDict[@"userType"] isEqualToString:@"teacher"] && userDict[@"userSource"]) {
            continue;
        }
        [mArr addObject:userDict];
    }
    [PLVLiveManager sharedLiveManager].onlineList = mArr;
    NSLog(@"聊天室在线列表信息：处理前人数 %ld, 处理后人数 %ld",count,mArr.count);
    return mArr;
}

/// 重置数据
- (void)resetData {
    [self.chatroomObjects removeAllObjects];
    [self.privateChatObjects removeAllObjects];
    [self.privateChatObjects addObject:createTeacherAnswerObject()];
    self.onlineList = [NSArray array];
}

#pragma mark - Private functions

/// 生成一个teacher回答的伪数据对象
PLVSocketChatRoomObject *createTeacherAnswerObject() {
    NSMutableDictionary *jsonDict = [NSMutableDictionary dictionaryWithObject:PLVSocketIOChatRoom_T_ANSWER_EVENT forKey:PLV_EVENT];
    jsonDict[PLVSocketIOChatRoom_T_ANSWER_content] = @"同学，您好！请问有什么问题吗？";
    jsonDict[PLVSocketIOChatRoom_T_ANSWER_userKey] = @{
                                                   PLVSocketIOChatRoomUserNickKey : @"讲师",
                                                   PLVSocketIOChatRoomUserPicKey : @"https://livestatic.polyv.net/assets/images/teacher.png"
                                                   };
    PLVSocketChatRoomObject *teacherAnswer = [PLVSocketChatRoomObject socketObjectWithJsonDict:jsonDict];
    teacherAnswer.localMessage = YES;
    return teacherAnswer;
}

@end
