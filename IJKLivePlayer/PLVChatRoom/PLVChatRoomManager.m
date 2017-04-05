//
//  PLVChatRoomManager.m
//  PolyvIJKLivePlayer
//
//  Created by ftao on 2017/1/6.
//  Copyright © 2017年 easefun. All rights reserved.
//

#import "PLVChatRoomManager.h"
#import "PLVTableViewCell.h"
#import <PLVChatManager/PLVChatManager.h>
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
    PLVChatSocket *_chatSocket;
    
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
    
    __weak typeof(self)weakSelf = self;
    [PLVChatRequest getChatTokenWithAppid:[PLVSettings sharedInstance].getAppId appSecret:[PLVSettings sharedInstance].getAppSecret success:^(NSString *chatToken) {
        NSLog(@"chat token is %@", chatToken);
        @try {
            // 初始化聊天室
            _chatSocket = [[PLVChatSocket alloc] initChatSocketWithConnectToken:chatToken enableLog:NO];
            _chatSocket.delegate = self;    // 设置代理
            [_chatSocket connect];          // 连接聊天室
        } @catch (NSException *exception) {
            NSLog(@"exceptin:%@, reason:%@",exception.name,exception.reason);
            NSString *message = [NSString stringWithFormat:@"exception name:%@, reason:%@, chatToken:%@",exception.name,exception.reason,chatToken];
            [weakSelf showAlertWithTitle:@"聊天室连接出错" message:message];
        }
    } failure:^(NSString *errorName, NSString *errorDescription) {
        NSLog(@"errorName: %@, errorDescription: %@",errorName,errorDescription);
        NSString *message = [NSString stringWithFormat:@"name:%@, reason:%@",errorName,errorDescription];
        [weakSelf showAlertWithTitle:@"聊天室未连接" message:message];
    }];
}

#pragma mark - UITableViewDelegate

// 返回单元格高度，根据具体内容计算高度
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    PLVChatObject *chatObject = listChats[indexPath.row];
    CGSize size = [self autoCalculateWidth:ChATMAXWIDTH
                                  orHeight:MAXFLOAT
                         attributedContent:chatObject.messageAttributedContent];
    
    if (chatObject.messageType == PLVChatMessageTypeSpeak)
    {
        return size.height + 60;
    }
    else if (chatObject.messageType == PLVChatMessageTypeOwnWords)
    {
        return size.height + 40;
    }
    else if (chatObject.messageType == PLVChatMessageTypeGongGao)
    {
        return 45;
    }
    else if (chatObject.messageType == PLVChatMessageTypeOpenRoom ||
             chatObject.messageType == PLVChatMessageTypeCloseRoom ||
             chatObject.messageType == PLVChatMessageTypeError)
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
    
    PLVChatObject *chatObject = listChats[indexPath.row];
    if (chatObject.messageType == PLVChatMessageTypeSpeak)        // 用户发言
    {
        NSError *error;
        NSData *imgData = [NSData dataWithContentsOfURL:[NSURL URLWithString:chatObject.speaker.nickImg] options:NSDataReadingMappedIfSafe error:&error];
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
        nickNameLable.text = chatObject.speaker.nickName;
        nickNameLable.textColor = [UIColor darkGrayColor];
        nickNameLable.font = [UIFont boldSystemFontOfSize:11.0];
        // 发言内容
        [cell addSubview:[self bubbleView:chatObject.messageAttributedContent fromSelf:NO withPosition:35]];
        
        return cell;
    }
    else if (chatObject.messageType == PLVChatMessageTypeOwnWords)    // 自己的发言
    {
        [cell addSubview:[self bubbleView:chatObject.messageAttributedContent fromSelf:YES withPosition:10]];
        
        return cell;
    }
    else if (chatObject.messageType == PLVChatMessageTypeGongGao)     // 聊天室公告
    {
        PLVTableViewCell *cell = [PLVTableViewCell theMessageGongGaoTextCell];
        cell.roomGongGaoLabel.text = [@"公告："stringByAppendingString:chatObject.messageContent];
        
        return cell;
    }
    else if (chatObject.messageType == PLVChatMessageTypeOpenRoom||chatObject.messageType == PLVChatMessageTypeCloseRoom||chatObject.messageType==PLVChatMessageTypeError)   // 聊天室状态
    {
        PLVTableViewCell *cell = [PLVTableViewCell theMessageStateCell];
        cell.roomStateLabel.text = chatObject.messageContent;
        
        return cell;
    }
    else
    {
        return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@""];
    }
}

