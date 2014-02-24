//
//  TimelineCurrentChapterViewCell.h
//  Fit
//
//  Created by Rich on 11/24/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TimelineCellDisclosureIndicator.h"

@interface TimelineCurrentChapterViewCell : UIView

@property (nonatomic) IBOutlet UIImageView *timelineCurrentChapterChapterImageView;

@property (nonatomic) IBOutlet UILabel *timelineCurrentChapterTitleLabel;
@property (nonatomic) IBOutlet UILabel *timelineCurrentChapterNavigationTargetLabel;

@property (nonatomic) IBOutlet TimelineCellDisclosureIndicator *timelineCurrentChapterNavigationIndicatorView;

@property (nonatomic) IBOutlet UIView *timelineCurrentChapterInfoGroupingView;

- (void)adjustImageToFitCurrentChapterCell;

@end
