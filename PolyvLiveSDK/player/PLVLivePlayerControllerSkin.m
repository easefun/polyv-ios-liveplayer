//
//  PLVMoviePlayerControllerSkin.m
//  PolyvIJKLivePlayer
//
//  Created by ftao on 2016/12/16.
//  Copyright © 2016年 easefun. All rights reserved.
//

#import "PLVLivePlayerControllerSkin.h"
#import "Masonry.h"

#define BACKCOLOR [UIColor colorWithRed:0 green:0 blue:0 alpha:0.7]

@interface PLVLivePlayerControllerSkin ()

@property (nonatomic, assign) BOOL isSkinShowing;

@property (nonatomic, strong) UIView *topBar;
@property (nonatomic, strong) UIView *bottomBar;

@property (nonatomic, strong) UIButton *returnButton;

@property (nonatomic, strong) UIButton *playButton;
@property (nonatomic, strong) UIButton *pauseButton;
@property (nonatomic, strong) UIButton *fullScreenButton;
@property (nonatomic, strong) UIButton *smallScreenButton;

@property (nonatomic, strong) UIImageView *noLiveImageView;

@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;
@property (nonatomic, strong) UIScrollView *videoInfoContainer;

@end

@implementation PLVLivePlayerControllerSkin {
    CGFloat _index;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        /** 添加的先后顺序不可变*/
        [self addSubview:self.noLiveImageView];
        [self addSubview:self.topBar];
        [self addSubview:self.bottomBar];
        [self addSubview:self.indicatorView];
        [self addSubview:self.videoInfoContainer];
        
        [self.topBar addSubview:self.returnButton];
        
        [self.bottomBar addSubview:self.playButton];
        [self.bottomBar addSubview:self.pauseButton];
        [self.bottomBar addSubview:self.fullScreenButton];
        [self.bottomBar addSubview:self.smallScreenButton];
        
        // 添加子控件约束
        [self makeSubviewsConstrains];
        self.isSkinShowing = YES;
    }
    return self;
}

- (void)makeSubviewsConstrains {
    [self.topBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.top.trailing.equalTo(self);
        make.height.mas_equalTo(60);
    }];
    [self.bottomBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.bottom.trailing.equalTo(self);
        make.height.mas_equalTo(50);
    }];
    [self.indicatorView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self);
    }];
    [self.videoInfoContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(10);
        make.bottom.equalTo(self.bottomBar.mas_top);
        make.width.mas_equalTo(130);
        make.height.mas_equalTo(100);
    }];
    [self.noLiveImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    
    // 上下边栏 ---------------------------------------------------
    [self.returnButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(50);
        make.leading.equalTo(self.topBar);
        make.top.equalTo(self.topBar).offset(10);
    }];
    [self.pauseButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(50);
        make.leading.bottom.equalTo(self.bottomBar);
    }];
    [self.playButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(50);
        make.leading.bottom.equalTo(self.bottomBar);
    }];
    [self.fullScreenButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(50);
        make.bottom.trailing.equalTo(self.bottomBar);
    }];
    [self.smallScreenButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(50);
        make.bottom.trailing.equalTo(self.bottomBar);
    }];
}

#pragma mark - 皮肤控制

- (void)animateHideSkin {
    if (!self.isSkinShowing) return;
    
    [UIView animateWithDuration:0.5 animations:^{
        self.topBar.alpha = 0;
        self.bottomBar.alpha = 0;
    } completion:^(BOOL finished) {
        self.isSkinShowing = NO;
    }];
}

- (void)animateShowSkin {
    if (self.isSkinShowing) return;
    [UIView animateWithDuration:0.5 animations:^{
        self.topBar.alpha = 1.0;
        self.bottomBar.alpha = 1.0;
    } completion:^(BOOL finished) {
        self.isSkinShowing = YES;
    }];
}

- (void)changeToFullScreen {
    //[self.topBar setBackgroundColor:BACKCOLOR];
    
}

- (void)changeToSmallScreen {
    //[self.topBar setBackgroundColor:[UIColor clearColor]];
}

- (void)addVideoInfoWithDescription:(NSString *)description {
    self.videoInfoContainer.alpha = 1.0;
    UILabel *label = [self videoInfoLabelWithTitle:description];
    label.frame = CGRectMake(0, _index, 130, 20);
    [UIView animateWithDuration:0.5 animations:^{
        [self.videoInfoContainer addSubview:label];
        [self.videoInfoContainer setContentInset:UIEdgeInsetsMake(80-_index, 0, 0, 0)];
    }];
    _index += 20;
}

