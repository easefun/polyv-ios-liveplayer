//
//  SkinVideoViewController.m
//  polyvSDK
//
//  Created by seanwong on 8/17/15.
//  Copyright (c) 2015 easefun. All rights reserved.
//

#import "SkinVideoController.h"
#import "SkinVideoControllerView.h"
#import <PLVChannel/PLVReportManager.h>

static const CGFloat pVideoPlayerControllerAnimationTimeinterval = 0.3f;
static const NSTimeInterval pVideoTimeout = 15;
#define TITLECOLOR [UIColor colorWithWhite:0.8 alpha:1]

@interface SkinVideoController ()

@property (nonatomic, strong) SkinVideoControllerView *videoControl;

@property (nonatomic, strong) UIImageView *movieBackgroundView;
@property (nonatomic, assign) BOOL isFullscreenMode;
@property (nonatomic, assign) BOOL isMuted;
@property (nonatomic, assign) BOOL isBitRateViewShowing;
@property (nonatomic, assign) CGRect originFrame;
@property (nonatomic, strong) NSTimer *durationTimer;

@property (nonatomic, assign) NSString* headtitle;
@property (nonatomic, assign) NSString* param1;



@end

@implementation SkinVideoController{
    int _position;
    __weak UINavigationController* _navigationController;
    __weak UIViewController *_parentViewController;
    float _currentVolume;
    NSString *_pid;
    
    NSTimer *_pollPlayerTimer;
    NSTimer *_stallTimer;
    int _watchTimeDuration;
    int _stayTimeDuration;
    NSDate* _firstLoadStartTime;
    NSDate* _secondLoadStartTime;
    BOOL _firstLoadTimeSent;
    BOOL _secondLoadTimeSent;
    
    BOOL _isManualRotateScreen;
    BOOL _isReportedErrorMsg;
}




- (void)dealloc
{
    //NSLog(@"%s",__FUNCTION__);
    [self cancelObserver];
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
}

- (void)clearTimer {
    [_stallTimer invalidate];
    [self endPlayerPolling];
}

- (instancetype)initWithFrame:(CGRect)frame videoLiveType:(SkinVideoLiveType)videoliveType {
    
    _videoLiveType = videoliveType;
    
    return [self initWithFrame:frame];
}


- (instancetype)initWithFrame:(CGRect)frame
{
    // default is
    self = [super init];
    if (self) {
        self.view.frame = frame;
        self.originFrame = frame;

        UIImage *image = [UIImage imageNamed:@"PLVLivePlayer.bundle/background"];       // 设置播放器背景图
        self.view.layer.contents = (id)image.CGImage;

        self.controlStyle = MPMovieControlStyleNone;
        [self.view addSubview:self.videoControl];
        
        //[self.view addSubview:self.backgroundView];
        self.videoControl.frame = self.view.bounds;
        [self configObserver];
        [self configControlAction];
        self.videoControl.closeButton.hidden = YES;
        _currentVolume = [[MPMusicPlayerController applicationMusicPlayer] volume];
        
        [self listeningRotating];                               // 监听旋转通知
    }
    return self;
}


/**
 *  监听设备旋转通知
 */
- (void)listeningRotating
{
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onDeviceOrientationChange)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil
     ];
}


#pragma mark - Override Method

- (void)setContentURL:(NSURL *)contentURL
{
    _pid = [PLVReportManager getPid];
    [self.videoControl.indicatorView startAnimating];
    [super setContentURL:contentURL];
    [self beginPlayerPolling];
    _firstLoadStartTime = [NSDate date];
}
- (void)setNavigationController:(UINavigationController*)navigationController{
    _navigationController = navigationController;
    [_navigationController setNavigationBarHidden:YES animated:NO];
}
- (void)setParentViewController:(UIViewController*)viewController{
    _parentViewController = viewController;
}


- (void)setHeadTitle:(NSString*)headtitle{
    [self.videoControl setHeadTitle:headtitle];
}

