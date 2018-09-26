//
//  PLVOnlineListController.m
//  IJKLivePlayer
//
//  Created by ftao on 11/01/2018.
//  Copyright © 2018 easefun. All rights reserved.
//

#import "PLVOnlineListController.h"
#import "PLVLiveManager.h"
#import <PLVLiveAPI/PLVLiveAPI.h>
#import "PLVUserTableViewCell.h"
#import <Masonry/Masonry.h>
#import <AgoraRtcEngineKit/AgoraRtcEngineKit.h>
#import "PLVUtils.h"

/// 连麦状态
typedef NS_ENUM(NSUInteger, PLVLinkMicStatus) {
    /// 无状态（无连麦）
    PLVLinkMicStatusNone,
    /// 等待发言中（举手中）
    PLVLinkMicStatusWait,
    /// 连麦中（加入中）
    PLVLinkMicStatusJoining,
    /// 发言中（连麦中）
    PLVLinkMicStatusJoin,
};

@interface PLVOnlineListController () <UITableViewDelegate,UITableViewDataSource,AgoraRtcEngineDelegate>

@property (nonatomic, strong) AgoraRtcEngineKit *agoraKit;

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *speakButtonBgView;
@property (nonatomic, strong) UIButton *speakButton;

@property (nonatomic, strong) NSMutableArray<NSDictionary *> *onlineList;

@property (nonatomic, strong) PLVSocketObject *login;
@property (nonatomic, assign) NSUInteger linkMicUserId;
@property (nonatomic, strong) NSDictionary *linkMicParams;
@property (nonatomic, getter=isLinkMicOpen) BOOL linkMicOpen;   // 连麦是否开启
@property (nonatomic, strong) NSString *linkMicType;            // 连麦类型
@property (nonatomic, assign) PLVLinkMicStatus linkMicStatus;   // 当前用户连麦状态

@property (nonatomic, assign) NSUInteger onlineCount;

@property (nonatomic, strong) NSTimer *timer;

@end

static NSString * const reuseUserCellIdentifier = @"OnlineListCell";

@implementation PLVOnlineListController

#pragma mark - Lifecycle

- (void)dealloc {
    NSLog(@"[%@ %@]",NSStringFromClass([self class]),NSStringFromSelector(_cmd));
    [AgoraRtcEngineKit destroy];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self setupUI];
    [self initializeLocalData];
    [self initializeAgoraKit];
    
    // 开启定时器，轮询列表及连麦状态
    self.timer = [NSTimer scheduledTimerWithTimeInterval:15.0 target:self selector:@selector(onTimeRequestNetwork) userInfo:nil repeats:YES];
    [self.timer fire];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark Initialize

- (void)setupUI {
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.tableView];
    self.tableView.backgroundColor = [UIColor clearColor];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    //[self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:reuseChatCellIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:@"PLVUserTableViewCell" bundle:nil] forCellReuseIdentifier:reuseUserCellIdentifier];
    
    self.speakButtonBgView = [[UIView alloc] init];
    self.speakButtonBgView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.speakButtonBgView];
    self.speakButtonBgView.hidden = YES;
    
    self.speakButton = [[UIButton alloc] init];
    [self.view addSubview:self.speakButton];
    [self.speakButton setShowsTouchWhenHighlighted:YES];
    [self.speakButton addTarget:self action:@selector(speakButtonBeClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.speakButton setHidden:YES];
    
    CGFloat heightOfSpeakButtonBgView = 50.0;
    if ([PLVUtils isPhoneX]) {
        CGRect tableViewRect = self.tableView.frame;
        tableViewRect.size.height -= 34.0;
        self.tableView.frame = tableViewRect;
        
        heightOfSpeakButtonBgView = 84.0;
        self.speakButton.layer.cornerRadius = 20.0;
        [self.speakButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.view);
            make.bottom.equalTo(self.view.mas_bottom).offset(-34.0);
            make.width.mas_equalTo(250.0);
            make.height.mas_equalTo(40.0);
        }];
    } else {
        [self.speakButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self.view);
            make.width.equalTo(self.view);
            make.height.mas_equalTo(50.0);
        }];
    }
    [self.speakButtonBgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view);
        make.width.equalTo(self.view);
        make.height.mas_equalTo(heightOfSpeakButtonBgView);
    }];
}

- (void)initializeLocalData {
    self.onlineList = [NSMutableArray array];
    self.linkMicStatus = PLVLinkMicStatusNone;
    self.login = [PLVLiveManager sharedLiveManager].login;
    self.linkMicUserId = [self.login.userId longLongValue];
    self.linkMicParams = [PLVLiveManager sharedLiveManager].linkMicParams;
}

