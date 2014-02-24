//
//  SocialAccountView.m
//  Fit
//
//  Created by Rich on 11/18/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//

#import "SocialAccountView.h"

static float kEdgeMargin = 20.0f;
static float kEdgeMarginIPAD = 180;
static float kButtonHeight = 40.0f;
static float kButtonTextFontSize = 13.0f;
static float kButtonTextXOffset = 80.0f;
static float socialPageImageDiameter = 150.0f;						// we assume that the image will be round

WebServicesEngine *socialAccountViewWebServicesEngine = nil;

@implementation SocialAccountView

#pragma mark - Initialization

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    if (self)
	{
		CGRect viewFrame = self.frame;
		[self initSocialAccountPageImageWithFrame:viewFrame];
		[self initSocialAccountPageTitleWithFrame:viewFrame];
		[self initSocialAccountPageFacebookButtonWithFrame:viewFrame];
		[self initSocialAccountPageTwitterButtonWithFrame:viewFrame];
		[self initSocialAccountPageFacebookButtonLabel];
		[self initSocialAccountPageTwitterButtonLabel];
		[self initSocialAccountPageFacebookButtonImage];
		[self initSocialAccountPageTwitterButtonImage];
		[self initSocialAccountPageMobiButtonWithFrame:viewFrame];
		[self initSocialAccountPageAlreadyHaveLabelWithFrame:viewFrame];
		[self initSocialAccountPageSkipButtonWithFrame:viewFrame];
 		[self initWebServicesEngine];
   }
    return self;
}

- (void)initSocialAccountPageImageWithFrame:(CGRect)viewFrame
{
	self.socialAccountMainImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"loginPageImage4"]];
	CGRect imageFrame = self.socialAccountMainImageView.frame;
	imageFrame.size.width = socialPageImageDiameter;
	imageFrame.size.height = socialPageImageDiameter;
	imageFrame.origin.x = (viewFrame.size.width / 2.0f) - (imageFrame.size.width / 2.0f);
    if (DEVICE_IS_IPAD)
        imageFrame.origin.y = 200.0f;
	else
        imageFrame.origin.y = 80.0f;
    
	self.socialAccountMainImageView.frame = imageFrame;
	[self addSubview:self.socialAccountMainImageView];
}

- (void)initSocialAccountPageTitleWithFrame:(CGRect)viewFrame
{
	if (viewFrame.size.height < 568.0f)
		return;
	if (DEVICE_IS_IPAD)
        self.socialAccountTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(kEdgeMarginIPAD, viewFrame.size.height - 428.0f, viewFrame.size.width - (kEdgeMargin * 2.0f), 150.0f)];
	else
        self.socialAccountTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(kEdgeMargin, viewFrame.size.height - 428.0f, viewFrame.size.width - (kEdgeMargin * 2.0f), 150.0f)];
    
	self.socialAccountTitleLabel.text = @" ";
	self.socialAccountTitleLabel.textColor = [UIColor whiteColor];
	self.socialAccountTitleLabel.font = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:70.0f];
	self.socialAccountTitleLabel.textAlignment = NSTextAlignmentCenter;
	[self addSubview:self.socialAccountTitleLabel];
}

