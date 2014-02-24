//
//  SocialAccountView.h
//  Fit
//
//  Created by Rich on 11/18/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WebServicesEngine.h"

@interface SocialAccountView : UIView

@property (nonatomic, strong) UIImageView *socialAccountMainImageView;
@property (nonatomic, strong) UIImageView *socialAccountFacebookImageView;
@property (nonatomic, strong) UIImageView *socialAccountTwitterImageView;

@property (nonatomic, strong) UILabel *socialAccountTitleLabel;
@property (nonatomic, strong) UILabel *socialAccountAlreadyHaveLabel;
@property (nonatomic, strong) UILabel *socialAccountFacebookButtonLabel;
@property (nonatomic, strong) UILabel *socialAccountTwitterButtonLabel;

@property (nonatomic, strong) UIButton *socialAccountFacebookButton;
@property (nonatomic, strong) UIButton *socialAccountTwitterButton;
@property (nonatomic, strong) UIButton *socialAccountMobiButton;
@property (nonatomic, strong) UIButton *socialAccountSkipButton;

@end
