//
//  TimelineSectionFooterView.h
//  Fit
//
//  Created by Richard Motofuji on 11/28/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TimelineUserProgressPointer.h"
#import "TimelineChapterProgressCircleView.h"

@interface TimelineSectionFooterView : UICollectionViewCell

@property (weak) IBOutlet TimelineChapterProgressCircleView *sectionFooterProgressView;
@property (weak) IBOutlet TimelineUserProgressPointer *sectionFooterProgressPointer;
@property (weak) IBOutlet UIImageView *sectionFooterUserImageView;
@property (weak) IBOutlet UIButton *sectionFooterUserButton;
@property (weak) IBOutlet UILabel *sectionFooterUserNameLabel;
@property (weak) IBOutlet UILabel *sectionFooterProgressPercentageLabel;
@property (weak) IBOutlet UIView *sectionFooterTimelineContinuationView;

@end
