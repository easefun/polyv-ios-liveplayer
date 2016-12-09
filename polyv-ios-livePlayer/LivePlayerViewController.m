//
//  LiveViewController.m
//  liveplayer
//
//  Created by seanwong on 10/27/15.
//  Copyright © 2015 easefun. All rights reserved.
//

#import "LivePlayerViewController.h"


@interface LivePlayerViewController ()

@property (nonatomic, strong)  SkinVideoController *videoPlayer;

@end


@implementation LivePlayerViewController

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    //[self.videoPlayer stop];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    //[self.videoPlayer play];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // 初始化播放器
    [self initPlayer];
    
    // 加载直播频道信息并播放
    [self loadVideoJson];
    
    // 监听程序将要进入前台的通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)initPlayer {
    if (self.videoPlayer) {
        // 重新配置播放器
        [self.videoPlayer stop];
        [self.videoPlayer removeObserverAndTime];
        self.videoPlayer.contentURL = nil;
    }
    CGFloat width = self.view.bounds.size.width;
    self.videoPlayer = [[SkinVideoController alloc] initWithFrame:CGRectMake(0, 0, width, width*(3.0/4.0)) videoLiveType:SkinVideoLiveTypeContinuing];
    [self.view addSubview:self.videoPlayer.view];
    [self.videoPlayer setParentViewController:self];    // 设置ParentViewController:或实现goBackBlock属性方法
    
    //__weak typeof(self) weakSelf = self;
    //self.videoPlayer.goBackBlock = ^(){
    //   [weakSelf dismissViewControllerAnimated:YES completion:nil];
    //};
}

- (void)loadVideoJson {
    
    [PLVChannel loadVideoUrl:self.channel.userId channelId:self.channel.channelId completion:^(PLVChannel *channel) {
        self.channel = channel;
        self.videoPlayer.channel = channel;
        [self.videoPlayer setHeadTitle:self.channel.name];
        [self.videoPlayer setContentURL:[NSURL URLWithString:self.channel.contentURL]];
        [self.videoPlayer play];
    } failure:^(NSInteger errorCode, NSString *description) {
        NSLog(@"channel load failure, code:%ld, description:%@",errorCode,description);
    }];
}

- (void)applicationWillEnterForeground  {
    // 为了解决程序在iOS8.4下的一个bug，此处重新初始化播放器，并重新获取videoJson信息
    [self initPlayer];
    // 此处需重新获取videoJson信息，现在视频地址具有防盗链功能(使用之前获取的url可能无法播放)
    [self loadVideoJson];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    DLog("%s",__FUNCTION__);
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
}


@end
