//
//  SocialAccountViewController.h
//  Fit
//
//  Created by Rich on 10/31/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//

// this should be removed later if we continue to use the programatically-created login scroll view

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
@interface SocialAccountViewController : UIViewController
{

    AppDelegate *sharedDelegate;

}
@property IBOutlet UIButton *facebookButton;
@property IBOutlet UIButton *twitterButton;
@property IBOutlet UIButton *createAccountButton;
@property IBOutlet UIButton *existingLoginButton;
@property IBOutlet UIButton *skipLoginButton;

- (IBAction)skipButtonTapped:(id)sender;

@end
