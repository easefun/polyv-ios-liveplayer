//
//  LivePlayerViewController.m
//  PolyvIJKLivePlayer
//
//  Created by ftao on 2016/12/14.
//  Copyright © 2016年 easefun. All rights reserved.
//

#import "LivePlayerViewController.h"
#import "PLVLivePlayerController.h"
#import <MBProgressHUD/MBProgressHUD.h>
#import <PolyvBusinessSDK/PLVSocketIO.h>
#import "FTPageController.h"
#import "PLVLiveManager.h"
#import "PLVChatroomController.h"
#import "PLVOnlineListController.h"
#import "PLVLiveInfoViewController.h"
#import "ZJZDanMu.h"
#import "PLVUtils.h"

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

/// 播放器背景图片路径
#define PLAYER_BACKGROUND @"PLVLivePlayerSkin.bundle/plv_background"

@interface LivePlayerViewController () <PLVSocketIODelegate, PLVChatroomDelegate, PLVOnlineListDelegate>

@property (nonatomic, strong) UIView *displayView;                          // 播放器显示层
@property (nonatomic, strong) ZJZDanMu *danmuLayer;                         // 弹幕
@property (nonatomic, strong) PLVLivePlayerController *livePlayer;          // PLV播放器

@property (nonatomic, strong) PLVSocketIO *socketIO;
@property (nonatomic, strong) PLVSocketObject *login;                       // Socket 登录对象
@property (nonatomic, assign) BOOL loginSuccess;                            // Socket 登录成功

@property (nonatomic, strong) FTPageController *pageController;             // 页控制器
@property (nonatomic, strong) PLVChatroomController *chatroomController;    // 互动聊天室(房间内公共聊天)
@property (nonatomic, strong) PLVOnlineListController *onlineListController;// 在线列表控制器
@property (nonatomic, strong) PLVChatroomController *privateChatController; // 咨询提问聊天室(房间内私有聊天)

@property (nonatomic, assign) NSUInteger channelId;

@property (nonatomic, assign) BOOL danmuEnable;

@end

@implementation LivePlayerViewController {
    BOOL _allowLandscape;
}

#pragma mark - Lifecycle

