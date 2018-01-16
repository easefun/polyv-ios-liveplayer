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
#import "ZJZDanMu.h"

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

/// 播放器背景图片路径
#define PLAYER_BACKGROUND @"PLVLivePlayerSkin.bundle/plv_background"

@interface LivePlayerViewController () <PLVSocketIODelegate, PLVChatroomDelegate>

@property (nonatomic, strong) PLVLivePlayerController *livePlayer;          // PLV播放器
@property (nonatomic, strong) UIView *displayView;                          // 播放器显示层

@property (nonatomic, strong) ZJZDanMu *danmuLayer;                         // 弹幕

@property (nonatomic, strong) PLVSocketIO *socketIO;                        // 即时通信
@property (nonatomic, assign) BOOL loginSuccess;                            // Socket 登录成功
//@property (nonatomic, strong) PLVSocketObject *login;                       // Socket 登录对象

@property (nonatomic, strong) FTPageController *pageController;             // 页控制器
@property (nonatomic, strong) PLVChatroomController *chatroomController;    // 互动聊天室(房间内公共聊天)
@property (nonatomic, strong) PLVOnlineListController *onlineListController;// 在线列表控制器
@property (nonatomic, strong) PLVChatroomController *privateChatController; // 咨询提问聊天室(房间内私有聊天)

@end

@implementation LivePlayerViewController {
    BOOL _allowLandscape;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initPlayer];
    [self initSocketIO];
    [self configDanmu];
    [self setupUI];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    _allowLandscape = YES;
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
}

#pragma mark - initialize

- (void)initPlayer {
    [IJKFFMoviePlayerController setLogLevel:k_IJK_LOG_INFO];    // IJK日志输出等级
    
    self.livePlayer = [self getLivePlayer];
    [self.livePlayer prepareToPlay];
    [self.livePlayer play];
    
    [self configObservers];
}

- (void)initSocketIO {
    __weak typeof(self)weakSelf = self;
    [PLVChannel requestAuthorizationForLinkingSocketWithChannelId:self.channelId Appld:[PLVSettings sharedInstance].getAppId appSecret:[PLVSettings sharedInstance].getAppSecret success:^(NSDictionary *responseDict) {
        NSString *chatToken = responseDict[@"chat_token"];
        
        // 初始化 socketIO 连接对象
        weakSelf.socketIO = [[PLVSocketIO alloc] initSocketIOWithConnectToken:chatToken enableLog:NO];
        weakSelf.socketIO.delegate = weakSelf;
        [weakSelf.socketIO connect];
        //weakSelf.socketIO.debugMode = YES;
        
        // 初始化一个socket登录对象（昵称和头像使用默认设置）
        [PLVLiveManager sharedLiveManager].login = [PLVSocketObject socketObjectForLoginEventWithRoomId:self.channelId nickName:nil avatar:nil userType:PLVSocketObjectUserTypeStudent];
    } failure:^(PLVLiveErrorCode errorCode, NSString *description) {
        NSLog(@"获取Socket授权失败:%ld,%@",errorCode,description);
    }];
}

- (void)configDanmu {
    CGRect bounds = self.livePlayer.view.bounds;
    self.danmuLayer = [[ZJZDanMu alloc] initWithFrame:CGRectMake(0, 20, bounds.size.width, bounds.size.height-20)];
    [self.livePlayer insertDanmuView:self.danmuLayer];
}

- (void)setupUI {
    self.view.backgroundColor = [UIColor whiteColor];
    CGRect pageCtrlFrame = CGRectMake(0, CGRectGetMaxY(self.displayView.frame), SCREEN_WIDTH, SCREEN_HEIGHT-CGRectGetMaxY(self.displayView.frame));
    
    // 初始化互动聊天室
    self.chatroomController = [[PLVChatroomController alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(pageCtrlFrame), CGRectGetHeight(pageCtrlFrame)-topBarHeight)];
    self.chatroomController.delegate = self;
    // 在线列表控制器
    self.onlineListController = [[PLVOnlineListController alloc] init];
    [self.onlineListController updateOnlineList];
    NSMutableArray *titles = [NSMutableArray arrayWithObjects:@"互动聊天",@"在线列表",nil];
    NSMutableArray *controllers = [NSMutableArray arrayWithObjects:self.chatroomController,self.onlineListController,nil];

    __weak typeof(self)weakSelf = self;
    [PLVChannel getChannelInfoWithQuestionMenuStatus:self.channelId completion:^(BOOL isOn) {
        if (isOn) { // 初始化咨询提问聊天室
            weakSelf.privateChatController = [[PLVChatroomController alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(pageCtrlFrame), CGRectGetHeight(pageCtrlFrame)-topBarHeight)];
            weakSelf.privateChatController.privateChatMode = YES;
            weakSelf.privateChatController.delegate = weakSelf;
            [titles addObject:@"咨询提问"];
            [controllers addObject:self.privateChatController];
        }
        [weakSelf setupPageControllerWithTitles:titles controllers:controllers frame:pageCtrlFrame];
    } failure:^(PLVLiveErrorCode errorCode, NSString *description) {
        NSLog(@"咨询提问状态获取失败:%ld,%@",errorCode,description);
        [weakSelf setupPageControllerWithTitles:titles controllers:controllers frame:pageCtrlFrame];
    }];
}

