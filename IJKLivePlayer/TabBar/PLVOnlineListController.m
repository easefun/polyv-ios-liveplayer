//
//  PLVOnlineListController.m
//  IJKLivePlayer
//
//  Created by ftao on 11/01/2018.
//  Copyright © 2018 easefun. All rights reserved.
//

#import "PLVOnlineListController.h"
#import "PLVLiveManager.h"
#import <PLVLiveAPI/PLVChannel.h>
#import "PLVUserTableViewCell.h"

@interface PLVOnlineListController () <UITableViewDelegate,UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<NSDictionary *> *onlineList;

@end

static NSString * const reuseUserCellIdentifier = @"OnlineListCell";

@implementation PLVOnlineListController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self setupUI];
    self.onlineList = [PLVLiveManager sharedLiveManager].onlineList;
}

- (void)setupUI {
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.tableView];
    self.tableView.backgroundColor = [UIColor clearColor];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    [self.tableView registerNib:[UINib nibWithNibName:@"PLVUserTableViewCell" bundle:nil] forCellReuseIdentifier:reuseUserCellIdentifier];
    //[self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:reuseChatCellIdentifier];
}

- (void)updateOnlineList {
    NSInteger channelId = [PLVLiveManager sharedLiveManager].channelId.integerValue;
    __weak typeof(self)weakSelf = self;
    [PLVChannel requestChatRoomListUsersWithRoomId:channelId completion:^(NSDictionary *listUsers) {
        weakSelf.onlineList = [PLVLiveManager handleOnlineListWithJsonDictionary:listUsers];
        [weakSelf.tableView reloadData];
    } failure:^(PLVLiveErrorCode errorCode, NSString *description) {
        NSLog(@"聊天室在线列表获取失败:%@",description);
    }];
}

#pragma mark - <UITableViewDataSource>

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.onlineList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    NSDictionary *userInfo = self.onlineList[indexPath.row];
    
    PLVUserTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseUserCellIdentifier forIndexPath:indexPath];
    cell.nicknameLB.text = userInfo[@"nick"];
    cell.imgUrl = userInfo[@"pic"];
//    if (cell) {
//        for (UIView *view in cell.subviews) {
//            [view removeFromSuperview];
//        }
//    }
//    cell.selectionStyle = UITableViewCellSelectionStyleNone;
//    cell.backgroundColor = [UIColor redColor];
    
    return cell;
}

#pragma mark - <UITableViewDelegate>

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
