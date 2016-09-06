//
//  SkinVideoControllerView.m
//  polyvSDK
//
//  Created by seanwong on 8/17/15.
//  Copyright (c) 2015 easefun. All rights reserved.
//

#import "SkinVideoControllerView.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import <PLVChannel/PLVChannel.h>

static const CGFloat pVideoControlBarHeight = 50.0;
static const CGFloat pVideoControlSettingWidth = 100;
static const CGFloat pVideoControlAnimationTimeinterval = 0.5;
//static const CGFloat pVideoControlTimeLabelFontSize = 15.0;
static const CGFloat pVideoControlTitleLabelFontSize = 15.0;
static const CGFloat pVideoControlBarAutoFadeOutTimeinterval = 5.0;

#define TITLECOLOR [UIColor colorWithWhite:0.8 alpha:1]


// 手势的水平移动和垂直移动
typedef NS_ENUM(NSInteger, PanDirection) {
    PanDirectionHorizontalMoved,                // 横向
    PanDirectionVerticalMoved                   // 纵向
};


@interface SkinVideoControllerView () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIView            *topBar;
@property (nonatomic, strong) UIButton          *closeButton;
@property (nonatomic, strong) UILabel           *titleLabel;
@property (nonatomic, strong) UIButton          *settingButton;
@property (nonatomic, strong) UIView            *settingView;

@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;
@property (nonatomic, strong) UISlider          *volumeViewSlider;

@property (nonatomic, strong) UIView            *bottomBar;
@property (nonatomic, strong) UIButton          *playButton;
@property (nonatomic, strong) UIButton          *pauseButton;
@property (nonatomic, strong) UILabel           *timeLabel;
@property (nonatomic, strong) UISlider          *progressSlider;
@property (nonatomic, strong) UIButton          *backButton;
@property (nonatomic, strong) UIButton          *muteButton;                // 直播状态
@property (nonatomic, strong) UIImageView       *liveStateView;
@property (nonatomic, strong) UIButton          *fullScreenButton;
@property (nonatomic, strong) UIButton          *shrinkScreenButton;


@property (nonatomic, assign) BOOL              isBarShowing;
@property (nonatomic, assign) BOOL              isVolume;                   // 是否在调节音量
@property (nonatomic, assign) PanDirection      panDirection;               // 保存枚举值


@end

@implementation SkinVideoControllerView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        [self addSubview:self.topBar];
        [self.topBar addSubview:self.titleLabel];
        [self.topBar addSubview:self.backButton];
        [self.topBar addSubview:self.settingButton];

        [self.topBar addSubview:self.closeButton];
        //[_topBar setBackgroundColor:nil];

        [self addSubview:self.settingView];
        self.settingView.hidden = YES;

        [self addSubview:self.bottomBar];
        [self.bottomBar addSubview:self.playButton];
        [self.bottomBar addSubview:self.pauseButton];
        self.pauseButton.hidden = YES;
        //[self.bottomBar addSubview:self.muteButton];
        [self.bottomBar addSubview:self.liveStateView];
        [self.bottomBar addSubview:self.fullScreenButton];
        [self.bottomBar addSubview:self.shrinkScreenButton];
        self.shrinkScreenButton.hidden = YES;
        //[self.bottomBar addSubview:self.progressSlider];
        //[self.bottomBar addSubview:self.timeLabel];
        [self addSubview:self.indicatorView];
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTap:)];
        [self addGestureRecognizer:tapGesture];
        
        // 设置音量滑块
        [self configVolumeViewSlider];
        
        // 添加平移(拖动)手势，控制声音和亮度
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panDirection:)];
        [self addGestureRecognizer:panGesture];
        panGesture.delegate = self;
    }
    return self;
}

#pragma mark - 手势相关

- (void)configVolumeViewSlider {
    MPVolumeView *volumeView = [[MPVolumeView alloc] init];
    for (UIView *view in [volumeView subviews]) {
        if ([[view.class description] isEqualToString:@"MPVolumeSlider"]) {
            _volumeViewSlider = (UISlider *)view;
            break;
        }
    }
    // 使用这个category的应用不会随着手机静音键打开而静音，可在手机静音下播放声音
    NSError *setCategoryError = nil;
    BOOL success = [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&setCategoryError];
    if (!success) {
        //
    }
}

