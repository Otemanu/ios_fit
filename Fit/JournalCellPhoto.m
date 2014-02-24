//
//  JournalCellPhoto.m
//  Fit
//
//  Created by Richard Motofuji on 2/10/14.
//  Copyright (c) 2014 mobifusion. All rights reserved.
//

#import "JournalCellPhoto.h"

@implementation JournalCellPhoto

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
	
    if (self)
	{
		[self configureView];
    }

    return self;
}

- (void)configureView
{
	// only put a border on the "add photo" photo. this is how to do it for all photos.
//	self.layer.borderColor = [[UIColor lightGrayColor] CGColor];
//	self.layer.borderWidth = 1.0f;
	self.contentMode = (UIViewContentModeCenter | UIViewContentModeScaleAspectFill);
	self.clipsToBounds = YES;
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
