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
#import <PLVLiveAPI/PLVSettings.h>

@interface LoginViewController ()

@property (weak, nonatomic) IBOutlet UITextField *userIdTF;
@property (weak, nonatomic) IBOutlet UITextField *channelIdTF;

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *appId = [PLVSettings sharedInstance].getAppId;
    NSString *appSecret = [PLVSettings sharedInstance].getAppSecret;
    if ( [appId isKindOfClass:[NSNull class]] || [appSecret isKindOfClass:[NSNull class]] || [appId isEqualToString:@""] || [appSecret isEqualToString:@""] ) {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        [hud setMode:MBProgressHUDModeText];
        hud.label.text = @"未配置appId和appSecret!";
        hud.detailsLabel.text = @"连接聊天室需要配置appId和appSecret，可查看AppDelegate中的说明";
        [hud hideAnimated:YES afterDelay:5.0];
    }
    
    NSArray *userInfo = [[NSUserDefaults standardUserDefaults] objectForKey:@"userInfo"];
    if (userInfo) {
        self.userIdTF.text = userInfo[0];
        self.channelIdTF.text = userInfo[1];
    }
}

// 登录
- (IBAction)loginButtonClick:(UIButton *)sender {
    [[NSUserDefaults standardUserDefaults] setObject:@[self.userIdTF.text,self.channelIdTF.text] forKey:@"userInfo"];   // 保存数据
    if (![self.userIdTF.text length] || ![self.channelIdTF.text length]) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:@"用户名和账号不能为空" preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alertController animated:YES completion:nil];
        return;
    }

    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = @"登录中...";
    
    // 请求拉流地址
    [PLVChannel loadVideoJsonWithUserId:self.userIdTF.text channelId:self.channelIdTF.text completionHandler:^(PLVChannel *channel) {
        [hud hideAnimated:YES];
        
        LivePlayerViewController *livePlayerVC = [LivePlayerViewController new];
        livePlayerVC.channel = channel;

        [self presentViewController:livePlayerVC animated:YES completion:nil];
        
    } failureHandler:^(NSString *errorName, NSString *errorDescription) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:errorName message:errorDescription preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alertController animated:YES completion:nil];
    }];
}


// 点击view结束编辑
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

// 禁止当前控制器转屏
- (BOOL)shouldAutorotate {
    return NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