- (void)dealloc {
    NSLog(@"-[%@ %@]",NSStringFromClass([self class]),NSStringFromSelector(_cmd));
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    // 判断是否有权限进入房间
    if ([PLVChatroomController havePermissionToWatchLive:self.channel.channelId]) {
        [self initLocalData];
        [self setupUI];
        [self connectToSocketServer];
        [self loadPlayer];
    }else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self showNoPermissionAlert];
        });
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    _allowLandscape = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - View controller

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if (_allowLandscape) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    }else {
        return UIInterfaceOrientationMaskPortrait;
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

#pragma mark - Initialize

- (void)initLocalData {
    self.danmuEnable = YES;
    self.channelId = self.channel.channelId.unsignedIntegerValue;
    [PLVLiveManager sharedLiveManager].channelId = self.channelId;
    
    // 初始化 socket 登录对象，参数传空会生成默认参数
    //NSDictionary *authorization = @{@"actor":@"自定义头衔",@"bgColor":@"#000000",@"fColor":@"#ffffff"};
    self.login = [PLVSocketObject socketObjectForLoginWithRoomId:self.channelId nickName:self.nickName avatar:self.avatar userId:self.userIdForSocket accountId:PLVLiveConfig.sharedInstance.userId authorization:nil userType:PLVSocketObjectUserTypeStudent];
    PLVLiveManager.sharedLiveManager.login = self.login;
}

- (void)connectToSocketServer {
    __weak typeof(self)weakSelf = self;
    [PLVLiveAPI getChatTokenWithChannelId:self.channelId role:@"viewer" userId:self.login.userId appld:PLVLiveConfig.sharedInstance.appId appSecret:PLVLiveConfig.sharedInstance.appSecret completion:^(NSDictionary *responseDict, NSError *error) {
        if (error) {
            [PLVUtils showHUDWithTitle:@"聊天室连接失败！" detail:error.localizedDescription view:weakSelf.view];
        } else {
            self.onlineListController.linkMicParams = responseDict;
            
            NSString *socketServerUrl = nil;
            NSString *chatDomain = responseDict[@"chatDomain"];
            if (chatDomain && [chatDomain isKindOfClass:NSString.class]) {
                socketServerUrl = [NSString stringWithFormat:@"https://%@", chatDomain];
            }
            
            // 初始化 socket 并连接
            weakSelf.socketIO = [[PLVSocketIO alloc] initSocketIOWithConnectToken:responseDict[@"token"] url:socketServerUrl enableLog:NO];
            weakSelf.socketIO.delegate = weakSelf;
            [weakSelf.socketIO connect];
            //weakSelf.socketIO.debugMode = YES;
        }
    }];
}

- (void)loadPlayer {
    self.livePlayer = [self initializeLivePlayer];
    
    __weak typeof(self)weakSelf = self;
    [PLVLiveAPI getStreamStatusWithChannelId:self.channelId stream:self.channel.stream completion:^(PLVLiveStreamState streamState, NSString *mode) {
        if (streamState == PLVLiveStreamStateNoStream) {
            [weakSelf.livePlayer playWithCover];
        }else {
            [weakSelf.livePlayer play];
        }
    } failure:^(PLVLiveErrorCode errorCode, NSString *description) {
        [weakSelf.livePlayer play];
    }];
    
    // 注册播放器通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(livePlayerReconnectNotification:) name:PLVLivePlayerReconnectNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(livePlayerWillChangeToFullScreenNotification) name:PLVLivePlayerWillChangeToFullScreenNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(livePlayerWillExitFullScreenNotification) name:PLVLivePlayerWillExitFullScreenNotification object:nil];
}

- (void)setupUI {
    CGRect pageCtrlFrame = CGRectMake(0, CGRectGetMaxY(self.displayView.frame), SCREEN_WIDTH, SCREEN_HEIGHT-CGRectGetMaxY(self.displayView.frame));
    
    // init public chatroom.
    self.chatroomController = [[PLVChatroomController alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(pageCtrlFrame), CGRectGetHeight(pageCtrlFrame)-topBarHeight)];
    self.chatroomController.delegate = self;
    [self.chatroomController loadSubViews];
    // init online list.
    self.onlineListController = [[PLVOnlineListController alloc] init];
    self.onlineListController.channelId = self.channelId;
    self.onlineListController.delegate = self;
    
    // init page controller.
    self.pageController = [[FTPageController alloc] initWithTitles:@[@"互动聊天", @"在线列表"] controllers:@[self.chatroomController,self.onlineListController]];
    self.pageController.view.backgroundColor = [UIColor colorWithRed:233/255.0 green:235/255.0 blue:245/255.0 alpha:1.0];
    self.pageController.view.frame = pageCtrlFrame;
    [self addChildViewController:self.pageController];
    [self.view addSubview:self.pageController.view];

    __weak typeof(self)weakSelf = self;
    [PLVLiveAPI getChannelMenuInfos:self.channelId completion:^(PLVChannelMenuInfo *channelMenuInfo) {
        for (PLVChannelMenu *menu in channelMenuInfo.channelMenus) {
            if ([@"desc" isEqualToString:menu.menuType] || [@"iframe" isEqualToString:menu.menuType] || [@"text" isEqualToString:menu.menuType]) {
                PLVLiveInfoViewController *liveInfoController = [[PLVLiveInfoViewController alloc] init];
                liveInfoController.channelMenuInfo = channelMenuInfo;
                liveInfoController.menu = menu;
                [weakSelf.pageController addPageWithTitle:menu.name controller:liveInfoController];
            } else if ([@"quiz" isEqualToString:menu.menuType]) {
                weakSelf.privateChatController = [[PLVChatroomController alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(pageCtrlFrame), CGRectGetHeight(pageCtrlFrame)-topBarHeight)];
                weakSelf.privateChatController.privateChatMode = YES;
                weakSelf.privateChatController.delegate = weakSelf;
                [weakSelf.privateChatController loadSubViews];
                [weakSelf.pageController insertPageWithTitle:@"咨询提问" controller:weakSelf.privateChatController atIndex:2];
            }
        }
    } failure:^(PLVLiveErrorCode errorCode, NSString *description) {
        [PLVUtils showHUDWithTitle:@"频道菜单获取失败！" detail:description view:self.view];
    }];
}

#pragma mark - Live Player

- (UIView *)displayView {
    if (!_displayView) {
        CGFloat width = self.view.bounds.size.width;
        // 初始化一个播放器显示层，用于显示直播内容（默认为竖屏模式，横屏模式需要按需修改）
        CGFloat y = [PLVUtils statusBarHeight];
        CGRect rect = CGRectMake(0, 0, width, width * 9 / 16 + y);
        _displayView = [[UIView alloc] initWithFrame:rect];
        _displayView.backgroundColor = [UIColor blackColor];
        //_displayView.layer.contents = (id)[UIImage imageNamed:PLAYER_BACKGROUND].CGImage;  // 播放器背景图
        [self.view addSubview:_displayView];
    }
    return _displayView;
}

- (ZJZDanMu *)danmuLayer {
    if (!_danmuLayer) {
        _danmuLayer = [[ZJZDanMu alloc] initWithFrame:CGRectMake(0, 20, CGRectGetWidth(self.displayView.bounds), CGRectGetHeight(self.displayView.bounds) -20)];
    }
    return _danmuLayer;
}

- (PLVLivePlayerController *)initializeLivePlayer {
    if (_livePlayer) {
        [_livePlayer clearPlayer];
        _livePlayer = nil ;
    }
    _livePlayer = [[PLVLivePlayerController alloc] initWithChannel:self.channel displayView:self.displayView];
    //[IJKFFMoviePlayerController setLogLevel:k_IJK_LOG_INFO];    // 日志等级
    [self configCallBackBlock];
    
    [_livePlayer insertDanmuView:self.danmuLayer]; // 添加弹幕层
    
    return _livePlayer;
}

- (void)configCallBackBlock {
    __weak typeof(self)weakSelf = self;
    [_livePlayer setReturnButtonClickBlock:^{
        NSLog(@"返回按钮点击了...");
        [weakSelf shutdownViewController];
    }];
    [_livePlayer setPlayButtonClickBlock:^{
        NSLog(@"播放按钮点击了...");
    }];
    [_livePlayer setPauseButtonClickBlock:^{
        NSLog(@"暂停按钮点击了...");
    }];
    [_livePlayer setFullScreenButtonClickBlock:^{
        NSLog(@"全屏按钮点击了...");
    }];
    [_livePlayer setSmallScreenButtonClickBlock:^{
        NSLog(@"小屏按钮点击了...");
    }];
    [_livePlayer setCoverImageBeClickedBlock:^(NSString *coverHref) {
        NSLog(@"点击了暖场图片，链接：%@",coverHref);
    }];
    [_livePlayer setDanmuEnableCallBack:^(BOOL danmuEnable) {
        NSLog(@"弹幕开启：%d",danmuEnable);
        weakSelf.danmuEnable = danmuEnable;
    }];
}

#pragma mark Notifications

// 直播播断流后重新连接时创建一个新的播放器
- (void)livePlayerReconnectNotification:(NSNotification *)notification {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = @"加载JSON...";
   
    __weak typeof(self)weakSelf = self;
    [PLVLiveAPI loadChannelInfoRepeatedlyWithUserId:self.channel.userId channelId:self.channelId completion:^(PLVLiveChannel *channel) {
        weakSelf.channel = channel;
        hud.label.text = @"JSON加载成功";
        [hud hideAnimated:YES];
        
        NSDictionary *userInfo = notification.userInfo;
        if (userInfo && userInfo[@"definition"]) {
            [weakSelf.channel updateDefaultDefinitionWithDefinition:userInfo[@"definition"]];
        }
        weakSelf.livePlayer = [weakSelf initializeLivePlayer];
        [weakSelf.livePlayer play];
    } failure:^(PLVLiveErrorCode errorCode, NSString *description) {
        hud.label.text = @"JSON加载失败";
        [hud hideAnimated:YES];
        NSLog(@"errorCode:%ld, description:%@",errorCode,description);
    }];
}

- (void)livePlayerWillChangeToFullScreenNotification {
    NSLog(@"将要全屏啦");
    [self.pageController.view setHidden:YES];
    [self.view endEditing:YES];
}

- (void)livePlayerWillExitFullScreenNotification {
    NSLog(@"将要退出全屏啦");
    [self.pageController.view setHidden:NO];
}

#pragma mark - Private methods

- (void)shutdownViewController {
    [self.livePlayer clearPlayer];
    [self.onlineListController clearController];
    [self.socketIO disconnect];
    [self.socketIO removeAllHandlers];
    [[PLVLiveManager sharedLiveManager] resetData];
    
    if (self.navigationController) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)showNoPermissionAlert {
    __weak typeof(self)weakSelf = self;
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:@"您未被授权观看本直播" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf shutdownViewController];
    }]];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (int)emitSocketIOMessage:(PLVSocketObject *)socketObject {
    if (self.socketIO) {
        if (self.loginSuccess && self.socketIO.socketIOState == PLVSocketIOStateConnected) {
            if (PLVLiveManager.sharedLiveManager.isBanned) {
                NSLog(@"已被禁言");
                return 0;
            } else {
                [self.socketIO emitMessageWithSocketObject:socketObject];
                return 1;
            }
        }else {
            [PLVUtils showHUDWithTitle:@"消息发送失败！" detail:[NSString stringWithFormat:@"登录失败或连接失败，state:%ld",self.socketIO.socketIOState] view:self.view];
            return 0;
        }
    }else {
        NSLog(@"socket.io not init.");
        return 0;
    }
}

