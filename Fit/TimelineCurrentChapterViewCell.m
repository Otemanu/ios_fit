//
//  TimelineCurrentChapterViewCell.m
//  Fit
//
//  Created by Rich on 11/24/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//

#import "TimelineCurrentChapterViewCell.h"

@implementation TimelineCurrentChapterViewCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)adjustImageToFitCurrentChapterCell;
{
	self.timelineCurrentChapterChapterImageView.clipsToBounds = YES;
	float adjustmentFactor = self.frame.size.width / self.timelineCurrentChapterChapterImageView.image.size.width;
	CGRect currentChapterImageFrame = CGRectMake(0.0f, 0.0f, self.timelineCurrentChapterChapterImageView.image.size.width * adjustmentFactor, self.timelineCurrentChapterChapterImageView.image.size.height * adjustmentFactor);
	self.timelineCurrentChapterChapterImageView.frame = currentChapterImageFrame;
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
