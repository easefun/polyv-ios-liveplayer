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

    [self.videoPlayer pause];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [self.videoPlayer play];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGFloat width = self.view.bounds.size.width;
    self.videoPlayer = [[SkinVideoController alloc] initWithFrame:CGRectMake(0, 0, width, width*(3.0/4.0))];
    [self.view addSubview:self.videoPlayer.view];
    [self.videoPlayer setParentViewController:self];
    
    // 加载直播频道信息
    [PLVChannel loadVideoUrl:self.channel.userId channelId:self.channel.channelId completion:^(PLVChannel*channel){
        if (channel==nil) {
            //error handle
            NSLog(@"channel load error");
        }else{
            self.channel = channel;
            self.videoPlayer.channel = channel;
            [self.videoPlayer setHeadTitle:self.channel.name];
            [self.videoPlayer setContentURL:[NSURL URLWithString:self.channel.contentURL]];
           
            [self.videoPlayer play];            // 播放视频
        }
    }];

}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)dealloc
{
    //[self.videoPlayer dismiss];
    NSLog(@"%s",__FUNCTION__);
}


@end
