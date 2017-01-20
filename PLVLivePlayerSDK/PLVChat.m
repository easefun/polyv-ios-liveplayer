//
//  PLVChat.m
//  PolyvIJKLivePlayer
//
//  Created by ftao on 2017/1/9.
//  Copyright © 2017年 easefun. All rights reserved.
//

#import "PLVChat.h"

#define CHATROOMURL @"https://beta.polyv.net:8001"

@implementation Speaker

- (void)setNickImg:(NSString *)nickImg {
    if (![nickImg containsString:@"http:"] && ![nickImg containsString:@"https:"] ) {
        _nickImg = [@"https:" stringByAppendingString:nickImg];
    }else {
        _nickImg = nickImg;
    }
}

@end

@interface PLVChat ()

@property (nonatomic, assign) PLVChatRoomState chatRoomState;
@property (nonatomic, assign) PLVChatMessageType messageType;
@property (nonatomic, strong) NSString *messageContent;

@property (nonatomic, strong) Speaker *speaker;

@end

@import SocketIO;
@implementation PLVChat {
    SocketIOClient *socket;
}

+ (instancetype)chatWithOwnMessageContent:(NSString *)messageContent {
    PLVChat *chat = [[PLVChat alloc] init];
    chat.messageType = PLVChatMessageTypeOwnWords;
    chat.messageContent = messageContent;
    
    return chat;
}

- (instancetype)initChatWithConnectParams:(NSDictionary *)params enableLog:(BOOL)enableLog {
    self = [super init];
    if (self) {
        [self initSocketIOWithParams:params enableLog:enableLog];
        [self addMonitor];
        // 初始化属性
        _messageContent = [NSString new];
        _speaker = [[Speaker alloc] init];
    }
    return self;
}

- (void)initSocketIOWithParams:(NSDictionary *)params enableLog:(BOOL)enableLog {
    NSURL *chatRoomUrl = [NSURL URLWithString:CHATROOMURL];
    socket = [[SocketIOClient alloc] initWithSocketURL:chatRoomUrl config:@{@"log" : enableLog?@YES:@NO,    // 是否输出调试信息
                                                                            @"forceWebsockets" : @YES,      // forceWebsockets/forcePolling
                                                                            @"connectParams" : params }];   // 握手参数
}

