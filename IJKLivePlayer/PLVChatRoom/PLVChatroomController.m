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

#define CHAT_FONT_SIZE 14.0       // 聊天发言文字大小
#define ChAT_MAX_WIDTH 200.0f     // 聊天发言文字最大长度
#define CHAT_FONT_SIZE2 12.0      // 聊天室其他消息文字大小
#define ChAT_MAX_WIDTH2 250.0f    // 聊天室其他消息最大长度

#define TOOL_BAR_HEIGHT 46.0      // 工具栏高度

static NSString * const reuseChatCellIdentifier = @"ChatCell";

@interface PLVChatroomController () <UITableViewDelegate,UITableViewDataSource,BCKeyBoardDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) BCKeyBoard *bcKeyBoard;

@property (nonatomic, strong) NSMutableArray *chatroomObjects;
@property (nonatomic, strong) NSMutableArray<PLVSocketChatRoomObject *> *privateChatObjects;

@end

@implementation PLVChatroomController

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

    self.chatroomObjects = [PLVLiveManager sharedLiveManager].chatroomObjects;
    self.privateChatObjects = [PLVLiveManager sharedLiveManager].privateChatObjects;
}

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
        self.chatroomObjects = [PLVLiveManager sharedLiveManager].chatroomObjects;
    }
    [self.tableView reloadData];
}

#pragma mark - <UITableViewDelegate>
/// 返回单元格高度
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.isPrivateChatMode) {
        PLVSocketChatRoomObject *chatObject = self.privateChatObjects[indexPath.row];
        NSString *content = chatObject.jsonDict[PLVSocketIOChatRoom_S_QUESTION_content];
        CGSize size = [self autoCalculateSizeWithString:content];
        if (chatObject.eventType == PLVSocketChatRoomEventType_S_QUESTION) {
            return size.height + 30;
        }else {
            return size.height + 50;
        }
    }else {
        id chatroomObject = self.chatroomObjects[indexPath.row];
        if ([chatroomObject isKindOfClass:[PLVSocketChatRoomObject class]]) {
            PLVSocketChatRoomObject *chatroom = (PLVSocketChatRoomObject *)chatroomObject;
            if (chatroom.eventType == PLVSocketChatRoomEventType_SPEAK) {
                NSString *speakContent = [chatroom.jsonDict[PLVSocketIOChatRoom_SPEAK_values] firstObject];
                CGSize size = [self autoCalculateSizeWithString:speakContent];
                if (chatroom.isLocalMessage) {
                    return size.height + 30;
                }else {
                    return size.height + 50;
                }
            }
        }
        return 40.0;
    }
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
        NSMutableAttributedString *attributeString = [[NSMutableAttributedString alloc] initWithString:content attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:CHAT_FONT_SIZE]}];
        switch (chatObject.eventType) {
            case PLVSocketChatRoomEventType_S_QUESTION:
                if (chatObject.isLocalMessage) {            // 自己提交的发言信息
                    [cell addSubview:[self bubbleViewForSelfWithContent:attributeString position:5]];
                } break;
            case PLVSocketChatRoomEventType_T_ANSWER: {
                NSString *nickname = chatObject.jsonDict[PLVSocketIOChatRoomUserKey][PLVSocketIOChatRoomUserNickKey];
                NSString *nickImg = chatObject.jsonDict[PLVSocketIOChatRoomUserKey][PLVSocketIOChatRoomUserPicKey];
                if (![nickImg containsString:@"http:"]) {
                    nickImg = [@"https:" stringByAppendingString:nickImg];
                }
                [cell addSubview:[self bubbleViewForOtherWithNickname:nickname nickImg:nickImg content:attributeString position:5]];
            } break;
            default: break;
        }
    }else {
        id chatroomObject = self.chatroomObjects[indexPath.row];
        if ([chatroomObject isKindOfClass:[NSString class]]) {
            NSString *content = (NSString *)chatroomObject;
            UIFont *font = [UIFont systemFontOfSize:CHAT_FONT_SIZE2 weight:UIFontWeightMedium];
            
            UILabel *contentLB = [[UILabel alloc] init];
            contentLB.backgroundColor = [UIColor darkGrayColor];
            contentLB.text = content;
            contentLB.textAlignment = NSTextAlignmentCenter;
            contentLB.font = font;
            contentLB.textColor = [UIColor whiteColor];
            contentLB.layer.cornerRadius = 4.0;
            contentLB.layer.masksToBounds = YES;
            
            NSMutableAttributedString *attributeString = [[NSMutableAttributedString alloc] initWithString:content attributes:@{NSFontAttributeName:font}];
            CGSize size = [self autoCalculateWidth:ChAT_MAX_WIDTH2 orHeight:MAXFLOAT attributedContent:attributeString];
            contentLB.frame = CGRectMake(0, 0, size.width+20, size.height+10);
            contentLB.center = cell.contentView.center;
            
            [cell addSubview:contentLB];
        }else if ([chatroomObject isKindOfClass:[PLVSocketChatRoomObject class]]) {
            PLVSocketChatRoomObject *chatroom = (PLVSocketChatRoomObject *)chatroomObject;
            if (chatroom.eventType == PLVSocketChatRoomEventType_SPEAK) {
                NSString *speakContent = [chatroom.jsonDict[PLVSocketIOChatRoom_SPEAK_values] firstObject];
                NSMutableAttributedString *attributeString = [[NSMutableAttributedString alloc] initWithString:speakContent attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:CHAT_FONT_SIZE]}];
                if (chatroom.isLocalMessage) {
                    [cell addSubview:[self bubbleViewForSelfWithContent:attributeString position:5]];
                }else {
                    NSString *nickname = chatroom.jsonDict[PLVSocketIOChatRoom_SPEAK_userKey][PLVSocketIOChatRoomUserNickKey];
                    NSString *nickImg = chatroom.jsonDict[PLVSocketIOChatRoom_SPEAK_userKey][PLVSocketIOChatRoomUserPicKey];
                    if (![nickImg containsString:@"http:"]) {
                        nickImg = [@"https:" stringByAppendingString:nickImg];
                    }
                    [cell addSubview:[self bubbleViewForOtherWithNickname:nickname nickImg:nickImg content:attributeString position:5]];
                }
            }
        }else {
        }
    }
    return cell;
}

