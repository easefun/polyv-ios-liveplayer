//
//  ViewController.m
//  PolyvIJKLivePlayer
//
//  Created by ftao on 2016/12/8.
//  Copyright © 2016年 easefun. All rights reserved.
//

#import "LoginViewController.h"
#import "LivePlayerViewController.h"
#import <MBProgressHUD/MBProgressHUD.h>

@interface LoginViewController ()

@property (weak, nonatomic) IBOutlet UITextField *userIdTF;
@property (weak, nonatomic) IBOutlet UITextField *channelIdTF;

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSArray *userInfo = [[NSUserDefaults standardUserDefaults] objectForKey:@"userInfo"];
    if (userInfo) {
        self.userIdTF.text = userInfo[0];
        self.channelIdTF.text = userInfo[1];
    }
}

- (IBAction)loginButtonClick:(UIButton *)sender {
    // 保存数据
    [[NSUserDefaults standardUserDefaults] setObject:@[self.userIdTF.text,self.channelIdTF.text] forKey:@"userInfo"];
    if (![self.userIdTF.text length] || ![self.channelIdTF.text length]) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:@"用户名和账号不能为空" preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alertController animated:YES completion:nil];
        return;
    }

    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [hud.label setText:@"登录中..."];
    
    NSString *userId = self.userIdTF.text;
    NSString *channelId = self.channelIdTF.text;
    
    // 获取直播频道信息
    __weak typeof(self)weakSelf = self;
    [PLVLiveAPI loadChannelInfoRepeatedlyWithUserId:userId channelId:channelId.integerValue completion:^(PLVLiveChannel *channel) {
        [channel updateChannelRestrictInfo:^(PLVLiveChannel *channel) {
            [hud hideAnimated:YES];
            LivePlayerViewController *livePlayerVC = [LivePlayerViewController new];
            livePlayerVC.channel = channel;
            [weakSelf presentViewController:livePlayerVC animated:YES completion:nil];
        }];
    } failure:^(PLVLiveErrorCode errorCode, NSString *description) {
        [hud hideAnimated:YES];
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"登录失败" message:description preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
        [weakSelf presentViewController:alertController animated:YES completion:nil];
    }];
}

#pragma mark - view controller

// 点击view结束编辑
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
