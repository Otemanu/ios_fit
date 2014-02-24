//
//  SettingsViewController
//  Fit
//
//  Created by Rich on 10/31/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//

#import "SettingsViewController.h"
#import "CustomerDataEngine.h"

@interface SettingsViewController ()

@end

@implementation SettingsViewController

UIImageView *blurredLoginBackgroundView;
LoginScrollView *loginScrollView;
UIPageControl *loginPageControl;
int loginScrollviewPageIndex = 0;
UIActivityIndicatorView *activityIndicator = nil;

#pragma mark - Button actions

- (IBAction)logoutButtonPressed:(id)sender;
{
	[[CustomerDataEngine customerDataEngine] removeAvatarImageFromLocalFilesystem];
	[self fadeOutAvatarImage];
	[self presentLoginView];
}

- (IBAction)resetProgressButtonPressed:(id)sender;
{
	[self showAlertWithTitle:@"ARE YOU SURE?" messageString:@"Do you really want to reset all reading and quiz progress?"];
}

#pragma mark - Alert popup (only for the "reset" button)

- (void) showAlertWithTitle:(NSString *)titleString messageString:(NSString *)messageString
{
	NSString *localizedMessage = NSLocalizedString(messageString, messageString);
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:titleString
													message:localizedMessage
												   delegate:self
										  cancelButtonTitle:@"Cancel"
										  otherButtonTitles:@"OK", nil];
	[alert show];
}

- (void) alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == 1)
	{
		[self showIndeterminateProgressIndicator];
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			[[DataController sharedController] resetAllProgress];
			[[NSNotificationCenter defaultCenter] postNotificationName:@"resetAllQuizAndProgressData" object:nil];
			dispatch_async(dispatch_get_main_queue(), ^{
				[self showClearedMessage];
			});
		});
	}
}

- (void)initActivityIndicator
{
	activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];

	CGRect activityFrame = activityIndicator.frame;
	activityFrame.size.width += 20.0f;
	activityFrame.size.height += 20.0f;
	float frameXOffset = (self.view.frame.size.width / 2.0f) - (activityFrame.size.width / 2.0f);
	float frameYOffsetAdjustment = 108.0f;		// change this to adjust the y position of the activity indicator
	float frameYOffset = (self.view.frame.size.height / 3.0f) + frameYOffsetAdjustment;
	activityFrame.origin.x = frameXOffset;
	activityFrame.origin.y = frameYOffset;
	activityIndicator.frame = activityFrame;
	
	activityIndicator.layer.cornerRadius = activityIndicator.frame.size.width / 2.0f;
	[activityIndicator startAnimating];
	[self.view addSubview:activityIndicator];
}

- (void)showIndeterminateProgressIndicator
{
	[self initActivityIndicator];
	[UIView beginAnimations:nil context:NULL];
	activityIndicator.layer.opacity = 1.0f;
	[UIView commitAnimations];
}

- (void)showClearedMessage
{
	[UIView animateWithDuration:0.5f animations:^{
		activityIndicator.layer.opacity = 0.0f;
	}completion:^(BOOL finished) {
		activityIndicator = nil;

		float messageWidth = self.view.bounds.size.width, messageHeight = 80.0f;
		float yOffsetAdjustment = 93.0f;		// change this to adjust the y position of the reset message
		float yOffset = (self.view.frame.size.height / 3.0f) + yOffsetAdjustment;
		CGRect messageFrame = CGRectMake(0.0f, yOffset, messageWidth, messageHeight);
		UILabel *messageLabel = [[UILabel alloc] initWithFrame:messageFrame];
		messageLabel.backgroundColor = [UIColor clearColor];
		messageLabel.text = NSLocalizedString(@"All Progress Reset", @"All Progress Reset");
		messageLabel.textColor = [UIColor whiteColor];
		messageLabel.font = [UIFont fontWithName:@"HelveticaNeue-CondensedBold" size:24.0f];
		messageLabel.textAlignment = NSTextAlignmentCenter;
		[self.view addSubview:messageLabel];
		[UIView beginAnimations:nil context:NULL];
		messageLabel.layer.opacity = 1.0f;
		[UIView commitAnimations];

    	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.5f * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
			[UIView beginAnimations:nil context:NULL];
			messageLabel.layer.opacity = 0.0f;
			[UIView commitAnimations];
		});
	}];
}

// the ease in/out methods are no longer used, but here they are anyway.
- (void)easeInMessageWithAnimation:(UILabel *)messageLabel fromFrame:(CGRect)fromFrame toFrame:(CGRect)toFrame
{
	messageLabel.layer.opacity = 0.0f;
	messageLabel.frame = fromFrame;

	[UIView beginAnimations:nil context:NULL];
	messageLabel.layer.opacity = 1.0f;
	messageLabel.frame = toFrame;
	[UIView commitAnimations];
}