- (void)addMonitor {
    if (!socket) return;
    
    // 监听客户端连接事件
    // 监听连接成功事件  Emitted when on a successful connection
    [socket on:@"connect" callback:^(NSArray * _Nonnull data, SocketAckEmitter * _Nonnull ack) {
        if (self.delegate) {
            self.chatRoomState = PLVChatRoomStateConnected;
            [self.delegate socketIODidConnect:self];
        }
    }];
    [socket on:@"disconnect" callback:^(NSArray * _Nonnull data, SocketAckEmitter * _Nonnull ack) {
        if (self.delegate) {
            self.chatRoomState = PLVChatRoomStateDisconnected;
            [self.delegate socketIODidDisconnect:self];
        }
    }];
    [socket on:@"error" callback:^(NSArray * _Nonnull data, SocketAckEmitter * _Nonnull ack) {
        if (self.delegate) {
            self.chatRoomState = PLVChatRoomStateConnectError;
            [self.delegate socketIOConnectOnError:self];
        }
    }];
    [socket on:@"reconnect" callback:^(NSArray * _Nonnull data, SocketAckEmitter * _Nonnull ack) {
        if (self.delegate) {
            self.chatRoomState = PLVChatRoomStateReconnect;
            [self.delegate socketIOReconnect:self];
        }
    }];
    [socket on:@"reconnectAttempt" callback:^(NSArray * _Nonnull data, SocketAckEmitter * _Nonnull ack) {
        if (self.delegate) {
            self.chatRoomState = PLVChatRoomStateReconnectAttempt;
            [self.delegate socketIOReconnectAttempt:self];
        }
    }];
    
    // 监听聊天室message事件
    [socket on:@"message" callback:^(NSArray * _Nonnull data, SocketAckEmitter * _Nonnull ack) {
        // 获取到首个数据
        NSString *jsonString = data[0];
        // 将NSString转化为NSData
        NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        // 解析json为dictionary类型
        NSDictionary *dict = [self toArrayOrNSDictionary:jsonData];
        //NSLog(@"-----------\n %@",dict);

        // 系统事件
        NSString *subEvent = dict[@"EVENT"];
        PLVChat *chat = [PLVChat new];
        
        if ([subEvent isEqualToString:@"CLOSEROOM"]) {      // 聊天室关闭
            NSDictionary *value = dict[@"value"];
            BOOL isClose = [value[@"closed"] boolValue];
            if (isClose) {
                chat.messageType = PLVChatMessageTypeCloseRoom;
                chat.messageContent = @"房间暂时关闭";
            }else {
                chat.messageType = PLVChatMessageTypeOpenRoom;
                chat.messageContent = @"房间已经打开";
            }
        }
        else if ([subEvent isEqualToString:@"GONGGAO"])   // 系统公告
        {
            chat.messageType = PLVChatMessageTypeGongGao;
            chat.messageContent = dict[@"content"];
        }
        else if ([subEvent isEqualToString:@"SPEAK"])     // 用户发言
        {
            chat.messageType = PLVChatMessageTypeSpeak;
            
            NSArray *speakContent = dict[@"values"];
            chat.messageContent = speakContent[0];
            
            NSDictionary *speakerInfo = dict[@"user"];
            Speaker *speaker = [[Speaker alloc] init];
            speaker.clientIp = speakerInfo[@"clientIp"];
            speaker.nickName = speakerInfo[@"nick"];
            speaker.nickImg = speakerInfo[@"pic"];
            speaker.type = speakerInfo[@"userType"];
            
            chat.speaker = speaker;
        }
        else if ([subEvent isEqualToString:@"REWARD"])    // 奖励信息
        {
            chat.messageType = PLVChatMessageTypeReward;
        }
        else if ([subEvent isEqualToString:@"QUESTION"])
        {
            chat.messageType = PLVChatMessageTypeElse;
        }
        else if ([subEvent isEqualToString:@"CLOSE_QUESTION"])
        {
            chat.messageType = PLVChatMessageTypeElse;
        }
        else if ([subEvent isEqualToString:@"ANSWER"])
        {
            chat.messageType = PLVChatMessageTypeElse;
        }
        else if ([subEvent isEqualToString:@"CUSTOMER_MESSAGE"])// 自定义信息
        {
            chat.messageType = PLVChatMessageTypeElse;
        }
        else if ([subEvent isEqualToString:@"ERROR"])     // 出错了
        {
            chat.messageType = PLVChatMessageTypeError;
        }else if ([subEvent isEqualToString:@"KICK"])     // 用户被踢
        {
            chat.messageType = PLVChatMessageTypeElse;
        }else
        {
            chat.messageType = PLVChatMessageTypeElse;
        }
        
        if (self.delegate) {
            // 需要传入一个新的对象
            [self.delegate socketIODidReceiveMessage:chat];
        }
    }];
}


- (void)connect {
    if (socket) {
        [socket connect];
    }
}

- (void)disconnect {
    if (socket) {
        [socket disconnect];
    }
}

- (void)removeAllHandlers {
    if (socket) {
        [socket removeAllHandlers];
    }
}

- (void)reconnect {
    if (socket) {
        [socket reconnect];
    }
}

- (void)sendMessage:(NSDictionary *)jsonData {
    if (socket) {
        NSString *jsonString = [[NSString alloc] initWithData:[self toJSONData:jsonData] encoding:NSUTF8StringEncoding];
        [socket emit:@"message" with:@[jsonString]];
    }
}

#pragma mark - 私有方法

// 将字典或者数组转化为JSON串
- (NSData *)toJSONData:(id)theData{
    
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:theData
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
    
    if ([jsonData length] > 0 && error == nil){
        return jsonData;
    }else{
        return nil;
    }
}

// 将JSON串转化为字典或者数组
- (id)toArrayOrNSDictionary:(NSData *)jsonData{
    NSError *error = nil;
    id jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData
                                                    options:NSJSONReadingAllowFragments
                                                      error:&error];
    
    if (jsonObject != nil && error == nil){
        return jsonObject;
    }else{
        // 解析错误
        return nil;
    }
}

-(void)dealloc {
    //NSLog(@"%@ dealloc", [self class]);
}

@end
