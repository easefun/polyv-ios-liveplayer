//
//  PLVChatRoomManager.m
//  PolyvIJKLivePlayer
//
//  Created by ftao on 2017/1/6.
//  Copyright © 2017年 easefun. All rights reserved.
//

#import "PLVChatRoomManager.h"
#import "PLVTableViewCell.h"
#import <PLVLiveAPI/PLVChat.h>
#import "BCKeyBoard.h"

#define TOOLBARHEIGHT 46
#define BACKCOLOR [UIColor colorWithRed:233/255.0 green:235/255.0 blue:245/255.0 alpha:1.0]

@interface PLVChatRoomManager () <SocketIODelegate, BCKeyBoardDelegate, UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UIView *view;

@end

@implementation PLVChatRoomManager  {
    CGRect origionFrame;
    // UI
    UITableView *_tableView;
    UIToolbar *toolBar;
    UITextField *chatInputField;
    // 数据源
    NSMutableArray *listChats;
    // chatSocket管理
    PLVChat *chatSocket;
    // Emoji 键盘
    BCKeyBoard *bcKeyBoard;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super init];
    if (self) {
        self.view.frame = frame;
        origionFrame = frame;
        
        [self setupTableView];
        [self addObservers];
        
        [self configChatSocket];
    }
    return self;
}

#pragma mark - 初始化配置

- (void)setupTableView {
    CGSize size = self.view.bounds.size;
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height-TOOLBARHEIGHT) style:UITableViewStylePlain];
    [self.view addSubview:_tableView];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    // 其他UI样式 头部添加"没有更多数据了"
    [_tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    _tableView.backgroundColor = [UIColor clearColor];
    
    // 初始化数据源
    listChats = [NSMutableArray new];
}

- (void)addObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onKeyboardDidShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onKeyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onKeyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onKeyboardDidShow:) name:UIKeyboardDidChangeFrameNotification object:nil];
}

- (void)configChatSocket {
    
    [PLVChat requestChatTokenCompletion:^(NSString *chatToken) {
        NSLog(@"chat token is %@", chatToken);
        @try {
            chatSocket = [[PLVChat alloc] initChatWithConnectParams:@{@"token":chatToken} enableLog:NO];
            chatSocket.delegate = self;
            [chatSocket connect];
        } @catch (NSException *exception) {
            NSLog(@"chat connect failed, reason:%@",exception.reason);
        }
    } failure:^(NSString *errorName, NSString *errorDescription) {
        NSLog(@"errorName: %@, errorDescription: %@",errorName,errorDescription);
    }];
}

#pragma mark - UITableViewDelegate

// 返回单元格高度
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    PLVChat *chat = listChats[indexPath.row];
    if (chat.messageType==PLVChatMessageTypeSpeak || chat.messageType==PLVChatMessageTypeOwnWords) {
        //根据内容计算高度 两处需要对应：宽度和文字大小（根据cell xib中的约束计算）
        PLVChat *chat = listChats[indexPath.row];
        CGRect rect = [chat.messageContent boundingRectWithSize:CGSizeMake(CGRectGetWidth(self.view.frame)-100, MAXFLOAT)
                                                        options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                                     attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14.0]} context:nil];
        return rect.size.height + 50;
        // 获取一个宽度，设置cell的label
    }else if (chat.messageType==PLVChatMessageTypeGongGao) {
        return 45;
    }else if (chat.messageType==PLVChatMessageTypeOpenRoom || chat.messageType==PLVChatMessageTypeCloseRoom
              || chat.messageType==PLVChatMessageTypeError) {
        return 50;
    }else {
        return 50;
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [listChats count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PLVChat *chat = listChats[indexPath.row];
   
    if (chat.messageType == PLVChatMessageTypeSpeak) {          // 用户发言
        PLVTableViewCell *cell = [PLVTableViewCell theMessageOtherTextCellWithTableView:tableView];
        cell.nickNameLable.text = chat.speaker.nickName;
        cell.contentLabel.attributedText = [[PLVEmojiModelManager sharedManager] convertTextEmotionToAttachment:chat.messageContent font:cell.contentLabel.font];
        // 请求头像图片
        NSError *error;
        NSData *imgData = [NSData dataWithContentsOfURL:[NSURL URLWithString:chat.speaker.nickImg] options:NSDataReadingMappedIfSafe error:&error];
        if (error) {
            cell.avatarImageView.image = [UIImage imageNamed:@"plv_missing_face"];
        }else {
            cell.avatarImageView.image = [UIImage imageWithData:imgData];
        }
        
        return cell;
    }
    else if (chat.messageType == PLVChatMessageTypeOwnWords){    // 自己的发言
        PLVTableViewCell *cell = [PLVTableViewCell theMessageOwnTextCellWithTableView:tableView];
        cell.mySpeakLabel.attributedText = [[PLVEmojiModelManager sharedManager] convertTextEmotionToAttachment:chat.messageContent font:cell.mySpeakLabel.font];
        
        return cell;
    }else if (chat.messageType == PLVChatMessageTypeGongGao){       // 聊天室公告
        PLVTableViewCell *cell = [PLVTableViewCell theMessageGongGaoTextCell];
        cell.roomGongGaoLabel.text = [@"公告："stringByAppendingString:chat.messageContent];
        
        return cell;
    }else if (chat.messageType == PLVChatMessageTypeOpenRoom||chat.messageType == PLVChatMessageTypeCloseRoom){      // 聊天室状态
        PLVTableViewCell *cell = [PLVTableViewCell theMessageStateCell];
        cell.roomStateLabel.text = chat.messageContent;
        
        return cell;
    }else {
        return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@""];
    }
}


