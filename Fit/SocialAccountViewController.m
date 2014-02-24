//
//  SocialAccountViewController.m
//  Fit
//
//  Created by Rich on 10/31/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//

// this should be removed later if we continue to use the programatically-created login scroll view

#import "SocialAccountViewController.h"
#import "AppDelegate.h"
#import "WebServicesEngine.h"


@interface SocialAccountViewController ()

@end
WebServicesEngine *socialAccountWebServicesEngine = nil;								// pointer to singleton

@implementation SocialAccountViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{

    [super viewDidLoad];
	[self initWebServicesEngine];
}

#pragma mark - Web services engine (singleton)

- (void)initWebServicesEngine
{
	socialAccountWebServicesEngine = [WebServicesEngine webServicesEngine];				// instantiates a singleton web services engine for use by all views
}

#pragma mark - Navigation

- (IBAction)skipButtonTapped:(id)sender
{
	[self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if (segue.identifier && [segue.identifier isEqualToString:@"skipButtonSegue"])
	{
		[socialAccountWebServicesEngine requestLoginWithAnonymousAccount];
	}
//	else if (segue.idetifier && [segue.identifier isEqualToString:@"fbButtonSegue"])
//	{
//		[socialAccountWebServicesEngine requestLoginWithAnonymousAccount];
//	}
//	etc.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