- (void)setParam1:(NSString*)param1{
    self.param1 = param1;
}

#pragma mark - Public Method

- (void)showInWindow
{
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    if (!keyWindow) {
        keyWindow = [[[UIApplication sharedApplication] windows] firstObject];
    }
    [keyWindow addSubview:self.view];
    self.view.alpha = 0.0;
    [UIView animateWithDuration:pVideoPlayerControllerAnimationTimeinterval animations:^{
        self.view.alpha = 1.0;
    } completion:^(BOOL finished) {

    }];
    self.videoControl.closeButton.hidden = NO;
    self.videoControl.showInWindowMode = YES;
    //[self enableDanmu:true];
}


- (void)dismiss
{
    [self stopDurationTimer];
    [UIView animateWithDuration:pVideoPlayerControllerAnimationTimeinterval animations:^{
        self.view.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self.view removeFromSuperview];
        if (self.dimissCompleteBlock) {
            self.dimissCompleteBlock();
        }
    }];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
}

- (void)configObserver
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMPMoviePlayerPlaybackStateDidChangeNotification) name:MPMoviePlayerPlaybackStateDidChangeNotification object:nil];      // Posted when a movie player’s playback state has changed.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMPMoviePlayerLoadStateDidChangeNotification) name:MPMoviePlayerLoadStateDidChangeNotification object:nil];          // Posted when a network buffering state has changed.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMPMoviePlayerReadyForDisplayDidChangeNotification) name:MPMoviePlayerReadyForDisplayDidChangeNotification object:nil];    // Posted when the ready for display state changes.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMPMovieDurationAvailableNotification) name:MPMovieDurationAvailableNotification object:nil];            // Posted when the duration of a movie has been determined.
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMPMoviePlayerPlaybackDidFinishNotification:) name:MPMoviePlayerPlaybackDidFinishNotification object:nil];           // Posted when a movie has finished playing.
    

    
    
    
}

