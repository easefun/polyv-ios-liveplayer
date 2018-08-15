//
//  PLVMoviePlayerControllerSkin.m
//  PolyvIJKLivePlayer
//
//  Created by ftao on 2016/12/16.
//  Copyright © 2016年 easefun. All rights reserved.
//

#import "PLVLivePlayerControllerSkin.h"
#import "Masonry.h"
#import "PLVRestrictView.h"

#define BACK_COLOR [UIColor colorWithRed:0 green:0 blue:0 alpha:0.7]

@interface PLVLivePlayerControllerSkin ()

@property (nonatomic, assign) BOOL isSkinShowing;

@property (nonatomic, strong) UIView *topBar;
@property (nonatomic, strong) UIView *bottomBar;

@property (nonatomic, strong) UIButton *returnButton;

@property (nonatomic, strong) UIButton *playButton;
@property (nonatomic, strong) UIButton *pauseButton;
@property (nonatomic, strong) UIButton *definitionButton;
@property (nonatomic, strong) UIButton *fullScreenButton;
@property (nonatomic, strong) UIButton *smallScreenButton;

@property (nonatomic, strong) UIView *definitionView;
@property (nonatomic, strong) UIImageView *noLiveImageView;
@property (nonatomic, strong) PLVRestrictView *restrictView;

@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;
@property (nonatomic, strong) UIScrollView *videoInfoContainer;
@property (nonatomic, strong) UIView *warningView;
@property (nonatomic, strong) UIButton *recommendedButton;

@property (nonatomic, strong) NSMutableArray<UIButton *> *definitionButtons;

@end

@implementation PLVLivePlayerControllerSkin {
    CGFloat _index;
}

#pragma mark - Lifecycle

- (instancetype)init {
    self = [super init];
    if (self) {
        /** 添加的先后顺序不可变*/
        [self addSubview:self.noLiveImageView];
        [self addSubview:self.bottomBar];
        [self addSubview:self.videoInfoContainer];
        [self addSubview:self.indicatorView];
        [self addSubview:self.warningView];
        [self addSubview:self.definitionView];
        [self addSubview:self.restrictView];
        [self addSubview:self.topBar];
        
        [self.topBar addSubview:self.returnButton];
        
        [self.bottomBar addSubview:self.playButton];
        [self.bottomBar addSubview:self.pauseButton];
        [self.bottomBar addSubview:self.definitionButton];
        [self.bottomBar addSubview:self.fullScreenButton];
        [self.bottomBar addSubview:self.smallScreenButton];
        
        // 添加子控件约束
        [self makeSubviewsConstrains];
        self.isSkinShowing = YES;
        
        self.definitionButtons = [NSMutableArray array];
    }
    return self;
}

- (void)dealloc {
    DLog()
}

#pragma mark - Initial

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
    [self.warningView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(260);
        make.height.mas_equalTo(24);
        make.left.offset(10);
        make.bottom.offset(-60);
    }];
    
    [self.noLiveImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    [self.restrictView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    [self.definitionView mas_makeConstraints:^(MASConstraintMaker *make) {
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
    [self.definitionButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(50);
        make.bottom.equalTo(self.bottomBar);
        make.trailing.equalTo(self.fullScreenButton.mas_leading);
    }];
}

#pragma mark - Public

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
    //[self.topBar setBackgroundColor:BACK_COLOR];
    //NSLog(@"changeToFullScreen");
    [self.definitionButtons enumerateObjectsUsingBlock:^(UIButton * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self setDefinitionBtnFullMode:YES btn:obj];
    }];
    
    [self updateLayoutDefinitionItemBtnsWithFull:YES];
}

- (void)changeToSmallScreen {
    //[self.topBar setBackgroundColor:[UIColor clearColor]];
    //NSLog(@"changeToSmallScreen");
    [self.definitionButtons enumerateObjectsUsingBlock:^(UIButton * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self setDefinitionBtnFullMode:NO btn:obj];
    }];
    
    [self updateLayoutDefinitionItemBtnsWithFull:NO];
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

- (void)showRecommendedDefinition:(NSString *)definition {
    [self.warningView setHidden:NO];
    [self.recommendedButton setTitle:definition forState:UIControlStateNormal];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.warningView.alpha = 1.0;
        [UIView animateWithDuration:0.5 animations:^{
            self.warningView.alpha = 0;
        } completion:^(BOOL finished) {
            self.warningView.alpha = 0;
        }];
    });
}

- (void)showRestrictPlayViewWithErrorCode:(NSString *)errorCode {
    [self.restrictView setHidden:NO];
    [self.restrictView.errorCodeLabel setText:errorCode];
}

#pragma mark - Rewrite
#pragma mark getter
- (UIImageView *)noLiveImageView {
    if (!_noLiveImageView) {
        _noLiveImageView = [[UIImageView alloc] initWithImage:[self playerSkinImageName:NOLIVE_BG_IMAGE]];
        [_noLiveImageView setContentMode:UIViewContentModeScaleAspectFit];
        [_noLiveImageView setBackgroundColor:[UIColor blackColor]];
        _noLiveImageView.hidden = YES;
    }
    return _noLiveImageView;
}

