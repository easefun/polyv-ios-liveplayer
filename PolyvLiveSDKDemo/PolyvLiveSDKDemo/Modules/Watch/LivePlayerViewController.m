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
#import <PLVSocketAPI/PLVSocketAPI.h>
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

@property (nonatomic, strong) NSString *userId;
@property (nonatomic, strong) NSString *stream;
@property (nonatomic, assign) NSUInteger channelId;

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
    
    [self initLocalData];
    [self initSocketIO];
    [self loadPlayer];
    
    [self setupUI];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    _allowLandscape = YES;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Initialize

- (void)initLocalData {
    self.userId = self.channel.userId;
    self.stream = self.channel.stream;
    self.channelId = self.channel.channelId.unsignedIntegerValue;
    [PLVLiveManager sharedLiveManager].channelId = self.channelId;
}

- (void)initSocketIO {
    __weak typeof(self)weakSelf = self;
    [PLVLiveAPI requestAuthorizationForLinkingSocketWithChannelId:self.channelId Appld:[PLVLiveConfig sharedInstance].appId appSecret:[PLVLiveConfig sharedInstance].appSecret success:^(NSDictionary *responseDict) {
        // 1.初始化 socketIO 连接对象
        weakSelf.socketIO = [[PLVSocketIO alloc] initSocketIOWithConnectToken:responseDict[@"chat_token"] enableLog:NO];
        weakSelf.socketIO.delegate = weakSelf;
        [weakSelf.socketIO connect];
        
        // 2.初始化一个socket登录对象（昵称和头像使用默认设置）
        self.login = [PLVSocketObject socketObjectForLoginEventWithRoomId:self.channelId nickName:self.nickName avatar:self.avatar userType:PLVSocketObjectUserTypeStudent];
        
        // 3.数据存储
        PLVLiveManager *manager = [PLVLiveManager sharedLiveManager];
        manager.login = self.login;
        manager.linkMicParams = responseDict;
    } failure:^(PLVLiveErrorCode errorCode, NSString *description) {
        [PLVUtils showHUDWithTitle:@"聊天室连接失败！" detail:[NSString stringWithFormat:@"错误码:%ld, 信息:%@",errorCode,description] view:self.view];
    }];
}