#pragma mark - <PLVSocketIODelegate>

// 此方法可能多次调用，如锁屏后返回会重连聊天室
- (void)socketIO:(PLVSocketIO *)socketIO didConnectWithInfo:(NSString *)info {
    NSLog(@"%@--%@",NSStringFromSelector(_cmd),info);

    // 登录 Socket 服务器
    __weak typeof(self)weakSelf = self;
    PLVSocketObject *loginObject = self.login;

    [socketIO loginSocketServer:loginObject timeout:12.0 callback:^(NSArray *ackArray) {
        NSLog(@"login ackArray: %@",ackArray);
        if (ackArray) {
            NSString *ackStr = [NSString stringWithFormat:@"%@",ackArray.firstObject];
            if (ackStr && ackStr.length > 4) {
                int status = [[ackStr substringToIndex:1] intValue];
                if (status == 2) {
                    weakSelf.loginSuccess = YES;
                    [PLVUtils showHUDWithTitle:@"登录成功" detail:nil view:weakSelf.view];
                    BOOL bannedStatus =  [[ackStr substringWithRange:NSMakeRange(4, 1)] boolValue];
                    PLVLiveManager.sharedLiveManager.banned = !bannedStatus;
                } else {
                    [weakSelf loginToSocketFailed:ackStr];
                }
            } else {
                [weakSelf loginToSocketFailed:ackStr];
            }
        }
    }];
}