- (PLVRestrictView *)restrictView {
    if (!_restrictView) {
        _restrictView = [PLVRestrictView restrictViewFromXIB];
        _restrictView.hidden = YES;
    }
    return _restrictView;
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
        _bottomBar.backgroundColor = BACK_COLOR;
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

- (UIButton *)definitionButton {
    if (!_definitionButton) {
        _definitionButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_definitionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_definitionButton.titleLabel setFont:[UIFont systemFontOfSize:14.0 weight:UIFontWeightMedium]];
        [_definitionButton addTarget:self action:@selector(definitionButtonBeClicked) forControlEvents:UIControlEventTouchUpInside];
        [_definitionButton setHidden:YES];
    }
    return _definitionButton;
}

- (UIView *)definitionView {
    if (!_definitionView) {
        _definitionView = [UIView new];
        _definitionView.backgroundColor = [UIColor clearColor];
        _definitionView.autoresizesSubviews = YES;
        _definitionView.hidden = YES;
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(definitionViewBeTapped)];
        [_definitionView addGestureRecognizer:tap];
        
        UIView *coverView = [[UIView alloc] initWithFrame:_definitionView.bounds];
        coverView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        coverView.backgroundColor = BACK_COLOR;
        [_definitionView addSubview:coverView];
        
        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 40)];
        title.center = CGPointMake(CGRectGetMidX(_definitionView.bounds), 35);
        title.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        title.text = @"- 选择当前清晰度 -";
        title.textAlignment = NSTextAlignmentCenter;
        [title setTextColor:[UIColor whiteColor]];
        [title setFont:[UIFont systemFontOfSize:14.0 weight:UIFontWeightSemibold]];
        [_definitionView addSubview:title];
    }
    return _definitionView;
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

- (UIView *)warningView {
    if (!_warningView) {
        _warningView = [[UIView alloc] init];
        _warningView.layer.cornerRadius = 12.0;
        _warningView.layer.masksToBounds = YES;
        _warningView.backgroundColor = [UIColor darkGrayColor];
        _warningView.hidden = YES;

        UILabel *label = [[UILabel alloc] init];
        label.backgroundColor = [UIColor clearColor];
        label.text = @"您当前网络状况不稳定，建议您切换至";
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightSemibold];
        [_warningView addSubview:label];
        [label mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.equalTo(_warningView);
            make.left.offset(14);
            make.width.mas_equalTo(210);
        }];
        
        _recommendedButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _recommendedButton.titleLabel.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightSemibold];
        [_recommendedButton setTitleColor:[UIColor colorWithRed:90/255.0 green:200/255.0 blue:250/255.0 alpha:1.0] forState:UIControlStateNormal];
        [_recommendedButton addTarget:self action:@selector(definitionBtnItemClicked:) forControlEvents:UIControlEventTouchUpInside];
        [_warningView addSubview:_recommendedButton];
        [_recommendedButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(label.mas_right).priorityHigh();
            make.top.bottom.right.equalTo(_warningView);
            make.width.mas_equalTo(40);
        }];
    }
    return _warningView;
}

- (UIButton *)createButttonWithTitle:(NSString *)title{
    
    UIButton *btn = [[UIButton alloc] init];
    
    [btn setTitle:title forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont systemFontOfSize:14.0];

    btn.layer.cornerRadius = 15.0;
    btn.layer.borderWidth = 1.0;
    btn.layer.borderColor = [UIColor whiteColor].CGColor;
    btn.backgroundColor = [UIColor clearColor];
    
    if ([self definitionIsSelect:title]){
        [self setDefinitionBtnSelect:YES btn:btn];
    }
    
    [btn addTarget:self action:@selector(definitionBtnItemClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    return btn;
}

- (void)setDefinitionBtnSelect:(BOOL)select btn:(UIButton *)btn{
    
    if (select){
        
        btn.layer.borderWidth = 0.0;
        btn.layer.borderColor = [UIColor clearColor].CGColor;
        btn.backgroundColor = [UIColor colorWithRed:29/255.0 green:162/255.0 blue:230/255.0 alpha:1.0];
    }
    else{
        
        btn.layer.borderWidth = 1.0;
        btn.layer.borderColor = [UIColor whiteColor].CGColor;
        btn.backgroundColor = [UIColor clearColor];
    }
}

- (void)setDefinitionBtnFullMode:(BOOL)fullModel btn:(UIButton *)btn{
    if (fullModel){
        btn.layer.cornerRadius = 20;
    }
    else{
        btn.layer.cornerRadius = 15;
    }
}

#pragma mark setter
- (void)setDefaultDefinition:(NSString *)defaultDefinition {
    _defaultDefinition = defaultDefinition;
    [self.definitionButton setTitle:defaultDefinition forState:UIControlStateNormal];
}

- (void)setDefinitions:(NSArray *)definitions {
    _definitions = definitions;

    [self.definitions enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        UIButton *button = [self createButttonWithTitle:obj];
        [self.definitionView addSubview:button];
        [self.definitionButtons addObject:button];
    }];
    
    [self layoutDefinitionItemBtns];
}

- (void)layoutDefinitionItemBtns{
    
    if (self.definitionButtons.count == 3){
        
        UIButton *button1 = [self.definitionButtons objectAtIndex:0];
        UIButton *button2 = [self.definitionButtons objectAtIndex:1];
        UIButton *button3 = [self.definitionButtons objectAtIndex:2];
        
        CGSize size = CGSizeMake(120, 30);
        [button1 mas_makeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(size);
            make.centerX.equalTo (self.definitionView);
            make.top.offset (50);
        }];
        [button2 mas_makeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(size);
            make.centerX.equalTo (self.definitionView);
            make.top.equalTo (button1.mas_bottom).offset (15);
        }];
        [button3 mas_makeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(size);
            make.centerX.equalTo (self.definitionView);
            make.top.equalTo (button2.mas_bottom).offset (15);
        }];

    }
    else if (self.definitionButtons.count == 2){
        UIButton *button1 = [self.definitionButtons objectAtIndex:0];
        UIButton *button2 = [self.definitionButtons objectAtIndex:1];
        
        CGSize size = CGSizeMake(120, 30);
        [button1 mas_makeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(size);
            make.centerX.equalTo (self.definitionView);
            make.top.offset (50);
        }];
        [button2 mas_makeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(size);
            make.centerX.equalTo (self.definitionView);
            make.top.equalTo (button1.mas_bottom).offset (15);
        }];
       
    }
    else if (self.definitionButtons.count == 1){
        UIButton *button1 = [self.definitionButtons objectAtIndex:0];
        
        CGSize size = CGSizeMake(120, 30);
        [button1 mas_makeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(size);
            make.centerX.equalTo (self.definitionView);
            make.top.offset (50);
        }];
    }
}

