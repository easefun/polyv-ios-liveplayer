//
//  PLVLivePlayerController.m
//  PolyvIJKLivePlayer
//
//  Created by ftao on 2016/12/16.
//  Copyright © 2016年 easefun. All rights reserved.
//

#import "PLVLivePlayerController.h"
#import "PLVLivePlayerControllerSkin.h"

NSString * const PLVLivePlayerReconnectNotification = @"PLVLivePlayerReconnectNotification";
NSString * const PLVLivePlayerWillChangeToFullScreenNotification = @"PLVLivePlayerWillChangeToFullScreenNotification";
NSString * const PLVLivePlayerWillExitFullScreenNotification = @"PLVLivePlayerWillExitFullScreenNotification";

#define PlayerErrorDomain @"net.polyv.live"

@interface PLVLivePlayerController ()

@property (nonatomic, strong) NSURL *contentURL;

@property (nonatomic, strong) PLVLivePlayerControllerSkin *playerSkin;

@property (nonatomic, weak) UIView *displayView;    // 引用外部的显示层
@property (nonatomic, assign) CGRect originFrame;   // 初始设置的frame

@end

@implementation PLVLivePlayerController {
    
    NSTimer *_liveStatusTimer;
    NSTimer *_playerPollingTimer;
    
    /** 直播服务质量/观看统计*/
    NSString *_pid;
    NSDate *_firstLoadStartDate;
    NSDate *_secondBufferStartDate;
    BOOL _isFirstLoadTimeSent;
    BOOL _isSecondBufferTimeSent;
    BOOL _isPlayerErrorSend;
    NSInteger _reportFreq;
    int _watchTimeDuration;
    int _stayTimeDuration;
    // 自定义参数
    NSString *_param1;
    NSString *_param2;
    NSString *_param3;
    NSString *_param4;
    NSString *_param5;
    NSString *_sessionId;
}

#pragma mark - 初始化方法

- (instancetype)initWithChannel:(PLVChannel *)channel displayView:(UIView *)displayView playHLS:(BOOL)playHLS {
    if (playHLS) {
        self.channel = channel;
        NSURL *aUrl = [NSURL URLWithString:channel.m3u8Url]; // 拉流地址为M3U8
        return [self initWithContentURL:aUrl displayView:displayView];
    }else {
        return [self initWithChannel:channel displayView:displayView];
    }
}

- (instancetype)initWithChannel:(PLVChannel *)channel displayView:(UIView *)displayView {
    self.channel = channel;
    
    NSURL *aUrl = [NSURL URLWithString:channel.flvUrl]; // 默认拉流地址为FLV格式
    return [self initWithContentURL:aUrl displayView:displayView];
}

- (instancetype)initWithContentURLString:(NSString *)aUrlString displayView:(UIView *)displayView {
    
    NSURL *aUrl = [NSURL URLWithString:aUrlString];
    return [self initWithContentURL:aUrl displayView:displayView];
}

- (instancetype)initWithContentURL:(NSURL *)aUrl displayView:(UIView *)displayView {
    [self.playerSkin addVideoInfoWithDescription:@"初始化播放器..."];
    self.contentURL = aUrl;
    _firstLoadStartDate = [NSDate date];
    
    // 此处可配置初始化IJK播放器的选项
    IJKFFOptions *options = [IJKFFOptions optionsByDefault];
    /** FFmpeg 参数配置*/
    [options setPlayerOptionIntValue:1 forKey:@"videotoolbox"]; // 打开硬解
    // specify how many microseconds are analyzed to probe the input (from 0 to I64_MAX)
    [options setFormatOptionValue:@"500000" forKey:@"analyzeduration"];
    // set probing size (from 32 to I64_MAX)
    [options setFormatOptionValue:@"4096" forKey:@"probsize"];
    //[options setFormatOptionValue:@"nobuffer" forKey:@"fflags"];
    //[options setFormatOptionIntValue:3 forKey:@"reconnect"];
    
    self = [super initWithContentURL:aUrl withOptions:options];
    
    if (self) {
        [self prepareToPlay];
        
        self.displayView = displayView;
        self.originFrame = displayView.bounds;
        self.streamState = PLVLiveStreamStateUnknown;
        
        displayView.backgroundColor = [UIColor blackColor];
        displayView.layer.contents = (id)[UIImage imageNamed:BACKGROUNDIMAGE].CGImage;  // 播放器背景图
        
        // 添加IJK播放器至displayView
        self.view.frame = displayView.bounds;
        self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [displayView addSubview:self.view];
        
        // 添加皮肤视图至IJK播放器
        self.playerSkin.frame = self.view.bounds;
        self.playerSkin.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.view addSubview:self.playerSkin];
        
        [self addPlayerSkinActions];
        
        [self configObservers];
        
        [self setShouldAutoplay:YES];
        [self setScalingMode:IJKMPMovieScalingModeAspectFit];
        //[self setPauseInBackground:NO];   // 后台播放模式(后台音频输出，还需在工程中打开后台音乐权限UIBackgroundModes：Audio，Airplay...)
        
#ifdef DEBUG
        [IJKFFMoviePlayerController setLogLevel:k_IJK_LOG_DEBUG];
#else
        [IJKFFMoviePlayerController setLogReport:NO];
        [IJKFFMoviePlayerController setLogLevel:k_IJK_LOG_INFO];
#endif
        // 添加手势事件
        [self addGestureActions];
        // 添加定时器事件
        [self addTimerEvents];
        
        // 开启活动指示器
        [self.playerSkin.indicatorView startAnimating];
        // 获取播放器ID
        _pid = [PLVReportManager getPid];
        
        [self.playerSkin addVideoInfoWithDescription:@"播放器初始化完成"];
    }
    
    return self;
}

