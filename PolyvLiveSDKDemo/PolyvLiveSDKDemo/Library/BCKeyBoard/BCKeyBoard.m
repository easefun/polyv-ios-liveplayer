//
//  BCKeyBoard.m
//  BCDemo
//
//  Created by baochao on 15/7/27.
//  Copyright (c) 2015年 baochao. All rights reserved.
//

#import "BCKeyBoard.h"
#import "BCTextView.h"

#define kBCTextViewHeight 36 /**< 底部textView的高度 */
#define kHorizontalPadding 8 /**< 横向间隔 */
#define kVerticalPadding 5 /**< 纵向间隔 */

@interface BCKeyBoard () <UITextViewDelegate,DXFaceDelegate,UIActionSheetDelegate,UINavigationControllerDelegate>

@property (nonatomic,strong)UIImageView *backgroundImageView;
@property (nonatomic,strong)UIButton *faceBtn;
@property (nonatomic,strong)UIButton *sendBtn;
@property (nonatomic,strong)BCTextView  *textView;
@property (nonatomic,strong)UIView *faceView;
@property (nonatomic,assign)CGFloat lastHeight;
@property (nonatomic,strong)UIView *activeView;

@end

@implementation BCKeyBoard {
    CGRect _originFrame;
    CGRect _lastKeyboardBeginFrame; // 键盘上次起始frame值
}

#pragma mark - Overwrite methods

- (instancetype)initWithFrame:(CGRect)frame
{
    if (frame.size.height < (kVerticalPadding * 2 + kBCTextViewHeight)) {
        frame.size.height = kVerticalPadding * 2 + kBCTextViewHeight;
    }
    self = [super initWithFrame:frame];
    if (self) {
        _originFrame = frame;
        [self createUI];
    }
    return self;
}

- (void)setFrame:(CGRect)frame
{
    if (frame.size.height < (kVerticalPadding * 2 + kBCTextViewHeight)) {
        frame.size.height = kVerticalPadding * 2 + kBCTextViewHeight;
    }
    [super setFrame:frame];
}

- (BCKeyBoardType)type {
    if (_faceBtn.selected) {
        return BCKeyBoardTypeFace;
    }else if (_textView.isFirstResponder) {
        return BCKeyBoardTypeSystem;
    }else {
        return BCKeyBoardTypeNone;
    }
}

#pragma mark - Initialize

- (void)createUI {
    _lastHeight = 30;
    // 注册键盘改变时调用
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    
    self.backgroundImageView = [[UIImageView alloc] initWithFrame:self.bounds];
    self.backgroundImageView.userInteractionEnabled = YES;
    self.backgroundImageView.image = [[UIImage imageNamed:@"messageToolbarBg"] stretchableImageWithLeftCapWidth:0.5 topCapHeight:10];
    
    // 表情按钮
    self.faceBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.faceBtn.frame = CGRectMake(kHorizontalPadding,kHorizontalPadding, 30, 30);
    [self.faceBtn addTarget:self action:@selector(willShowFaceView:) forControlEvents:UIControlEventTouchUpInside];
    [self.faceBtn setBackgroundImage:[UIImage imageNamed:@"chatBar_face"] forState:UIControlStateNormal];
    [self.faceBtn setBackgroundImage:[UIImage imageNamed:@"chatBar_keyboard"] forState:UIControlStateSelected];
    [self addSubview:self.faceBtn];
    
    // 文本
    self.textView = [[BCTextView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.faceBtn.frame)+kHorizontalPadding, kHorizontalPadding, self.bounds.size.width - 4*kHorizontalPadding - 30*2, 30)];
    self.textView.placeholderColor = self.placeholderColor;
    self.textView.returnKeyType = UIReturnKeySend;
    self.textView.scrollEnabled = NO;
    self.textView.backgroundColor = [UIColor clearColor];
    self.textView.layer.borderColor = [UIColor colorWithWhite:0.8f alpha:1.0f].CGColor;
    self.textView.layer.borderWidth = 0.65f;
    self.textView.layer.cornerRadius = 6.0f;
    self.textView.delegate = self;
    
    // 发送按钮
    self.sendBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.sendBtn setTitle:@"发送" forState:UIControlStateNormal];
    self.sendBtn.frame = CGRectMake(CGRectGetMaxX(self.textView.frame),kHorizontalPadding,50,30);
    [self.sendBtn addTarget:self action:@selector(sendButtonClick) forControlEvents:UIControlEventTouchUpInside];
    
    [self addSubview:self.backgroundImageView];
    [self.backgroundImageView addSubview:self.textView];
    [self.backgroundImageView addSubview:self.faceBtn];
    [self.backgroundImageView addSubview:self.sendBtn];
    
    if (!self.faceView) {
        self.faceView = [[DXFaceView alloc] initWithFrame:CGRectMake(0, (kHorizontalPadding * 2 + 30), self.frame.size.width, 200)];
        [(DXFaceView *)self.faceView setDelegate:self];
        self.faceView.backgroundColor = [UIColor whiteColor];
        self.faceView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    }
}