- (void)cancelObserver
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)configControlAction
{
    [self.videoControl.playButton addTarget:self action:@selector(playButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.videoControl.backButton addTarget:self action:@selector(backButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.videoControl.pauseButton addTarget:self action:@selector(pauseButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.videoControl.closeButton addTarget:self action:@selector(closeButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.videoControl.fullScreenButton addTarget:self action:@selector(fullScreenButtonClick) forControlEvents:UIControlEventTouchUpInside];
    //[self.videoControl.muteButton addTarget:self action:@selector(muteButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.videoControl.shrinkScreenButton addTarget:self action:@selector(shrinkScreenButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.videoControl.settingButton addTarget:self action:@selector(settingButtonClick) forControlEvents:UIControlEventTouchUpInside];
    
    [self.videoControl.progressSlider addTarget:self action:@selector(progressSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self.videoControl.progressSlider addTarget:self action:@selector(progressSliderTouchBegan:) forControlEvents:UIControlEventTouchDown];
    [self.videoControl.progressSlider addTarget:self action:@selector(progressSliderTouchEnded:) forControlEvents:UIControlEventTouchUpInside];
    [self.videoControl.progressSlider addTarget:self action:@selector(progressSliderTouchEnded:) forControlEvents:UIControlEventTouchUpOutside];
    [self setProgressSliderMaxMinValues];
    [self monitorVideoPlayback];
}

#pragma mark - 通知事件

- (void)onMPMoviePlayerPlaybackStateDidChangeNotification
{
    if (self.playbackState == MPMoviePlaybackStatePlaying) {
        self.videoControl.pauseButton.hidden = NO;
        self.videoControl.playButton.hidden = YES;
        [self.videoControl.indicatorView stopAnimating];
        [self startDurationTimer];
        [self.videoControl autoFadeOutControlBar];
        //NSLog(@"onMPMoviePlayerPlaybackStateDidChangeNotification playing");

        
        
    } else {
       //NSLog(@"onMPMoviePlayerPlaybackStateDidChangeNotification stoped");

        self.videoControl.pauseButton.hidden = YES;
        self.videoControl.playButton.hidden = NO;
        [self stopDurationTimer];
        if (self.playbackState == MPMoviePlaybackStateStopped) {
            [self.videoControl animateShow];
            
        }
        
    }

    
}

- (void)onMPMoviePlayerLoadStateDidChangeNotification
{
    
    //NSLog(@"%@--%ld",NSStringFromSelector(_cmd),self.loadState);

    if (_videoLiveType == SkinVideoLiveTypeWillStop) {
        
        NSError *error = nil;
        NSString *urlStr = [NSString stringWithFormat:@"http://api.live.polyv.net/live_status/query?stream=%@",self.channel.stream];
        NSString *state = [NSString stringWithContentsOfURL:[NSURL URLWithString:urlStr] encoding:NSUTF8StringEncoding error:&error];
        if (!error && [state isEqualToString:@"end\n"]) {       // 字符串中有个"\n"
            NSLog(@"直播结束");
            return;     // 直播停止,不在执行后面的方法
        }
    }
    
    if (self.loadState & MPMovieLoadStateStalled) {         //
        //NSLog(@"onMPMoviePlayerLoadStateDidChangeNotification stalled");
        //开始二次缓冲计时
        if (!_secondLoadTimeSent && _firstLoadTimeSent) {
            NSLog(@"二次缓冲计时开始");
            _secondLoadStartTime = [NSDate date];
        }
        if (_stallTimer) {
            [_stallTimer invalidate];
        }
         _stallTimer = [NSTimer scheduledTimerWithTimeInterval:pVideoTimeout target:self selector:@selector(videoStalled) userInfo:nil repeats:NO];
        
        [self.videoControl.indicatorView startAnimating];
    }
    if (self.loadState & MPMovieLoadStatePlaythroughOK) {
        //NSLog(@"onMPMoviePlayerLoadStateDidChangeNotification playthrough ok");
        if (_stallTimer) {
            [_stallTimer invalidate];
        }
        [self.videoControl.indicatorView stopAnimating];
        //send first load time cost report
        if (!_firstLoadTimeSent) {
            _firstLoadTimeSent = YES;
            double diffTime = [[NSDate date] timeIntervalSinceDate:_firstLoadStartTime];
            [PLVReportManager reportLoading:_pid uid:self.channel.userId channelId:self.channel.channelId time:diffTime * 1000 param1:@"" param2:@"" param3:@"" param4:@"" param5:@"polyv_liveplayer_ios_sdk"];
            
        }
        
        if (!_secondLoadTimeSent && _secondLoadStartTime) {
            _secondLoadTimeSent = YES;
            NSLog(@"二次缓冲发送");
            double diffTime = [[NSDate date] timeIntervalSinceDate:_secondLoadStartTime];
            [PLVReportManager reportBuffer:_pid uid:self.channel.userId channelId:self.channel.channelId time:diffTime * 1000 param1:@"" param2:@"" param3:@"" param4:@"" param5:@"polyv_liveplayer_ios_sdk"];
        }
        
    }
  
}

- (void)onMPMoviePlayerReadyForDisplayDidChangeNotification
{
     //NSLog(@"%@",NSStringFromSelector(_cmd));
}
-(void)onMPMoviePlayerPlaybackDidFinishNotification:(NSNotification *)notification{
    
        //NSLog(@"%@",NSStringFromSelector(_cmd));
    self.videoControl.progressSlider.value = self.duration;
    double totalTime = floor(self.duration);
    [self setTimeLabelValues:totalTime totalTime:totalTime];
    //====error report
    NSDictionary *notificationUserInfo = [notification userInfo];
    NSNumber *resultValue = [notificationUserInfo objectForKey:MPMoviePlayerPlaybackDidFinishReasonUserInfoKey];
    MPMovieFinishReason reason = [resultValue intValue];
    if (reason == MPMovieFinishReasonPlaybackError)
    {
        NSError *mediaPlayerError = [notificationUserInfo objectForKey:@"error"];
        
        NSString*errorstring = @"";
        if (mediaPlayerError)
        {
            errorstring = [NSString stringWithFormat:@"%@",[mediaPlayerError localizedDescription]];
            
        }
        else
        {
            errorstring = @"playback failed without any given reason";
        }
        //retry
        [self.videoControl.indicatorView stopAnimating];
        [self stop];
        [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(play) userInfo:nil repeats:NO];


        if (!_isReportedErrorMsg) {
            _isReportedErrorMsg = YES;
           [PLVReportManager reportError:_pid uid:self.channel.userId channelId:self.channel.channelId error:errorstring param1:self.param1 param2:@"" param3:@"" param4:@"" param5:@"polyv_liveplayer_ios_sdk"];
        }
    }
    
    
}
- (void)onMPMovieDurationAvailableNotification
{
    //NSLog(@"%@",NSStringFromSelector(_cmd));
    [self setProgressSliderMaxMinValues];
}

#pragma mark - 交互事件

-(void)backButtonClick {
    if (self.isFullscreenMode) {
        [self shrinkScreenButtonClick];
        
        
    }else{
        
        [self clearTimer];          // 清除timer,解决循环引用导致的内存无法释放的问题
        
        if (self.goBackBlock) {
            self.goBackBlock();
        }
        
        if (_navigationController) {
            [_navigationController popViewControllerAnimated:YES];
        }else if(_parentViewController){
            
            [_parentViewController dismissViewControllerAnimated:YES completion:nil];
            
        }
        
    }
}

- (void)playButtonClick
{
    [self play];
    self.videoControl.playButton.hidden = YES;
    self.videoControl.pauseButton.hidden = NO;
}

- (void)pauseButtonClick
{
    [self pause];
    self.videoControl.playButton.hidden = NO;
    self.videoControl.pauseButton.hidden = YES;
}
- (void)closeButtonClick
{
    [self dismiss];
}

- (void)settingButtonClick {

    [self.videoControl autoFadeOutControlBar];
    self.videoControl.settingView.hidden = !self.videoControl.settingView.isHidden;
    
    if (!self.videoControl.settingView.subviews.count) {
        [self setPLVVideoScalingModeView:@[@"画面比例",@"等比例适应",@"填充屏幕",@"等比例填充"]];
    }
}


// 设置填充模式视图
- (void)setPLVVideoScalingModeView:(NSArray *)scalingModes {
    for (int i = 0 ; i < scalingModes.count; i++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.tag = 200+i;
        [self.videoControl.settingView addSubview:btn];
        btn.titleLabel.font = [UIFont systemFontOfSize:13];
        [btn.titleLabel setTextAlignment:NSTextAlignmentCenter];
        CGFloat interval = self.videoControl.settingView.frame.size.height/4;
        btn.frame = CGRectMake(0, interval*i, 100, 30);
        [btn setTitle:scalingModes[i] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(changeScalingMode:) forControlEvents:UIControlEventTouchUpInside];
        
        btn.enabled = i;                                                    // title Button
        UIColor *titleColor = i-1 ? TITLECOLOR : [UIColor redColor];        // 默认button
        [btn setTitleColor:titleColor forState:UIControlStateNormal];
    }
}

- (void)changeScalingMode:(UIButton *)button {
    switch (button.tag) {
        case 201:
            [self setScalingMode:MPMovieScalingModeAspectFit];      // 等比例适应(默认)，一边接触到屏幕边缘
            break;
        case 202:
            [self setScalingMode:MPMovieScalingModeFill];           // 填充屏幕
            break;
        case 203:
            [self setScalingMode:MPMovieScalingModeAspectFill];     // 等比例填充
        default:
            break;
    }
    
    [button setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    for (UIButton *btn in self.videoControl.settingView.subviews) {
        if ((btn.tag == 201 || btn.tag == 202 || btn.tag == 203)
            &&btn.tag != button.tag ) {
            [btn setTitleColor:TITLECOLOR forState:UIControlStateNormal];
        }
    }
    //self.videoControl.settingView.hidden = YES;
}

//-(void)muteButtonClick
//{
//    if (!self.isMuted) {
//        [[MPMusicPlayerController applicationMusicPlayer] setVolume:0];
//        [self.videoControl changeToMute];
//        self.isMuted = YES;
//    }else{
//        [[MPMusicPlayerController applicationMusicPlayer] setVolume:0.7];
//        [self.videoControl changeToUnMute];
//        self.isMuted = NO;
//    }
//}

- (void)fullScreenButtonClick
{
    if (self.isFullscreenMode) {
        return;
    }

    _isManualRotateScreen = YES;
    [self setOrientation:UIInterfaceOrientationLandscapeRight];
    [self setOrientationLandscape];

}

- (void)shrinkScreenButtonClick
{
    if (!self.isFullscreenMode) {
        return;
    }
    
    _isManualRotateScreen = YES;
    [self setOrientation:UIInterfaceOrientationPortrait];
    [self setOrientationPortrait];
}



- (void)setProgressSliderMaxMinValues {
    CGFloat duration = self.duration;
    self.videoControl.progressSlider.minimumValue = 0.f;
    self.videoControl.progressSlider.maximumValue = duration;
}

- (void)progressSliderTouchBegan:(UISlider *)slider {
    [self pause];
    [self.videoControl cancelAutoFadeOutControlBar];
}

- (void)progressSliderTouchEnded:(UISlider *)slider {
    [self setCurrentPlaybackTime:floor(slider.value)];
    [self play];
    [self.videoControl autoFadeOutControlBar];
}

- (void)progressSliderValueChanged:(UISlider *)slider {
    double currentTime = floor(slider.value);
    double totalTime = floor(self.duration);
    [self setTimeLabelValues:currentTime totalTime:totalTime];
}

- (void)monitorVideoPlayback
{
    double currentTime = floor(self.currentPlaybackTime);
    double totalTime = floor(self.duration);
     
        
    [self setTimeLabelValues:currentTime totalTime:totalTime];
    self.videoControl.progressSlider.value = ceil(currentTime);
    
    /*if (self.loadState == MPMovieLoadStateUnknown)
    {
        [self pause];
        [self play];
    }*/
    
    
}
-(void)videoStalled {
    NSLog(@"stalled and restart");
    [self.videoControl.indicatorView stopAnimating];
    [self stop];
    [self play];
    [_stallTimer invalidate];
}
- (void)setTimeLabelValues:(double)currentTime totalTime:(double)totalTime {
    double minutesElapsed = floor(currentTime / 60.0);
    double secondsElapsed = fmod(currentTime, 60.0);
    
    NSString *timeElapsedString = [NSString stringWithFormat:@"%02.0f:%02.0f", minutesElapsed, secondsElapsed];
    
    double minutesRemaining = floor(totalTime / 60.0);;
    double secondsRemaining = floor(fmod(totalTime, 60.0));;
    NSString *timeRmainingString = [NSString stringWithFormat:@"%02.0f:%02.0f", minutesRemaining, secondsRemaining];
    
    self.videoControl.timeLabel.text = [NSString stringWithFormat:@"%@/%@",timeElapsedString,timeRmainingString];
}

- (void)startDurationTimer
{
    self.durationTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(monitorVideoPlayback) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.durationTimer forMode:NSDefaultRunLoopMode];
}

- (void)stopDurationTimer
{
    [self.durationTimer invalidate];
}

- (void)fadeDismissControl
{
    [self.videoControl animateHide];
}

#pragma mark - Property

- (SkinVideoControllerView *)videoControl
{
    if (!_videoControl) {
        _videoControl = [[SkinVideoControllerView alloc] init];
    }
    return _videoControl;
}

- (UIImageView *)movieBackgroundView
{
    if (!_movieBackgroundView) {
        _movieBackgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"loading_bgView"]];
        _movieBackgroundView.frame = self.view.bounds;
//        _movieBackgroundView.alpha = 0.0;
        //_movieBackgroundView.backgroundColor = [UIColor blackColor];
    }
    return _movieBackgroundView;
}

- (void)setFrame:(CGRect)frame
{
    [self.view setFrame:frame];
    [self.videoControl setFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
    [self.videoControl setNeedsLayout];
    [self.videoControl layoutIfNeeded];
}


#pragma mark - 屏幕转屏相关

// 设置屏幕旋转方向
- (void)setOrientation:(UIInterfaceOrientation)orientation {
    
    if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)]) {
        SEL selector = NSSelectorFromString(@"setOrientation:");
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDevice instanceMethodSignatureForSelector:selector]];
        [invocation setSelector:selector];
        [invocation setTarget:[UIDevice currentDevice]];
        int val = orientation;
        [invocation setArgument:&val atIndex:2];
        [invocation invoke];
    }
}


