//
//  TimelineBranchArc.m
//  Fit
//
//  Created by Rich on 11/21/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//

#import "TimelineBranchArcRight.h"

@implementation TimelineBranchArcRight

@synthesize isRightSide;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    if (self)
	{
		self.frame = frame;
    }

    return self;
}

- (void)drawRect:(CGRect)rect
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetRGBStrokeColor(context, 1.0f, 1.0f, 1.0f, 1.0f);
	CGContextSetLineWidth(context, 1.0f);

	// we draw a circular ellipse with radius equal to the width of the frame.  this gives a "quarter arc".
	// and we move the circle down 1 pixel to prevent clipping the top by 1/2 pixel.
	CGContextAddEllipseInRect(context, CGRectMake(0.0f, 1.0f, rect.size.width * 2.0f, rect.size.height * 2.0f));
	CGContextStrokePath(context);
}

@end
