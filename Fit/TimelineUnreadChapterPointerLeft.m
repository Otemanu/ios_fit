//
//  TimelineUnreadChapterPointer.m
//  Fit
//
//  Created by Rich on 11/25/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//

#import "TimelineUnreadChapterPointerLeft.h"

@implementation TimelineUnreadChapterPointerLeft

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

	CGContextMoveToPoint(context, 0.0f, 0.0f);
	CGContextAddLineToPoint(context, rect.size.width / 2.0f, rect.size.width / 2.0f);
	CGContextAddLineToPoint(context, 0.0f, rect.size.height);
	CGContextClosePath(context);
	CGContextFillPath(context);
}

@end