- (void)hideVideoInfo {
    [UIView animateWithDuration:1.0 animations:^{
        self.videoInfoContainer.alpha = 0;
    } completion:^(BOOL finished) {
        for (UIView *view in self.videoInfoContainer.subviews) {
            [view removeFromSuperview];
        }
        _index = 0;
    }];
}

#pragma mark - 私有方法

// 加载视频状态显示的label
- (UILabel *)videoInfoLabelWithTitle:(NSString *)title {
    UILabel *videoInfoLabel = [[UILabel alloc] init];
    videoInfoLabel.backgroundColor = [UIColor colorWithWhite:0.67 alpha:0.3];
    videoInfoLabel.font = [UIFont systemFontOfSize:12.0];
    videoInfoLabel.text = title;
    videoInfoLabel.textColor = [UIColor whiteColor];
    videoInfoLabel.textAlignment = NSTextAlignmentLeft;
    videoInfoLabel.adjustsFontSizeToFitWidth = YES;
    videoInfoLabel.layer.cornerRadius = 2.5;
    videoInfoLabel.layer.masksToBounds = YES;
    
    return videoInfoLabel;
}

#pragma mark - 重写

- (UIImageView *)noLiveImageView {
    if (!_noLiveImageView) {
        _noLiveImageView = [[UIImageView alloc] initWithImage:[self playerSkinImageName:NOLIVE_BG_IMAGE]];
        [_noLiveImageView setContentMode:UIViewContentModeScaleAspectFit];
        [_noLiveImageView setBackgroundColor:[UIColor blackColor]];
        _noLiveImageView.hidden = YES;
    }
    return _noLiveImageView;
}

- (UIView *)topBar {
    if (!_topBar) {
        _topBar = [UIView new];
        _topBar.backgroundColor = [UIColor clearColor];
    }
    return _topBar;
}

- (UIView *)bottomBar {
    if (!_bottomBar) {
        _bottomBar = [UIView new];
        _bottomBar.backgroundColor = BACKCOLOR;
    }
    return _bottomBar;
}

- (UIButton *)returnButton {
    if (!_returnButton) {
        _returnButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_returnButton setImage:[self playerSkinImageName:@"plv_return"] forState:UIControlStateNormal];
    }
    return _returnButton;
}

- (UIButton *)playButton {
    if (!_playButton) {
        _playButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_playButton setImage:[self playerSkinImageName:@"plv_play"] forState:UIControlStateNormal];
    }
    return _playButton;
}

- (UIButton *)pauseButton {
    if (!_pauseButton) {
        _pauseButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_pauseButton setImage:[self playerSkinImageName:@"plv_pause"] forState:UIControlStateNormal];
        _pauseButton.hidden = YES;
    }
    return _pauseButton;
}

- (UIButton *)fullScreenButton {
    if (!_fullScreenButton) {
        _fullScreenButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_fullScreenButton setImage:[self playerSkinImageName:@"plv_fullScreen"] forState:UIControlStateNormal];
    }
    return _fullScreenButton;
}

- (UIButton *)smallScreenButton {
    if (!_smallScreenButton) {
        _smallScreenButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_smallScreenButton setImage:[self playerSkinImageName:@"plv_smallScreen"] forState:UIControlStateNormal];
        _smallScreenButton.hidden = YES;
    }
    return _smallScreenButton;
}

- (UIActivityIndicatorView *)indicatorView {
    if (!_indicatorView) {
        _indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        [_indicatorView stopAnimating];
    }
    return _indicatorView;
}

- (UIScrollView *)videoInfoContainer {
    if (!_videoInfoContainer) {
        _videoInfoContainer = [[UIScrollView alloc] init];
        _videoInfoContainer.showsHorizontalScrollIndicator = NO;
        _videoInfoContainer.showsVerticalScrollIndicator = NO;
        _videoInfoContainer.alpha = 0;
    }
    return _videoInfoContainer;
}

#pragma mark - Private Method

- (UIImage *)playerSkinImageName:(NSString *)name {
    NSString *imageName = [@"PLVLivePlayerSkin.bundle" stringByAppendingPathComponent:name];
    return [UIImage imageNamed:imageName];
}

- (void)dealloc {
    DLog()
}

@end