// 响应到panGesture的方法
- (void)panDirection:(UIPanGestureRecognizer *)panGesture {
    // 根据view上panGesture的位置，判断是调节亮度还是音量
    CGPoint locationPoint = [panGesture locationInView:self];
    // 只相应垂直移动
    // 根据上次和本次移动位置,算出一个速率的point
    CGPoint velocity = [panGesture velocityInView:self];
    //NSLog(@"%@",NSStringFromCGPoint(velocity));
    
    switch (panGesture.state) {
        case UIGestureRecognizerStateBegan: {   //began move
            CGFloat x = fabs(velocity.x);
            CGFloat y = fabs(velocity.y);
            if (x<y) {  //竖直移动
                self.panDirection = PanDirectionVerticalMoved;
                if (locationPoint.x < self.bounds.size.width/2) {
                    self.isVolume = YES;    // 调节音量
                }else {
                    self.isVolume = NO;     // 调节亮度
                }
            }
        }
            break;
        case UIGestureRecognizerStateChanged: {  //moving
            switch (self.panDirection) {
                case PanDirectionVerticalMoved:
                    [self verticalMoved:velocity.y];    // 竖直方向移动传递y值
                    break;
                default:
                    break;
            }
        }
            break;
        case UIGestureRecognizerStateEnded: {   //end move
            // 移动结束也需要判断垂直或者平移
            // 比如水平移动结束时，要快进到指定位置，如果这里没有判断，当我们调节音量完之后，会出现屏幕跳动的bug
            switch (self.panDirection) {
                case PanDirectionVerticalMoved: {
                    // 垂直移动结束后，把状态改为不再控制音量
                    self.isVolume = NO;
                }
                    break;
                default:
                    break;
            }
        }
            break;
        default:
            break;
    }
}

// 竖直方向移动
- (void)verticalMoved:(CGFloat)value {
    if (self.isVolume) {
        // 更改系统音量
        self.volumeViewSlider.value -= value / 10000; // 越小幅度越小
        //NSLog(@"self.volumeViewSlider.value:%f",self.volumeViewSlider.value);
    }else {
        // 亮度
        [UIScreen mainScreen].brightness -= value / 10000;
        //NSLog(@"brightness:%f",[UIScreen mainScreen].brightness);
    }
}

// UIGestureRecognizerDelegate代理方法
//- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
//    CGPoint point = [touch locationInView:self]; // 可获取触摸位置
  //  return YES;
//}