#pragma mark - <BCKeyBoardDelegate>

- (void)didSendText:(NSString *)text {
    if (!text || !text.length) {
        return;
    }
    //NSLog(@"send text:%@",text);
    if (self.delegate && [self.delegate respondsToSelector:@selector(sendMessage:privateChatMode:)]) {
        [self.delegate sendMessage:text privateChatMode:self.isPrivateChatMode];
    }
}

- (void)returnHeight:(CGFloat)height {
    //NSLog(@"keyboard height:%f",height);
    CGRect frame = self.view.frame;
    frame.size.height -= height;
    [self.tableView setFrame:frame];
}

#pragma mark - Private methods

- (UIView *)bubbleViewForOtherWithNickname:(NSString *)nickname nickImg:(NSString *)nickImg content:(NSAttributedString *)attributedText position:(int)position {
    // 计算文字大小
    CGSize fontSize = [self autoCalculateWidth:ChAT_MAX_WIDTH orHeight:MAXFLOAT attributedContent:attributedText];
    CGSize bubbleSize = CGSizeMake(fontSize.width + 10, fontSize.height + 10);
    
    // build single chat bubble cell with given text
    UIView *returnView = [[UIView alloc] initWithFrame:CGRectZero];
    returnView.backgroundColor = [UIColor clearColor];
    returnView.frame = CGRectMake(position, 0, bubbleSize.width, bubbleSize.height + 20);
    
    // 昵称
    UILabel *nicknameLB = [[UILabel alloc] initWithFrame:CGRectMake(40, 0, CGRectGetWidth(returnView.bounds), 20)];
    if (bubbleSize.width < 80) {
        nicknameLB.frame = CGRectMake(40, 0, 80, 20);
    }
    nicknameLB.text = nickname;
    nicknameLB.textColor = [UIColor colorWithWhite:85/255.0 alpha:1.0];
    nicknameLB.font = [UIFont boldSystemFontOfSize:12.0];
    nicknameLB.textAlignment = NSTextAlignmentLeft;
    
    NSError *error; // asynchronous
    NSData *imgData = [NSData dataWithContentsOfURL:[NSURL URLWithString:nickImg] options:NSDataReadingMappedIfSafe error:&error];
    // 用户头像
    UIImageView *avatarView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 35, 35)];
    if (error) {
        avatarView.image = [UIImage imageNamed:@"PLVLivePlayerSkin.bundle/plv_missing_face"];
    }else {
        avatarView.image = [UIImage imageWithData:imgData];
    }
    
    // 聊天文字背景
    UIImage *bubble = [UIImage imageNamed:@"PLVLivePlayerSkin.bundle/plv_chatfrom_other"];
    UIImageView *bubbleImageView = [[UIImageView alloc] initWithImage:[bubble stretchableImageWithLeftCapWidth:floorf(bubble.size.width/2) topCapHeight:floorf(bubble.size.height*2/3)]];
    bubbleImageView.frame = CGRectMake(30, 25, bubbleSize.width+20, bubbleSize.height+5);
    
    // 文本
    UILabel *bubbleText = [[UILabel alloc] initWithFrame:CGRectMake(50, 30, fontSize.width, fontSize.height)];
    bubbleText.backgroundColor = [UIColor clearColor];
    bubbleText.font = [UIFont systemFontOfSize:CHAT_FONT_SIZE];
    bubbleText.numberOfLines = 0;
    bubbleText.lineBreakMode = NSLineBreakByWordWrapping;
    bubbleText.attributedText =  attributedText;
    
    [returnView addSubview:avatarView];
    [returnView addSubview:nicknameLB];
    [returnView addSubview:bubbleImageView];
    [returnView addSubview:bubbleText];
    return returnView;
}

