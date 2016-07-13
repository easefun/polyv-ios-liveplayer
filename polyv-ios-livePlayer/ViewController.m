//
//  ViewController.m
//  liveplayer
//
//  Created by seanwong on 11/19/14.
//  Copyright (c) 2014 easefun. All rights reserved.
//

#import "ViewController.h"
#import "LivePlayerViewController.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextField *useridTextField;
@property (weak, nonatomic) IBOutlet UITextField *channelidTextField;

@end


@implementation ViewController

- (IBAction)touch:(id)sender {
    
    PLVChannel*channel = [[PLVChannel alloc]init];
    channel.userId =self.useridTextField.text;
    channel.channelId =self.channelidTextField.text;
    
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    LivePlayerViewController *liveViewController = [storyboard instantiateViewControllerWithIdentifier:@"LiveViewController"];
    liveViewController.hidesBottomBarWhenPushed = YES;
    liveViewController.channel = channel;
    
    [self presentViewController:liveViewController animated:YES completion:nil];
    
}

- (void)viewDidLoad {
    
    
    [super viewDidLoad];
}


- (BOOL)shouldAutorotate {
    return YES;              // 禁止转屏
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
