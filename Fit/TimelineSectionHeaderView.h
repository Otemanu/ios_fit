//
//  TimelineSectionHeaderView.h
//  Fit
//
//  Created by Richard Motofuji on 11/28/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TimelineCellDisclosureIndicator.h"

@interface TimelineSectionHeaderView : UICollectionViewCell

@property (weak) IBOutlet UILabel *sectionHeaderTitleLabel;
@property (weak) IBOutlet UIImageView *sectionHeaderImageView;
@property (weak) IBOutlet UIView *sectionHeaderChapterGroupView;
@property (weak) IBOutlet UIView *sectionHeaderChapterBackgroundView;
@property (weak) IBOutlet UIImageView *sectionHeaderChapterImageView;
@property (weak) IBOutlet UILabel *sectionHeaderChapterTitleLabel;
@property (weak) IBOutlet UILabel *sectionHeaderChapterContinueLabel;
@property (weak) IBOutlet TimelineCellDisclosureIndicator *sectionHeaderChapterDisclosureView;

@end