- (void)initializeAgoraKit {
    self.agoraKit = [AgoraRtcEngineKit sharedEngineWithAppId:self.linkMicParams[@"connect_appId"] delegate:self];
    [self.agoraKit setChannelProfile:AgoraRtc_ChannelProfile_Communication];
    [self.agoraKit setVideoProfile:AgoraRtc_VideoProfile_180P swapWidthAndHeight:NO];
}

#pragma mark - Rewrite

- (void)setLinkMicObject:(PLVSocketLinkMicObject *)linkMicObject {
    _linkMicObject = linkMicObject;
    NSDictionary *jsonDict = linkMicObject.jsonDict;
    switch (linkMicObject.eventType) {
        case PLVSocketLinkMicEventType_OPEN_MICROPHONE: { // 教师端/服务器操作（广播消息broadcast）
            if (jsonDict[@"teacherId"]) {   // 开启/关闭连麦
                [self updateRoomLinkMicStatus:jsonDict[@"status"] type:jsonDict[@"type"]];
            }else if ([jsonDict[@"userId"] isEqualToString:[NSString stringWithFormat:@"%lu",self.linkMicUserId]]) {
                // 断开学员连麦(自己)
                [self leaveAgoraRtc];
                [self showEndLinkMicAlert];
            }
        } break;
        case PLVSocketLinkMicEventType_JOIN_REQUEST:   // 举手请求（广播消息broadcast）
        case PLVSocketLinkMicEventType_JOIN_LEAVE:     // linkMicUserId离开（广播消息broadcast）
        case PLVSocketLinkMicEventType_JOIN_SUCCESS: { // 加入声网成功事件（广播消息broadcast）
            NSDictionary *userInfo = jsonDict[@"user"];
            NSString *linkMicUserId = userInfo[@"userId"];
            if ([linkMicUserId isEqualToString:@(self.linkMicUserId).stringValue]) {
                if (linkMicObject.eventType == PLVSocketLinkMicEventType_JOIN_REQUEST) {
                    [self.onlineList insertObject:userInfo atIndex:0];
                    [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
                }else if (linkMicObject.eventType == PLVSocketLinkMicEventType_JOIN_LEAVE) {
                    for (int i=0; i<self.onlineList.count; i++) {
                        NSDictionary *userInfo = self.onlineList[i];
                        if ([linkMicUserId isEqualToString:userInfo[@"userId"]] && userInfo[@"status"] ) {
                            [self.onlineList removeObject:userInfo];
                            [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:i inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
                            break;
                        }
                    }
                }else {
                }
            }
        } break;
        case PLVSocketLinkMicEventType_JOIN_RESPONSE: { // 老师同意通话事件（单播消息unicast）
            [self joinAgoraRtc];
        } break;
        default: break;
    }
}

- (void)setLinkMicStatus:(PLVLinkMicStatus)linkMicStatus {
    switch (linkMicStatus) {
        case PLVLinkMicStatusNone: { // 执行申请发言操作
            if (_linkMicStatus != PLVLinkMicStatusNone) {
                [self emitLinkMicObjectWithEventType:PLVSocketLinkMicEventType_JOIN_LEAVE]; //emit join leave event.
            }
            [self.speakButton setEnabled:YES];
            [self.speakButton setTitle:@"申请发言" forState:UIControlStateNormal];
            [self.speakButton.titleLabel setFont:[UIFont systemFontOfSize:16.0 weight:UIFontWeightMedium]];
            [self.speakButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [self.speakButton setBackgroundColor:[UIColor colorWithRed:0 green:154/255.0 blue:1 alpha:1]];
        } break;
        case PLVLinkMicStatusWait: { // 执行举手操作
            if (_linkMicStatus == PLVLinkMicStatusNone) {
                [self emitLinkMicObjectWithEventType:PLVSocketLinkMicEventType_JOIN_REQUEST]; //emit join request event.
            }
            [self.speakButton setEnabled:YES];
            [self.speakButton setTitle:@"取消发言" forState:UIControlStateNormal];
            [self.speakButton.titleLabel setFont:[UIFont systemFontOfSize:16.0 weight:UIFontWeightRegular]];
            [self.speakButton setTitleColor:[UIColor colorWithWhite:64/255.0 alpha:1.0] forState:UIControlStateNormal];
            [self.speakButton setBackgroundColor:[UIColor whiteColor]];
        } break;
        case PLVLinkMicStatusJoining: { // 连麦中状态
            [self.speakButton setEnabled:NO];
            [self.speakButton setTitle:@"加入中" forState:UIControlStateNormal];
        } break;
        case PLVLinkMicStatusJoin: { // 执行结束发言操作
            [self.speakButton setEnabled:YES];
            [self.speakButton setTitle:@"结束发言" forState:UIControlStateNormal];
            [self.speakButton.titleLabel setFont:[UIFont systemFontOfSize:16.0 weight:UIFontWeightMedium]];
            [self.speakButton setTitleColor:[UIColor colorWithRed:231/255.0 green:76/255.0 blue:60/255.0 alpha:1] forState:UIControlStateNormal];
            [self.speakButton setBackgroundColor:[UIColor whiteColor]];
        } break;
        default: break;
    }
    _linkMicStatus = linkMicStatus;
}

#pragma mark - Actions

- (void)speakButtonBeClicked:(UIButton *)sender {
    switch (self.linkMicStatus) {
        case PLVLinkMicStatusNone: { // 执行申请发言操作
            if ([PLVUtils hasVideoAndAudioAuthorization]) { // 需要音视频权限
                self.linkMicStatus = PLVLinkMicStatusWait;
            }else {
                [PLVUtils requestVideoAndAudioAuthorizationWithViewController:self];
            }
        } break;
        case PLVLinkMicStatusWait: { // 执行取消发言操作
            self.linkMicStatus = PLVLinkMicStatusNone;
        } break;
        case PLVLinkMicStatusJoin: { // 执行结束发言操作
            __weak typeof(self)weakSelf = self;
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:@"您确定要结束发言吗？" preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
            [alertController addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [weakSelf leaveAgoraRtc];
            }]];
            [self presentViewController:alertController animated:YES completion:nil];
        } break;
        default: break;
    }
}

#pragma mark - Public methods

- (void)clearController {
    [self leaveAgoraRtc];
    [self invalidateTimer];
}

- (void)invalidateTimer {
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
}

#pragma mark - Private methods

- (void)onTimeRequestNetwork {
    __weak typeof(self)weakSelf = self;
    [PLVLiveAPI requestLinkMicStatusWithRoomId:self.channelId completion:^(NSString *status, NSString *type) {
        [weakSelf updateRoomLinkMicStatus:status type:type];
    } failure:^(PLVLiveErrorCode errorCode, NSString *description) {
        [PLVUtils showHUDWithTitle:@"连麦状态获取失败！" detail:description view:self.view];
    }];
    [PLVLiveAPI requestChatRoomListUsersWithRoomId:self.channelId completion:^(NSDictionary *listUsers) {
        weakSelf.onlineCount =  [listUsers[@"count"] unsignedIntegerValue];
        if (weakSelf.isLinkMicOpen) {
            [PLVLiveAPI requestLinkMicOnlineListWithRoomId:self.channelId completion:^(NSArray *onlineList) {
                weakSelf.onlineList = listUsers[@"userlist"];
                [weakSelf.onlineList insertObjects:onlineList atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, onlineList.count)]];
                [weakSelf.tableView reloadData];
                [weakSelf updateUserLinkMicStatus:onlineList];
            } failure:^(PLVLiveErrorCode errorCode, NSString *description) {
                [PLVUtils showHUDWithTitle:@"连麦在线列表获取失败！" detail:description view:self.view];
            }];
        }else { // 数据源更新和reloadData需要同时处理
            weakSelf.onlineList = listUsers[@"userlist"];
            [weakSelf.tableView reloadData];
        }
    } failure:^(PLVLiveErrorCode errorCode, NSString *description) {
        [PLVUtils showHUDWithTitle:@"聊天室在线列表获取失败！" detail:description view:self.view];
    }];
}

