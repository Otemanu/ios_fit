//
//  RoundedRectView.m
//  Fit
//
//  Created by Rich on 11/08/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//

#import "RoundedRectView.h"
#import <QuartzCore/QuartzCore.h>

@implementation RoundedRectView

- (id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
	
    if (self)
	{
		self.layer.cornerRadius = 5.0f;
		self.clipsToBounds = YES;
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
