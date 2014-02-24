//
//  ProgressBarView.m
//  Fit
//
//  Created by Rich on 11/8/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//

#import "ProgressBarView.h"

@implementation ProgressBarView

#pragma mark - Animation

- (void) createOffscreenProgressBarForPercentage:(int)percentageInt
{
	self.barPercentage = (float)percentageInt;
	float progressLineLength = self.frame.size.width * self.barPercentage / 100.0f + 2.0f;
	CGRect barFrame = CGRectMake(0.0f, 0.0f, progressLineLength - (self.endCapDiameter / 2.0f) + 2.0f, self.barThickness);
	CGRect capFrame = CGRectMake(progressLineLength - (self.endCapDiameter / 2.0f),
								 barFrame.origin.y - ((self.endCapDiameter - self.barThickness) / 2.0f),
								 self.endCapDiameter,
								 self.endCapDiameter);
	
	CGRect barOffscreenFrame = barFrame;
	barOffscreenFrame.origin.x -= progressLineLength;
	self.barView.frame = barOffscreenFrame;
	
	self.barView.backgroundColor = self.progressBarColor;
	self.barView.layer.borderColor = [self.progressBarColor CGColor];
	self.barView.layer.opacity = 1.0;					// do not animate the progress bar's opacity: looks hideous with shadow
	
	CGRect capOffscreenFrame = capFrame;
	capOffscreenFrame.origin.x -= progressLineLength;
	self.capView.frame = capOffscreenFrame;
	
	self.capView.backgroundColor = self.progressBarColor;
	self.capView.layer.borderColor = [self.progressBarColor CGColor];
	self.capView.layer.borderWidth = 1.0f;
	self.capView.layer.opacity = 1.0;
}

- (void)showProgressBarWithAnimation:(BOOL)animate
{
	CGRect barFrame = self.barView.frame;				// should only be called when the progress bar is not visible (offscreen to left)
	CGRect capFrame = self.capView.frame;
	barFrame.origin.x += self.barView.frame.size.width;	// we have already calculated the bar width and moved it offscreen
	capFrame.origin.x += self.barView.frame.size.width;

	if (animate)
	{
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationDuration:0.75f];
	}

	self.barView.frame = barFrame;
	self.capView.frame = capFrame;
//	self.barView.layer.opacity = 1.0f;					// again, we don't animate progress bar/cap opacity
//	self.capView.layer.opacity = 1.0f;

	if (animate)
		[UIView commitAnimations];
}

- (void)hideProgressBar
{
	CGRect barFrame = self.barView.frame;				// should only be called when the progress bar is visible
	CGRect capFrame = self.capView.frame;
	barFrame.origin.x -= self.barView.frame.size.width;
	capFrame.origin.x -= self.barView.frame.size.width;
	
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.4f];
	self.barView.frame = barFrame;
	self.capView.frame = capFrame;
	self.barView.layer.opacity = 0.0f;
	self.capView.layer.opacity = 0.0f;
	[UIView commitAnimations];
}

#pragma mark - Initialization

- (id)initWithFrame:(CGRect)frame
{
	// caller should pass in a rect with full-screen width, correct y offset from top of screen, and a reasonable height (just bigger than the end cap)
    self = [super initWithFrame:frame];

    if (self)
	{
		self.barView = [[UIView  alloc] initWithFrame:CGRectZero];
		self.capView = [[RoundedRectView  alloc] initWithFrame:CGRectZero];
		[self addSubview:self.barView];
		[self addSubview:self.capView];

		// set defaults for progress bar and its line cap
        self.barPercentage = 0.0f;
		self.progressBarColor = [UIColor whiteColor];
		self.barThickness = 4.0f;
		self.endCapDiameter = 8.0f;
    }

    return self;
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
