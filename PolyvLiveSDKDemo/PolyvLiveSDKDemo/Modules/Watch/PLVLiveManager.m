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

@property (nonatomic, assign) NSUInteger onlineCount;

@end

/// 返回用户头衔
NSString *NameStringWithUserType(NSString *actor, NSString *userType) {
    if (actor && actor.length) {
        return actor;
    }
    if (userType && userType.length) {
        if ([userType isEqualToString:@"teacher"]) {
            return @"讲师";
        }else if ([userType isEqualToString:@"manager"]) {
            return @"管理员";
        }else if ([userType isEqualToString:@"assistant"]) {
            return @"助教";
        }else {
            return nil;
        }
    }else { // 不存在 userType 字段或为空
        return nil;
    }
}

@implementation PLVLiveManager

+ (instancetype)sharedLiveManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        liveManager = [[PLVLiveManager alloc] init];
        liveManager.chatroomObjects = [NSMutableArray array];
        liveManager.privateChatObjects = [NSMutableArray array];
        [liveManager.privateChatObjects addObject:createTeacherAnswerObject()];
    });
    return liveManager;
}

/// 处理聊天室信息
- (NSString *)handleChatroomObject:(PLVSocketChatRoomObject *)chatroomObject completion:(void(^)(BOOL isChatroom))completion {
    switch (chatroomObject.eventType) {
        // ------------------ 1.聊天室内容
        case PLVSocketChatRoomEventType_LOGIN: {    // 1.1.用户登录
            NSNumber *onlineUserNumber = chatroomObject.jsonDict[@"onlineUserNumber"];
            self.onlineCount = onlineUserNumber.unsignedIntegerValue;
            NSString *nickname = chatroomObject.jsonDict[PLVSocketIOChatRoom_LOGIN_userKey][PLVSocketIOChatRoomUserNickKey];
            [self.chatroomObjects addObject:[NSString stringWithFormat:@"欢迎%@加入",nickname]];
            completion(YES);
        } break;
        case PLVSocketChatRoomEventType_LOGOUT: {
            NSNumber *onlineUserNumber = chatroomObject.jsonDict[@"onlineUserNumber"];
            self.onlineCount = onlineUserNumber.unsignedIntegerValue;
        } break;
        case PLVSocketChatRoomEventType_GONGGAO: {  // 1.2.管理员发言/跑马灯公告
            NSString *content = chatroomObject.jsonDict[PLVSocketIOChatRoom_GONGGAO_content];
            [self.chatroomObjects addObject:[@"管理员发言:\n" stringByAppendingString:content]];
            completion(YES);
        } break;
        case PLVSocketChatRoomEventType_BULLETIN: { // 1.3.公告
            NSString *content = chatroomObject.jsonDict[PLVSocketIOChatRoom_BULLETIN_content];
            content = [content stringByReplacingOccurrencesOfString:@"<br/>" withString:@"\n"];
            [self.chatroomObjects addObject:[@"公告:\n" stringByAppendingString:content]];
            completion(YES);
        } break;
        case PLVSocketChatRoomEventType_SPEAK: {    // 1.4.用户发言
            NSDictionary *user = chatroomObject.jsonDict[PLVSocketIOChatRoom_SPEAK_userKey];
            NSString *status = chatroomObject.jsonDict[@"status"];
            if (status) {
                if ([status isEqualToString:@"censor"]) { // 聊天室审核
                }else if ([status isEqualToString:@"error"]) { // 严禁词
                }
            }else if (user) {
                NSString *userId = [NSString stringWithFormat:@"%@",user[PLVSocketIOChatRoomUserUserIdKey]];
                if ([userId isEqualToString:self.login.userId]) {
                    break;
                }
                [self.chatroomObjects addObject:chatroomObject];
                completion(YES);
                return [chatroomObject.jsonDict[PLVSocketIOChatRoom_SPEAK_values] firstObject];
            }
        } break;
        // ------------------  2.咨询提问（私有聊天）
        case PLVSocketChatRoomEventType_T_ANSWER: { // 2.1.讲师发言
            NSString *userId = chatroomObject.jsonDict[PLVSocketIOChatRoom_T_ANSWER_sUserId];
            if ([userId isEqualToString:self.login.userId]) {
                [self.privateChatObjects addObject:chatroomObject];
                completion(NO);
            }
        } break;
        default: break;
    }
    return nil;
}

- (void)handleChatRoomHistoryMessage:(NSArray *)historyList {
    if (historyList && historyList.count) {
        for (NSDictionary *messageDict in historyList) {
            NSString *msgSource = messageDict[@"msgSource"];
            if (msgSource) {    // redpaper（红包）、get_redpaper（领红包）
            } else {
                NSString *uid = [NSString stringWithFormat:@"%@",messageDict[@"user"][@"uid"]];
                if ([uid isEqualToString:@"1"] || [uid isEqualToString:@"1"]) {
                    // uid = 1，打赏消息；uid = 2，自定义消息
                }else { // 发言消息
                    NSMutableDictionary *speakDict = [NSMutableDictionary dictionaryWithObject:PLVSocketIOChatRoom_SPEAK_EVENT forKey:PLV_EVENT];
                    speakDict[PLVSocketIOChatRoom_SPEAK_values] = @[messageDict[@"content"]];
                    speakDict[PLVSocketIOChatRoom_SPEAK_userKey] = messageDict[PLVSocketIOChatRoom_SPEAK_userKey];
                    speakDict[PLVSocketIOChatRoom_SPEAK_time] = messageDict[PLVSocketIOChatRoom_SPEAK_time];
                    PLVSocketChatRoomObject *chatRoomObject = [PLVSocketChatRoomObject socketObjectWithJsonDict:speakDict];
                    [self.chatroomObjects insertObject:chatRoomObject atIndex:0];
                }
            }
        }
    }
}

/// 重置数据
- (void)resetData {
    [self.chatroomObjects removeAllObjects];
    [self.privateChatObjects removeAllObjects];
    [self.privateChatObjects addObject:createTeacherAnswerObject()];
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