- (void)initSocialAccountPageFacebookButtonWithFrame:(CGRect)viewFrame
{
	self.socialAccountFacebookButton = [UIButton buttonWithType:UIButtonTypeCustom];
	CGRect buttonFrame = self.socialAccountFacebookButton.frame;
    if (DEVICE_IS_IPAD) {
        buttonFrame.size = CGSizeMake(viewFrame.size.width - (kEdgeMarginIPAD * 2.0f), kButtonHeight);
        buttonFrame.origin = CGPointMake(kEdgeMarginIPAD, viewFrame.size.height - 268.0f);
    }
    else
    {
        buttonFrame.size = CGSizeMake(viewFrame.size.width - (kEdgeMargin * 2.0f), kButtonHeight);
        buttonFrame.origin = CGPointMake(kEdgeMargin, viewFrame.size.height - 268.0f);
    }
    self.socialAccountFacebookButton.frame = buttonFrame;
	[self.socialAccountFacebookButton setTitle:nil forState:UIControlStateNormal];
	self.socialAccountFacebookButton.titleLabel.font = [UIFont systemFontOfSize:kButtonTextFontSize];
	[self.socialAccountFacebookButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	self.socialAccountFacebookButton.backgroundColor = [UIColor colorWithRed:0.3f green:0.5f blue:1.0f alpha:1.0f];
	[self.socialAccountFacebookButton addTarget:self action:@selector(handleFacebookButtonTap) forControlEvents:UIControlEventTouchUpInside];
	[self roundButtonCorners:self.socialAccountFacebookButton];
	[self addSubview:self.socialAccountFacebookButton];
}

- (void)initSocialAccountPageTwitterButtonWithFrame:(CGRect)viewFrame
{
	self.socialAccountTwitterButton = [UIButton buttonWithType:UIButtonTypeCustom];
	CGRect buttonFrame = self.socialAccountTwitterButton.frame;
    if (DEVICE_IS_IPAD) {
        buttonFrame.size = CGSizeMake(viewFrame.size.width - (kEdgeMarginIPAD * 2.0f), kButtonHeight);
        buttonFrame.origin = CGPointMake(kEdgeMarginIPAD, viewFrame.size.height - 208.0f);
    }
	else
    {
        buttonFrame.size = CGSizeMake(viewFrame.size.width - (kEdgeMargin * 2.0f), kButtonHeight);
        buttonFrame.origin = CGPointMake(kEdgeMargin, viewFrame.size.height - 208.0f);
    }
	self.socialAccountTwitterButton.frame = buttonFrame;
	[self.socialAccountTwitterButton setTitle:nil forState:UIControlStateNormal];
	self.socialAccountTwitterButton.titleLabel.font = [UIFont systemFontOfSize:kButtonTextFontSize];
	[self.socialAccountTwitterButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	self.socialAccountTwitterButton.backgroundColor = [UIColor colorWithRed:0.6f green:0.6f blue:1.0f alpha:1.0f];
	[self.socialAccountTwitterButton addTarget:self action:@selector(handleTwitterButtonTap) forControlEvents:UIControlEventTouchUpInside];
	[self roundButtonCorners:self.socialAccountTwitterButton];
	[self addSubview:self.socialAccountTwitterButton];
}

- (void)initSocialAccountPageFacebookButtonLabel
{
	CGRect buttonFrame = self.socialAccountFacebookButton.frame;
	buttonFrame.origin.x += kButtonTextXOffset;
	buttonFrame.size.width -= kButtonTextXOffset;
	self.socialAccountFacebookButtonLabel = [[UILabel alloc] initWithFrame:buttonFrame];
	self.socialAccountFacebookButtonLabel.text = NSLocalizedString(@"Connect with Facebook", @"Connect with Facebook");
	self.socialAccountFacebookButtonLabel.textAlignment = NSTextAlignmentLeft;
	self.socialAccountFacebookButtonLabel.textColor = [UIColor whiteColor];
	self.socialAccountFacebookButtonLabel.font = [UIFont systemFontOfSize:kButtonTextFontSize];
	self.socialAccountFacebookButtonLabel.userInteractionEnabled = NO;
	[self addSubview:self.socialAccountFacebookButtonLabel];
}

- (void)initSocialAccountPageTwitterButtonLabel
{
	CGRect labelFrame = self.socialAccountTwitterButton.frame;
	labelFrame.origin.x += kButtonTextXOffset;
	labelFrame.size.width -= kButtonTextXOffset;
	self.socialAccountTwitterButtonLabel = [[UILabel alloc] initWithFrame:labelFrame];
	self.socialAccountTwitterButtonLabel.text = NSLocalizedString(@"Connect with Twitter", @"Connect with Twitter");
	self.socialAccountTwitterButtonLabel.textAlignment = NSTextAlignmentLeft;
	self.socialAccountTwitterButtonLabel.textColor = [UIColor whiteColor];
	self.socialAccountTwitterButtonLabel.font = [UIFont systemFontOfSize:kButtonTextFontSize];
	self.socialAccountTwitterButtonLabel.userInteractionEnabled = NO;
	[self addSubview:self.socialAccountTwitterButtonLabel];
}

- (void)initSocialAccountPageFacebookButtonImage
{
	self.socialAccountFacebookImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"facebookf1"]];
	CGRect imageFrame = self.socialAccountFacebookButton.frame;
	float yOffset = imageFrame.origin.y + (imageFrame.size.height / 2.0f) - (self.socialAccountFacebookImageView.frame.size.height / 2.0f);
	imageFrame.origin.y = yOffset;
	imageFrame.origin.x += 14.0f;
	imageFrame.size.width = 30.0f;
	imageFrame.size.height = 30.0f;
	self.socialAccountFacebookImageView.frame = imageFrame;
	self.socialAccountFacebookImageView.userInteractionEnabled = NO;
	
	CGRect maskFrame = self.socialAccountFacebookButton.frame;
	maskFrame.size.width = imageFrame.size.width * 2.0f;
	UIView *maskView = [[UIView alloc] initWithFrame:maskFrame];
	maskView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.2f];
	[self addSubview:maskView];
	[self addSubview:self.socialAccountFacebookImageView];
}

- (void)initSocialAccountPageTwitterButtonImage
{
	self.socialAccountTwitterImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"twitterbird1"]];
	CGRect imageFrame = self.socialAccountTwitterButton.frame;
	float yOffset = imageFrame.origin.y + (imageFrame.size.height / 2.0f) - (self.socialAccountTwitterImageView.frame.size.height / 2.0f);
	imageFrame.origin.y = yOffset;
	imageFrame.origin.x += 14.0f;
	imageFrame.size.width = 30.0f;
	imageFrame.size.height = 30.0f;
	self.socialAccountTwitterImageView.frame = imageFrame;
	self.socialAccountTwitterImageView.userInteractionEnabled = NO;
	
	CGRect maskFrame = self.socialAccountTwitterButton.frame;
	maskFrame.size.width = imageFrame.size.width * 2.0f;
	UIView *maskView = [[UIView alloc] initWithFrame:maskFrame];
	maskView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.2f];
	[self addSubview:maskView];
	[self addSubview:self.socialAccountTwitterImageView];
}