#pragma mark - 初始化配置

- (void)configObservers {
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter addObserver:self selector:@selector(movieNaturalSizeAvailable:) name:IJKMPMovieNaturalSizeAvailableNotification object:nil];
    
    [defaultCenter addObserver:self selector:@selector(mediaPlaybackIsPreparedToPlay:) name:IJKMPMediaPlaybackIsPreparedToPlayDidChangeNotification object:nil];
    
    [defaultCenter addObserver:self selector:@selector(moviePlayerLoadStateDidChange:) name:IJKMPMoviePlayerLoadStateDidChangeNotification object:nil];
    [defaultCenter addObserver:self selector:@selector(moviePlayerPlaybackStateDidChange:) name:IJKMPMoviePlayerPlaybackStateDidChangeNotification object:nil];
    [defaultCenter addObserver:self selector:@selector(moviePlayerPlaybackDidFinish:) name:IJKMPMoviePlayerPlaybackDidFinishNotification object:nil];
    
    [defaultCenter addObserver:self selector:@selector(moviePlayerVideoDecoderOpen:) name:IJKMPMoviePlayerVideoDecoderOpenNotification object:nil];
    [defaultCenter addObserver:self selector:@selector(moviePlayerFirstVideoFrameRendered:) name:IJKMPMoviePlayerFirstVideoFrameRenderedNotification object:nil];
    [defaultCenter addObserver:self selector:@selector(moviePlayerFirstAudioFrameRendered:) name:IJKMPMoviePlayerFirstAudioFrameRenderedNotification object:nil];
    
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [defaultCenter addObserver:self selector:@selector(deviceOrientationDidChange) name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)addPlayerSkinActions {
    [self.playerSkin.returnButton addTarget:self action:@selector(returnButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.playerSkin.playButton addTarget:self action:@selector(playButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.playerSkin.pauseButton addTarget:self action:@selector(pauseButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.playerSkin.fullScreenButton addTarget:self action:@selector(fullScreenButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.playerSkin.smallScreenButton addTarget:self action:@selector(smallScreenButtonClick) forControlEvents:UIControlEventTouchUpInside];
}

- (void)addGestureActions {
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(screenBeClicked)];
    [self.view addGestureRecognizer:tapGesture];
}

- (void)addTimerEvents {
    _liveStatusTimer = [NSTimer scheduledTimerWithTimeInterval:6.0 target:self
                                                      selector:@selector(onTimeCheckLiveStreamState) userInfo:nil repeats:YES];
    _playerPollingTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self
                                                         selector:@selector(playerPollingTimerTick) userInfo:nil repeats:YES];
    [_liveStatusTimer fire];
    // 超时未加载出视频逻辑
}

#pragma mark - 播放器通知内部方法处理

// -----------------------------------------------------------------------------
// Movie Property Notifications

- (void)movieNaturalSizeAvailable:(NSNotification *)notification {
    DLog("获取到视频信息")
}

// -----------------------------------------------------------------------------
//  MPMediaPlayback.h

- (void)mediaPlaybackIsPreparedToPlay:(NSNotification *)notification {
    [self.playerSkin addVideoInfoWithDescription:@"视频即将播放"];
}

// -----------------------------------------------------------------------------
//  MPMoviePlayerController.h
//  Movie Player Notifications

- (void)moviePlayerLoadStateDidChange:(NSNotification *)notification {
    DLog()
    if (self.loadState & IJKMPMovieLoadStateStalled) {
        [self.playerSkin.indicatorView startAnimating];
        if (_isFirstLoadTimeSent && !_isSecondBufferTimeSent) _secondBufferStartDate = [NSDate date];
    }else {
        [self.playerSkin.indicatorView stopAnimating];
    }
    
    if (self.loadState & IJKMPMovieLoadStatePlaythroughOK) {
        [self reportFirstLoading];   // 发送首次加载时长（二次缓冲时长）
    }
}

- (void)moviePlayerPlaybackStateDidChange:(NSNotification *)notification {
    if (self.playbackState==IJKMPMoviePlaybackStatePlaying) {
        DLog("开始播放")
        [self.playerSkin hideVideoInfo];
        [self.playerSkin.playButton setHidden:YES];
        [self.playerSkin.pauseButton setHidden:NO];
        [self.playerSkin.indicatorView stopAnimating];
    }else if (self.playbackState==IJKMPMoviePlaybackStateStopped || self.playbackState==IJKMPMoviePlaybackStatePaused) {
        DLog("暂停/停止播放")
        [self.playerSkin.playButton setHidden:NO];
        [self.playerSkin.pauseButton setHidden:YES];
    }
}

- (void)moviePlayerPlaybackDidFinish:(NSNotification *)notification {
    DLog()
    NSDictionary *dict = [notification userInfo];
    NSNumber *finishReason =  dict[IJKMPMoviePlayerPlaybackDidFinishReasonUserInfoKey];
    switch (finishReason.integerValue) {
        case IJKMPMovieFinishReasonPlaybackEnded: {
            DLog("IJKMPMovieFinishReasonPlaybackEnded")
            [self.playerSkin.playButton setHidden:NO];
            [self.playerSkin.pauseButton setHidden:YES];
        }
            break;
        case IJKMPMovieFinishReasonPlaybackError: {
            DLog("IJKMPMovieFinishReasonPlaybackError")
            [self.playerSkin addVideoInfoWithDescription:@"出错啦~"];
            [self.playerSkin.indicatorView stopAnimating];
            [self playbackFailureAnalysis];   // 播放器出错分析
        }
            break;
        case IJKMPMovieFinishReasonUserExited: {
            DLog("IJKMPMovieFinishReasonUserExited")
        }
            break;
            
        default:
            break;
    }
}

// -----------------------------------------------------------------------------
//  Extend Notifications

- (void)moviePlayerVideoDecoderOpen:(NSNotification *)notifacation {
    DLog("播放器编码器打开")
}

- (void)moviePlayerFirstVideoFrameRendered:(NSNotification *)notification {
    DLog()
}

- (void)moviePlayerFirstAudioFrameRendered:(NSNotification *)notification {
    DLog()
}

#pragma mark - 旋屏通知

- (void)deviceOrientationDidChange {
    UIInterfaceOrientation interfaceOrientation = (UIInterfaceOrientation)[[UIDevice currentDevice] orientation];
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

#pragma mark - 播放器点击事件处理

- (void)returnButtonClick {
    
    if (CGRectEqualToRect(self.view.frame, [UIScreen mainScreen].bounds)) {
        // 当前控制器旋转至竖屏
        [self setOrientation:UIInterfaceOrientationPortrait];
    }else {
        [self clearPlayer];
        if (self.returnButtonClickBlcok) self.returnButtonClickBlcok();
    }
}

- (void)playButtonClick {
    [self play];
    [self.playerSkin.playButton setHidden:YES];
    [self.playerSkin.pauseButton setHidden:NO];
    
    if (self.playButtonClickBlcok) self.playButtonClickBlcok();
}

- (void)pauseButtonClick {
    [self pause];
    [self.playerSkin.pauseButton setHidden:YES];
    [self.playerSkin.playButton setHidden:NO];
    
    if (self.pauseButtonClickBlcok) self.pauseButtonClickBlcok();
}

- (void)fullScreenButtonClick {
    [self.playerSkin.fullScreenButton setHidden:YES];
    [self.playerSkin.smallScreenButton setHidden:NO];
    
    // 当前控制器旋转至横屏
    [self setOrientation:UIInterfaceOrientationLandscapeRight];
    
    if (self.fullScreenButtonClickBlcok) self.fullScreenButtonClickBlcok();
}

- (void)smallScreenButtonClick {
    
    // 当前控制器旋转至竖屏
    [self setOrientation:UIInterfaceOrientationPortrait];
    
    if (self.smallScreenButtonClickBlcok) self.smallScreenButtonClickBlcok();
}

- (void)screenBeClicked {
    if (self.playerSkin.isSkinShowing) {
        [self.playerSkin animateHideSkin];
    }else {
        [self.playerSkin animateShowSkin];
    }
}

#pragma mark - 外部接口方法

// 设置标题；旋屏通知/回调；直接全屏样式
+ (NSArray *)getSDKVersion {
    return @[[PLVReportManager getSDKVersion]];
}

- (void)insertDanmuView:(UIView *)danmuView {
    [self.playerSkin insertSubview:danmuView belowSubview:self.playerSkin.topBar];
}

#pragma mark - 重写

- (void)play {
    [super play];
    [self.playerSkin addVideoInfoWithDescription:@"视频加载中..."];
}

- (PLVLivePlayerControllerSkin *)playerSkin {
    if (!_playerSkin) {
        _playerSkin = [[PLVLivePlayerControllerSkin alloc] init];
    }
    return _playerSkin;
}

- (void)setFrame:(CGRect)frame {
    _frame = frame;
    self.displayView.frame = frame;
}

- (void)setChannel:(PLVChannel *)channel {
    _channel = channel;
    _reportFreq = channel.reportFreq.integerValue;
}

- (void)setStreamState:(PLVLiveStreamState)streamState {
    switch (streamState) {
        case PLVLiveStreamStateNoStream: {
            DLog("直播未在进行")
            if (self.playerSkin.noLiveImageView.isHidden) {
                [self.playerSkin.noLiveImageView setHidden:NO];
                [self.playerSkin.indicatorView stopAnimating];
                [self.playerSkin hideVideoInfo];
                [self shutdown];    // 播放器停止
            }
        }
            break;
        case PLVLiveStreamStateLive: {
            DLog("直播中")
            if (!self.playerSkin.noLiveImageView.isHidden && self.playbackState == IJKMPMoviePlaybackStateStopped) {
                [self.playerSkin.noLiveImageView setHidden:YES];
                // 发送播放器重连通知
                [[NSNotificationCenter defaultCenter] postNotificationName:PLVLivePlayerReconnectNotification object:nil];
            }
        }
            break;
        case PLVLiveStreamStateUnknown:
            DLog("直播状态未知")
            break;
        default:
            break;
        }
    // 最后改变流状态
    _streamState = streamState;
}

#pragma mark - 私有方法

// 定时检查直播状态
- (void)onTimeCheckLiveStreamState {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // 异步线程中请求（该方法为同步线程）
        NSInteger streamState = [PLVChannel isLiveWithStreame:self.channel.stream];
        // 回主线程更新
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setStreamState:streamState];
        });
    });
}

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