- (void)easeOutMessageWithAnimation:(UILabel *)messageLabel toFrame:(CGRect)toFrame afterDelay:(float)delayFloat
{
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delayFloat * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
		[self doEaseOutWithMessage:messageLabel toFrame:toFrame];
	});
}

- (void)doEaseOutWithMessage:(UILabel *)messageLabel toFrame:(CGRect)toFrame
{
	[UIView beginAnimations:nil context:NULL];
	messageLabel.layer.opacity = 0.0f;
	messageLabel.frame = toFrame;
	[UIView commitAnimations];
}

-(void)addShadowForBackgroundView{
    
    CALayer *layer=[self.backgroundView layer];
    [layer setShadowPath:[UIBezierPath bezierPathWithRect:layer.bounds].CGPath];
    [layer setShadowColor:[UIColor blackColor].CGColor];
    [layer setShadowOffset:CGSizeMake(1, 1)];
    [layer setShadowRadius:15.0f];
    [layer setShadowOpacity:0.40];
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    if(DEVICE_IS_IPAD)
        [self addShadowForBackgroundView];
	[self configureView];
}

- (void)viewWillAppear:(BOOL)animated
{
	[self setCustomerNameWithAnimation:NO];
	[self fadeInAvatarImage];
	[self registerForNotifications];
	[self setLogoutButtonTitle];
	[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[self unRegisterForNotifications];
}

// note: all login view code should be broken out into a new class, and we should instantiate that class from
// both the Timeline view and Settings view.

#pragma mark - View delegate methods

- (BOOL)prefersStatusBarHidden
{
    return NO;
}

#pragma mark - Login scrollview

- (void)presentLoginView
{
	[self createBlurredLoginViewBackground];
	[self createLoginScrollView];
	[self initPageControl];
}

- (void)createBlurredLoginViewBackground
{
	UIGraphicsBeginImageContextWithOptions(self.view.frame.size, NO, 1.0f);
	[self.view drawViewHierarchyInRect:self.view.bounds afterScreenUpdates:NO];
	UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	UIImage *blurredImage = [newImage applyDarkEffect];
	blurredLoginBackgroundView = [[UIImageView alloc] initWithImage:blurredImage];
	blurredLoginBackgroundView.layer.opacity = 0.0f;
	blurredLoginBackgroundView.userInteractionEnabled = YES;							// prevent taps and swipes from passing through to the tab bar and table view
	[self.tabBarController.view addSubview:blurredLoginBackgroundView];					// make sure the blurred background image covers the tab bar as well
	
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.5f];
	blurredLoginBackgroundView.layer.opacity = 1.0f;
	[UIView commitAnimations];
}

- (void)createLoginScrollView
{
	loginScrollView = [[LoginScrollView alloc] initWithFrame:self.view.bounds];
	loginScrollView.userInteractionEnabled = YES;
	loginScrollView.delegate = self;
	[blurredLoginBackgroundView addSubview:loginScrollView];
	[blurredLoginBackgroundView bringSubviewToFront:loginScrollView];
}

- (void)hideLoginView
{
	[UIView animateWithDuration:0.5f
						  delay:0.0
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^{
						 blurredLoginBackgroundView.layer.opacity = 0.0f;
						 loginScrollView.layer.opacity = 0.0f;
						 loginPageControl.alpha = 0.0f;
					 }
					 completion:^(BOOL finished){
						 [blurredLoginBackgroundView removeFromSuperview];
						 [loginScrollView removeFromSuperview];
						 [loginPageControl removeFromSuperview];
					 }];
}

- (void)initPageControl
{
	float pageControlWidth = 200.0f;
	float pageControlHeight = 50.0f;
	CGRect frame = CGRectMake((self.view.frame.size.width / 2.0f) - (pageControlWidth / 2.0f), self.view.frame.size.height - pageControlHeight, pageControlWidth, pageControlHeight);
	loginPageControl = [[UIPageControl alloc] initWithFrame:frame];
	loginPageControl.numberOfPages = 4;
	loginPageControl.currentPage = 0;
	loginPageControl.opaque = YES;
	loginPageControl.alpha = 1.0f;
	loginPageControl.pageIndicatorTintColor = [UIColor blackColor];
	loginPageControl.currentPageIndicatorTintColor = [UIColor lightGrayColor];
	loginPageControl.backgroundColor = [UIColor clearColor];
	[loginPageControl addTarget:self action:@selector(loginScrollViewPageChanged) forControlEvents:UIControlEventValueChanged];
	[blurredLoginBackgroundView addSubview:loginPageControl];
	[blurredLoginBackgroundView bringSubviewToFront:loginPageControl];
}

