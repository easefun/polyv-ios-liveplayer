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
@property (nonatomic, strong) PLVSocketObject *login;                       // Socket 登录对象
@property (nonatomic, assign) BOOL loginSuccess;                            // Socket 登录成功

@property (nonatomic, strong) PLVChatroomController *chatroomController;    // 互动聊天室(房间内公共聊天)
@property (nonatomic, strong) PLVChatroomController *privateChatController;     // 咨询提问聊天室(房间内私有聊天)

@end

@implementation LivePlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initPlayer];
    [self initSocketIO];
    [self configDanmu];
    [self setupUI];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
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
    NSString *chatToken = @"";  // TODO:请求连麦授权接口
    // 初始化 socketIO 连接对象
    self.socketIO = [[PLVSocketIO alloc] initSocketIOWithConnectToken:chatToken enableLog:NO];
    self.socketIO.delegate = self;
    [self.socketIO connect];
    
    // 初始化一个socket登录对象（昵称和头像使用默认设置）
    self.login = [PLVSocketObject socketObjectForLoginEventWithRoomId:[PLVLiveManager sharedLiveManager].channelId.integerValue nickName:nil avatar:nil userType:PLVSocketObjectUserTypeStudent];
}

- (void)configDanmu {
    CGRect bounds = self.livePlayer.view.bounds;
    self.danmuLayer = [[ZJZDanMu alloc] initWithFrame:CGRectMake(0, 20, bounds.size.width, bounds.size.height-20)];
    [self.livePlayer insertDanmuView:self.danmuLayer];
}

- (void)setupUI {
    self.view.backgroundColor = [UIColor whiteColor];
    
    // TODO:请求后台判断是否开启提问功能
    CGRect pageCtrlFrame = CGRectMake(0, CGRectGetMaxY(self.displayView.frame), SCREEN_WIDTH, SCREEN_HEIGHT-CGRectGetMaxY(self.displayView.frame));
    
    // 初始化互动聊天室
    self.chatroomController = [[PLVChatroomController alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(pageCtrlFrame), CGRectGetHeight(pageCtrlFrame)-topBarHeight)];
    self.chatroomController.delegate = self;
    // 初始化咨询提问聊天室
    self.privateChatController = [[PLVChatroomController alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(pageCtrlFrame), CGRectGetHeight(pageCtrlFrame)-topBarHeight)];
    self.privateChatController.privateChatMode = YES;
    self.privateChatController.delegate = self;
    
    NSArray *titles = @[@"互动聊天",@"咨询提问"];
    NSArray *controllers = @[self.chatroomController,self.privateChatController];
    
    FTPageController *pageController = [[FTPageController alloc] initWithTitles:titles controllers:controllers];
    pageController.view.frame = pageCtrlFrame;
    [self addChildViewController:pageController];
    [self.view addSubview:pageController.view];
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
        //[weakSelf.chatRoomManager closeChatRoom];
        [weakSelf.socketIO disconnect];
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
    //[self.chatRoomManager setHiddenView:YES];
}

- (void)livePlayerWillExitFullScreenNotification {
    NSLog(@"将要退出全屏啦");
    //[self.chatRoomManager setHiddenView:NO];
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
    [socketIO emitMessageWithSocketObject:self.login];  // 登录聊天室
}

/// 收到聊天室信息
- (void)socketIO:(PLVSocketIO *)socketIO didReceiveChatMessage:(PLVSocketChatRoomObject *)chatObject {
    NSLog(@"%@--type:%lu, event:%@",NSStringFromSelector(_cmd),chatObject.eventType,chatObject.event);
    NSDictionary *dict = chatObject.jsonDict;
    switch (chatObject.eventType) {
        case PLVSocketChatRoomEventType_LOGIN: {          // 聊天室内容
            self.loginSuccess = YES;
            [[PLVLiveManager sharedLiveManager].chatRoomObjects addObject:chatObject];
            [self.chatroomController updateChatroom];
        } break;
        case PLVSocketChatRoomEventType_GONGGAO:
        case PLVSocketChatRoomEventType_BULLETIN:
        case PLVSocketChatRoomEventType_SPEAK: {
            if (chatObject.eventType == PLVSocketChatRoomEventType_SPEAK) {
                // 移除自己的数据，开启聊天室审核后会收到自己数据
                [self.danmuLayer insertDML:[dict[PLVSocketIOChatRoom_SPEAK_values] firstObject]];
            }else {
                [self.danmuLayer insertDML:[@"公告:" stringByAppendingString:dict[PLVSocketIOChatRoom_GONGGAO_content]]];
            }
            // 更新数据源及显示
            [[PLVLiveManager sharedLiveManager].chatRoomObjects addObject:chatObject];
            [self.chatroomController updateChatroom];
        } break;
        case PLVSocketChatRoomEventType_S_QUESTION:      // 提问内容
        case PLVSocketChatRoomEventType_T_ANSWER: {
            NSString *userId;
            if (chatObject.eventType == PLVSocketChatRoomEventType_S_QUESTION) {
                userId = dict[PLVSocketIOChatRoom_S_QUESTION_userKey][PLVSocketIOChatRoomUserUserIdKey];
            }else {
                userId = dict[PLVSocketIOChatRoom_T_ANSWER_sUserId];
            }
            if ([userId isEqualToString:[NSString stringWithFormat:@"%lu",self.login.userId]]) {
                // 更新提问私聊数据源
                [[PLVLiveManager sharedLiveManager].privateChatObjects addObject:chatObject];
                [self.chatroomController updateChatroom];
            }
        } break;
        default:
            break;
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

- (void)sendMessage:(NSString *)message privateChatMode:(BOOL)privateChatMode {
    if (privateChatMode) {
        PLVSocketChatRoomObject *sQuestion = [PLVSocketChatRoomObject chatRoomObjectForStudentQuestionEventTypeWithLoginObject:self.login content:message];
        [self.socketIO emitMessageWithSocketObject:sQuestion];
        [[PLVLiveManager sharedLiveManager].privateChatObjects addObject:sQuestion];
    }else {
        [self.danmuLayer insertDML:message];
        PLVSocketChatRoomObject *mySpeak = [PLVSocketChatRoomObject chatRoomObjectForSpeakEventTypeWithRoomId:[PLVLiveManager sharedLiveManager].channelId.integerValue content:message];
        [self.socketIO emitMessageWithSocketObject:mySpeak];
        [[PLVLiveManager sharedLiveManager].chatRoomObjects addObject:mySpeak];
    }
    [self.chatroomController updateChatroom];
}

#pragma mark - view controller

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    // 退出键盘
    [self.view endEditing:YES];
    //[self.chatRoomManager returnKeyBoard];
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