#pragma mark -  皮肤布局

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.topBar.frame = CGRectMake(CGRectGetMinX(self.bounds), CGRectGetMinY(self.bounds), CGRectGetWidth(self.bounds), pVideoControlBarHeight);
    //NSLog(@"topBar: %@", NSStringFromCGRect(self.topBar.frame));
    self.backButton.frame = CGRectMake(0, CGRectGetMinX(self.topBar.bounds)+5, CGRectGetWidth(self.backButton.bounds), CGRectGetHeight(self.backButton.bounds));
    self.titleLabel.frame = CGRectMake(CGRectGetWidth(self.backButton.bounds), CGRectGetMinX(self.topBar.bounds)+5, 300, CGRectGetHeight(self.topBar.bounds));
    self.settingButton.frame = CGRectMake(CGRectGetWidth(self.topBar.bounds) - CGRectGetWidth(self.settingButton.bounds)-10, CGRectGetMinX(self.topBar.bounds)+5, CGRectGetWidth(self.settingButton.bounds), CGRectGetHeight(self.settingButton.bounds));
    self.settingView.frame = CGRectMake(CGRectGetWidth(self.bounds)-pVideoControlSettingWidth, CGRectGetMaxY(self.topBar.bounds), pVideoControlSettingWidth ,  CGRectGetHeight(self.bounds)/2);
    

    self.closeButton.frame = CGRectMake(CGRectGetWidth(self.topBar.bounds) - CGRectGetWidth(self.closeButton.bounds), CGRectGetMinX(self.topBar.bounds), CGRectGetWidth(self.closeButton.bounds), CGRectGetHeight(self.closeButton.bounds));
    self.bottomBar.frame = CGRectMake(CGRectGetMinX(self.bounds), CGRectGetHeight(self.bounds) - pVideoControlBarHeight, CGRectGetWidth(self.bounds), pVideoControlBarHeight);
    self.playButton.frame = CGRectMake(CGRectGetMinX(self.bottomBar.bounds), CGRectGetHeight(self.bottomBar.bounds)/2 - CGRectGetHeight(self.playButton.bounds)/2, CGRectGetWidth(self.playButton.bounds), CGRectGetHeight(self.playButton.bounds));
    self.pauseButton.frame = self.playButton.frame;
    
    self.muteButton.frame = CGRectMake(CGRectGetWidth(self.bottomBar.bounds) - CGRectGetWidth(self.fullScreenButton.bounds) - CGRectGetWidth(self.muteButton.bounds), CGRectGetHeight(self.bottomBar.bounds)/2 - CGRectGetHeight(self.muteButton.bounds)/2, CGRectGetWidth(self.muteButton.bounds), CGRectGetHeight(self.muteButton.bounds));
   
    self.liveStateView.frame = CGRectMake(CGRectGetMaxX(self.playButton.frame), CGRectGetHeight(self.bottomBar.bounds)/2 - CGRectGetHeight(self.liveStateView.bounds)/2, CGRectGetWidth(self.liveStateView.bounds), CGRectGetHeight(self.liveStateView.bounds));
    self.fullScreenButton.frame = CGRectMake(CGRectGetWidth(self.bottomBar.bounds) - CGRectGetWidth(self.fullScreenButton.bounds), CGRectGetHeight(self.bottomBar.bounds)/2 - CGRectGetHeight(self.fullScreenButton.bounds)/2, CGRectGetWidth(self.fullScreenButton.bounds), CGRectGetHeight(self.fullScreenButton.bounds));
    

    self.shrinkScreenButton.frame = self.fullScreenButton.frame;
    //self.progressSlider.frame = CGRectMake(CGRectGetMaxX(self.playButton.frame), CGRectGetHeight(self.bottomBar.bounds)/2 - CGRectGetHeight(self.progressSlider.bounds)/2, CGRectGetMinX(self.muteButton.frame) - CGRectGetMaxX(self.playButton.frame), CGRectGetHeight(self.progressSlider.bounds));
    
    //self.timeLabel.frame = CGRectMake(CGRectGetMidX(self.progressSlider.frame), CGRectGetHeight(self.bottomBar.bounds) - CGRectGetHeight(self.timeLabel.bounds) - 2.0, CGRectGetWidth(self.progressSlider.bounds)/2, CGRectGetHeight(self.timeLabel.bounds));
    
    //self.timeLabel.frame = CGRectMake(CGRectGetMaxX(self.playButton.frame), (CGRectGetHeight(self.bottomBar.bounds) - CGRectGetHeight(self.timeLabel.bounds))/2, CGRectGetWidth(self.timeLabel.bounds), CGRectGetHeight(self.timeLabel.bounds));
    
    
    self.indicatorView.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
}

- (void)setHeadTitle:(NSString*)headtitle{
    [self.titleLabel setText:headtitle];
}


//- (void)changeToMute{
//    [_muteButton setImage:[UIImage imageNamed:[self videoImageName:@"pl-video-player-mute"]] forState:UIControlStateNormal];
//}
//- (void)changeToUnMute{
//    [_muteButton setImage:[UIImage imageNamed:[self videoImageName:@"pl-video-player-speaker"]] forState:UIControlStateNormal];
//}

- (void)didMoveToSuperview
{
    [super didMoveToSuperview];
    self.isBarShowing = YES;
}

#pragma mark - 皮肤隐藏/显示

