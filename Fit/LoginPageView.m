//
//  LoginPageView.m
//  Fit
//
//  Created by Rich on 11/17/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//

#import "LoginPageView.h"

static float borderWidth = 30.0f;
static float titleHeight = 300.0f;
static float descriptionHeight = 250.0f;

@implementation LoginPageView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    if (self)
	{
        float titleYOffset;
        float descriptionYOffset;
        if (DEVICE_IS_IPAD) {
            titleYOffset = frame.size.height - 510.0f;
            descriptionYOffset = frame.size.height - 400.0f;
        }
        else
        {
            titleYOffset = frame.size.height - 410.0f;
            descriptionYOffset = frame.size.height - 300.0f;
        }
		
		self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(borderWidth, titleYOffset, frame.size.width - (borderWidth * 2.0f), titleHeight)];
		self.descriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(borderWidth, descriptionYOffset, frame.size.width - (borderWidth * 2.0f), descriptionHeight)];
		self.descriptionLabel.textAlignment = NSTextAlignmentCenter;
		
		self.titleLabel.numberOfLines = 0;									// 0 means no limit to the number of lines
		self.descriptionLabel.numberOfLines = 0;
		
		self.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:12.0f];
		self.descriptionLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:38.0f];
		
		self.titleLabel.textAlignment = NSTextAlignmentCenter;
		self.descriptionLabel.textAlignment = NSTextAlignmentCenter;
		
		self.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
		self.descriptionLabel.lineBreakMode = NSLineBreakByWordWrapping;
		
		self.titleLabel.textColor = [UIColor whiteColor];
		self.descriptionLabel.textColor = [UIColor whiteColor];

		[self addSubview:self.titleLabel];
		[self addSubview:self.descriptionLabel];
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
