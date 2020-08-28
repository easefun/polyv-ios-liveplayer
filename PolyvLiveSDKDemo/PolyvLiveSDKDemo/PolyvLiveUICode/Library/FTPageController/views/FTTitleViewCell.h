//
//  FTTitleViewCell.h
//  FTPageController
//
//  Created by ftao on 04/01/2018.
//  Copyright © 2018 easefun. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FTTitleViewCell : UICollectionViewCell

@property (nonatomic, assign) BOOL clicked;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (weak, nonatomic) IBOutlet UIView *indicatorView;

@end