// 收到旋屏的通知
- (void)onDeviceOrientationChange {

    if (_isManualRotateScreen) {
        _isManualRotateScreen = NO;
        return;
    }
    
    UIDeviceOrientation orientation             = [UIDevice currentDevice].orientation;
    UIInterfaceOrientation interfaceOrientation = (UIInterfaceOrientation)orientation;
    switch (interfaceOrientation) {
        case UIInterfaceOrientationPortrait:
            [self setOrientationPortrait];
            break;
            
        case UIInterfaceOrientationLandscapeLeft:
        case UIInterfaceOrientationLandscapeRight:
            [self setOrientationLandscape];
        default:
            break;
    }
}


/**
 *  设置竖屏约束
 */
- (void)setOrientationPortrait  {
    
    [UIView animateWithDuration:0.3f animations:^{
        //[self.view setTransform:CGAffineTransformIdentity];
        self.frame = self.originFrame;
  
    } completion:^(BOOL finished) {
        self.isFullscreenMode = NO;
        [self.videoControl changeToSmallsreen];
        self.videoControl.fullScreenButton.hidden = NO;
        self.videoControl.shrinkScreenButton.hidden = YES;
    }];
}

/**
 *  设置横屏约束
 */
- (void)setOrientationLandscape {
    
    [UIView animateWithDuration:0.3f animations:^{
        self.frame = [UIScreen mainScreen].bounds;
        //[self.view setTransform:CGAffineTransformMakeRotation(0)];
        
    } completion:^(BOOL finished) {
        self.isFullscreenMode = YES;
        [self.videoControl changeToFullsreen];
        self.videoControl.fullScreenButton.hidden = YES;
        self.videoControl.shrinkScreenButton.hidden = NO;
    }];
}


#pragma mark - polling

- (void) beginPlayerPolling {
    [self endPlayerPolling];
    NSTimer *tmpTimer = [NSTimer scheduledTimerWithTimeInterval:1
                                                         target:self
                                                       selector:@selector(pollPlayerTimer_tick:)
                                                       userInfo:nil
                                                        repeats:YES];
    
    _pollPlayerTimer = tmpTimer;
    
}

- (void) pollPlayerTimer_tick:(NSObject *)sender {
    _stayTimeDuration++;
    if (self.playbackState == MPMoviePlaybackStatePlaying){
        _watchTimeDuration++;
        if (_watchTimeDuration%4==0) {
            [PLVReportManager stat:_pid uid:self.channel.userId cid:self.channel.channelId flow:0 pd:_watchTimeDuration sd:_stayTimeDuration cts:[self currentPlaybackTime] duration:[self duration]];
        }
        
    }
}

- (void) endPlayerPolling {
    if (_pollPlayerTimer != nil)
    {
        [_pollPlayerTimer invalidate];
        _pollPlayerTimer = nil;
    }
}




@end

