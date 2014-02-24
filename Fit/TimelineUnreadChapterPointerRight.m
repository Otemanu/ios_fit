//
//  TimelineUnreadChapterPointerRight.m
//  Fit
//
//  Created by Rich on 11/25/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//

#import "TimelineUnreadChapterPointerRight.h"

@implementation TimelineUnreadChapterPointerRight

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
	
    if (self)
	{
        // Initialization code
    }
	
    return self;
}

- (void)drawRect:(CGRect)rect
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetRGBFillColor(context, 1.0f, 1.0f, 1.0f, 0.5f);
	CGContextSetLineWidth(context, 2.0f);
	
	CGContextMoveToPoint(context, rect.size.width, 0.0f);
	CGContextAddLineToPoint(context, rect.size.width / 2.0f, rect.size.height / 2.0f);
	CGContextAddLineToPoint(context, rect.size.width, rect.size.height);
	CGContextClosePath(context);
	CGContextFillPath(context);
}

@end