- (void)updateLayoutDefinitionItemBtnsWithFull:(BOOL)fullMode{
    
    CGSize buttonSize = CGSizeMake(120, 30);
    CGFloat space = 15;
    CGFloat firstTop = 50;
    if (fullMode){
        buttonSize = CGSizeMake(160, 40);
        space = 30;
        firstTop = 80;
    }
    
    if (self.definitionButtons.count == 3){
        
        UIButton *button1 = [self.definitionButtons objectAtIndex:0];
        UIButton *button2 = [self.definitionButtons objectAtIndex:1];
        UIButton *button3 = [self.definitionButtons objectAtIndex:2];
        
        [button1 mas_updateConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(buttonSize);
            make.top.offset (firstTop);
        }];
        [button2 mas_updateConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(buttonSize);
            make.top.equalTo (button1.mas_bottom).offset (space);
        }];
        [button3 mas_updateConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(buttonSize);
            make.top.equalTo (button2.mas_bottom).offset (space);
        }];
    }
    else if (self.definitionButtons.count == 2){
        UIButton *button1 = [self.definitionButtons objectAtIndex:0];
        UIButton *button2 = [self.definitionButtons objectAtIndex:1];
        
        [button1 mas_updateConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(buttonSize);
            make.top.offset (firstTop);
        }];
        [button2 mas_updateConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(buttonSize);
            make.top.equalTo (button1.mas_bottom).offset (space);
        }];
    }
    else if (self.definitionButtons.count == 1){
        UIButton *button1 = [self.definitionButtons objectAtIndex:0];
        
        [button1 mas_updateConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(buttonSize);
            make.top.offset (firstTop);
        }];
    }
}

- (BOOL)definitionIsSelect:(NSString *)definitionStr{
    BOOL select = NO;
    if ([self.defaultDefinition isEqualToString:definitionStr]){
        select = YES;
    }
    
    return select;
}

#pragma mark - Private

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

- (UIImage *)playerSkinImageName:(NSString *)name {
    NSString *imageName = [@"PLVLivePlayerSkin.bundle" stringByAppendingPathComponent:name];
    return [UIImage imageNamed:imageName];
}

#pragma mark Actions

- (void)definitionButtonBeClicked {
    //NSLog(@"%@——%@",NSStringFromSelector(_cmd),self.definitions);
    if (self.definitions && self.definitions.count) {
        [self.definitionView setHidden:NO];
    }
}

- (void)definitionViewBeTapped {
    [self.definitionView setHidden:YES];
}

- (void)definitionBtnItemClicked:(UIButton *)button {
    
    // 只有1个或者0个码率，不让切换
    if (self.definitions.count <= 1){
        return;
    }
    
    // 相同码率不让切换
    if ([self.definitionButton.titleLabel.text isEqualToString:button.titleLabel.text]){
        return;
    }
    
    NSString *title = button.titleLabel.text;
    if (title && title.length) {
        if (self.definitionsCallBack) {
            self.definitionsCallBack(title);
        }
    }
    
    // 底部工具栏码率显示
    [self.definitionButton setTitle:title forState:UIControlStateNormal];
    
    // 隐藏码率选择视图
    [self definitionViewBeTapped];
    
    // 重置选项UI
    [self.definitionButtons enumerateObjectsUsingBlock:^(UIButton * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self setDefinitionBtnSelect:NO btn:obj];
    }];
    
    [self setDefinitionBtnSelect:YES btn:button];
}

@end