- (void)setupPageControllerWithTitles:(NSArray *)titles controllers:(NSArray *)controllers frame:(CGRect)frame {
    self.pageController = [[FTPageController alloc] initWithTitles:titles controllers:controllers];
    self.pageController.view.backgroundColor = [UIColor colorWithRed:233/255.0 green:235/255.0 blue:245/255.0 alpha:1.0];
    self.pageController.view.frame = frame;
    [self addChildViewController:self.pageController];
    [self.view addSubview:self.pageController.view];
}

// 注册播放器通知
- (void)configObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(livePlayerReconnectNotification) name:PLVLivePlayerReconnectNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(livePlayerWillChangeToFullScreenNotification) name:PLVLivePlayerWillChangeToFullScreenNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(livePlayerWillExitFullScreenNotification) name:PLVLivePlayerWillExitFullScreenNotification object:nil];
}

#pragma mark - player callback

- (void)configCallBackBlock {
    __weak typeof(self)weakSelf = self;
    [_livePlayer setReturnButtonClickBlcok:^{
        NSLog(@"返回按钮点击了...");
        [weakSelf.socketIO disconnect];
        [[PLVLiveManager sharedLiveManager] resetData];
        [weakSelf dismissViewControllerAnimated:YES completion:nil];
    }];
    [_livePlayer setPlayButtonClickBlcok:^{
        NSLog(@"播放按钮点击了...");
    }];
    [_livePlayer setPauseButtonClickBlcok:^{
        NSLog(@"暂停按钮点击了...");
    }];
    [_livePlayer setFullScreenButtonClickBlcok:^{
        NSLog(@"全屏按钮点击了...");
    }];
    [_livePlayer setSmallScreenButtonClickBlcok:^{
        NSLog(@"小屏按钮点击了...");
    }];
}

#pragma mark - notifications

// 直播播断流后重新连接时创建一个新的播放器
- (void)livePlayerReconnectNotification {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = @"加载JSON...";
    
    __weak typeof(self)weakSelf = self;
    PLVLiveManager *liveManager = [PLVLiveManager sharedLiveManager];
    [PLVChannel loadVideoJsonWithUserId:liveManager.userId channelId:liveManager.channelId completionHandler:^(PLVChannel *channel) {
        weakSelf.channel = channel;
        
        hud.label.text = @"JSON加载成功";
        [hud hideAnimated:YES];
        
        weakSelf.livePlayer = [weakSelf getLivePlayer];
        [weakSelf.livePlayer prepareToPlay];
        [weakSelf.livePlayer play];
        // 如果弹幕存在的话就重新插入弹幕层
        if (weakSelf.danmuLayer) {
            [weakSelf.livePlayer insertDanmuView:self.danmuLayer];
        }
    } failureHandler:^(NSString *errorName, NSString *errorDescription) {
        hud.label.text = @"JSON加载失败";
        [hud hideAnimated:YES];
        DLog("errorName:%@, errorDescription:%@",errorName,errorDescription)
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

#pragma mark - private methods

- (PLVLivePlayerController *)getLivePlayer {
    if (_livePlayer) {
        [_livePlayer clearPlayer];
        _livePlayer = nil ;
    }
    _livePlayer = [[PLVLivePlayerController alloc] initWithChannel:self.channel displayView:self.displayView];
    [self configCallBackBlock];
    
    return _livePlayer;
}

- (UIView *)displayView {
    if (!_displayView) {
        CGFloat width = self.view.bounds.size.width;
        // 初始化一个播放器显示层，用于显示直播内容（默认为竖屏模式，横屏模式需要按需修改）
        _displayView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, width*3.0/4.0)];
        _displayView.backgroundColor = [UIColor blackColor];
        _displayView.layer.contents = (id)[UIImage imageNamed:PLAYER_BACKGROUND].CGImage;  // 播放器背景图
        [self.view addSubview:_displayView];
    }
    return _displayView;
}

#pragma mark - <PLVSocketIODelegate>
/// 连接成功
- (void)socketIO:(PLVSocketIO *)socketIO didConnectWithInfo:(NSString *)info {
    NSLog(@"%@--%@",NSStringFromSelector(_cmd),info);
    [socketIO emitMessageWithSocketObject:[PLVLiveManager sharedLiveManager].login];       // 登录聊天室
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
        [self.onlineListController updateOnlineList];
    }
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
    if (self.socketIO) {
      [self.socketIO emitMessageWithSocketObject:chatRoomObject];
    }
    if (message) {
        [self.danmuLayer insertDML:message];
    }
}

#pragma mark - view controller

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

- (void)dealloc {
    DLog()
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
