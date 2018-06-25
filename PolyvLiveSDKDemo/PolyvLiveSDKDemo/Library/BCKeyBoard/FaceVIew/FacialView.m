/************************************************************
  *  * EaseMob CONFIDENTIAL 
  * __________________ 
  * Copyright (C) 2013-2014 EaseMob Technologies. All rights reserved. 
  *  
  * NOTICE: All information contained herein is, and remains 
  * the property of EaseMob Technologies.
  * Dissemination of this information or reproduction of this material 
  * is strictly forbidden unless prior written permission is obtained
  * from EaseMob Technologies.
  */

#import "FacialView.h"
#import "Emoji.h"
#import "PLVEmojiModel.h"

@interface FacialView ()

@property (nonatomic, strong) UIScrollView *scrollView;

@property (nonatomic) NSBundle *emotionBundle;

@end

@implementation FacialView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        Emoji *emoji = [Emoji sharedEmoji];
        
        // 参数配置
        _faces = emoji.allEmojiModels;
        //_faces = [Emoji allImageEmoji];
        // 参数配置
        PLVEmojiModelManager *emojiManager = [PLVEmojiModelManager sharedManager];
        emojiManager.emotionDictionary = emoji.emotionDictionary;
    }
    return self;
}


//给faces设置位置
-(void)loadFacialView:(int)page size:(CGSize)size
{
	int maxRow = 5;
    int maxCol = 7;
    CGFloat itemWidth = self.frame.size.width / maxCol;
    CGFloat itemHeight = self.frame.size.height / maxRow;
    
    // 初始化bundle包
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Emotion" ofType:@"bundle"];
    self.emotionBundle = [NSBundle bundleWithPath:path];

    // 添加表情
    for (int index = 0, row = 0; index < [_faces count]; row++) {
        int page = row / maxRow;
        CGFloat addtionWidth = page * CGRectGetWidth(self.bounds);
        int decreaseRow = page * maxRow;
        for (int col = 0; col < maxCol; col++, index ++) {
            if (index < [_faces count]) {
                // 去除掉每页最后一行最后一列的显示
                if (row%maxRow==maxRow-1 && col==maxCol-1) {
                    break;
                }
                UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
                [self.scrollView addSubview:button];
                [button setBackgroundColor:[UIColor clearColor]];
                [button setFrame:CGRectMake(col * itemWidth + addtionWidth, (row-decreaseRow) * itemHeight, itemWidth, itemHeight)];
                button.showsTouchWhenHighlighted = YES;
                button.tag = index;
                [button addTarget:self action:@selector(selected:) forControlEvents:UIControlEventTouchUpInside];
                
                PLVEmojiModel *emojiModel = [_faces objectAtIndex:index];
                [button setImage:[self imageForEmotionPNGName:emojiModel.imagePNG] forState:UIControlStateNormal];
            
            } else {
                break;
            }
        }
    }
    
    // 添加删除键
    for (int i=0; i<3; ++i) {
        UIButton *deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.scrollView addSubview:deleteButton];
        [deleteButton setBackgroundColor:[UIColor clearColor]];
        [deleteButton setFrame:CGRectMake((maxCol - 1) * itemWidth + CGRectGetWidth(self.bounds)*i, (maxRow - 1) * itemHeight, itemWidth, itemHeight)];
        [deleteButton setImage:[UIImage imageNamed:@"faceDelete"] forState:UIControlStateNormal];
        //deleteButton.tag = 10000;
        [deleteButton addTarget:self action:@selector(deleteButtonClick) forControlEvents:UIControlEventTouchUpInside];
    }
}

#pragma mark - 重写

- (UIScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] init];
        [self addSubview:_scrollView];
        _scrollView.frame = self.bounds;
        _scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.bounds)*3, CGRectGetHeight(self.bounds));
        // 使用分页
        _scrollView.pagingEnabled = YES;
    }
    return _scrollView;
}


-(void)selected:(UIButton *)bt {
    // 添加逻辑判断代理是否实现这个方法
    if (_delegate) {
        [_delegate selectedFacialView:[_faces objectAtIndex:bt.tag]];
    }
}

- (void)deleteButtonClick {
    if (_delegate) {
        [_delegate deleteEmoji];
    }
}


#pragma mark - 自定义方法

- (UIImage *)imageForEmotionPNGName:(NSString *)pngName {
    return [UIImage imageNamed:pngName inBundle:self.emotionBundle
 compatibleWithTraitCollection:nil];
}

@end
