//
//  LoginScrollView.h
//  Fit
//
//  Created by Rich on 10/31/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LoginPageView.h"
#import "SocialAccountView.h"
#import "FacebookLoginView.h"
#import "TwitterLoginView.h"
#import "CreateNewMobiAccountView.h"
#import "Scalars.h"

@interface LoginScrollView : UIScrollView <UIScrollViewDelegate>

@property UIScrollView *imageScrollView;						// separate scroll view for the "dot" images that scroll at a different speed

- (LoginScrollView *)initWithFrame:(CGRect)frame;
- (void)initImageViews;
- (void)initImageViewOffsets;

- (void)positionPageImagesForXOffset:(float)xOffset;
- (void)determineCurrentScrollDirection;

@end
