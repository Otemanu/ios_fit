//
//  ReadWebView.m
//  Fit
//
//  Created by Rich on 12/9/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//

#import "ReadWebView.h"

@implementation ReadWebView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    if (self)
	{
        [self setBackgroundColor:[UIColor whiteColor]];
        [self setOpaque:NO];
        [self.scrollView setBounces:NO];
        [self.scrollView setDirectionalLockEnabled:YES];
        self.scrollView.layer.opacity = 0.0f;
        self.scrollView.layer.opacity = 1.0f;

        for (UIView *subview in [self.scrollView subviews])
            if ([subview isKindOfClass:[UIImageView class]])
                subview.hidden = YES;
        self.scrollView.delegate = self;
    }

    return self;
}

// forward scrolling to superview and to our own delegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [super scrollViewDidScroll:scrollView];
	
    if ([self.ReadWebViewScrollDelegate respondsToSelector:@selector(scrollViewDidScroll:)])
		[self.ReadWebViewScrollDelegate scrollViewDidScroll:scrollView];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)aScrollView
{
    [super scrollViewDidEndDecelerating:aScrollView];

	
    if ([self.ReadWebViewScrollDelegate respondsToSelector:@selector(scrollViewDidEndDecelerating:)])
		[self.ReadWebViewScrollDelegate scrollViewDidEndDecelerating:aScrollView];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)aScrollView
{
    if ([self.ReadWebViewScrollDelegate respondsToSelector:@selector(scrollViewDidEndScrollingAnimation:)])
		[self.ReadWebViewScrollDelegate scrollViewDidEndScrollingAnimation:aScrollView];
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