- (void)emitLinkMicObjectWithEventType:(PLVSocketLinkMicEventType)eventType {
    if (self.delegate && [self.delegate respondsToSelector:@selector(emitLinkMicObject:)]) {
        PLVSocketLinkMicObject *linkMicObject = [PLVSocketLinkMicObject linkMicObjectWithEventType:eventType roomId:self.channelId userNick:self.login.nickName userPic:self.login.avatar userId:self.linkMicUserId userType:PLVSocketObjectUserTypeStudent];
        [self.delegate emitLinkMicObject:linkMicObject];
    }
}

/// 更新当前房间连麦状态
- (void)updateRoomLinkMicStatus:(NSString *)status type:(NSString *)type {
    //NSLog(@"link mic status:%@, type:%@",status,type);
    self.linkMicType = type;
    if ([status isEqualToString:@"open"]) { // 服务器状态：连麦开启
        if (self.isLinkMicOpen && !self.speakButton.isHidden) {
            return;
        }else { // set link mic ui.
            self.linkMicOpen = YES;
            self.speakButtonBgView.hidden = NO;
            [self.speakButton setHidden:NO];
            CGRect newFrame = self.tableView.frame;
            newFrame.size.height -= 50;
            [self.tableView setFrame:newFrame];
        }
    }else { // 服务器状态：连麦未开启
        if (!self.isLinkMicOpen && self.speakButton.isHidden) {
            return;
        }else { // recover ui and handle
            self.linkMicOpen = NO;
            self.speakButtonBgView.hidden = YES;
            [self.speakButton setHidden:YES];
            [self.tableView setFrame:self.view.bounds];
            switch (self.linkMicStatus) {
                case PLVLinkMicStatusJoin: // 教师端关闭连麦时自己在连麦状态
                    [self showEndLinkMicAlert];
                case PLVLinkMicStatusWait: { // 教师端关闭连麦时自己在举手状态
                    [self leaveAgoraRtc];
                } break;
                default: break;
            }
        }
    }
}

