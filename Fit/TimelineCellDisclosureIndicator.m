//
//  TimelineCellDisclosureIndicator.m
//  Fit
//
//  Created by Rich on 11/22/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//

#import "TimelineCellDisclosureIndicator.h"

// we use the absolute minimum number of graphic images in the UI.  we render as much as possible within reason, including disclosure indicators not in table cells.

@implementation TimelineCellDisclosureIndicator

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
	
    if (self)
	{
    }

    return self;
}

- (void)drawRect:(CGRect)rect
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetRGBStrokeColor(context, 0.2f, 0.2f, 0.2f, 1.0f);
	CGContextSetLineWidth(context, 1.0f);

	CGContextMoveToPoint(context, 10.0f, 13.0f);
	CGContextAddLineToPoint(context, 15.0f, 18.0f);
	CGContextAddLineToPoint(context, 10.0f, 23.0f);
	CGContextStrokePath(context);
}

@end
