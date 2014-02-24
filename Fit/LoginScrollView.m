//
//  LoginScrollView.m
//  Fit
//
//  Created by Rich on 10/31/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//

#import "LoginScrollView.h"

// preliminary parallax scrolling of circular images in login scrollview

@implementation LoginScrollView

UIImageView *page0ImageView;									// the images above the text of the various login views embedded in the scroll view
UIImageView *page1ImageView;
UIImageView *page2ImageView;
UIImageView *page3ImageView;
UIImageView *page4ImageView;

FacebookLoginView *facebookLoginView;
TwitterLoginView *twitterLoginView;
CreateNewMobiAccountView *newMobiAccountView;

static float imageScrollScaleFactor = 0.5f;						// images move this fast relative to the main scroll view's motion (looks bad unless it's 0.5)
static float imageMinOpacity = 0.3f;							// if we add opacity changes on scrolling, set min and max opacity here
static float imageMaxOpacity = 0.8f;
static float loginImageDiameter = 150.0f;						// we assume that the images will be round
static int pageCount = 4;										// change the page count if we add or remove pages

float page0ImageInitialXOffset;									// starting x offsets of the images
float page1ImageInitialXOffset;
float page2ImageInitialXOffset;
float page3ImageInitialXOffset;
float page4ImageInitialXOffset;

float lastContentOffset = 0.0f;									// for determining scroll direction (for fading images in and out)
float fadePercentagePerPoint;									// how much to fade images by how far the page has scrolled

int currentScrollDirection = kScrollDirectionNone;				// if we add opacity changes on scrolling, we'll need to know which way the scroll view is going

#pragma mark - Initialization

- (LoginScrollView *)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	self.showsHorizontalScrollIndicator = NO;
	self.showsVerticalScrollIndicator = NO;
	[self adjustPageScrollViewWithFrame:frame];
	[self initImageScrollViewWithFrame:frame];
	[self initPageViews];
	[self initImageViews];
	[self initImageViewOffsets];
	[self registerForNotifications];
	return self;
}

- (void)adjustPageScrollViewWithFrame:(CGRect)frame
{
	float contentWidth = frame.size.width * (float)pageCount;
	float contentHeight = frame.size.height;
	self.contentSize = CGSizeMake(contentWidth, contentHeight);
	self.pagingEnabled = YES;
	fadePercentagePerPoint = 100.0f / self.frame.size.width;
}

- (void)initImageScrollViewWithFrame:(CGRect)frame
{
	float contentWidth = frame.size.width * (float)pageCount;	// half as wide a the actual page scrollview
	float contentHeight = frame.size.height;
	CGRect imageScrollViewFrame = CGRectMake(0.0f, 20.0f, contentWidth, frame.size.height);
	
	self.imageScrollView = [[UIScrollView alloc] initWithFrame:imageScrollViewFrame];
	self.imageScrollView.contentSize = CGSizeMake(contentWidth, contentHeight);
	
	self.imageScrollView.scrollEnabled = YES;
	self.imageScrollView.userInteractionEnabled = NO;
	[self addSubview:self.imageScrollView];
}

- (void)initPageViews
{
	[self initPage0View];
	[self initPage1View];
	[self initPage2View];
	[self initPage3SocialAccountView];
	[self initPage4CreateMobiAccountView];
}

- (void)initPage0View
{
	LoginPageView *page0View = [[LoginPageView alloc] initWithFrame:self.frame];
	page0View.titleLabel.text = NSLocalizedString(@"LOGIN TO GET", @"LOGIN TO GET");
	page0View.descriptionLabel.text = NSLocalizedString(@"Cloud sync between your devices", @"Cloud sync between your devices");
	[self addSubview:page0View];
}

- (void)initPage1View
{
	CGRect pageFrame = self.frame;
	pageFrame.origin.x += self.frame.size.width;
	LoginPageView *page1View = [[LoginPageView alloc] initWithFrame:pageFrame];
	page1View.titleLabel.text = NSLocalizedString(@"LOGIN TO GET", @"LOGIN TO GET");
	page1View.descriptionLabel.text = NSLocalizedString(@"Progress\n&\nGrading", @"Progress\n&\nGrading");
	[self addSubview:page1View];
}