/// 修正当前用户连麦状态（使用服务器数据）
- (void)updateUserLinkMicStatus:(NSArray *)linkMicList {
    if (linkMicList && linkMicList.count) {
        for (NSDictionary *userInfo in linkMicList) {
            NSString *linkMicUserId = [NSString stringWithFormat:@"%@",userInfo[@"userId"]];
            if ([linkMicUserId isEqualToString:@(self.linkMicUserId).stringValue]) { // 当前用户为自己
                if ([userInfo[@"status"] isEqualToString:@"join"]) {    //1.后台显示连麦中
                    if (self.linkMicStatus == PLVLinkMicStatusJoin) {
                        return;
                    }else {
                        self.linkMicStatus = PLVLinkMicStatusJoin;   //1.1非Wait状态时更新
                    }
                }else { //2.后台显示举手中
                    if (self.linkMicStatus==PLVLinkMicStatusWait || self.linkMicStatus==PLVLinkMicStatusJoining) {
                        return;
                    }else {
                        self.linkMicStatus = PLVLinkMicStatusWait;  //2.1非Wait状态时更新
                    }
                }
                return;
            }
        }
        if (self.linkMicStatus != PLVLinkMicStatusNone) { //3.当前状态不为None（同时连麦列表中找不到此人）
            [self leaveAgoraRtc]; // 3.1非None状态时更新
            [PLVUtils showHUDWithTitle:@"连麦列表无当前用户" detail:@"恢复至申请发言状态" view:self.view];
        }
    }
}

- (void)showEndLinkMicAlert {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:@"老师已结束与您的通话" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"我知道了" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)joinAgoraRtc {
    self.linkMicStatus = PLVLinkMicStatusJoining;
    if ([self.linkMicType isEqualToString:@"video"]) {
        [self.agoraKit enableVideo];
        [self.agoraKit enableLocalVideo:YES];
    }else {
        [self.agoraKit disableVideo];
        [self.agoraKit enableLocalVideo:NO];
    }
    [self.agoraKit setDefaultAudioRouteToSpeakerphone:YES];

    __weak typeof(self)weakSelf = self;
    NSString *channelName = [NSString stringWithFormat:@"%ld",self.channelId];
    int code = [self.agoraKit joinChannelByKey:self.linkMicParams[@"connect_channel_key"] channelName:channelName info:nil uid:self.linkMicUserId joinSuccess:^(NSString * _Nonnull channel, NSUInteger uid, NSInteger elapsed) {
        NSLog(@"Join rtc success, channel:%@,uid:%ld,elapsed:%ld",channel,uid,elapsed);
        [weakSelf joinRtcSuccessfully];
    }];
    if (code != 0) {    // invoke failed
        [PLVUtils showHUDWithTitle:@"连麦提示：加入失败！" detail:[NSString stringWithFormat:@"Join channel failed: %d", code] view:self.view];
    }
}

- (void)leaveAgoraRtc {
    if (!self.agoraKit) return;
    if (self.linkMicStatus == PLVLinkMicStatusJoining
        || self.linkMicStatus == PLVLinkMicStatusJoin) {
        __weak typeof(self)weakSelf = self;
        [self.agoraKit leaveChannel:^(AgoraRtcStats * _Nonnull stat) {
            [weakSelf leaveRtcSuccessfully];
        }];
    }
    self.linkMicStatus = PLVLinkMicStatusNone;
}

- (void)joinRtcSuccessfully {
    NSLog(@"%@",NSStringFromSelector(_cmd));
    self.linkMicStatus = PLVLinkMicStatusJoin;
    [self setIdleTimerActive:NO];
    [[NSNotificationCenter defaultCenter] postNotificationName:PLVLiveLinkMicDidJoinNotification object:self];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.timer fire];
    });
}