#pragma mark - Public interfaces

- (void)setPlaceholder:(NSString *)placeholder {
    self.textView.placeholder = placeholder;
}

- (void)setPlaceholderColor:(UIColor *)placeholderColor {
    self.textView.placeholderColor = placeholderColor;
}

- (BOOL)isFirstResponder {
    return _textView.isFirstResponder;
}

- (void)hideTheKeyBoard {
    if (self.textView.isFirstResponder) {
        [self.textView resignFirstResponder];
    }else {
        [self willShowBottomView:nil];
        self.faceBtn.selected = NO;
        if (self.delegate && [self.delegate respondsToSelector:@selector(returnHeight:)]) {
            [self.delegate returnHeight:CGRectGetHeight(_originFrame)];
        }
    }
}

#pragma mark - Interaction events

- (void)willShowFaceView:(UIButton *)btn {
    btn.selected = !btn.selected;
    if(btn.selected == YES) {
        [self.textView resignFirstResponder];
        [self willShowBottomView:self.faceView];
    }else {
        [self.textView becomeFirstResponder];
        [self willShowBottomView:nil];
    }
}

-(void)sendButtonClick {
    [self hideTheKeyBoard];
    if (self.delegate && [self.delegate respondsToSelector:@selector(didSendText:)]) {
        [self.delegate didSendText:self.textView.text];
        self.textView.text = @"";
        [self changeFrame:ceilf([self.textView sizeThatFits:self.textView.frame.size].height)];
    }
}

#pragma mark - Notifications

- (void)keyboardWillChangeFrame:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    //NSLog(@"userInfo:%@",userInfo);
    CGRect beginFrame = [userInfo[UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    CGRect endFrame = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve curve = [userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    
    /*if (CGRectGetMinY(beginFrame) == SCREEN_HEIGHT) {   // 键盘从底部弹出
     }else if (CGRectGetMinY(endFrame) == SCREEN_HEIGHT) { // 键盘收回至底部
     }else {} // 键盘高度改变(切换键盘改变/自动更正改变) */
    // 重复通知问题
    if (CGRectEqualToRect(beginFrame, _lastKeyboardBeginFrame)) {
        return;
    }else {
        _lastKeyboardBeginFrame = beginFrame;
    }
    
    CGFloat yOffset = beginFrame.origin.y - endFrame.origin.y;
    void(^animations)(void) = ^{
        if (CGRectGetMinY(endFrame) == SCREEN_HEIGHT) { // 键盘收回至底部
            if (!self.activeView) {
                self.frame = _originFrame;
                if (self.delegate && [self.delegate respondsToSelector:@selector(returnHeight:)]) {
                    [self.delegate returnHeight:CGRectGetHeight(_originFrame)];
                }
            }
        }else { // 键盘高度改变
            CGRect frame = self.frame;
            frame.origin.y = CGRectGetMinY(frame) - yOffset;
            //NSLog(@"self.frame:%@,frame:%@,endFrame:%@",NSStringFromCGRect(self.frame),NSStringFromCGRect(frame),NSStringFromCGRect(endFrame));
            self.frame = frame;
            if (self.delegate && [self.delegate respondsToSelector:@selector(returnHeight:)]) {
                [self.delegate returnHeight:CGRectGetHeight(endFrame)+CGRectGetHeight(_originFrame)];
            }
        }
        /* 1.0 版本（存在bug）
        if (CGRectGetMinY(beginFrame) > CGRectGetMinY(endFrame)) {  // 键盘弹出
            CGRect frame = self.frame;
            frame.origin.y = CGRectGetMinY(frame) - endFrame.size.height;
            self.frame = frame;
            if (self.delegate && [self.delegate respondsToSelector:@selector(returnHeight:)]) {
                [self.delegate returnHeight:CGRectGetHeight(endFrame)+CGRectGetHeight(_originFrame)];
            }
        }else {  // 键盘隐藏
            if (!self.activeView) {
                self.frame = _originFrame;
                if (self.delegate && [self.delegate respondsToSelector:@selector(returnHeight:)]) {
                    [self.delegate returnHeight:CGRectGetHeight(_originFrame)];
                }
            }
        }*/
    };
    //void(^completion)(BOOL) = ^(BOOL finished){
    //    NSLog(@"finished:%d",finished);
    //};
    [UIView animateWithDuration:duration delay:0.0f options:(curve << 16 | UIViewAnimationOptionBeginFromCurrentState) animations:animations completion:nil];
}

#pragma mark - Private methods
- (CGFloat)modifyFrame:(CGFloat)bottomHeight {
    CGFloat toHeight = CGRectGetHeight(_originFrame) - 30.0 + self.textView.frame.size.height + bottomHeight;
    CGRect toFrame = CGRectMake(self.frame.origin.x, (self.frame.origin.y + self.frame.size.height) - toHeight, self.frame.size.width, toHeight);
    self.frame = toFrame;
    self.backgroundImageView.frame = self.bounds;
    return toHeight;
}

- (void)changeFrame:(CGFloat)height {
    if (height == _lastHeight) {
        return;
    }else {
        [self.textView setContentOffset:CGPointMake(0.0f, (self.textView.contentSize.height - self.textView.frame.size.height) / 2) animated:YES];
        
        CGRect frame = self.textView.frame;
        frame.size.height = height;
        self.textView.frame = frame;
        
        CGFloat bottomHeight = 0.0;
        if (self.activeView) {
            bottomHeight = self.activeView.frame.size.height;
        }
        [self modifyFrame:bottomHeight];
        
        _lastHeight = height;
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(returnHeight:)]) {
            [self.delegate returnHeight:height];
        }
    }
}

