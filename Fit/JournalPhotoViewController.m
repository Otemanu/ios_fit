//
//  JournalPhotoViewController.m
//  Fit
//
//  Created by Rich on 2/13/14.
//  Copyright (c) 2014 mobifusion. All rights reserved.
//

#import "JournalPhotoViewController.h"

@interface JournalPhotoViewController ()

@property IBOutlet UIButton *journalPhotoViewDoneButton;
@property IBOutlet UIButton *journalPhotoViewEmoticonButton;
@property IBOutlet JournalPhotoEmoticonView *journalEmoticonEmoticonView;
@property IBOutlet UIScrollView *journalPhotoViewScrollView;				// scrollview containing user's photos if we want to allow flicking thorugh full-sized photos

@end

@implementation JournalPhotoViewController

#pragma mark - Private constants

const float kPickerViewWidth = 200.0f;
const float kPickerViewHeight = 150.0f;
const float kPickerYOffset = 250.0f;

#pragma mark - Initialization

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	
    if (self)
	{
	}

    return self;
}

- (void)fetchJournalImage
{
	ALAssetsLibraryAssetForURLResultBlock resultblock = ^(ALAsset *imageAsset)
	{
		ALAssetRepresentation *assetRepresentation = imageAsset.defaultRepresentation;
		UIImageOrientation orientation = (UIImageOrientation)assetRepresentation.orientation;
		UIImage *journalImage = [UIImage imageWithCGImage:assetRepresentation.fullResolutionImage scale:1.0 orientation:orientation];
		UIImageView *journalImageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
		journalImageView.image = [self imageWithImage:journalImage scaledToFillRect:self.view.bounds forOrientation:orientation];
		journalImageView.alpha = 0.0f;
		[self.journalPhotoViewScrollView addSubview:journalImageView];
		
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationDuration:0.4f];
		journalImageView.alpha = 1.0f;
		[UIView commitAnimations];
	};
	
	ALAssetsLibraryAccessFailureBlock failureblock = ^(NSError *error )
	{
		NSLog(@"ALAssetsLibraryAccessFailureBlock: error %@", error);
	};
	
	[self.assetsLibrary assetForURL:self.journalPhotoAssetURL resultBlock:resultblock failureBlock:failureblock];
}

- (void)configureView
{
	self.journalPhotoViewScrollView.backgroundColor = [UIColor blackColor];
	
	self.view.backgroundColor = [UIColor blackColor];
	
	self.journalPhotoViewDoneButton.backgroundColor = [UIColor colorWithWhite:0.2f alpha:0.7f];
	self.journalPhotoViewDoneButton.layer.borderColor = [[UIColor colorWithWhite:0.5f alpha:0.7f] CGColor];
	self.journalPhotoViewDoneButton.layer.borderWidth = 1.0f;
	self.journalPhotoViewDoneButton.layer.cornerRadius = self.journalPhotoViewDoneButton.frame.size.width / 2.0f;
	[self.journalPhotoViewDoneButton setTitle:@"X" forState:UIControlStateNormal];
	self.journalPhotoViewDoneButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:16.0f];
	[self.journalPhotoViewDoneButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	self.journalPhotoViewDoneButton.enabled = YES;

	self.journalPhotoViewEmoticonButton.backgroundColor = [UIColor colorWithWhite:0.2f alpha:0.7f];
	self.journalPhotoViewEmoticonButton.layer.borderColor = [[UIColor colorWithWhite:0.5f alpha:0.7f] CGColor];
	self.journalPhotoViewEmoticonButton.layer.borderWidth = 1.0f;
	self.journalPhotoViewEmoticonButton.layer.cornerRadius = self.journalPhotoViewEmoticonButton.frame.size.width / 2.0f;
	[self.journalPhotoViewEmoticonButton setTitle:@":-)" forState:UIControlStateNormal];			// zzzzz temporarily use text emoticons in the buttons' label until we have real image assets
	self.journalPhotoViewEmoticonButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:16.0f];
	[self.journalPhotoViewEmoticonButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	self.journalPhotoViewEmoticonButton.enabled = YES;

	self.journalEmoticonEmoticonView.backgroundColor = [UIColor colorWithWhite:1.0f alpha:1.0f];
	self.journalEmoticonEmoticonView.layer.cornerRadius = 8.0f;
	self.journalEmoticonEmoticonView.alpha = 0.0f;
	[self.view addSubview:self.journalEmoticonEmoticonView];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	[self configureView];
}

