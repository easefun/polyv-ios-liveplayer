//
//  PLVChatroomController.m
//  IJKLivePlayer
//
//  Created by ftao on 08/01/2018.
//  Copyright © 2018 easefun. All rights reserved.
//

#import "PLVChatroomController.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "PLVLiveManager.h"
#import "BCKeyBoard.h"
#import <Masonry/Masonry.h>
#import "PLVUtils.h"
#import <PLVLiveAPI/PLVLiveAPI.h>
#import "PLVLivePlayerController.h"

#define SPEAK_FONT_SIZE 14.0       // 聊天发言文字大小
#define SYSTEM_FONT_SIZE 12.0      // 系统样式文字大小
#define SPEAK_MAX_WIDTH 200.0f     // 聊天发言消息最大长度
#define SYSTEM_MAX_WIDTH 250.0f    // 系统样式消息最大长度

#define TOOL_BAR_HEIGHT 46.0       // 工具栏高度

static NSString * const reuseChatCellIdentifier = @"ChatCell";

@interface PLVChatroomController () <UITableViewDelegate,UITableViewDataSource,BCKeyBoardDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIButton *showLatestMessageBtn;
@property (nonatomic, strong) BCKeyBoard *bcKeyBoard;

@property (nonatomic, assign) NSUInteger roomId;
@property (nonatomic, strong) NSMutableArray *chatroomObjects;
@property (nonatomic, strong) NSMutableArray<PLVSocketChatRoomObject *> *privateChatObjects;

@end

@implementation PLVChatroomController {
    CGRect _originFrame;
    NSDate *_lastSpeakTime;
    BOOL _isSelfSpeak;
    BOOL _isCellInBottom;
    BOOL _moreMessage;
    BOOL _haveloaded;
    NSUInteger _startIndex;
}

#pragma mark - LifeCycle
- (void)dealloc {
    // 防止销毁后继续执行代理事件
    if (self.bcKeyBoard) {
        self.bcKeyBoard.delegate = nil;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

    _isCellInBottom = YES;
    _moreMessage = YES;
    self.roomId = [PLVLiveManager sharedLiveManager].channelId;
    self.chatroomObjects = [PLVLiveManager sharedLiveManager].chatroomObjects;
    self.privateChatObjects = [PLVLiveManager sharedLiveManager].privateChatObjects;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideEmojiKeyBoard) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideEmojiKeyBoard) name:UIApplicationProtectedDataWillBecomeUnavailable object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideEmojiKeyBoard) name:PLVLivePlayerWillChangeToFullScreenNotification object:nil];
}

//- (void)statusBarOrientationDidChange:(NSNotification *)notification {
//    UIInterfaceOrientation interfaceOritation = [[UIApplication sharedApplication] statusBarOrientation];
//    if (interfaceOritation == UIInterfaceOrientationPortrait
//        && self.bcKeyBoard.type != BCKeyBoardTypeFace) {
//        [self.tableView setFrame:_originFrame];
//    }
//}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (!_haveloaded && !self.privateChatMode) {
        [self setupRefresh];
        _haveloaded = YES;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self hideEmojiKeyBoard];
}

- (void)setupUIWithFrame:(CGRect)frame {
    CGFloat keyBoardHeight = TOOL_BAR_HEIGHT;
    if ([PLVUtils isPhoneX]) {
        keyBoardHeight += 38.0;
    }
    
    _originFrame = CGRectMake(0, 0, CGRectGetWidth(frame), CGRectGetHeight(frame) - keyBoardHeight);
    self.tableView = [[UITableView alloc] initWithFrame:_originFrame style:UITableViewStylePlain];
    [self.view addSubview:self.tableView];
    self.tableView.backgroundColor = [UIColor clearColor];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:reuseChatCellIdentifier];
    
    // 表情键盘
    self.bcKeyBoard = [[BCKeyBoard alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(frame) - keyBoardHeight, CGRectGetWidth(frame), keyBoardHeight)];
    [self.view addSubview:self.bcKeyBoard];
    self.bcKeyBoard.placeholder = @"我也来聊几句...";
    self.bcKeyBoard.placeholderColor = [UIColor colorWithRed:133/255 green:133/255 blue:133/255 alpha:0.5];
    self.bcKeyBoard.backgroundColor = [UIColor clearColor];
    self.bcKeyBoard.delegate = self;
    
    self.showLatestMessageBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.showLatestMessageBtn setTitle:@"有更多新消息，点击查看" forState:UIControlStateNormal];
    [self.showLatestMessageBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.showLatestMessageBtn.titleLabel setFont:[UIFont systemFontOfSize:12 weight:UIFontWeightMedium]];
    self.showLatestMessageBtn.backgroundColor = [UIColor colorWithRed:90/255.0 green:200/255.0 blue:250/255.0 alpha:1];
    self.showLatestMessageBtn.clipsToBounds = YES;
    self.showLatestMessageBtn.layer.cornerRadius = 15.0;
    [self.view addSubview:self.showLatestMessageBtn];
    [self.showLatestMessageBtn addTarget:self action:@selector(scrollTableViewToBottom) forControlEvents:UIControlEventTouchUpInside];
    self.showLatestMessageBtn.hidden = YES;
    
    [self.showLatestMessageBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(185, 30));
        make.centerX.equalTo(self.view);
        make.bottom.equalTo(self.bcKeyBoard.mas_top).offset(-10);
    }];
}

