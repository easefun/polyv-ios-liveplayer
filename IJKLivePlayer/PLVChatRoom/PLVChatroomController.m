//
//  PLVChatroomController.m
//  IJKLivePlayer
//
//  Created by ftao on 08/01/2018.
//  Copyright © 2018 easefun. All rights reserved.
//

#import "PLVChatroomController.h"
#import "PLVLiveManager.h"
#import "BCKeyBoard.h"
#import <Masonry/Masonry.h>

#define TOOL_BAR_HEIGHT 46.0

static NSString * const reuseChatCellIdentifier = @"ChatCell";

@interface PLVChatroomController () <UITableViewDelegate,UITableViewDataSource,BCKeyBoardDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) BCKeyBoard *bcKeyBoard;

@property (nonatomic, strong) NSMutableArray<PLVSocketChatRoomObject *> *chatRoomObjects;
@property (nonatomic, strong) NSMutableArray<PLVSocketChatRoomObject *> *privateChatObjects;

@end

@implementation PLVChatroomController {
    CGFloat _keyBoardHeight;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super init];
    if (self) {
        [self setupUIWithFrame:frame];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //[self setupUI];
    
    self.chatRoomObjects = [PLVLiveManager sharedLiveManager].chatRoomObjects;
    self.privateChatObjects = [PLVLiveManager sharedLiveManager].privateChatObjects;
}

//- (void)setupUI {
//    // 表情键盘
//    self.bcKeyBoard = [[BCKeyBoard alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.view.bounds)-TOOL_BAR_HEIGHT, CGRectGetWidth(self.view.bounds), TOOL_BAR_HEIGHT)];
//    [self.view addSubview:self.bcKeyBoard];
//    [self.bcKeyBoard mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.left.bottom.right.equalTo(self.view);
//        make.height.mas_equalTo(TOOL_BAR_HEIGHT);
//    }];
//    self.bcKeyBoard.delegate = self;
//    self.bcKeyBoard.placeholder = @"我也来聊几句...";
//    self.bcKeyBoard.placeholderColor = [UIColor colorWithRed:133/255 green:133/255 blue:133/255 alpha:0.5];
//    self.bcKeyBoard.backgroundColor = [UIColor clearColor];
//
//    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
//    //self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
//    [self.view addSubview:self.tableView];
//    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.left.top.right.equalTo(self.view);
//        make.bottom.equalTo(self.bcKeyBoard.mas_top);
//    }];
//    self.tableView.backgroundColor = [UIColor redColor];
//    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
//    self.tableView.delegate = self;
//    self.tableView.dataSource = self;
//
//    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:reuseChatCellIdentifier];
//}

- (void)setupUIWithFrame:(CGRect)frame {
    self.view.backgroundColor = [UIColor colorWithRed:233/255.0 green:235/255.0 blue:245/255.0 alpha:1.0];
    
    // 表情键盘
    self.bcKeyBoard = [[BCKeyBoard alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(frame)-TOOL_BAR_HEIGHT, CGRectGetWidth(frame), TOOL_BAR_HEIGHT)];
    [self.view addSubview:self.bcKeyBoard];
    self.bcKeyBoard.delegate = self;
    self.bcKeyBoard.placeholder = @"我也来聊几句...";
    self.bcKeyBoard.placeholderColor = [UIColor colorWithRed:133/255 green:133/255 blue:133/255 alpha:0.5];
    self.bcKeyBoard.backgroundColor = [UIColor clearColor];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(frame), CGRectGetHeight(frame)-TOOL_BAR_HEIGHT) style:UITableViewStylePlain];
    //self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.tableView];
    self.tableView.backgroundColor = [UIColor clearColor];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:reuseChatCellIdentifier];
}

#pragma mark - Public interface

- (void)updateChatroom {
    if (self.privateChatMode) {
        self.privateChatObjects = [PLVLiveManager sharedLiveManager].privateChatObjects;
    }else {
        self.chatRoomObjects = [PLVLiveManager sharedLiveManager].chatRoomObjects;
    }
    [self.tableView reloadData];
}

#pragma mark - <UITableViewDelegate>
/// 返回单元格高度
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.isPrivateChatMode) {
        
    }else {
        
    }
    return 40.0;
}

#pragma mark - <UITableViewDataSource>

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.isPrivateChatMode) {
        return self.privateChatObjects.count;
    }else {
        return self.chatRoomObjects.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseChatCellIdentifier forIndexPath:indexPath];
    if (cell) {
        for (UIView *view in cell.subviews) {
            [view removeFromSuperview];
        }
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.backgroundColor = [UIColor clearColor];
    
    if (self.isPrivateChatMode) {
        PLVSocketChatRoomObject *chatObject = self.chatRoomObjects[indexPath.row];
        switch (chatObject.eventType) {
            case PLVSocketChatRoomEventType_S_QUESTION:
                break;
            case PLVSocketChatRoomEventType_T_ANSWER:
                break;
            default:
                break;
        }
    }else {
        PLVSocketChatRoomObject *chatObject = self.chatRoomObjects[indexPath.row];
        switch (chatObject.eventType) {
            case PLVSocketChatRoomEventType_SPEAK: {
                
            } break;
            case PLVSocketChatRoomEventType_LOGIN: {
                
            } break;
            case PLVSocketChatRoomEventType_GONGGAO:
            case PLVSocketChatRoomEventType_BULLETIN: {
                
            } break;
            default:
                break;
        }
    }

    return cell;
}

#pragma mark - <BCKeyBoardDelegate>

- (void)didSendText:(NSString *)text {
    if (!text || !text.length) {
        return;
    }
    NSLog(@"send text:%@",text);
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(sendMessage:privateChatMode:)]) {
        [self.delegate sendMessage:text privateChatMode:self.isPrivateChatMode];
    }
}

- (void)returnHeight:(CGFloat)height {
    NSLog(@"keyboard height:%f",height);
    _keyBoardHeight = height;
    
    CGRect frame = self.view.frame;
    frame.size.height -= height;
    [self.tableView setFrame:frame];
}

#pragma mark - notifications
/*
- (void)onKeyboardDidShow:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    CGRect endFrame = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    NSLog(@"endFrame:%@,duration:%f",NSStringFromCGRect(endFrame),duration);
    [UIView animateWithDuration:duration animations:^{
        [UIView setAnimationCurve:[userInfo[UIKeyboardAnimationCurveUserInfoKey] doubleValue]];
//        CGRect frame = self.view.frame;
//        frame.size.height -= CGRectGetHeight(endFrame) + 64.0;
//        self.view.frame = frame;
        
//        CGRect frame = self.view.frame;
//        //        frame.size.height = endFrame.origin.y - origionFrame.origin.y;
//        frame.size.height = CGRectGetHeight(frame) - CGRectGetHeight(endFrame) - 64.0 - TOOL_BAR_HEIGHT;
//        self.tableView.frame = frame;
//
//        [self.view layoutIfNeeded];
    }];
}*/

#pragma mark -

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