- (void)willShowBottomHeight:(CGFloat)bottomHeight bottomView:(UIView *)bottomView {
    CGFloat toHeight = [self modifyFrame:bottomHeight];
    if (bottomView) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(returnHeight:)]) {
            [self.delegate returnHeight:toHeight];
        }
    }
}

- (void)willShowBottomView:(UIView *)bottomView {
    if (![self.activeView isEqual:bottomView]) {
        CGFloat bottomHeight = bottomView ? bottomView.frame.size.height : 0;
        [self willShowBottomHeight:bottomHeight bottomView:bottomView];
        
        if (bottomView) {
            CGRect rect = bottomView.frame;
            rect.origin.y = self.textView.frame.origin.y + self.textView.frame.size.height + kHorizontalPadding;
            bottomView.frame = rect;
            [self addSubview:bottomView];
        }
        if (self.activeView) {
            [self.activeView removeFromSuperview];
        }
        self.activeView = bottomView;
    }
}

- (CGFloat)getTextViewContentH:(UITextView *)textView {
    return ceilf([textView sizeThatFits:textView.frame.size].height);
}

#pragma mark - <UITextViewDelegate>

- (void)textViewDidBeginEditing:(UITextView *)textView {
    [self willShowBottomView:nil];
    self.faceBtn.selected = NO;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {         // 返回键符号
        if (self.delegate && [self.delegate respondsToSelector:@selector(didSendText:)]) {
            [self.delegate didSendText:textView.text];
            self.textView.text = @"";
            [self changeFrame:ceilf([textView sizeThatFits:textView.frame.size].height)];
        }
        [textView resignFirstResponder];
        return NO;
    }
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView {
    [self changeFrame:ceilf([textView sizeThatFits:textView.frame.size].height)];
}

#pragma mark - <DXFaceDelegate>

- (void)selectedEmoji:(PLVEmojiModel *)emojiModel {
    NSString *chatText = self.textView.text;
    self.textView.text = [NSString stringWithFormat:@"%@%@",chatText,emojiModel.text];
    [self textViewDidChange:self.textView];
}

- (void)deleteEvent {
    NSString *chatText = self.textView.text;
    if (chatText.length > 0) {
        self.textView.text = [chatText substringToIndex:chatText.length-1];
    }
    //if (chatText.length >= 4) {
    //    NSString *subStr = [chatText substringFromIndex:chatText.length-4];
    //    self.textView.text = [chatText substringToIndex:chatText.length-4];
    //    [self textViewDidChange:self.textView];
    //    return;
    //}
}

#pragma mark - Dealloc

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
}

@end