/*
登陆LOGIN事件ack返回的数据格式改为一个整数，整数每位表示如下：
第1位：登陆结果，2表示成功，4表示传递参数非法等问题，5表示报错
第2位：房间是否合法，即找不到房间id，或者房间id类型不正确，1表示合法，0表示非法
第3位：头像昵称错误，1表示正确，0表示错误
第4位：是否被踢出，1表示没有被踢出房间，0表示已被踢出房间
第5位：是否被禁言，1表示没有被禁言，0表示被禁言
 */
- (void)loginToSocketFailed:(NSString *)ackStr {
    [self.socketIO disconnect];
    self.loginSuccess = NO;
    [PLVUtils showHUDWithTitle:@"登录失败" detail:ackStr view:self.view];
}

// 公聊消息
- (void)socketIO:(PLVSocketIO *)socketIO didReceivePublicChatMessage:(PLVSocketChatRoomObject *)chatObject {
    if (chatObject.eventType == PLVSocketChatRoomEventType_RELOGIN) {
        __weak typeof(self) weakSelf = self;
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"当前账号已在其他地方登录，您将被退出观看" message:nil preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [weakSelf shutdownViewController];
        }]];
        [self presentViewController:alertController animated:YES completion:nil];
        
        return;
    }
    
    [self.chatroomController addNewChatroomObject:chatObject];
    
    NSString *message = [[PLVLiveManager sharedLiveManager] handleChatroomObject:chatObject completion:^(BOOL isChatroom) {
        [self.chatroomController updateChatroom];
    }];
    if (message && self.danmuEnable) {
        [self.danmuLayer insertDML:message];    // 插入弹幕信息
    }
}

