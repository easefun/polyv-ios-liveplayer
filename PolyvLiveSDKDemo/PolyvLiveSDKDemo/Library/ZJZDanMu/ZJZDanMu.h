//
//  ZJZDanMu.h
//  DanMu
//
//  Created by 郑家柱 on 16/6/17.
//  Copyright © 2016年 Jiangsu Houxue Network Information Technology Limited By Share Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ZJZDanMu : UIView

/* 插入弹幕 */
- (void)insertDML:(NSString *)content;

/* 重置Frame */
- (void)resetFrame:(CGRect)frame;

@end