// 设置横屏样式
- (void)setOrientationLandscape {
    [[NSNotificationCenter defaultCenter] postNotificationName:PLVLivePlayerWillChangeToFullScreenNotification object:self];    // 发送全屏通知
    [UIView animateWithDuration:0.3 animations:^{
        self.frame = [UIScreen mainScreen].bounds;
        [self.playerSkin changeToFullScreen];
        // 发送全屏通知
    } completion:^(BOOL finished) {
        [self.playerSkin.fullScreenButton setHidden:YES];
        [self.playerSkin.smallScreenButton setHidden:NO];
    }];
}

// 设置竖屏样式
- (void)setOrientationPortrait {
    [[NSNotificationCenter defaultCenter] postNotificationName:PLVLivePlayerWillExitFullScreenNotification object:self];    // 发送退出全屏通知
    [UIView animateWithDuration:0.3 animations:^{
        self.frame = self.originFrame;
        [self.playerSkin changeToSmallScreen];
    } completion:^(BOOL finished) {
        [self.playerSkin.smallScreenButton setHidden:YES];
        [self.playerSkin.fullScreenButton setHidden:NO];
    }];
}

#pragma mark - 直播服务质量统计

- (void)reportFirstLoading {
    if (_isFirstLoadTimeSent) {
        [self reportSecondBuffer];
        return;
    }
    _isFirstLoadTimeSent = YES;
    
    double diffTime = [[NSDate date] timeIntervalSinceDate:_firstLoadStartDate];
    [PLVReportManager reportLoading:_pid uid:self.channel.userId channelId:self.channel.channelId time:(int)floor(diffTime*1000)  session_id:_sessionId param1:_param1 param2:_param2 param3:_param3 param4:_param4 param5:_param5];
}