- (void)loginScrollViewPageChanged
{
	CGFloat xOffset = self.view.frame.size.width * loginPageControl.currentPage;
	[loginScrollView setContentOffset:CGPointMake(xOffset, 0.0f) animated:YES];
}

- (void)addFifthPageToPageControl
{
	loginPageControl.numberOfPages = 5;		// ordinal count
	loginPageControl.currentPage = 4;		// index
}

#pragma mark - Scroll view delegate

// note: this is only for the login scroll view

- (void)scrollViewDidScroll:(UIScrollView *)aScrollView
{
	float pageWidth = self.view.frame.size.width;
	float speedupThreshold = pageWidth * 2.0f;
	float xOffset = aScrollView.contentOffset.x;
	
	if (xOffset > speedupThreshold)
		xOffset -= (450.0f * (xOffset - speedupThreshold) / xOffset);
	
    int pageIndex = floor((loginScrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
	
	if (pageIndex != loginScrollviewPageIndex)
	{
		loginScrollviewPageIndex = pageIndex;
		loginPageControl.currentPage = loginScrollviewPageIndex;
	}
	
	[loginScrollView positionPageImagesForXOffset:xOffset];
	[loginScrollView determineCurrentScrollDirection];
	
	//	[self adjustPageImageOpacitiesForOffset:xOffset pageIndex:(int)(xOffset / self.view.frame.size.width)];
}

#pragma mark - Misc view methods

- (void)configureView
{
	self.settingsAvatarImageView.layer.cornerRadius = self.settingsAvatarImageView.frame.size.width / 2.0f;
	self.settingsAvatarBackgroundView.layer.cornerRadius = self.settingsAvatarBackgroundView.frame.size.width / 2.0f;
	self.settingsAvatarMaskView.layer.cornerRadius = self.settingsAvatarMaskView.frame.size.width / 2.0f;
	self.settingsAvatarShadowView.layer.cornerRadius = self.settingsAvatarShadowView.frame.size.width / 2.0f;
	self.view.backgroundColor = [UIColor colorWithRed:0.62 green:0.871 blue:0.176 alpha:1];
	[self setUserAvatarImage];
}

- (void)setUserAvatarImage
{
	self.settingsAvatarImageView.image = [[CustomerDataEngine customerDataEngine] readAvatarImageFromLocalFilesystem];
	
	if (self.settingsAvatarImageView.image == nil)
		self.settingsAvatarImageView.image = [UIImage imageNamed:@"default-avatar"];
}

- (void)setCustomerNameWithAnimation:(BOOL)animate
{
	if (animate)
	{
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationDuration:0.5f];
	}

	self.settingsUsername.text = [[CustomerDataEngine customerDataEngine] getCustomerName];

	if (animate)
		[UIView commitAnimations];
}

- (void)fadeInAvatarImage
{
	self.settingsAvatarImageView.alpha = 0.0f;
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.5f];
	self.settingsAvatarImageView.alpha = 1.0f;
	[UIView commitAnimations];

	self.settingsAvatarBackgroundView.alpha = 0.0f;
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.5f];
	self.settingsAvatarBackgroundView.alpha = 1.0f;
	[UIView commitAnimations];
}

- (void)fadeOutAvatarImage
{
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.5f];
	self.settingsAvatarImageView.alpha = 0.0f;
	[UIView commitAnimations];
	
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.5f];
	self.settingsAvatarBackgroundView.alpha = 0.0f;
	[UIView commitAnimations];
}

#pragma mark - Notifications

- (void)registerForNotifications
{
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(finishLogin)
												 name:@"loginViewDoneNotification"
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(updateUserAvatar)
												 name:@"avatarImageReadyNotification"
											   object:nil];
}

- (void)unRegisterForNotifications
{
 	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:@"loginViewDoneNotification"
												  object:nil];
 	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:@"avatarImageReadyNotification"
												  object:nil];
}

- (void)finishLogin
{
	[self setCustomerNameWithAnimation:YES];
	[self hideLoginView];
	[[WebServicesEngine webServicesEngine] closeAllLoginWebSockets];
}

- (void)updateUserAvatar
{
	self.settingsAvatarImageView.alpha = 0.0f;
	[self setUserAvatarImage];
	[self fadeInAvatarImage];
}

#pragma mark - Initialization

- (void)setLogoutButtonTitle
{
	NSString *buttonText = [self.settingsUsername.text hasPrefix:@"Anonymous_"] ? NSLocalizedString(@"LOGIN", @"LOGIN") :  NSLocalizedString(@"LOGOUT", @"LOGOUT");
	[self.settingsLogoutButton setTitle:buttonText forState:UIControlStateNormal];
}

#pragma mark - Notifications

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