// 下拉刷新控件
- (void)setupRefresh {
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refreshClick:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:refreshControl];
    [self refreshClick:refreshControl]; // 主动触发一次
}

- (void)refreshClick:(UIRefreshControl *)refreshControl {
    [refreshControl endRefreshing];
    //NSLog(@"refreshClick:");
    NSUInteger length = 20;
    if (_moreMessage) {
        __weak typeof(self)weakSelf = self;
        [PLVLiveAPI requestChatRoomHistoryWithRoomId:self.roomId startIndex:_startIndex endIndex:_startIndex+length completion:^(NSArray *historyList) {
            NSLog(@"historyList count:%ld",historyList.count);
            [[PLVLiveManager sharedLiveManager] handleChatRoomHistoryMessage:historyList];
            [weakSelf.tableView reloadData];
            if (!_startIndex) {
                [weakSelf.tableView scrollsToTop];
            }
            if (historyList.count > length) {
                _startIndex += length;
            }else {
                _moreMessage = NO;
            }
        } failure:^(PLVLiveErrorCode errorCode, NSString *description) {
            [PLVUtils showHUDWithTitle:@"聊天室历史记录获取失败！" detail:description view:weakSelf.view];
        }];
    } else {
        [PLVUtils showHUDWithTitle:@"没有更多数据了" detail:nil view:self.view];
    }
}

#pragma mark - Public
/// !!!:当前数据更新只存在新增数据一种情况
- (void)updateChatroom {
    [self.tableView reloadData];
    if (_isSelfSpeak || self.privateChatMode) {
        _isSelfSpeak = NO;
        [self scrollTableViewToBottom];
    }else {
        if (_isCellInBottom) {
            [self scrollTableViewToBottom];
        }else {
            self.showLatestMessageBtn.hidden = NO;
        }
    }
    //[self.tableView visibleCells];  // apple bugs.
    //[self.tableView.indexPathsForVisibleRows lastObject];
}

- (void)hideEmojiKeyBoard {
    [self.bcKeyBoard hideTheKeyBoard];
    [self.tableView setFrame:_originFrame];
}

