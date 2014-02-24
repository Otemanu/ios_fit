//
//  TimelineUserProgressPointer.m
//  Fit
//
//  Created by Rich on 11/23/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//

#import "TimelineUserProgressPointer.h"

@implementation TimelineUserProgressPointer

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
	// red 113, green 134, blue 255 in storyboard.  if the color of the circle changes in storyboard, do the math and change the RGB colors to match.
	CGContextSetRGBStrokeColor(context, 0.443f, 0.529f, 1.0f, 1.0f);
	CGContextSetRGBFillColor(context, 0.443f, 0.529f, 1.0f, 1.0f);
	CGContextSetLineWidth(context, 2.0f);
	
	CGContextMoveToPoint(context, 0.0f, 0.0f);
	CGContextAddLineToPoint(context, rect.size.width / 2.0f, (rect.size.width / 2.0f) + 1.0f);
	CGContextAddLineToPoint(context, rect.size.width, 0.0f);
	CGContextClosePath(context);
	CGContextFillPath(context);
}

@end
