//
//  PLVChatRoomManager.m
//  PolyvIJKLivePlayer
//
//  Created by ftao on 2017/1/6.
//  Copyright © 2017年 easefun. All rights reserved.
//

#import "PLVChatRoomManager.h"
#import "PLVTableViewCell.h"
#import <PLVLiveAPI/PLVLiveAPI.h>
#import "BCKeyBoard.h"


#define CHATFONTSIZE 14.0       // 聊天文字大小
#define ChATMAXWIDTH 200.0f     // 聊天内容长度

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

// 返回单元格高度，根据具体内容计算高度
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    PLVChat *chat = listChats[indexPath.row];
    CGSize size = [self autoCalculateWidth:ChATMAXWIDTH
                                  orHeight:MAXFLOAT
                         attributedContent:chat.messageAttributedContent];
    
    if (chat.messageType == PLVChatMessageTypeSpeak)
    {
        return size.height + 60;
    }
    else if (chat.messageType == PLVChatMessageTypeOwnWords)
    {
        return size.height + 40;
    }
    else if (chat.messageType == PLVChatMessageTypeGongGao)
    {
        return 45;
    }
    else if (chat.messageType == PLVChatMessageTypeOpenRoom ||
             chat.messageType == PLVChatMessageTypeCloseRoom ||
             chat.messageType == PLVChatMessageTypeError)
    {
        return 50;
    }
    else
    {
        return 50;
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [listChats count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.backgroundColor = [UIColor clearColor];
    }else{
        for (UIView *cellView in cell.subviews){
            [cellView removeFromSuperview];
        }
    }
    
    PLVChat *chat = listChats[indexPath.row];
    if (chat.messageType == PLVChatMessageTypeSpeak)        // 用户发言
    {
        NSError *error;
        NSData *imgData = [NSData dataWithContentsOfURL:[NSURL URLWithString:chat.speaker.nickImg] options:NSDataReadingMappedIfSafe error:&error];
        // 用户头像
        UIImageView *avatarView = [[UIImageView alloc]initWithFrame:CGRectMake(5, 5, 35, 35)];
        [cell addSubview:avatarView];
        if (error) {
            avatarView.image = [UIImage imageNamed:@"plv_missing_face"];
        }else {
            avatarView.image = [UIImage imageWithData:imgData];
        }
        // 用户名
        UILabel *nickNameLable = [[UILabel alloc] initWithFrame:CGRectMake(50, 5, 123, 20)];
        [cell addSubview:nickNameLable];
        nickNameLable.text = chat.speaker.nickName;
        nickNameLable.textColor = [UIColor darkGrayColor];
        nickNameLable.font = [UIFont boldSystemFontOfSize:11.0];
        // 职称
        // 发言内容
        [cell addSubview:[self bubbleView:chat.messageAttributedContent fromSelf:NO withPosition:35]];
        
        return cell;
    }
    else if (chat.messageType == PLVChatMessageTypeOwnWords)    // 自己的发言
    {
        [cell addSubview:[self bubbleView:chat.messageAttributedContent fromSelf:YES withPosition:10]];
        
        return cell;
    }
    else if (chat.messageType == PLVChatMessageTypeGongGao)     // 聊天室公告
    {
        PLVTableViewCell *cell = [PLVTableViewCell theMessageGongGaoTextCell];
        cell.roomGongGaoLabel.text = [@"公告："stringByAppendingString:chat.messageContent];
        
        return cell;
    }
    else if (chat.messageType == PLVChatMessageTypeOpenRoom||chat.messageType == PLVChatMessageTypeCloseRoom||chat.messageType==PLVChatMessageTypeError)   // 聊天室状态
    {
        PLVTableViewCell *cell = [PLVTableViewCell theMessageStateCell];
        cell.roomStateLabel.text = chat.messageContent;
        
        return cell;
    }
    else
    {
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
    
    if (chat.messageType == PLVChatMessageTypeOwnWords && chatSocket.chatRoomState != PLVChatRoomStateConnected) {
        NSLog(@"聊天室未连接");
        chat.messageType = PLVChatMessageTypeCloseRoom;
        chat.messageContent = @"聊天室未连接";
    }
    
    // 将内容转化为属性文本
    chat.messageAttributedContent = [[PLVEmojiModelManager sharedManager] convertTextEmotionToAttachment:chat.messageContent
                                                                                                    font:[UIFont systemFontOfSize:CHATFONTSIZE]];
    // 数据源更新
    [listChats addObject:chat];
    // 优化，管理socke和聊天内容分开
    //chatSocket.messageType = chat.messageType;
    
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

// 计算属性字符串文本的宽或高
- (CGSize)autoCalculateWidth:(float)width orHeight:(float)height attributedContent:(NSAttributedString *)attributedContent
{
    CGRect rect = [attributedContent boundingRectWithSize:CGSizeMake(width, height)
                                                  options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                                  context:nil];
    return rect.size;
}

// 设置泡泡文本(属性字符串)
- (UIView *)bubbleView:(NSAttributedString *)attributedText fromSelf:(BOOL)fromSelf withPosition:(int)position {
    
    //计算文字大小
    CGSize size = [self autoCalculateWidth:ChATMAXWIDTH
                                  orHeight:MAXFLOAT
                         attributedContent:attributedText];
    
    // build single chat bubble cell with given text
    UIView *returnView = [[UIView alloc] initWithFrame:CGRectZero];
    returnView.backgroundColor = [UIColor clearColor];
    
    //背影图片
    UIImage *bubble = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:fromSelf?@"plv_chatfrom_mine":@"plv_chatfrom_other" ofType:@"png"]];
    
    UIImageView *bubbleImageView = [[UIImageView alloc] initWithImage:[bubble stretchableImageWithLeftCapWidth:floorf(bubble.size.width/2) topCapHeight:floorf(bubble.size.height*0.7)]];
    NSLog(@"%f,%f",size.width,size.height);
    
    //添加文本信息
    UILabel *bubbleText = [[UILabel alloc] initWithFrame:CGRectMake(fromSelf ? 15.0f : 22.0f, fromSelf ? 16.0f : 6.0f, size.width+10, size.height+10)];
    bubbleText.backgroundColor = [UIColor clearColor];
    bubbleText.font = [UIFont systemFontOfSize:CHATFONTSIZE];
    bubbleText.numberOfLines = 0;
    bubbleText.lineBreakMode = NSLineBreakByWordWrapping;
    bubbleText.attributedText =  attributedText;
    
    bubbleImageView.frame = CGRectMake(0, fromSelf ? 10.0 : 0, bubbleText.frame.size.width+30.0f, bubbleText.frame.size.height+20.0f);
    
    if(fromSelf)
        returnView.frame = CGRectMake(CGRectGetWidth(self.view.frame)-position-(bubbleText.frame.size.width+30.0f), 0.0f, bubbleText.frame.size.width+30.0f, bubbleText.frame.size.height+20.0f);
    else
        returnView.frame = CGRectMake(position, 27.0f, bubbleText.frame.size.width+30.0f, bubbleText.frame.size.height+20.0f);
    
    [returnView addSubview:bubbleImageView];
    [returnView addSubview:bubbleText];
    
    return returnView;
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
