//
//  PLVRestrictView.m
//  PolyvLiveSDKDemo
//
//  Created by ftao on 31/07/2018.
//  Copyright © 2018 easefun. All rights reserved.
//

#import "PLVRestrictView.h"

@implementation PLVRestrictView {
    __weak IBOutlet UIImageView *warningImageView;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    warningImageView.image = [UIImage imageNamed:@"PLVLivePlayerSkin.bundle/plv_restrict_icon"];
}

+ (instancetype)restrictViewFromXIB {
    return [[NSBundle mainBundle] loadNibNamed:@"PLVRestrictView" owner:self options:nil].firstObject;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