#pragma mark - SocketIO delegate 事件

/** socket成功连接上聊天室*/
- (void)socketIODidConnect:(PLVChat *)chat {
    NSLog(@"socket connected");

    NSArray *values = @[self.nickName,self.userPic,self.userId];
    NSDictionary *dict = @{@"EVENT":@"LOGIN", @"values":values, @"roomId":self.channelId};
    
    [chat sendMessage:dict];
}

/** socket收到聊天室信息*/
- (void)socketIODidReceiveMessage:(PLVChat *)chat {
    NSLog(@"%ld,",chat.messageType);
    
    switch (chat.messageType) {
        case PLVChatMessageTypeCloseRoom:
        case PLVChatMessageTypeOpenRoom: {
            NSLog(@"房间暂时关闭/打开");
            [self addNewChat:chat];
        }
            break;
        case PLVChatMessageTypeGongGao: {
            NSLog(@"GongGao: %@",chat.messageContent);
            [self addNewChat:chat];
        }
            break;
        case PLVChatMessageTypeSpeak: {
            NSLog(@"messageContent, %@",chat.messageContent);
            // 容错处理，
            if (chat.messageContent && ![chat.messageContent isKindOfClass:[NSNull class]]) {
                [self addNewChat:chat];
            }
        }
            break;
        case PLVChatMessageTypeReward:
            
            break;
        case PLVChatMessageTypeElse:
            
            break;
        case PLVChatMessageTypeError:
            
            break;
        default:
            break;
    }
}

- (void)socketIOConnectOnError:(PLVChat *)chat {
    NSLog(@"socket error");
}

- (void)socketIODidDisconnect:(PLVChat *)chat {
    NSLog(@"socket disconnect");
}

- (void)socketIOReconnect:(PLVChat *)chat {
    NSLog(@"socket reconnect");
}

- (void)socketIOReconnectAttempt:(PLVChat *)chat {
    NSLog(@"socket reconnectAttempt");
}

#pragma mark - 私有方法

// 添加新的聊天
- (void)addNewChat:(PLVChat *)chat {
    // 数据源更新
    [listChats addObject:chat];
    
    // tableView更新（插入新的cell）
    NSInteger rows = [_tableView numberOfRowsInSection:0];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:rows inSection:0];
    [_tableView beginUpdates];
    [_tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    [_tableView endUpdates];
    
    // 保持添加的row在tableView的底部
    [_tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    
    // 回调聊天信息
    if (chat.messageType==PLVChatMessageTypeSpeak || chat.messageType==PLVChatMessageTypeOwnWords) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(receiveMessage:)]) {
            [self.delegate receiveMessage:chat.messageContent];
        }
    }
}