- (void)initSocialAccountPageMobiButtonWithFrame:(CGRect)viewFrame
{
	self.socialAccountMobiButton = [UIButton buttonWithType:UIButtonTypeCustom];
	CGRect buttonFrame = self.socialAccountMobiButton.frame;
    if (DEVICE_IS_IPAD) {
        buttonFrame.size = CGSizeMake(viewFrame.size.width - (kEdgeMarginIPAD * 2.0f), kButtonHeight);
        buttonFrame.origin = CGPointMake(kEdgeMarginIPAD, viewFrame.size.height - 148.0f);
    }
    else
    {
        buttonFrame.size = CGSizeMake(viewFrame.size.width - (kEdgeMargin * 2.0f), kButtonHeight);
        buttonFrame.origin = CGPointMake(kEdgeMargin, viewFrame.size.height - 148.0f);
    }
	self.socialAccountMobiButton.frame = buttonFrame;
	[self.socialAccountMobiButton setTitle:NSLocalizedString(@"Create an Account", @"Create an Account") forState:UIControlStateNormal];
	self.socialAccountMobiButton.titleLabel.font = [UIFont systemFontOfSize:kButtonTextFontSize];
	[self.socialAccountMobiButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
	self.socialAccountMobiButton.backgroundColor = [UIColor whiteColor];
	self.socialAccountMobiButton.opaque = YES;
	self.socialAccountMobiButton.enabled = YES;
	[self.socialAccountMobiButton addTarget:self action:@selector(handleMobiAccountButtonTap) forControlEvents:UIControlEventTouchUpInside];
	[self roundButtonCorners:self.socialAccountMobiButton];
	[self addSubview:self.socialAccountMobiButton];
}

- (void)initSocialAccountPageAlreadyHaveLabelWithFrame:(CGRect)viewFrame
{
    if (DEVICE_IS_IPAD)
        self.socialAccountAlreadyHaveLabel = [[UILabel alloc] initWithFrame:CGRectMake(kEdgeMarginIPAD + 3.0f, viewFrame.size.height - 108.0f, viewFrame.size.width - (kEdgeMarginIPAD * 2.0f), kButtonHeight)];
    else
        self.socialAccountAlreadyHaveLabel = [[UILabel alloc] initWithFrame:CGRectMake(kEdgeMargin + 3.0f, viewFrame.size.height - 108.0f, viewFrame.size.width - (kEdgeMargin * 2.0f), kButtonHeight)];

	self.socialAccountAlreadyHaveLabel.text = NSLocalizedString(@"Already have an account?", @"Already have an account?");
	self.socialAccountAlreadyHaveLabel.textColor = [UIColor yellowColor];
	self.socialAccountAlreadyHaveLabel.font = [UIFont systemFontOfSize:kButtonTextFontSize];
	[self addSubview:self.socialAccountAlreadyHaveLabel];
}

- (void)initSocialAccountPageSkipButtonWithFrame:(CGRect)viewFrame
{
	self.socialAccountSkipButton = [UIButton buttonWithType:UIButtonTypeCustom];
	CGRect buttonFrame = self.socialAccountSkipButton.frame;
	buttonFrame.size = CGSizeMake(80.0f, kButtonHeight);
    if (DEVICE_IS_IPAD)
        buttonFrame.origin = CGPointMake((self.frame.size.width - kEdgeMarginIPAD - buttonFrame.size.width), self.socialAccountAlreadyHaveLabel.frame.origin.y);
    else
        buttonFrame.origin = CGPointMake(230.0f, self.socialAccountAlreadyHaveLabel.frame.origin.y);
    
	self.socialAccountSkipButton.frame = buttonFrame;
	[self.socialAccountSkipButton setTitle:NSLocalizedString(@"Skip", @"Skip") forState:UIControlStateNormal];
	self.socialAccountSkipButton.titleLabel.font = [UIFont systemFontOfSize:kButtonTextFontSize];
	[self.socialAccountSkipButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	self.socialAccountSkipButton.opaque = YES;
	self.socialAccountSkipButton.enabled = YES;
	[self.socialAccountSkipButton addTarget:self action:@selector(handleSkipButtonTap) forControlEvents:UIControlEventTouchUpInside];
	[self addSubview:self.socialAccountSkipButton];
}

- (void)initWebServicesEngine
{
	socialAccountViewWebServicesEngine = [WebServicesEngine webServicesEngine];
}

#pragma mark - Actions

- (void)handleFacebookButtonTap
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"facebookLoginNotification" object:nil];
}

- (void)handleTwitterButtonTap
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"twitterLoginNotification" object:nil];
}

- (void)handleMobiAccountButtonTap
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"createMobiAccountNotification" object:nil];
}

- (void)handleSkipButtonTap
{
	[socialAccountViewWebServicesEngine requestLoginWithAnonymousAccount];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loginViewDoneNotification" object:nil];
}

#pragma mark - Utility methods

- (void)roundButtonCorners:(UIButton *)button
{
	button.layer.cornerRadius = 3.0f;
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