#pragma mark - SocketIO delegate 事件

/** socket成功连接上聊天室*/
- (void)socketIODidConnect:(PLVChatSocket *)chatSocket {
    NSLog(@"socket connected");
    
    // 登录聊天室
    [chatSocket loginChatRoomWithChannelId:self.channelId nickName:self.nickName avatar:self.userPic];
}

/** socket收到聊天室信息*/
- (void)socketIODidReceiveMessage:(PLVChatSocket *)chatSocket withChatObject:(PLVChatObject *)chatObject {
    
    NSLog(@"messageType: %ld",(long)chatObject.messageType);
    
    switch (chatObject.messageType) {
        case PLVChatMessageTypeCloseRoom:
        case PLVChatMessageTypeOpenRoom: {
            NSLog(@"房间暂时关闭/打开");
            [self addNewChatObject:chatObject];
        }
            break;
        case PLVChatMessageTypeGongGao: {
            NSLog(@"GongGao: %@",chatObject.messageContent);
            [self addNewChatObject:chatObject];
        }
            break;
        case PLVChatMessageTypeSpeak: {
            NSLog(@"messageContent, %@",chatObject.messageContent);
            // 容错处理
            if (chatObject.messageContent && ![chatObject.messageContent isKindOfClass:[NSNull class]]) {
                [self addNewChatObject:chatObject];
            }
        }
            break;
        case PLVChatMessageTypeReward:
            
            break;
        case PLVChatMessageTypeError:
            
            break;
        case PLVChatMessageTypeElse:
            
            break;
        default:
            break;
    }
}

- (void)socketIOConnectOnError:(PLVChatSocket *)chatSocket {
    NSLog(@"socket error");
}

- (void)socketIODidDisconnect:(PLVChatSocket *)chatSocket {
    NSLog(@"socket disconnect");
}

- (void)socketIOReconnect:(PLVChatSocket *)chatSocket {
    NSLog(@"socket reconnect");
}

- (void)socketIOReconnectAttempt:(PLVChatSocket *)chatSocket {
    NSLog(@"socket reconnectAttempt");
}

#pragma mark - 私有方法

// 展示alert信息
- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:nil]];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.currentCrl presentViewController:alertController animated:YES completion:nil];
    });
}

// 添加新的聊天
- (void)addNewChatObject:(PLVChatObject *)chatObject {
    
    if (chatObject.messageType == PLVChatMessageTypeOwnWords && _chatSocket.chatRoomState != PLVChatRoomStateConnected) {
        NSLog(@"聊天室未连接");
        chatObject.messageType = PLVChatMessageTypeCloseRoom;
        chatObject.messageContent = @"聊天室未连接";
    }
    
    // 将内容转化为属性文本
    chatObject.messageAttributedContent = [[PLVEmojiModelManager sharedManager] convertTextEmotionToAttachment:chatObject.messageContent
                                                                                                    font:[UIFont systemFontOfSize:CHATFONTSIZE]];
    // 数据源更新
    [listChats addObject:chatObject];
    
    // tableView更新（插入新的cell）
    NSInteger rows = [_tableView numberOfRowsInSection:0];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:rows inSection:0];
    [_tableView beginUpdates];
    [_tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    [_tableView endUpdates];
    
    // 保持添加的row在tableView的底部
    [_tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    
    // 回调聊天信息
    if (chatObject.messageType==PLVChatMessageTypeSpeak || chatObject.messageType==PLVChatMessageTypeOwnWords) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(receiveMessage:)]) {
            [self.delegate receiveMessage:chatObject.messageContent];
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
    [_chatSocket disconnect];        // 断开聊天室
    [_chatSocket removeAllHandlers]; // 移除所有监听事件
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
    
    // 提交发言
    [_chatSocket sendMessageWithContent:text];
    
    // 更新到本地上显示
    [self addNewChatObject:[PLVChatObject chatObjectWithOwnMessageContent:text]];
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