- (void)leaveRtcSuccessfully {
    NSLog(@"%@",NSStringFromSelector(_cmd));
    self.linkMicStatus = PLVLinkMicStatusNone;
    [self setIdleTimerActive:YES];
    [[NSNotificationCenter defaultCenter] postNotificationName:PLVLiveLinkMicDidLeaveNotification object:self];
}

- (void)setIdleTimerActive:(BOOL)active {
    [UIApplication sharedApplication].idleTimerDisabled = !active;
}

#pragma mark - <AgoraRtcEngineDelegate>

#pragma mark SDK common delegates
- (void)rtcEngine:(AgoraRtcEngineKit *)engine didOccurWarning:(AgoraRtcWarningCode)warningCode {
    NSLog(@"%@,%ld",NSStringFromSelector(_cmd),warningCode);
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine didOccurError:(AgoraRtcErrorCode)errorCode {
    NSLog(@"%@,%ld",NSStringFromSelector(_cmd),errorCode);
    [PLVUtils showHUDWithTitle:@"连麦出错！" detail:[NSString stringWithFormat:@"错误码：%ld",errorCode] view:self.view];
    if (errorCode != AgoraRtc_Error_LeaveChannelRejected) {
        [self leaveAgoraRtc];
    }
}

- (void)rtcEngineRequestChannelKey:(AgoraRtcEngineKit *)engine {
    NSLog(@"%@",NSStringFromSelector(_cmd));
    [PLVLiveAPI requestAuthorizationForLinkingSocketWithChannelId:self.channelId Appld:[PLVLiveConfig sharedInstance].appId appSecret:[PLVLiveConfig sharedInstance].appSecret success:^(NSDictionary *responseDict) {
        [engine renewChannelKey:responseDict[@"connect_channel_key"]];
    } failure:^(PLVLiveErrorCode errorCode, NSString *description) {
        NSLog(@"ChannelKey获取失败:%ld %@",errorCode,description);
    }];
}

/// 在 SDK 和服务器失去了网络连接时，触发该回调。失去连接后，除非APP主动调用 leaveChannel，SDK 会一直自动重连。
- (void)rtcEngineConnectionDidInterrupted:(AgoraRtcEngineKit *)engine {
    NSLog(@"%@",NSStringFromSelector(_cmd));
    [PLVUtils showHUDWithTitle:@"连麦提示：网络连接中断" detail:@"自动重连中..." view:self.view];
}

- (void)rtcEngineConnectionDidLost:(AgoraRtcEngineKit *)engine {
    NSLog(@"%@",NSStringFromSelector(_cmd));
    [PLVUtils showHUDWithTitle:@"连麦提示：网络连接丢失" detail:@"自动重连中..." view:self.view];
}

#pragma mark Local user common delegates
/// 有时候由于网络原因，客户端可能会和服务器失去连接，SDK 会进行自动重连，自动重连成功后触发此回调方法
- (void)rtcEngine:(AgoraRtcEngineKit *)engine didRejoinChannel:(NSString * _Nonnull)channel withUid:(NSUInteger)uid elapsed:(NSInteger)elapsed {
    NSLog(@"%@,uid:%lu",NSStringFromSelector(_cmd),uid);
    [PLVUtils showHUDWithTitle:@"连麦提示：重连成功" detail:nil view:self.view];
}

#pragma mark Local user video delegates
- (void)rtcEngineCameraDidReady:(AgoraRtcEngineKit *)engine {
    NSLog(@"%@",NSStringFromSelector(_cmd));
}

- (void)rtcEngineVideoDidStop:(AgoraRtcEngineKit *)engine {
    NSLog(@"%@",NSStringFromSelector(_cmd));
}

#pragma mark Remote user common delegates
- (void)rtcEngine:(AgoraRtcEngineKit *)engine didJoinedOfUid:(NSUInteger)uid elapsed:(NSInteger)elapsed {
    NSLog(@"%@,uid:%lu,elapase:%ld",NSStringFromSelector(_cmd),uid,elapsed);
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine didOfflineOfUid:(NSUInteger)uid reason:(AgoraRtcUserOfflineReason)reason {
    NSLog(@"%@,uid:%lu,reason:%ld",NSStringFromSelector(_cmd),uid,reason);
}

#pragma mark - <UITableViewDataSource>

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.onlineList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PLVUserTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseUserCellIdentifier forIndexPath:indexPath];
    cell.userInfo = self.onlineList[indexPath.row];
    cell.linkMicType = self.linkMicType;
    
    return cell;
}

#pragma mark - <UITableViewDelegate>

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}

@end
