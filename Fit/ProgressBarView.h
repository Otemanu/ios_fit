//
//  ProgressBarView.h
//  Fit
//
//  Created by Rich on 11/8/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RoundedRectView.h"

@interface ProgressBarView : UIView

@property (nonatomic, strong) UIView *barView;				// the progress bar
@property (nonatomic, strong) RoundedRectView *capView;		// circular end cap composed of a rounded rect with radius large enough to make a circle

@property float barPercentage;								// 0.0 to 100.0
@property float barThickness;
@property float endCapDiameter;

@property (nonatomic, strong) UIColor *progressBarColor;	// bar and end cap color

- (void) createOffscreenProgressBarForPercentage:(int)percentageInt;
- (void)showProgressBarWithAnimation:(BOOL)animate;
- (void)hideProgressBar;

@end