// 私聊消息
- (void)socketIO:(PLVSocketIO *)socketIO didReceivePrivateChatMessage:(PLVSocketChatRoomObject *)chatObject {
    [[PLVLiveManager sharedLiveManager] handleChatroomObject:chatObject completion:^(BOOL isChatroom) {
        if (self.privateChatController) {
            [self.privateChatController updateChatroom];
        }
    }];
}

/// 收到连麦消息
- (void)socketIO:(PLVSocketIO *)socketIO didReceiveLinkMicMessage:(PLVSocketLinkMicObject *)linkMicObject {
    NSLog(@"%@--type:%lu, event:%@",NSStringFromSelector(_cmd),linkMicObject.eventType,linkMicObject.event);
    self.onlineListController.linkMicObject = linkMicObject;
}

/// 失去连接
- (void)socketIO:(PLVSocketIO *)socketIO didDisconnectWithInfo:(NSString *)info {
    NSLog(@"%@--%@",NSStringFromSelector(_cmd),info);
    self.loginSuccess = NO;
}

/// 连接出错
- (void)socketIO:(PLVSocketIO *)socketIO connectOnErrorWithInfo:(NSString *)info {
    NSLog(@"%@--%@",NSStringFromSelector(_cmd),info);
}

/// 重连SocketIO服务器
- (void)socketIO:(PLVSocketIO *)socketIO reconnectWithInfo:(NSString *)info {
    NSLog(@"%@--%@",NSStringFromSelector(_cmd),info);
}

/// 本地错误信息
- (void)socketIO:(PLVSocketIO *)socketIO localError:(NSString *)description {
    NSLog(@"%@--%@",NSStringFromSelector(_cmd),description);
}

#pragma mark - <PLVChatroomDelegate>

- (void)chatroom:(PLVChatroomController *)chatroom didOpenError:(PLVChatroomErrorCode)code {
    if (code==PLVChatroomErrorCodeBeKicked) {
        [self showNoPermissionAlert];
    }
}

- (void)emitChatroomObject:(PLVSocketChatRoomObject *)chatRoomObject withMessage:(NSString *)message {
    int code = [self emitSocketIOMessage:chatRoomObject];
    if (code && message && self.danmuEnable) {
        [self.danmuLayer insertDML:message];
    }
}

#pragma mark - <PLVOnlineListDelegate>

- (void)emitLinkMicObject:(PLVSocketLinkMicObject *)linkMicObject {
    [self emitSocketIOMessage:linkMicObject];
}

@end
