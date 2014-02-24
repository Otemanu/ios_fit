//
//  TimelineCollectionViewCell.h
//  Fit
//
//  Created by Rich on 11/20/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TimelineBranchArcRight.h"
#import "TimelineBranchArcLeft.h"
#import "TimelineUnreadChapterPointerLeft.h"
#import "TimelineUnreadChapterPointerRight.h"
#import "TimelineCellDisclosureIndicator.h"

@interface TimelineCollectionViewCell : UICollectionViewCell

@property (nonatomic) IBOutlet UIView *timelineCellQuizScoreCircleView;				// colored circle behind chapter quiz score (rounded by changing layer corner radius)
@property (nonatomic) IBOutlet UIView *timelineCellLineView;						// central vertical line with branches to each chapter
@property (nonatomic) IBOutlet UIView *timelineCellLineCapView;						// dot at top of first chapter vertical line
@property (nonatomic) IBOutlet UIView *timelineCellChapterInfoGroupingView;			// background for chapter image, chapter title, re-read label & image

@property (nonatomic) IBOutlet TimelineCellDisclosureIndicator *timelineCellNavigationIndicatorView;	// we render the "navigation indicator" instead of using a graphic

@property (nonatomic) IBOutlet TimelineBranchArcRight *timelineCellBranchRightView;	// timeline arc "branch" to chapter cells on the right column of the timeline view
@property (nonatomic) IBOutlet TimelineBranchArcLeft *timelineCellBranchLeftView;	// timeline arc "branch" to chapter cells on the left column of the timeline view

@property (nonatomic) IBOutlet TimelineUnreadChapterPointerRight *timelineUnreadPointerRightView;	// unread chapter triangular "pointer" to timeline for right column
@property (nonatomic) IBOutlet TimelineUnreadChapterPointerLeft *timelineUnreadPointerLeftView;		// unread chapter triangular "pointer" to timeline for left column

@property (nonatomic) IBOutlet UIView *timelineUnreadCircleView;					// circular unread chapter indicator in timeline

@property (nonatomic) IBOutlet UILabel *timelineCellQuizScoreLabel;					// chapter quiz score with colored quiz score circle as its background
@property (nonatomic) IBOutlet UILabel *timelineCellChapterTitleLabel;				// chapter title text below chapter title image
@property (nonatomic) IBOutlet UILabel *timelineCellNavigationTargetLabel;			// "Re-read" or "Continue" or "Start"

@property (nonatomic) IBOutlet UIImageView *timelineCellChapterImageView;			// thumbnail of the chapter's title image

- (void)adjustImageToFitTimelineCell;

@end