- (void)reportSecondBuffer {
    if (_isSecondBufferTimeSent) return;
    _isSecondBufferTimeSent = YES;
    
    double diffTime = [[NSDate date] timeIntervalSinceDate:_secondBufferStartDate];
    [PLVReportManager reportBuffer:_pid uid:self.channel.userId channelId:self.channel.channelId time:(int)floor(diffTime*1000) session_id:_sessionId param1:_param1 param2:_param2 param3:_param3 param4:_param4 param5:_param5];
}

// MARK: 播放出错分析报告
- (void)playbackFailureAnalysis {
    if (_isPlayerErrorSend) return;
    _isPlayerErrorSend = YES;
    
    NSURLRequest *request = [NSURLRequest requestWithURL:self.contentURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:20.0];
    NSURLSessionDataTask *dataTask = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSInteger responseCode = [(NSHTTPURLResponse *)response statusCode];    // 服务器响应的状态码
        NSString *errorCode = [NSString new];                                   // 播放错误代码
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"null" forKey:NSLocalizedDescriptionKey];
        NSError *playErr = [NSError errorWithDomain:PlayerErrorDomain code:-100 userInfo:userInfo]; // 播放错误内容描述
        
        if (error) {
            errorCode = @"load_livevideo_failure";  // 加载直播失败
            playErr = error;
        }else if (responseCode != 200) {
            if (responseCode == 403) {
                errorCode = @"stream_403_error";    // 加载403错误
            }else {
                errorCode = @"stream_NOT200_error"; // 加载非200错误
            }
        }else {
            errorCode = @"other_error";             // 其他播放问题
        }
        [PLVReportManager reportError:_pid uid:_channel.userId channelId:_channel.channelId session_id:_sessionId param1:_param1 param2:_param2 param3:_param3 param4:_param4 param5:_param5 uri:self.contentURL.absoluteString status:[NSString stringWithFormat:@"%ld",(long)responseCode] errorcode:errorCode errormsg:[NSString stringWithFormat:@"code:%ld,reason:%@",(long)playErr.code,playErr.localizedDescription]];
    }];
    [dataTask resume];
}

