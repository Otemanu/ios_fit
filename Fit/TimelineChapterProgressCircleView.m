//
//  TimelineChapterProgressCircleView.m
//  Fit
//
//  Created by Rich on 11/30/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//

#define   DEGREES_TO_RADIANS(degrees)  ((M_PI * degrees)/ 180.0f)

#import "TimelineChapterProgressCircleView.h"

@implementation TimelineChapterProgressCircleView

float circleDiameter = 0.0f;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    if (self)
	{
		self.backgroundColor = [UIColor clearColor];
		self.layer.borderColor = [[UIColor clearColor] CGColor];
		self.completionFraction = 0.0f;
    }

    return self;
}

- (void)drawRect:(CGRect)rect
{
	circleDiameter = self.frame.size.width - 6.0f;		// adjust the diameter of the circle as needed around the image layer's circular border
	
	UIGraphicsBeginImageContext(self.bounds.size);
	
	CAShapeLayer *circleLayer = nil;

	for (CALayer *subLayer in self.layer.sublayers)
	{
		if ([subLayer isMemberOfClass:[CAShapeLayer class]])
		{
			circleLayer = (CAShapeLayer *)subLayer;
			break;
		}
	}

	if (circleLayer == nil)
	{
		circleLayer = [CAShapeLayer layer];
		[circleLayer setBounds:CGRectMake(0.0f, ( - circleDiameter), circleDiameter, circleDiameter)];
		[circleLayer setPosition:CGPointMake((circleDiameter / 2.0f) + 3.0f, (circleDiameter / 2.0f) + 3.0f)];		// align the circle's coordinates to the view coordinates
		[circleLayer setFillColor:[[UIColor clearColor] CGColor]];
		[circleLayer setLineWidth:4.0f];
		[self.layer addSublayer:circleLayer];
	}

	UIBezierPath *path = [self createArcPath];
	CGAffineTransform rot = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(-90.0f));							// rotate -90 degrees because "0" defaults to 90 degrees clockwise from top dead center
	[path applyTransform:rot];
	[circleLayer setPath:[path CGPath]];
	[circleLayer setStrokeColor:[[UIColor colorWithRed:0.443f green:0.529f blue:1.0f alpha:1.0f] CGColor]];		// color must match the color of the progress pointer, which is a separate view object
	UIGraphicsEndImageContext();
}

- (UIBezierPath *)createArcPath
{
	float completionDegrees = self.completionFraction * 360.0f;
	UIBezierPath *aPath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(circleDiameter / 2.0f, circleDiameter / 2.0f)
														 radius:(circleDiameter / 2.0f)
													 startAngle:DEGREES_TO_RADIANS(0.0f)
													   endAngle:DEGREES_TO_RADIANS(completionDegrees)
													  clockwise:YES];
	return aPath;
}

@end