- (void)initPage2View
{
	CGRect pageFrame = self.frame;
	pageFrame.origin.x += self.frame.size.width * 2.0f;
	LoginPageView *page2View = [[LoginPageView alloc] initWithFrame:pageFrame];
	page2View.titleLabel.text = NSLocalizedString(@"LOGIN TO GET", @"LOGIN TO GET");
	page2View.descriptionLabel.text = NSLocalizedString(@"Timeline of your activity", @"Timeline of your activity");
	[self addSubview:page2View];
}

- (void)initPage3SocialAccountView
{
	// this is the last page of the scroll view, and it contains social account login buttons, the mobi account creation button, and the 'skip' button
	CGRect pageFrame = self.frame;
	pageFrame.origin.x += self.frame.size.width * 3.0f;
	SocialAccountView *page3View = [[SocialAccountView alloc] initWithFrame:pageFrame];
	[self addSubview:page3View];
}

- (void)initPage4CreateMobiAccountView
{
	// not needed, but left in anyway
}

- (void)initImageViews
{
	page0ImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"loginPageImage1"]];
	page1ImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"loginPageImage2"]];
	page2ImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"loginPageImage3"]];
	page3ImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@""]];
	page4ImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@""]];

	[self.imageScrollView addSubview:page0ImageView];
	[self.imageScrollView addSubview:page1ImageView];
	[self.imageScrollView addSubview:page2ImageView];

	// if we ever add more "login benefit" pages, we will add them here.  otherwise page 3 is social accounts, page 4 is new mobi account	
	if (pageCount > 2)
		[self.imageScrollView addSubview:page3ImageView];
	
	if (pageCount > 3)
		[self.imageScrollView addSubview:page4ImageView];
}

- (void)initImageViewOffsets
{
	float adjustedImageYOffset = [self getYOffsetForCurrentFrameSize];
	float page0ImageYOffset = adjustedImageYOffset;							// y offsets of the various page images.  assume they're the same size (for now.)
	float page1ImageYOffset = adjustedImageYOffset;
	float page2ImageYOffset = adjustedImageYOffset;
	float page3ImageYOffset = adjustedImageYOffset;
	float page4ImageYOffset = adjustedImageYOffset;
	
	float viewPageWidth = self.frame.size.width;
	page0ImageInitialXOffset = (viewPageWidth * 0.0f) + (viewPageWidth / 2.0f) - (loginImageDiameter / 2.0f);
	CGRect frame = page0ImageView.frame;
	frame.origin.x = page0ImageInitialXOffset;
	frame.origin.y = page0ImageYOffset;
	frame.size.width = loginImageDiameter;
	frame.size.height = loginImageDiameter;
	page0ImageView.frame = frame;
	
	page1ImageInitialXOffset = page0ImageInitialXOffset + (viewPageWidth * imageScrollScaleFactor);
	frame = page1ImageView.frame;
	frame.origin.x = page1ImageInitialXOffset;
	frame.origin.y = page1ImageYOffset;
	frame.size.width = loginImageDiameter;
	frame.size.height = loginImageDiameter;
	page1ImageView.frame = frame;
	
	page2ImageInitialXOffset = page1ImageInitialXOffset + (viewPageWidth * imageScrollScaleFactor);
	frame = page2ImageView.frame;
	frame.origin.x = page2ImageInitialXOffset;
	frame.origin.y = page2ImageYOffset;
	frame.size.width = loginImageDiameter;
	frame.size.height = loginImageDiameter;
	page2ImageView.frame = frame;
	
	page3ImageInitialXOffset = page2ImageInitialXOffset + (viewPageWidth * imageScrollScaleFactor);
	frame = page3ImageView.frame;
	frame.origin.x = page3ImageInitialXOffset;
	frame.origin.y = page3ImageYOffset;
	frame.size.width = loginImageDiameter;
	frame.size.height = loginImageDiameter;
	page3ImageView.frame = frame;
	
	page4ImageInitialXOffset = page3ImageInitialXOffset + (viewPageWidth * imageScrollScaleFactor);
	frame = page4ImageView.frame;
	frame.origin.x = page4ImageInitialXOffset;
	frame.origin.y = page4ImageYOffset;
	frame.size.width = loginImageDiameter;
	frame.size.height = loginImageDiameter;
	page4ImageView.frame = frame;
}