#pragma mark - <UITableViewDataSource>

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.isPrivateChatMode) {
        return self.privateChatObjects.count;
    }else {
        return self.chatroomObjects.count;
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
        PLVSocketChatRoomObject *chatObject = self.privateChatObjects[indexPath.row];
        NSString *content = chatObject.jsonDict[PLVSocketIOChatRoom_S_QUESTION_content];
        switch (chatObject.eventType) {
            case PLVSocketChatRoomEventType_S_QUESTION:
                if (chatObject.isLocalMessage) {            // 自己提交的发言信息
                    [cell addSubview:[self bubbleViewForSelfWithContent:content position:5]];
                } break;
            case PLVSocketChatRoomEventType_T_ANSWER: {
                NSString *nickname = chatObject.jsonDict[PLVSocketIOChatRoomUserKey][PLVSocketIOChatRoomUserNickKey];
                NSString *nickImg = chatObject.jsonDict[PLVSocketIOChatRoomUserKey][PLVSocketIOChatRoomUserPicKey];
                if (![nickImg containsString:@"http"]) {
                    nickImg = [@"https:" stringByAppendingString:nickImg];
                }
                [cell addSubview:[self bubbleViewForOtherWithNickname:nickname nickImg:nickImg content:content position:5]];
            } break;
            default: break;
        }
    }else {
        id chatroomObject = self.chatroomObjects[indexPath.row];
        if ([chatroomObject isKindOfClass:[PLVSocketChatRoomObject class]]) {
            PLVSocketChatRoomObject *chatroom = (PLVSocketChatRoomObject *)chatroomObject;
            if (chatroom.eventType == PLVSocketChatRoomEventType_SPEAK) {
                NSString *content = [chatroom.jsonDict[PLVSocketIOChatRoom_SPEAK_values] firstObject];
                if (chatroom.isLocalMessage) {
                    [cell addSubview:[self bubbleViewForSelfWithContent:content position:5]];
                }else {
                    NSString *nickname = chatroom.jsonDict[PLVSocketIOChatRoom_SPEAK_userKey][PLVSocketIOChatRoomUserNickKey];
                    NSString *nickImg = chatroom.jsonDict[PLVSocketIOChatRoom_SPEAK_userKey][PLVSocketIOChatRoomUserPicKey];
                    if (![nickImg containsString:@"http:"]) {
                        nickImg = [@"https:" stringByAppendingString:nickImg];
                    }
                    [cell addSubview:[self bubbleViewForOtherWithNickname:nickname nickImg:nickImg content:content position:5]];
                }
            }
        }else if ([chatroomObject isKindOfClass:[NSString class]]) {
            NSString *content = (NSString *)chatroomObject;
            CGSize size = [self autoCalculateSystemTypeWithContent:content];
            
            UILabel *contentLB = [[UILabel alloc] init];
            contentLB.backgroundColor = [UIColor colorWithWhite:51/255.0 alpha:0.65];
            contentLB.textAlignment = NSTextAlignmentCenter;
            contentLB.font = [UIFont systemFontOfSize:SYSTEM_FONT_SIZE weight:UIFontWeightMedium];
            //NSAttributedString *attributedStr = [[NSAttributedString alloc] initWithData:[content dataUsingEncoding:NSUnicodeStringEncoding] options:@{ NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType } documentAttributes:nil error:nil];
            //[attributedStr addAttribute:NSFontAttributeName value:contentLB.font range:NSMakeRange(0, attributedStr.length)];
            //contentLB.attributedText = attributedStr; // 聊天室内容和公告内容转义
            contentLB.text = content;
            contentLB.textColor = [UIColor whiteColor];
            contentLB.layer.cornerRadius = 4.0;
            contentLB.layer.masksToBounds = YES;
            contentLB.numberOfLines = 0;
            contentLB.frame = CGRectMake(0, 0, size.width+20, size.height+10);
            contentLB.center = cell.contentView.center;
            [cell addSubview:contentLB];
        }
    }
    return cell;
}

#pragma mark - <UITableViewDelegate>

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.isPrivateChatMode) {
        PLVSocketChatRoomObject *chatObject = self.privateChatObjects[indexPath.row];
        NSString *content = chatObject.jsonDict[PLVSocketIOChatRoom_S_QUESTION_content];
        if (chatObject.eventType == PLVSocketChatRoomEventType_S_QUESTION) {
            return [self autoCalculateSpeakTypeSizeWithContent:content].height + 25;
        }else {
            return [self autoCalculateSpeakTypeSizeWithContent:content].height + 50;
        }
    }else {
        id chatroomObject = self.chatroomObjects[indexPath.row];
        if ([chatroomObject isKindOfClass:[PLVSocketChatRoomObject class]]) {
            PLVSocketChatRoomObject *chatroom = (PLVSocketChatRoomObject *)chatroomObject;
            if (chatroom.eventType == PLVSocketChatRoomEventType_SPEAK) {
                NSString *content = [chatroom.jsonDict[PLVSocketIOChatRoom_SPEAK_values] firstObject];
                if (chatroom.isLocalMessage) {
                    return [self autoCalculateSpeakTypeSizeWithContent:content].height + 25;
                }else {
                    return [self autoCalculateSpeakTypeSizeWithContent:content].height + 50;
                }
            }
        }else if ([chatroomObject isKindOfClass:[NSString class]]) {
            return [self autoCalculateSystemTypeWithContent:(NSString *)chatroomObject].height + 20;
        }
        return 40.0;
    }
}

#pragma mark - <UIScrollViewDelegate>
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.privateChatMode) return;
    CGFloat height = scrollView.frame.size.height;
    CGFloat contentOffsetY = scrollView.contentOffset.y;
    CGFloat bottomOffset = scrollView.contentSize.height - contentOffsetY;
    //NSLog(@"bottomOffset:%lf,%lf",bottomOffset,height);
    if (bottomOffset < height+1) { // tolerance
        _isCellInBottom = YES;
        self.showLatestMessageBtn.hidden = YES;
    }else {
        _isCellInBottom = NO;
    }
}

#pragma mark - <BCKeyBoardDelegate>