- (void)playerPollingTimerTick {
    ++ _stayTimeDuration;
    if (self.playbackState & IJKMPMoviePlaybackStatePlaying) {
        ++ _watchTimeDuration;
        if ( _watchTimeDuration%_reportFreq == 0) {
            [PLVReportManager stat:_pid uid:self.channel.userId cid:self.channel.channelId flow:0 pd:_watchTimeDuration sd:_stayTimeDuration cts:[self currentPlaybackTime] duration:[self duration]];
        }
    }
}

#pragma mark 设置额外提交的参数

- (void)setParam1:(NSString *)param1 {
    if (param1) _param1 = param1;
}

- (void)setParam2:(NSString *)param2 {
    if (param2) _param2 = param2;
}

- (void)setParam3:(NSString *)param3 {
    if (param3) _param3 = param3;
}

- (void)setParam4:(NSString *)param4 {
    if (param4) _param4 = param4;
}

- (void)setParam5:(NSString *)param5 {
    if (param5) _param5 = param5;
}

- (void)setSessionId:(NSString *)sessionId {
    if (_sessionId) _sessionId = sessionId;
}

#pragma mark - 清除性操作

// 播放器销毁前须调用
- (void)clearPlayer {
    if (_liveStatusTimer) {
        [_liveStatusTimer invalidate];
        _liveStatusTimer = nil;
    }
    if (_playerPollingTimer) {
        [_playerPollingTimer invalidate];
        _playerPollingTimer = nil;
    }
    @try {
        [self shutdown];
        [self.view removeFromSuperview];
    } @catch (NSException *exception) {
        DLog("shutdown failure, exception name: %@, exception reason: %@",exception.name,exception.reason)
    }
}


- (void)dealloc {
    DLog()
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
}

@end
