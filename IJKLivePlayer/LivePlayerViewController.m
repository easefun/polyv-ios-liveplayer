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
#import "PLVChatRoomManager.h"
#import "ZJZDanMu.h"

#define WIDTH [UIScreen mainScreen].bounds.size.width
#define HEIGHT [UIScreen mainScreen].bounds.size.height

@interface LivePlayerViewController ()<PLVChatRoomDelegate>

@property (nonatomic, strong) PLVLivePlayerController *livePlayer;  // PLV播放器
@property (nonatomic, strong) UIView *displayView;                  // 播放器显示层

@property (nonatomic, strong) PLVChatRoomManager *chatRoomManager;  // 聊天室管理
@property (nonatomic, strong) ZJZDanMu *danmuLayer;                 // 弹幕层

@end

@implementation LivePlayerViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    /** 初始化播放器、聊天室、弹幕*/
    [self initPlayer];
    [self addChatRoom];
    [self configDanmu];
}

#pragma mark - 初始化配置

// 初始化播放器
- (void)initPlayer {
    
    self.livePlayer = [self getLivePlayer];
    [self.livePlayer prepareToPlay];
    [self.livePlayer play];
    
    [self configObservers];
}

// 添加聊天室
- (void)addChatRoom {

    CGFloat videoBottom = self.livePlayer.view.bounds.size.height;
    self.chatRoomManager = [[PLVChatRoomManager alloc] initWithFrame:CGRectMake(0, videoBottom, WIDTH, HEIGHT-videoBottom)];
    /** 添加自身view和设置currentCtl先后顺序不可变(view层次关系)*/
    [self.view addSubview:self.chatRoomManager.view];
    self.chatRoomManager.currentCrl = self;
    self.chatRoomManager.delegate = self;
    
    // 初始化请求参数
    self.chatRoomManager.channelId = self.channel.channelId;
    self.chatRoomManager.userId = self.channel.userId;
    self.chatRoomManager.nickName = @"iPhoneSimulator";
    self.chatRoomManager.userPic = @"http://www.polyv.net/images/effect/effect-device.png";
}

// 配置弹幕
- (void)configDanmu {
    
    CGRect bounds = self.livePlayer.view.bounds;
    self.danmuLayer = [[ZJZDanMu alloc] initWithFrame:CGRectMake(0, 20, bounds.size.width, bounds.size.height-20)];
    [self.livePlayer insertDanmuView:self.danmuLayer];
}

// 注册播放器通知
- (void)configObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(livePlayerReconnectNotification) name:PLVLivePlayerReconnectNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(livePlayerWillChangeToFullScreenNotification) name:PLVLivePlayerWillChangeToFullScreenNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(livePlayerWillExitFullScreenNotification) name:PLVLivePlayerWillExitFullScreenNotification object:nil];
}

#pragma mark - 播放器回调通知

- (void)configCallBackBlock {
    __weak typeof(self)weakSelf = self;
    [_livePlayer setReturnButtonClickBlcok:^{
        NSLog(@"返回按钮点击了...");
        [weakSelf.chatRoomManager closeChatRoom];
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

// 直播播断流后重新连接时创建一个新的播放器
- (void)livePlayerReconnectNotification {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = @"加载JSON...";
    
    __weak typeof(self)weakSelf = self;
    [PLVChannel loadVideoJsonWithUserId:_channel.userId channelId:_channel.channelId completionHandler:^(PLVChannel *channel) {
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
    [self.chatRoomManager setHiddenView:YES];
}

- (void)livePlayerWillExitFullScreenNotification {
    NSLog(@"将要退出全屏啦");
    [self.chatRoomManager setHiddenView:NO];
}

#pragma mark - 播放器器相关

- (PLVLivePlayerController *)getLivePlayer {
    if (_livePlayer) {
        [_livePlayer clearPlayer];
        _livePlayer = nil ;
    }
    // 初始化PLVLivePlayerController（默认拉流地址为FLV格式）
    _livePlayer = [[PLVLivePlayerController alloc] initWithChannel:self.channel displayView:self.displayView];
    [self configCallBackBlock];
    
    return _livePlayer;
}

- (UIView *)displayView {
    if (!_displayView) {
        CGFloat width = self.view.bounds.size.width;
        // 初始化一个播放器显示层，用于显示直播内容（默认为竖屏模式，横屏模式需要按需修改）
        _displayView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, width*3.0/4.0)];
        [self.view addSubview:_displayView];
    }
    return _displayView;
}

#pragma mark - PLVChatRoomDelegate 聊天室信息回调

- (void)receiveMessage:(NSString *)message {
    
    if (self.danmuLayer) {
        [self.danmuLayer insertDML:message];
    }
}


- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    // 退出键盘
    [self.view endEditing:YES];
    [self.chatRoomManager returnKeyBoard];
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