- (void)didSendText:(NSString *)text {
    if (!text || !text.length) {
        return;
    }
    //NSLog(@"send text:%@",text);
    if (!self.isPrivateChatMode) {
        if (_lastSpeakTime) {   // 发言时间间隔
            NSDate *currentTime = [NSDate date];
            NSTimeInterval intervalTime = currentTime.timeIntervalSinceReferenceDate -_lastSpeakTime.timeIntervalSinceReferenceDate;
            if (intervalTime <= 3) {
                [self.chatroomObjects addObject:@"您的发言过快，请稍后再试"];
                [self.tableView reloadData];
                return;
            }
            _lastSpeakTime = currentTime;
        }else {
            _lastSpeakTime = [NSDate date];
        }
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(emitChatroomObject:withMessage:)]) {
        PLVLiveManager *liveManager = [PLVLiveManager sharedLiveManager];
        if (self.isPrivateChatMode) {
            PLVSocketChatRoomObject *sQuestion = [PLVSocketChatRoomObject chatRoomObjectForStudentQuestionEventTypeWithLoginObject:liveManager.login content:text];
            [liveManager.privateChatObjects addObject:sQuestion];
            [self.delegate emitChatroomObject:sQuestion withMessage:nil];
        }else {
            PLVSocketChatRoomObject *mySpeak = [PLVSocketChatRoomObject chatRoomObjectForSpeakEventTypeWithRoomId:liveManager.login.roomId content:text];
            [liveManager.chatroomObjects addObject:mySpeak];
            [self.delegate emitChatroomObject:mySpeak withMessage:text];
        }
        _isSelfSpeak = YES;
        [self updateChatroom];
    }
}

- (void)returnHeight:(CGFloat)height {
    //NSLog(@"keyboard height:%f",height);
    if ([UIApplication sharedApplication].statusBarOrientation != UIInterfaceOrientationPortrait ) {
        return;
    }
    CGRect frame = self.view.frame;
    frame.size.height -= height;
    // 多个对象时会收到多次返回
    if (self.privateChatMode) {
        [self.tableView setFrame:frame];
    }else {
        [self.tableView setFrame:frame];
    }
}

#pragma mark - Private
/// 自己发言样式
- (UIView *)bubbleViewForSelfWithContent:(NSString *)content position:(int)position {
    UIView *returnView = [[UIView alloc] initWithFrame:CGRectZero];
    returnView.backgroundColor = [UIColor clearColor];
    if (!content || !content.length) {
        return returnView;
    }
    
    // 计算生成属性字符串及计算文字大小
    NSMutableAttributedString *attributedString = [[PLVEmojiModelManager sharedManager] convertTextEmotionToAttachment:content font:[UIFont systemFontOfSize:SPEAK_FONT_SIZE]];
    CGSize fontSize = [self autoCalculateWidth:SPEAK_MAX_WIDTH orHeight:MAXFLOAT attributedContent:attributedString];
    CGSize bubbleSize = CGSizeMake(fontSize.width + 30, fontSize.height + 15);
    
    returnView.frame = CGRectMake(CGRectGetWidth(self.view.bounds)-position-bubbleSize.width, 0, bubbleSize.width, bubbleSize.height);
    
    // 聊天背景
    UIImage *bubble = [UIImage imageNamed:@"PLVLivePlayerSkin.bundle/plv_chatfrom_mine"];
    UIImageView *bubbleImageView = [[UIImageView alloc] initWithImage:[bubble stretchableImageWithLeftCapWidth:floorf(bubble.size.width/2) topCapHeight:floorf(bubble.size.height/2)]];
    bubbleImageView.frame = CGRectMake(0, 0, bubbleSize.width, bubbleSize.height);
    
    // 聊天内容
    UILabel *bubbleText = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, fontSize.width, fontSize.height)];
    bubbleText.backgroundColor = [UIColor clearColor];
    bubbleText.numberOfLines = 0;
    bubbleText.lineBreakMode = NSLineBreakByWordWrapping;
    bubbleText.attributedText =  attributedString;
    [bubbleImageView addSubview:bubbleText];
    
    [returnView addSubview:bubbleImageView];
    return returnView;
}

