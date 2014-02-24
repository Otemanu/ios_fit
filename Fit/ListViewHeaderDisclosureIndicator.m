//
//  ListViewHeaderDisclosureIndicator.m
//  Fit
//
//  Created by Richard Motofuji on 1/1/14.
//  Copyright (c) 2014 mobifusion. All rights reserved.
//

#import "ListViewHeaderDisclosureIndicator.h"

@implementation ListViewHeaderDisclosureIndicator

float indicatorWidth = 8.0f;			// change these to alter the size and proportions of the ">" indicator
float indicatorHeight = 16.0f;

float xOffset, yOffset;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    if (self)
	{
		xOffset = (self.frame.size.width / 2.0f) - (indicatorWidth / 2.0f);
		yOffset = (self.frame.size.height / 2.0f) - (indicatorHeight / 2.0f);
    }

    return self;
}

- (void)drawRect:(CGRect)rect
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetRGBStrokeColor(context, 0.0f, 0.0f, 0.0f, 1.0f);
	CGContextSetLineWidth(context, 2.0f);
	
	CGContextMoveToPoint(context, xOffset, yOffset);
	CGContextAddLineToPoint(context, xOffset + indicatorWidth, yOffset + (indicatorHeight / 2.0f));
	CGContextAddLineToPoint(context, xOffset, yOffset + indicatorHeight);
	CGContextStrokePath(context);
}

@end
