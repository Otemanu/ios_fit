//
//  NewAccountView.h
//  Fit
//
//  Created by Rich on 10/31/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//

// this should be removed later if we continue to use the programatically-created login scroll view

#import <UIKit/UIKit.h>
#import "NewAccountTableViewCell.h"

@interface NewAccountViewController : UIViewController <UITextFieldDelegate>

@property IBOutlet UITableView *accountTableView;
@property IBOutlet UIButton *accountViewDoneButton;

@property UITextField *fullNameTextField;
@property UITextField *emailTextField;
@property UITextField *passwordTextField;
@property UITextField *retypePasswordTextField;

@property IBOutlet UIButton *continueButton;

- (IBAction)inputDone:(id)sender;

@end