- (void)animateHide
{
    if (!self.isBarShowing) {
        return;
    }
    [UIView animateWithDuration:pVideoControlAnimationTimeinterval animations:^{
        self.topBar.alpha = 0.0;
        self.bottomBar.alpha = 0.0;
        self.settingView.alpha = 0.0;
        
        if (CGRectEqualToRect(self.bounds, [UIScreen mainScreen].bounds)) {
            [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
        }
    } completion:^(BOOL finished) {
        self.isBarShowing = NO;
    }];
}

- (void)animateShow
{
    if (self.isBarShowing) {
        return;
    }
    
    [UIView animateWithDuration:pVideoControlAnimationTimeinterval animations:^{
        self.topBar.alpha = 1.0;
        self.bottomBar.alpha = 1.0;
        self.settingView.alpha = 1.0;
       
        if (CGRectEqualToRect(self.bounds, [UIScreen mainScreen].bounds)) {
            [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
        }
    } completion:^(BOOL finished) {
        self.isBarShowing = YES;
        [self autoFadeOutControlBar];
    }];
}

- (void)autoFadeOutControlBar
{
    if (!self.isBarShowing) {
        return;
    }
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(animateHide) object:nil];
    [self performSelector:@selector(animateHide) withObject:nil afterDelay:pVideoControlBarAutoFadeOutTimeinterval];
}

- (void)cancelAutoFadeOutControlBar
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(animateHide) object:nil];
}

- (void)onTap:(UITapGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateRecognized) {
        if (self.isBarShowing) {
            [self animateHide];
        } else {
            [self animateShow];
        }
    }
}

#pragma mark - 全屏/非全屏样式

- (void)changeToFullsreen {
    _topBar.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.8];
    _titleLabel.hidden = NO;
    _settingButton.hidden = NO;
    _settingView.alpha = 1;
    
    if (self.isBarShowing) {
        [UIApplication sharedApplication].statusBarHidden = NO;
    }else {
        [UIApplication sharedApplication].statusBarHidden = YES;
    }
}

- (void)changeToSmallsreen {
    _topBar.backgroundColor = [UIColor clearColor];
    _titleLabel.hidden = YES;
    _settingButton.hidden = YES;
    _settingView.hidden = YES;
    
    [UIApplication sharedApplication].statusBarHidden = NO;
}



#pragma mark - Property

- (UIView *)topBar
{
    if (!_topBar) {
        _topBar = [UIView new];
        _topBar.backgroundColor = [UIColor clearColor];
        //_topBar.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
    }
    return _topBar;
}

- (UIView *)bottomBar
{
    if (!_bottomBar) {
        _bottomBar = [UIView new];
        _bottomBar.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.8];
    }
    return _bottomBar;
}
- (UIView *)settingView
{
    if (!_settingView) {
        _settingView = [UIView new];
        _settingView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.7];
    }
    return _settingView;
}

- (UIButton *)playButton
{
    if (!_playButton) {
        _playButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_playButton setImage:[UIImage imageNamed:[self videoImageName:@"pl-video-player-play"]] forState:UIControlStateNormal];
        _playButton.bounds = CGRectMake(0, 0, pVideoControlBarHeight, pVideoControlBarHeight);
    }
    return _playButton;
}

- (UIButton *)pauseButton
{
    if (!_pauseButton) {
        _pauseButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_pauseButton setImage:[UIImage imageNamed:[self videoImageName:@"pl-video-player-pause"]] forState:UIControlStateNormal];
        _pauseButton.bounds = CGRectMake(0, 0, pVideoControlBarHeight, pVideoControlBarHeight);
    }
    return _pauseButton;
}
- (UIButton *)backButton
{
    if (!_backButton) {
        _backButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_backButton setImage:[UIImage imageNamed:[self videoImageName:@"pl-video-player-back"]] forState:UIControlStateNormal];
        _backButton.bounds = CGRectMake(0, 0, pVideoControlBarHeight, pVideoControlBarHeight);
    }
    return _backButton;
}


- (UIButton *)fullScreenButton
{
    if (!_fullScreenButton) {
        _fullScreenButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_fullScreenButton setImage:[UIImage imageNamed:[self videoImageName:@"pl-video-player-fullscreen"]] forState:UIControlStateNormal];
        _fullScreenButton.bounds = CGRectMake(0, 0, pVideoControlBarHeight, pVideoControlBarHeight);
    }
    return _fullScreenButton;
}