- (float)getYOffsetForCurrentFrameSize
{
	float yOffset = 0.0f;
	if (DEVICE_IS_IPAD) {
        yOffset = 200.0f;
    }
    else
    {
        if (self.frame.size.height == 480.0f)				// iphone 4/4S/iPod touch 4th gen
            yOffset = -10.0f;
        else if (self.frame.size.height == 568.0f)         // iPhone 5/5S/5C/iPod touch 5th gen
            yOffset = 60.0f;
    }
				
	
	return yOffset;
}

#pragma mark - Page image position & opacity

// We scroll the images in proportion to the main scroll view's motion.
// Change the scroll factor and we alter the speed at which the images scroll in relation to the main scroll view's motions.
- (void)positionPageImagesForXOffset:(float)xOffset
{
	CGRect frame = page0ImageView.frame;
	frame.origin.x = page0ImageInitialXOffset - (xOffset / 2.0f) + xOffset;
	page0ImageView.frame = frame;
	
	frame = page1ImageView.frame;
	frame.origin.x = page1ImageInitialXOffset - (xOffset / 2.0f) + xOffset;
	page1ImageView.frame = frame;
	
	frame = page2ImageView.frame;
	frame.origin.x = page2ImageInitialXOffset - (xOffset / 2.0f) + xOffset;
	page2ImageView.frame = frame;
	
	frame = page3ImageView.frame;
	frame.origin.x = page3ImageInitialXOffset - (xOffset / 2.0f) + xOffset;
	page3ImageView.frame = frame;
	
	frame = page4ImageView.frame;
	frame.origin.x = page4ImageInitialXOffset - (xOffset / 2.0f) + xOffset;
	page4ImageView.frame = frame;
}

- (void)adjustPageImageOpacitiesForOffset:(float)xOffset pageIndex:(int)pageIndex
{
	int visiblePageIndex = (int)(xOffset / self.frame.size.width);

	switch (visiblePageIndex)
	{
		case 0:
			[self setOpacityOfPage0ImagesForXOffset:xOffset pageIndex:pageIndex];
			break;
		case 1:
			[self setOpacityOfPage1ImagesForXOffset:xOffset pageIndex:pageIndex];
			break;
		case 2:
			[self setOpacityOfPage2ImagesForXOffset:xOffset pageIndex:pageIndex];
			break;
		case 3:
			[self setOpacityOfPage3ImagesForXOffset:xOffset pageIndex:pageIndex];
			break;
		case 4:
			[self setOpacityOfPage4ImagesForXOffset:xOffset pageIndex:pageIndex];
			break;
	}
}

- (void)setOpacityOfPage0ImagesForXOffset:(float)xOffset pageIndex:(int)pageIndex
{
	if (currentScrollDirection == kScrollDirectionLeft)
	{
		// fade out image 0, fade in image 1, leave image 2 faded out
		float pointsLeftOfCenter = xOffset - (self.frame.size.width * 0.0f);
		float image0Opacity = imageMinOpacity + ((imageMaxOpacity - imageMinOpacity) * pointsLeftOfCenter * fadePercentagePerPoint);
		page0ImageView.layer.opacity = image0Opacity;
		float image1Opacity = imageMaxOpacity - ((imageMaxOpacity - imageMinOpacity) * pointsLeftOfCenter * fadePercentagePerPoint);
		page1ImageView.layer.opacity = image1Opacity;
	}
	else if (currentScrollDirection == kScrollDirectionRight)
	{
		// if at left edge, we fade nothing
		if (xOffset < 0.0f)
			return;
	}
}

- (void)setOpacityOfPage1ImagesForXOffset:(float)xOffset pageIndex:(int)pageIndex
{
}

- (void)setOpacityOfPage2ImagesForXOffset:(float)xOffset pageIndex:(int)pageIndex
{
	
}

- (void)setOpacityOfPage3ImagesForXOffset:(float)xOffset pageIndex:(int)pageIndex
{
	
}

- (void)setOpacityOfPage4ImagesForXOffset:(float)xOffset pageIndex:(int)pageIndex
{
	
}

#pragma mark - Mobi account creation view

// note: these are only called when the user has scrolled to the social accounts page and taps "connect with facebook, "connect with twitter", or "create an account".
// if the login scrollview only has 4 pages, we create the new page view and add it as the 5th page.  otherwise, if the user has tapped a different button
// (e.g. they tapped "create an account" then came back and tapped the "connect with facebook" button, then we remove the mobi account view while it's offscreen,
// replace it with the facebook login view, then scroll to the 5th page.  ad nauseam.

