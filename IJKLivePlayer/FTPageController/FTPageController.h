//
//  FTPageController.h
//  FTPageController
//
//  Created by ftao on 04/01/2018.
//  Copyright © 2018 easefun. All rights reserved.
//

#import <UIKit/UIKit.h>

#define topBarHeight 44.0

@interface FTPageController : UIViewController

@property (nonatomic, strong, readonly) NSArray *titles;

@property (nonatomic, strong, readonly) NSArray *controllers;

@property (nonatomic, assign) BOOL circulation;

/**
 通过添子控制器及标题初始化页控制器

 @param titles 自控制器标题
 @param controllers 自控制器
 @return 页控制
 */
- (instancetype)initWithTitles:(NSArray<NSString *> *)titles controllers:(NSArray<UIViewController *> *)controllers;

//- (void)addTitle:(NSString *)title withController:(UIViewController *)controller;

@end