/// 别人发言样式
- (UIView *)bubbleViewForOtherWithNickname:(NSString *)nickname nickImg:(NSString *)nickImg content:(NSString *)content position:(int)position {
    UIView *returnView = [[UIView alloc] initWithFrame:CGRectZero];
    returnView.backgroundColor = [UIColor clearColor];
    if (!content || !content.length) {
        return returnView;
    }
    
    // 计算生成属性字符串及计算文字大小
    NSMutableAttributedString *attributedString = [[PLVEmojiModelManager sharedManager] convertTextEmotionToAttachment:content font:[UIFont systemFontOfSize:SPEAK_FONT_SIZE]];
    CGSize fontSize = [self autoCalculateWidth:SPEAK_MAX_WIDTH orHeight:MAXFLOAT attributedContent:attributedString];
    CGSize bubbleSize = CGSizeMake(fontSize.width + 30, fontSize.height + 15);
    
    returnView.frame = CGRectMake(position, 0, bubbleSize.width, bubbleSize.height + 20);
    
    // 用户头像
    UIImageView *avatarView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 35, 35)];
    avatarView.layer.cornerRadius = 35/2.0;
    avatarView.layer.masksToBounds = YES;
    [avatarView sd_setImageWithURL:[NSURL URLWithString:nickImg] placeholderImage:[UIImage imageNamed:@"plv_default_user"]];
    
    // 昵称
    UILabel *nicknameLB = [[UILabel alloc] initWithFrame:CGRectMake(40, 0, CGRectGetWidth(returnView.bounds), 20)];
    if (bubbleSize.width < 80) {
        nicknameLB.frame = CGRectMake(40, 0, 80, 20);
    }
    nicknameLB.text = nickname;
    nicknameLB.textColor = [UIColor colorWithWhite:85/255.0 alpha:1.0];
    nicknameLB.font = [UIFont boldSystemFontOfSize:12.0];
    nicknameLB.textAlignment = NSTextAlignmentLeft;
    
    // 聊天背景
    UIImage *bubble = [UIImage imageNamed:@"PLVLivePlayerSkin.bundle/plv_chatfrom_other"];
    UIImageView *bubbleImageView = [[UIImageView alloc] initWithImage:[bubble stretchableImageWithLeftCapWidth:floorf(bubble.size.width/2) topCapHeight:floorf(bubble.size.height*2/3)]];
    bubbleImageView.frame = CGRectMake(30, 25, bubbleSize.width, bubbleSize.height);
    
    // 聊天内容
    UILabel *bubbleText = [[UILabel alloc] initWithFrame:CGRectMake(20, 5, fontSize.width, fontSize.height)];
    bubbleText.backgroundColor = [UIColor clearColor];
    bubbleText.numberOfLines = 0;
    bubbleText.lineBreakMode = NSLineBreakByWordWrapping;
    bubbleText.attributedText = attributedString;
    [bubbleImageView addSubview:bubbleText];
    
    [returnView addSubview:avatarView];
    [returnView addSubview:nicknameLB];
    [returnView addSubview:bubbleImageView];
    return returnView;
}

/// 计算发言样式Size
- (CGSize)autoCalculateSpeakTypeSizeWithContent:(NSString *)content {
    if (!content || !content.length) {
        return CGSizeZero;
    }
    NSMutableAttributedString *attributedString = [[PLVEmojiModelManager sharedManager] convertTextEmotionToAttachment:content font:[UIFont systemFontOfSize:SPEAK_FONT_SIZE]];
    return [self autoCalculateWidth:SPEAK_MAX_WIDTH orHeight:MAXFLOAT attributedContent:attributedString];
}

/// 计算系统样式Size
- (CGSize)autoCalculateSystemTypeWithContent:(NSString *)content {
    if (!content || !content.length) {
        return CGSizeZero;
    }
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:content attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:SYSTEM_FONT_SIZE weight:UIFontWeightMedium]}];
    return [self autoCalculateWidth:SYSTEM_MAX_WIDTH orHeight:MAXFLOAT attributedContent:attributedString];
}

/// 计算属性字符串文本的宽或高
- (CGSize)autoCalculateWidth:(float)width orHeight:(float)height attributedContent:(NSAttributedString *)attributedContent {
    CGRect rect = [attributedContent boundingRectWithSize:CGSizeMake(width, height)
                                                  options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                                  context:nil];
    return rect.size;
}

- (void)scrollTableViewToBottom {
    if (self.privateChatMode) {
        NSIndexPath *lastIndex = [NSIndexPath indexPathForRow:self.privateChatObjects.count-1 inSection:0];
        [self.tableView scrollToRowAtIndexPath:lastIndex atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }else {
        self.showLatestMessageBtn.hidden = YES;
        NSIndexPath *lastIndex = [NSIndexPath indexPathForRow:self.chatroomObjects.count-1 inSection:0];
        [self.tableView scrollToRowAtIndexPath:lastIndex atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
}

@end
