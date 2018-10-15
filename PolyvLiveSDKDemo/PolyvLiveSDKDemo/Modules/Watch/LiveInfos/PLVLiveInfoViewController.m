//
//  PLVLiveInfoViewController.m
//  PolyvLiveSDKDemo
//
//  Created by zykhbl(zhangyukun@polyv.net) on 2018/7/18.
//  Copyright © 2018年 polyv. All rights reserved.
//

#import "PLVLiveInfoViewController.h"
#import <WebKit/WebKit.h>
#import <Masonry/Masonry.h>
#import <PLVLiveAPI/PLVLiveAPI.h>
#import <SDWebImage/UIImageView+WebCache.h>

@interface PLVLiveInfoViewController () <WKNavigationDelegate>

@property (nonatomic, weak) IBOutlet UIView *headerView;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UIImageView *avatarImgView;
@property (nonatomic, weak) IBOutlet UILabel *hostLabel;
@property (nonatomic, weak) IBOutlet UIButton *likesBtn;
@property (nonatomic, weak) IBOutlet UIButton *watchesBtn;
@property (nonatomic, weak) IBOutlet UILabel *liveTimeLabel;
@property (nonatomic, weak) IBOutlet UIButton *liveStatusBtn;
@property (nonatomic, weak) IBOutlet UIView *emptyStatusView;
@property (nonatomic, strong) WKWebView *webView;

@end

@implementation PLVLiveInfoViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.webView = [[WKWebView alloc] init];
    self.webView.navigationDelegate = self;
    self.webView.hidden = YES;
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.webView];
    [self.view addSubview:self.emptyStatusView];
    __weak typeof(self) weakSelf = self;
    [self.emptyStatusView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(weakSelf.view).offset(0.0);
        make.trailing.equalTo(weakSelf.view).offset(0.0);
        make.top.mas_equalTo(142.0);
        if (@available(iOS 11.0, *)) {
            make.bottom.equalTo(weakSelf.view.mas_safeAreaLayoutGuideBottom).offset(0.0);
        } else {
            make.bottom.equalTo(weakSelf.view.mas_bottom).offset(0.0);
        }
    }];
    [self.webView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(weakSelf.view).offset(0.0);
        make.trailing.equalTo(weakSelf.view).offset(0.0);
        make.top.mas_equalTo(142.0);
        if (@available(iOS 11.0, *)) {
            make.bottom.equalTo(weakSelf.view.mas_safeAreaLayoutGuideBottom).offset(0.0);
        } else {
            make.bottom.equalTo(weakSelf.view.mas_bottom).offset(0.0);
        }
        make.width.greaterThanOrEqualTo(weakSelf.view.mas_width);
        make.height.greaterThanOrEqualTo(weakSelf.emptyStatusView.mas_height);
    }];
    
    if ([@"desc" isEqualToString:self.menu.menuType]) {
        self.titleLabel.text = self.channelMenuInfo.name;
        if (self.channelMenuInfo && ![self.channelMenuInfo.coverImage isKindOfClass:[NSNull class]]) {
            [self.avatarImgView sd_setImageWithURL:[NSURL URLWithString:self.channelMenuInfo.coverImage] placeholderImage:[UIImage imageNamed:@"plv_img_defaultUser"]];
        }
        self.hostLabel.text = self.channelMenuInfo.publisher;
        
        if (self.channelMenuInfo.likes.integerValue >= 10000) {
            [self.likesBtn setTitle:[NSString stringWithFormat:@"%0.1fW", self.channelMenuInfo.likes.integerValue / 10000.0] forState:UIControlStateNormal];
        } else {
            [self.likesBtn setTitle:[NSString stringWithFormat:@"%ld", self.channelMenuInfo.likes.integerValue] forState:UIControlStateNormal];
        }
        
        if (self.channelMenuInfo.pageView.integerValue > 10000) {
            [self.watchesBtn setTitle:[NSString stringWithFormat:@"%0.1fW", self.channelMenuInfo.pageView.integerValue / 10000.0] forState:UIControlStateNormal];
        } else {
            [self.watchesBtn setTitle:[NSString stringWithFormat:@"%ld", self.channelMenuInfo.pageView.integerValue] forState:UIControlStateNormal];
        }
        
        self.liveTimeLabel.text = self.channelMenuInfo.startTime != nil ? [NSString stringWithFormat:@"直播时间:%@", self.channelMenuInfo.startTime] : @"";
        if ([@"N" isEqualToString:self.channelMenuInfo.status]) {
            [self.liveStatusBtn setTitle:@"暂无直播" forState:UIControlStateNormal];
        } else {
            [self.liveStatusBtn setTitle:@"正在直播" forState:UIControlStateNormal];
        }

        if (![self.menu.content isKindOfClass:[NSNull class]] && self.menu.content.length) {
            [self.webView loadData:[self.menu.content dataUsingEncoding:NSUTF8StringEncoding] MIMEType:@"text/html" characterEncodingName:@"UTF-8" baseURL:[NSURL URLWithString:@""]];
        }
    } else {
        self.headerView.hidden = YES;
        [self.emptyStatusView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(2.0);
        }];
        [self.webView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(2.0);
        }];
        
        if ([@"text" isEqualToString:self.menu.menuType]) {
            if (![self.menu.content isKindOfClass:[NSNull class]] && self.menu.content.length) {
                [self.webView loadData:[self.menu.content dataUsingEncoding:NSUTF8StringEncoding] MIMEType:@"text/html" characterEncodingName:@"UTF-8" baseURL:[NSURL URLWithString:@""]];
            }
        } else if ([@"iframe" isEqualToString:self.menu.menuType]) {
            [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.menu.content]]];
        }
    }
}

- (IBAction)likes:(id)sender {
    [self.likesBtn setTitle:[NSString stringWithFormat:@"%ld", self.channelMenuInfo.likes.integerValue] forState:UIControlStateNormal];
}

- (IBAction)watches:(id)sender {
    [self.watchesBtn setTitle:[NSString stringWithFormat:@"%ld", self.channelMenuInfo.pageView.integerValue] forState:UIControlStateNormal];
}

- (IBAction)liveStatus:(id)sender {
    
}

//============WKNavigationDelegate============
- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation; {
    self.emptyStatusView.hidden = YES;
    self.webView.hidden = NO;
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    if (navigationAction.targetFrame == nil) {
        [[UIApplication sharedApplication] openURL:navigationAction.request.URL];
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}

@end