// 计算宽窄
-(float)autoCalculateWidthOrHeight:(float)height
                             width:(float)width
                          fontsize:(float)fontsize
                           content:(NSString*)content
{
    //计算出rect
    CGRect rect = [content boundingRectWithSize:CGSizeMake(width, height)
                                        options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                     attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:fontsize]} context:nil];
    
    //判断计算的是宽还是高
    if (height == MAXFLOAT) {
        return rect.size.height;
    }
    else
        return rect.size.width;
}

#pragma mark - 外部接口方法

- (void)closeChatRoom {
    [chatSocket disconnect];        // 断开聊天室
    [chatSocket removeAllHandlers]; // 移除所有监听事件
}

- (void)returnKeyBoard {
    [bcKeyBoard hideTheKeyBoard];
}

// 隐藏显示键盘、view等处理
- (void)setHiddenView:(BOOL)hidden {
    if (hidden) {
        [bcKeyBoard hideTheKeyBoard];
    }else {
        [self setViewFrame:origionFrame];
        [bcKeyBoard setFrame:CGRectMake(0, SCREEN_HEIGHT-TOOLBARHEIGHT, SCREEN_WIDTH, TOOLBARHEIGHT)];
    }
    [self.view setHidden:hidden];
    [bcKeyBoard setHidden:hidden];
}

#pragma mark - 键盘通知

- (void)onKeyboardDidShow:(NSNotification *)notification
{
//    if (bcKeyBoard.isFirstResponder)
//    {
        NSDictionary *userInfo = notification.userInfo;
        CGRect endFrame = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
        CGFloat duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
        
        [UIView animateWithDuration:duration animations:^{
            [UIView setAnimationCurve:[userInfo[UIKeyboardAnimationCurveUserInfoKey] doubleValue]];
            
            CGRect frame = self.view.frame;
            frame.size.height = endFrame.origin.y - origionFrame.origin.y;
            [self setViewFrame:frame];
            [self.view layoutIfNeeded];
        }];
//    }
}

- (void)onKeyboardWillHide:(NSNotification *)notification
{
    NSDictionary* userInfo = [notification userInfo];
    CGFloat duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    [UIView animateWithDuration:duration animations:^{
        [UIView setAnimationCurve:[userInfo[UIKeyboardAnimationCurveUserInfoKey] doubleValue]];
        
        CGRect frame = origionFrame;
        [self setViewFrame:frame];
        [self.view layoutIfNeeded];
    }];
}

#pragma mark - face view代理方法

- (void)didSendText:(NSString *)text {
    NSLog(@"--- %@",text);
    if ([text isEqualToString:@""]) {
        return;
    }
    NSDictionary *dict = @{
                           @"EVENT":@"SPEAK",
                           @"values":@[text],
                           @"roomId":self.channelId };
    [chatSocket sendMessage:dict];
    // 更新到本地上显示
    [self addNewChat:[PLVChat chatWithOwnMessageContent:text]];
}

- (void)returnHeight:(CGFloat)height {
    NSLog(@"--- %f",height);
}

#pragma mark - 重写

- (UIView *)view {
    if (!_view) {
        _view = [[UIView alloc] init];
        _view.backgroundColor = BACKCOLOR;
    }
    return _view;
}

- (void)setViewFrame:(CGRect)frame {
    self.view.frame = frame;
    _tableView.frame = CGRectMake(0, 0, frame.size.width, frame.size.height-TOOLBARHEIGHT);
}

- (void)setCurrentCrl:(UIViewController *)currentCrl {
    _currentCrl = currentCrl;
    
    [self setupEmojiKeyBoard];
}

- (void)setupEmojiKeyBoard {
    // 添加表情键盘
    bcKeyBoard = [[BCKeyBoard alloc] initWithFrame:CGRectMake(0, SCREEN_HEIGHT-TOOLBARHEIGHT, SCREEN_WIDTH, TOOLBARHEIGHT)];
    [self.currentCrl.view addSubview:bcKeyBoard];
    bcKeyBoard.delegate = self;
    
    bcKeyBoard.placeholder = @"我也来聊几句...";
    bcKeyBoard.placeholderColor = [UIColor colorWithRed:133/255 green:133/255 blue:133/255 alpha:0.5];
    bcKeyBoard.backgroundColor = [UIColor clearColor];
}

- (void)dealloc {
    NSLog(@"%@ dealloc", [self class]);
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
