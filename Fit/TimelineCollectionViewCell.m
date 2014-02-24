//
//  TimelineCollectionViewCell.m
//  Fit
//
//  Created by Rich on 11/20/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//

#import "TimelineCollectionViewCell.h"

@implementation TimelineCollectionViewCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    if (self)
	{
    }
    return self;
}

- (void)adjustImageToFitTimelineCell;
{
	self.timelineCellChapterImageView.clipsToBounds = YES;
	float adjustmentFactor = self.frame.size.width / self.timelineCellChapterImageView.image.size.width;
	CGRect timelineCellImageFrame = self.timelineCellChapterImageView.frame;
	timelineCellImageFrame.size.width = self.timelineCellChapterImageView.image.size.width * adjustmentFactor;
	timelineCellImageFrame.size.height = self.timelineCellChapterImageView.image.size.height * adjustmentFactor;
	self.timelineCellChapterImageView.frame = timelineCellImageFrame;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