- (void)loadPlayer {
    self.livePlayer = [self initializeLivePlayer];
    
    __weak typeof(self)weakSelf = self;
    [PLVLiveAPI getStreamStatusWithChannelId:self.channelId stream:self.stream completion:^(PLVLiveStreamState streamState, NSString *mode) {
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
    self.view.backgroundColor = [UIColor whiteColor];
    CGRect pageCtrlFrame = CGRectMake(0, CGRectGetMaxY(self.displayView.frame), SCREEN_WIDTH, SCREEN_HEIGHT-CGRectGetMaxY(self.displayView.frame));
    
    // 初始化互动聊天室
    self.chatroomController = [[PLVChatroomController alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(pageCtrlFrame), CGRectGetHeight(pageCtrlFrame)-topBarHeight)];
    self.chatroomController.delegate = self;
    // 在线列表控制器
    self.onlineListController = [[PLVOnlineListController alloc] init];
    self.onlineListController.channelId = self.channelId;
    self.onlineListController.delegate = self;
    
    NSMutableArray *titles = [NSMutableArray arrayWithObjects:@"互动聊天", @"在线列表", nil];
    NSMutableArray *controllers = [NSMutableArray arrayWithObjects:self.chatroomController, self.onlineListController, nil];

    __weak typeof(self)weakSelf = self;
    [PLVLiveAPI getChannelMenuInfos:self.channelId completion:^(PLVChannelMenuInfo *channelMenuInfo) {
        for (PLVChannelMenu *menu in channelMenuInfo.channelMenus) {
            if ([@"desc" isEqualToString:menu.menuType] || [@"iframe" isEqualToString:menu.menuType] || [@"text" isEqualToString:menu.menuType]) {
                PLVLiveInfoViewController *liveInfoController = [[PLVLiveInfoViewController alloc] init];
                liveInfoController.channelMenuInfo = channelMenuInfo;
                liveInfoController.menu = menu;
                [titles addObject:menu.name];
                [controllers addObject:liveInfoController];
            } else if ([@"quiz" isEqualToString:menu.menuType]) {
                weakSelf.privateChatController = [[PLVChatroomController alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(pageCtrlFrame), CGRectGetHeight(pageCtrlFrame)-topBarHeight)];
                weakSelf.privateChatController.privateChatMode = YES;
                weakSelf.privateChatController.delegate = weakSelf;
                [titles insertObject:@"咨询提问" atIndex:2];
                [controllers insertObject:self.privateChatController atIndex:2];
            }
        }
        [weakSelf setupPageControllerWithTitles:titles controllers:controllers frame:pageCtrlFrame];
    } failure:^(PLVLiveErrorCode errorCode, NSString *description) {
        [PLVUtils showHUDWithTitle:@"频道菜单获取失败！" detail:description view:self.view];
        [weakSelf setupPageControllerWithTitles:titles controllers:controllers frame:pageCtrlFrame];
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
        // clearController 方法需要在 socketIO disconnect前调用
        [weakSelf.onlineListController clearController];
        [weakSelf.socketIO disconnect];
        [weakSelf.socketIO removeAllHandlers];
        [[PLVLiveManager sharedLiveManager] resetData];
        [weakSelf dismissViewControllerAnimated:YES completion:nil];
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
}

#pragma mark Notifications

// 直播播断流后重新连接时创建一个新的播放器
- (void)livePlayerReconnectNotification:(NSNotification *)notification {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = @"加载JSON...";
   
    __weak typeof(self)weakSelf = self;
    [PLVLiveAPI loadChannelInfoRepeatedlyWithUserId:self.userId channelId:self.channelId completion:^(PLVLiveChannel *channel) {
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

- (void)setupPageControllerWithTitles:(NSArray *)titles controllers:(NSArray *)controllers frame:(CGRect)frame {
    self.pageController = [[FTPageController alloc] initWithTitles:titles controllers:controllers];
    self.pageController.view.backgroundColor = [UIColor colorWithRed:233/255.0 green:235/255.0 blue:245/255.0 alpha:1.0];
    self.pageController.view.frame = frame;
    [self addChildViewController:self.pageController];
    [self.view addSubview:self.pageController.view];
}

- (int)emitSocketIOMessage:(PLVSocketObject *)socketObject {
    if (self.socketIO) {
        //NSLog(@"socketIOState:%ld",self.socketIO.socketIOState);
        if (self.loginSuccess && self.socketIO.socketIOState == PLVSocketIOStateConnected) {
            [self.socketIO emitMessageWithSocketObject:socketObject];
            return 1;
        }else {
            [PLVUtils showHUDWithTitle:@"消息发送失败！" detail:[NSString stringWithFormat:@"登录失败或连接失败，state:%ld",self.socketIO.socketIOState] view:self.view];
            return 0;
        }
    }else {
        NSLog(@"socket.io not init.");
        return 0;
    }
}

//- (void)configDanmu {
//    CGRect bounds = self.livePlayer.view.bounds;
//    self.danmuLayer = [[ZJZDanMu alloc] initWithFrame:CGRectMake(0, 20, bounds.size.width, bounds.size.height-20)];
//    [self.livePlayer insertDanmuView:self.danmuLayer];
//}

#pragma mark - <PLVSocketIODelegate>
/// 连接成功
- (void)socketIO:(PLVSocketIO *)socketIO didConnectWithInfo:(NSString *)info {
    NSLog(@"%@--%@",NSStringFromSelector(_cmd),info);
    [socketIO emitMessageWithSocketObject:self.login];       // 登录聊天室
}

/// 收到聊天室信息
- (void)socketIO:(PLVSocketIO *)socketIO didReceiveChatMessage:(PLVSocketChatRoomObject *)chatObject {
    NSLog(@"%@--type:%lu, event:%@",NSStringFromSelector(_cmd),chatObject.eventType,chatObject.event);
    
    __weak typeof(self)weakSelf = self;
    NSString *message = [[PLVLiveManager sharedLiveManager] handleChatroomObject:chatObject completion:^(BOOL isChatroom) {
        if (isChatroom) {
            [weakSelf.chatroomController updateChatroom];
        }else {
            if (weakSelf.privateChatController) {
              [weakSelf.privateChatController updateChatroom];
            }
        }
    }];
    if (message) {
        [self.danmuLayer insertDML:message];    // 插入弹幕信息
    }
    
    if (chatObject.eventType == PLVSocketChatRoomEventType_LOGIN
        || chatObject.eventType == PLVSocketChatRoomEventType_LOGOUT) {
        self.loginSuccess = YES;
    }
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

- (void)emitChatroomObject:(PLVSocketChatRoomObject *)chatRoomObject withMessage:(NSString *)message {
    int code = [self emitSocketIOMessage:chatRoomObject];
    if (code && message) {
        [self.danmuLayer insertDML:message];
    }
}

#pragma mark - <PLVOnlineListDelegate>

- (void)emitLinkMicObject:(PLVSocketLinkMicObject *)linkMicObject {
    [self emitSocketIOMessage:linkMicObject];
}

#pragma mark - View controller

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    // 退出键盘
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

@end
