//
//  SettingsViewController
//  Fit
//
//  Created by Rich on 10/31/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIImage+ImageEffects.h"
#import "LoginScrollView.h"

@interface SettingsViewController : UIViewController <UIScrollViewDelegate>

@property IBOutlet UIImageView *settingsAvatarImageView;

@property IBOutlet UIView *settingsAvatarMaskView;
@property IBOutlet UIView *settingsAvatarBackgroundView;
@property IBOutlet UIView *settingsAvatarShadowView;
@property IBOutlet UIView *backgroundView;
@property IBOutlet UILabel *settingsUsername;

@property IBOutlet UIButton *settingsLogoutButton;
@property IBOutlet UIButton *settingsResetButton;

- (IBAction)logoutButtonPressed:(id)sender;
- (IBAction)resetProgressButtonPressed:(id)sender;

@end
