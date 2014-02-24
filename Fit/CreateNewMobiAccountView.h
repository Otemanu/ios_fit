//
//  NewAccountView.h
//  Fit
//
//  Created by Rich on 11/18/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NewAccountTableViewCell.h"
#import "WebServicesEngine.h"

@interface CreateNewMobiAccountView : UIView <UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UIImageView *createMobiAccountImageView;

@property (nonatomic, strong) UILabel *createMobiAccountTitle;

@property (nonatomic, strong) UITableView *createMobiAccountTableView;

@property (nonatomic, strong) UIButton *createMobiAccountContinueButton;
@property (nonatomic, strong) UIButton *createMobiAccountInputDoneButton;

@property (nonatomic, strong) UITextField *createMobiAccountFullNameTextField;
@property (nonatomic, strong) UITextField *createMobiAccountEmailTextField;
@property (nonatomic, strong) UITextField *createMobiAccountPasswordTextField;
@property (nonatomic, strong) UITextField *createMobiAccountRetypePasswordTextField;

@property (nonatomic, strong) UIScrollView *createMobiAccountTableScrollView;		// allows the table to scroll up above keyboard

@end