- (void)presentFacebookLoginView
{
	float facebookLoginPageOffset = self.contentOffset.x + self.bounds.size.width;
	CGRect facebookFrame = CGRectMake(facebookLoginPageOffset, 0.0f, self.bounds.size.width, self.bounds.size.height);
	facebookLoginView = [[FacebookLoginView alloc] initWithFrame:facebookFrame];
	pageCount = 5;
	[self adjustPageScrollViewWithFrame:self.bounds];
	[self removeMobiLoginView];
	[self removeTwitterLoginView];
	[self addSubview:facebookLoginView];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"addFifthPageToPageControl" object:nil];
	[self setContentOffset:CGPointMake(facebookLoginPageOffset, 0.0f) animated:YES];
}

- (void)presentTwitterLoginView
{
	float twitterLoginPageOffset = self.contentOffset.x + self.bounds.size.width;
	CGRect twitterFrame = CGRectMake(twitterLoginPageOffset, 0.0f, self.bounds.size.width, self.bounds.size.height);
	twitterLoginView = [[TwitterLoginView alloc] initWithFrame:twitterFrame];
	pageCount = 5;
	[self adjustPageScrollViewWithFrame:self.bounds];
	[self removeFacebookLoginView];
	[self removeMobiLoginView];
	[self addSubview:twitterLoginView];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"addFifthPageToPageControl" object:nil];
	[self setContentOffset:CGPointMake(twitterLoginPageOffset, 0.0f) animated:YES];
}

- (void)presentMobiAccountCreationView
{
	float mobiAccountPageOffset = self.contentOffset.x + self.bounds.size.width;

	if (newMobiAccountView == nil)				// if it doesn't already exist, create it.  otherwise, just scroll over to the existing mobi account creation view.
	{
		CGRect mobiFrame = CGRectMake(mobiAccountPageOffset, 0.0f, self.bounds.size.width, self.bounds.size.height);
		newMobiAccountView = [[CreateNewMobiAccountView alloc] initWithFrame:mobiFrame];
		pageCount = 5;
		[self adjustPageScrollViewWithFrame:self.bounds];
		[self removeFacebookLoginView];
		[self removeTwitterLoginView];
		[self addSubview:newMobiAccountView];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"addFifthPageToPageControl" object:nil];
	}

	[self setContentOffset:CGPointMake(mobiAccountPageOffset, 0.0f) animated:YES];
}

- (void)hideMobiAccountCreationView
{
	[newMobiAccountView removeFromSuperview];
	pageCount--;
	[self adjustPageScrollViewWithFrame:self.bounds];
}

#pragma mark - Notifications

- (void)registerForNotifications
{
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(presentMobiAccountCreationView)
												 name:@"createMobiAccountNotification"
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(presentFacebookLoginView)
												 name:@"facebookLoginNotification"
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(presentTwitterLoginView)
												 name:@"twitterLoginNotification"
											   object:nil];
}

- (void) unRegisterForNotifications
{
 	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:@"createMobiAccountNotification"
												  object:nil];
 	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:@"facebookLoginNotification"
												  object:nil];
 	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:@"twitterLoginNotification"
												  object:nil];
}

#pragma mark - Scroll view and page control methods

- (void)determineCurrentScrollDirection
{
	if (lastContentOffset > self.imageScrollView.contentOffset.x)
		currentScrollDirection = kScrollDirectionRight;
	else if (lastContentOffset < self.imageScrollView.contentOffset.x)
		currentScrollDirection = kScrollDirectionLeft;
	
	lastContentOffset = self.imageScrollView.contentOffset.x;
}

#pragma mark - View lifecycle & cleanup

- (void)dealloc
{
	facebookLoginView = nil, twitterLoginView = nil, newMobiAccountView = nil;
	[self unRegisterForNotifications];
}

- (void)removeFacebookLoginView
{
	if (facebookLoginView)
	{
		[facebookLoginView removeFromSuperview];
		facebookLoginView = nil;
	}
}

- (void)removeTwitterLoginView
{
	if (twitterLoginView)
	{
		[twitterLoginView removeFromSuperview];
		twitterLoginView = nil;
	}
}

- (void)removeMobiLoginView
{
	if (newMobiAccountView)
	{
		[newMobiAccountView removeFromSuperview];
		newMobiAccountView = nil;
	}
}

@end