- (UIButton *)shrinkScreenButton
{
    if (!_shrinkScreenButton) {
        _shrinkScreenButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_shrinkScreenButton setImage:[UIImage imageNamed:[self videoImageName:@"pl-video-player-shrinkscreen"]] forState:UIControlStateNormal];
        _shrinkScreenButton.bounds = CGRectMake(0, 0, pVideoControlBarHeight, pVideoControlBarHeight);
    }
    return _shrinkScreenButton;
}
- (UIButton *)muteButton
{
    if (!_muteButton) {
        _muteButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_muteButton setImage:[UIImage imageNamed:[self videoImageName:@"iconfont-iconlive"]] forState:UIControlStateNormal];
        _muteButton.bounds = CGRectMake(0, 0, pVideoControlBarHeight, pVideoControlBarHeight);
    }
    return _muteButton;
}

- (UIImageView *)liveStateView {
    if (!_liveStateView) {
        UIImage *image = [UIImage imageNamed:[self videoImageName:@"iconfont-iconlive"]];
        _liveStateView = [[UIImageView alloc] initWithImage:image];
        _liveStateView.bounds = CGRectMake(0, 0, image.size.width, image.size.height);
    }
    return _liveStateView;
}

- (UISlider *)progressSlider
{
    if (!_progressSlider) {
        _progressSlider = [[UISlider alloc] init];
        [_progressSlider setThumbImage:[UIImage imageNamed:[self videoImageName:@"pl-video-player-point"]] forState:UIControlStateNormal];
        [_progressSlider setMinimumTrackTintColor:[UIColor whiteColor]];
        [_progressSlider setMaximumTrackTintColor:[UIColor lightGrayColor]];
        _progressSlider.value = 0.f;
        _progressSlider.continuous = YES;
    }
    return _progressSlider;
}

- (UIButton *)closeButton
{
    if (!_closeButton) {
        _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_closeButton setImage:[UIImage imageNamed:[self videoImageName:@"pl-video-player-close"]] forState:UIControlStateNormal];
        _closeButton.bounds = CGRectMake(0, 0, pVideoControlBarHeight, pVideoControlBarHeight);
    }
    return _closeButton;
}

- (UILabel *)timeLabel
{
    if (!_timeLabel) {
        _timeLabel = [UILabel new];
        _timeLabel.backgroundColor = [UIColor clearColor];
        _timeLabel.font = [UIFont systemFontOfSize:12];
        _timeLabel.textColor = [UIColor whiteColor];
        _timeLabel.textAlignment = NSTextAlignmentRight;
        _timeLabel.bounds = CGRectMake(0, 0, 90, 50);
    }
    return _timeLabel;
}

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.font = [UIFont systemFontOfSize:pVideoControlTitleLabelFontSize];
        _titleLabel.textColor = TITLECOLOR;
        _titleLabel.textAlignment = NSTextAlignmentLeft;
        _titleLabel.bounds = CGRectMake(0, 0, pVideoControlTitleLabelFontSize, pVideoControlTitleLabelFontSize);
        _titleLabel.hidden = YES;
    }
    return _titleLabel;
}

- (UIButton *)settingButton {
    if (!_settingButton) {
        _settingButton = [UIButton new];
        [_settingButton setImage:[UIImage imageNamed:[self videoImageName:@"set"]] forState:UIControlStateNormal];
        _settingButton.bounds = CGRectMake(0, 0, pVideoControlBarHeight, pVideoControlBarHeight);
        _settingButton.hidden = YES;
    }
    return _settingButton;
}

- (UIActivityIndicatorView *)indicatorView
{
    if (!_indicatorView) {
        _indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        [_indicatorView stopAnimating];
    }
    return _indicatorView;
}

- (void)dealloc {
    DLog("%s",__FUNCTION__);
}

#pragma mark - Private Method

- (NSString *)videoImageName:(NSString *)name
{
    return [@"PLVLivePlayer.bundle" stringByAppendingPathComponent:name];
}

@end