- (void)viewWillAppear:(BOOL)animated
{
	[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
	[self updateEmoticonImage];
	[self fetchJournalImage];
}

#pragma mark - Image manipulation

- (UIImage *)imageWithImage:(UIImage *)image scaledToFillRect:(CGRect)photoRect forOrientation:(UIImageOrientation)orientation
{
	CGFloat photoWidth = 0.0f;
	CGFloat photoHeight = 0.0f;
	CGFloat imageWidth = 0.0f;
	CGFloat imageHeight = 0.0f;
	
	if (orientation == UIImageOrientationUp || orientation == UIImageOrientationDown)		// landscape orientations
	{
		photoWidth = photoRect.size.height;													// we rotate 90 clockwise later for landscape, so we need to flip width and height
		photoHeight = photoRect.size.width;
		imageWidth = image.size.height;
		imageHeight = image.size.width;
	}
	else
	{
		photoWidth = photoRect.size.width;
		photoHeight = photoRect.size.height;
		imageWidth = image.size.width;
		imageHeight = image.size.height;
	}

	CGFloat scale = 1.0f;																	// we may need to scale the image to fit the screen
    CGFloat scaledWidth = 0.0f;
    CGFloat scaledHeight = 0.0f;
	
	if (orientation == UIImageOrientationUp || orientation == UIImageOrientationDown)
	{
		scale = MIN(photoWidth/imageHeight, photoHeight/imageWidth);
		scaledWidth = imageHeight * scale;
		scaledHeight = imageWidth * scale;
	}
	else
	{
		scale = MIN(photoWidth/imageWidth, photoHeight/imageHeight);
		scaledWidth = imageWidth * scale;
		scaledHeight = imageHeight * scale;
	}

    CGRect imageRect = CGRectMake((photoWidth - scaledWidth)/2.0f,							// we always fill the screen either horizontally or vertically, then center the image on the other axis
                                  (photoHeight - scaledHeight)/2.0f,
                                  scaledWidth,
                                  scaledHeight);
	
	// note: rotation pivots clockwise around top left corner, m_pi / 2 means 90 degree clockwise rotation
	// note: UIImageOrientationUp means "photo taken in landscape orientation with camera at top"
	//	  UIImageOrientationRight means "photo taken in portrait orientation with camera at top"
	
    UIGraphicsBeginImageContextWithOptions(photoRect.size, NO, 0);

	if (orientation == UIImageOrientationUp || orientation == UIImageOrientationDown)		// rotate and adjust image position if photo was taken in landscape orientation
	{
		imageRect.origin.x = (self.view.bounds.size.height - scaledWidth) / 2.0f;
		imageRect.origin.y = (- scaledHeight - ((self.view.bounds.size.width - scaledHeight) / 2.0f));
		CGContextRotateCTM(UIGraphicsGetCurrentContext(), M_PI / 2);
	}

    [image drawInRect:imageRect];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

#pragma mark - Button actions

- (IBAction)doneButtonTapped:(id)sender
{
	[self dismissViewControllerAnimated:YES completion:^{
	}];
}

- (IBAction)emoticonButtonTapped:(id)sender
{
	self.journalEmoticonEmoticonView.hidden = NO;
	[self fadeEmoticonViewToAlpha:1.0f];
}

- (IBAction)happyButtonTapped:(id)sender
{
	if (self.emotionalStateIndex != kHappy)
	{
		self.emotionalStateIndex = kHappy;
		[self updateEmoticonImage];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"emoticonButtonTappedNotification" object:[NSNumber numberWithInt:self.emotionalStateIndex]];
	}
}

- (IBAction)neutralButtonTapped:(id)sender
{
	if (self.emotionalStateIndex != kNeutral)
	{
		self.emotionalStateIndex = kNeutral;
		[self updateEmoticonImage];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"emoticonButtonTappedNotification" object:[NSNumber numberWithInt:self.emotionalStateIndex]];
	}
}

- (IBAction)unhappyButtonTapped:(id)sender
{
	if (self.emotionalStateIndex != kUnhappy)
	{
		self.emotionalStateIndex = kUnhappy;
		[self updateEmoticonImage];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"emoticonButtonTappedNotification" object:[NSNumber numberWithInt:self.emotionalStateIndex]];
	}
}

- (IBAction)cancelButtonTapped:(id)sender
{
	[self fadeEmoticonViewToAlpha:0.0f];
}

- (IBAction)okButtonTapped:(id)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName:@"emoticonViewOKButtonTappedNotification" object:nil];
	[self fadeEmoticonViewToAlpha:0.0f];
}

#pragma mark - Utility methods

- (void)updateEmoticonImage
{
	// zzzzz temporarily use text emoticon until we have real images
	NSString *emoticonString;
	
	if (self.emotionalStateIndex == kHappy)
		emoticonString = @":-)";
	else if (self.emotionalStateIndex == kNeutral)
		emoticonString = @":-|";
	else
		emoticonString = @":-(";

	[self.journalPhotoViewEmoticonButton setTitle:emoticonString forState:UIControlStateNormal];
}

- (void)fadeEmoticonViewToAlpha:(float)alpha
{
	[UIView beginAnimations:nil context:NULL];
	self.journalEmoticonEmoticonView.alpha = alpha;
	[UIView commitAnimations];
}

#pragma mark - Memory

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
