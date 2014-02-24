//
//  TimelineSectionFooterView.m
//  Fit
//
//  Created by Richard Motofuji on 11/28/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//

#import "TimelineSectionFooterView.h"

@implementation TimelineSectionFooterView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
 
	if (self)
	{
    }

    return self;
}

- (IBAction)navigateToSettingsView:(id)sender;
{
	[[NSNotificationCenter defaultCenter] postNotificationName:@"navigateToSettingsView" object:nil];
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