- (UIView *)bubbleViewForSelfWithContent:(NSAttributedString *)attributedText position:(int)position {
    // 计算文字大小
    CGSize fontSize = [self autoCalculateWidth:ChAT_MAX_WIDTH orHeight:MAXFLOAT attributedContent:attributedText];
    CGSize bubbleSize = CGSizeMake(fontSize.width + 30, fontSize.height + 10);
    
    // build single chat bubble cell with given text
    UIView *returnView = [[UIView alloc] initWithFrame:CGRectZero];
    returnView.backgroundColor = [UIColor clearColor];
    returnView.frame = CGRectMake(CGRectGetWidth(self.view.bounds)-position-bubbleSize.width, 0, bubbleSize.width, bubbleSize.height);
    
    // 聊天文字背景
    UIImage *bubble = [UIImage imageNamed:@"PLVLivePlayerSkin.bundle/plv_chatfrom_mine"];
    UIImageView *bubbleImageView = [[UIImageView alloc] initWithImage:[bubble stretchableImageWithLeftCapWidth:floorf(bubble.size.width/2) topCapHeight:floorf(bubble.size.height/2)]];
    bubbleImageView.frame = CGRectMake(0, 0, bubbleSize.width, bubbleSize.height+5);
    
    // 文本
    UILabel *bubbleText = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, fontSize.width, fontSize.height)];
    bubbleText.backgroundColor = [UIColor clearColor];
    bubbleText.font = [UIFont systemFontOfSize:CHAT_FONT_SIZE];
    bubbleText.numberOfLines = 0;
    bubbleText.lineBreakMode = NSLineBreakByWordWrapping;
    bubbleText.attributedText =  attributedText;
    
    [returnView addSubview:bubbleImageView];
    [returnView addSubview:bubbleText];
    return returnView;
}

- (CGSize)autoCalculateSizeWithString:(NSString *)string {
    NSMutableAttributedString *attributeString = [[NSMutableAttributedString alloc] initWithString:string attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:CHAT_FONT_SIZE]}];
    return [self autoCalculateWidth:ChAT_MAX_WIDTH orHeight:MAXFLOAT attributedContent:attributeString];
}

/// 计算属性字符串文本的宽或高
- (CGSize)autoCalculateWidth:(float)width orHeight:(float)height attributedContent:(NSAttributedString *)attributedContent
{
    CGRect rect = [attributedContent boundingRectWithSize:CGSizeMake(width, height)
                                                  options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                                  context:nil];
    return rect.size;
}

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
