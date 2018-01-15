//
//  PLVLiveManager.m
//  IJKLivePlayer
//
//  Created by ftao on 05/01/2018.
//  Copyright © 2018 easefun. All rights reserved.
//

#import "PLVLiveManager.h"

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
- (NSString *)handleChatroomObject:(PLVSocketChatRoomObject *)chatroomObject completion:(void(^)(BOOL isChatroom))completion {
    switch (chatroomObject.eventType) {
        // ------------------ 1.聊天室内容
        case PLVSocketChatRoomEventType_LOGIN: {    // 1.1.用户登录
            NSString *nickname = chatroomObject.jsonDict[PLVSocketIOChatRoom_LOGIN_userKey][PLVSocketIOChatRoomUserNickKey];
            [self.chatroomObjects addObject:[NSString stringWithFormat:@"欢迎%@加入",nickname]];
            completion(YES);
        } break;
        case PLVSocketChatRoomEventType_GONGGAO: {  // 1.2.管理员发言/跑马灯公告
            NSString *content = chatroomObject.jsonDict[PLVSocketIOChatRoom_GONGGAO_content];
            [self.chatroomObjects addObject:[@"管理员发言:\n" stringByAppendingString:content]];
            completion(YES);
        } break;
        case PLVSocketChatRoomEventType_BULLETIN: { // 1.3.公告
            NSString *content = chatroomObject.jsonDict[PLVSocketIOChatRoom_BULLETIN_content];
            [self.chatroomObjects addObject:[@"公告:\n" stringByAppendingString:content]];
            completion(YES);
        } break;
        case PLVSocketChatRoomEventType_SPEAK: {    // 1.4.用户发言
            NSDictionary *user = chatroomObject.jsonDict[PLVSocketIOChatRoom_SPEAK_userKey];
            if (user) {     // use不存在可能为严禁词类型
                NSString *userId = user[PLVSocketIOChatRoomUserUserIdKey];
                // 非自己发言内容(开启聊天审核后会收到自己数据)
                if (![userId isEqualToString:[NSString stringWithFormat:@"%lu",self.login.userId]]) {
                    [self.chatroomObjects addObject:chatroomObject];
                    completion(YES);
                    return [chatroomObject.jsonDict[PLVSocketIOChatRoom_SPEAK_values] firstObject];
                }
            }
        } break;
        // ------------------  2.提问内容(私有聊天)
        //case PLVSocketChatRoomEventType_S_QUESTION:
        case PLVSocketChatRoomEventType_T_ANSWER: { // 2.1.讲师发言
            NSString *userId = chatroomObject.jsonDict[PLVSocketIOChatRoom_T_ANSWER_sUserId];
            if ([userId isEqualToString:[NSString stringWithFormat:@"%lu",self.login.userId]]) {
                [self.privateChatObjects addObject:chatroomObject];
                completion(NO);
            }
        } break;
        default: break;
    }
    return nil;
}

/// 生成在线用户列表
+ (NSArray *)handleOnlineListWithJsonDictionary:(NSDictionary *)jsonDict {
    if (!jsonDict) {
        return nil;
    }
    //NSInteger count = [jsonDict[@"count"] integerValue];
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
    //NSLog(@"聊天室在线列表信息：处理前人数 %ld, 处理后人数 %ld",count,mArr.count);
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
