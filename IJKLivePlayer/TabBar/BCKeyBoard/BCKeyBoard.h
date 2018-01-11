//
//  BCKeyBoard.h
//  BCDemo
//
//  Created by baochao on 15/7/27.
//  Copyright (c) 2015年 baochao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DXFaceView.h"

#define SCREEN_WIDTH ([[UIScreen mainScreen] bounds].size.width)
#define SCREEN_HEIGHT ([[UIScreen mainScreen] bounds].size.height)

@protocol BCKeyBoardDelegate <NSObject>

/**
 发送的文字
 */
- (void)didSendText:(NSString *)text;

/**
 keyBoard每次改变高度时调用
 */
- (void)returnHeight:(CGFloat)height;

@end

@interface BCKeyBoard : UIView

@property (nonatomic, weak) id<BCKeyBoardDelegate> delegate;
@property (nonatomic, strong) NSString *placeholder;          // 占位文字
@property (nonatomic, strong) UIColor *placeholderColor;      // 占位文字颜色

// 键盘的textView是否第一响应者
@property (nonatomic, assign, readonly) BOOL isFirstResponder;

// 隐藏键盘
- (void)hideTheKeyBoard;

@end
