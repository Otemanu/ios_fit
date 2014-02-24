//
//  TimelineViewController
//  Fit
//
//  Created by Rich on 10/31/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIImage+ImageEffects.h"
#import "TimelineCollectionViewCell.h"
#import "TimelineSectionHeaderView.h"
#import "TimelineSectionFooterView.h"
#import "TimelineCurrentChapterViewCell.h"
#import "TimelineBranchArcRight.h"
#import "TimelineUserProgressPointer.h"
#import "TimelineChapterProgressCircleView.h"
#import "Pages.h"
#import "PageInstance.h"
#import "PageSections.h"
#import "Scalars.h"
#import "CreateNewMobiAccountView.h"
#import "LoginScrollView.h"

@interface TimelineViewController : UICollectionViewController <UIScrollViewDelegate>

@property IBOutlet UIView *statusBarBackground;

- (void)navigateToSettingsView:(id)sender;

@end
