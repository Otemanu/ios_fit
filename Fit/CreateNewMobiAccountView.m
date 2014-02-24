//
//  NewAccountView.m
//  Fit
//
//  Created by Rich on 11/18/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//

#import "CreateNewMobiAccountView.h"

static float kEdgeMargin = 20.0f;
static float kButtonHeight = 40.0f;
static float kButtonTextFontSize = 15.0f;

static int kNewAccountViewTableRowCount = 4;
static int kMinimumNameLength = 2;
static int kMaximumNameLength = 100;
static int kMinimumPasswordLength = 6;
static int kMaximumPasswordLength = 100;
static int kPasswordRowIndex = 2;
static int kRetypePasswordRowIndex = 3;

static NSString *kTableCellReuseIdentifier = @"newAccountViewTableCell";

float tableViewNormalYOffset = 270.0f;
float tableViewEditingYOffset = 140.0f;

WebServicesEngine *createNewMobiAccountViewWebServicesEngine = nil;

@implementation CreateNewMobiAccountView

#pragma mark - Initialization

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    if (self)
	{
 		CGRect viewFrame = self.frame;
		[self initYOffsets];
		[self initNewAccountPageImageWithFrame:viewFrame];
		[self initNewAccountPageTitleWithFrame:viewFrame];
		[self initNewAccountPageTableWithFrame:viewFrame];
		[self initNewAccountPageContinueButtonWithFrame:viewFrame];
		[self initNewAccountPageInputDoneButtonWithFrame:viewFrame];
		[self initWebServicesEngine];
   }

    return self;
}

- (void)initNewAccountPageImageWithFrame:(CGRect)viewFrame
{
	self.createMobiAccountImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"loginPageImage5"]];
	CGRect itemFrame = self.createMobiAccountImageView.frame;
	itemFrame.size.width = 150.0f;
	itemFrame.size.height = 150.0f;
	itemFrame.origin.x = (viewFrame.size.width / 2.0f) - (itemFrame.size.width / 2.0f);
	itemFrame.origin.y = 80.0f;
	self.createMobiAccountImageView.frame = itemFrame;
	[self addSubview:self.createMobiAccountImageView];
}

- (void)initNewAccountPageTitleWithFrame:(CGRect)viewFrame
{
	if (viewFrame.size.height < 568.0f)
		return;
	
	self.createMobiAccountTitle = [[UILabel alloc] initWithFrame:CGRectMake(kEdgeMargin, 140.0f, viewFrame.size.width - (kEdgeMargin * 2.0f), 150.0f)];
	self.createMobiAccountTitle.text = @" ";
	self.createMobiAccountTitle.textColor = [UIColor whiteColor];
	self.createMobiAccountTitle.font = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:70.0f];
	self.createMobiAccountTitle.textAlignment = NSTextAlignmentCenter;
	[self addSubview:self.createMobiAccountTitle];
}

- (void)initNewAccountPageTableWithFrame:(CGRect)viewFrame
{
	CGRect tableRect = viewFrame;
	tableRect.origin = CGPointMake(kEdgeMargin, tableViewNormalYOffset);
	tableRect.size = CGSizeMake(viewFrame.size.width - (kEdgeMargin * 2.0f), 200.0f);
	self.createMobiAccountTableView = [[UITableView alloc] initWithFrame:tableRect style:UITableViewStylePlain];
	self.createMobiAccountTableView.delegate = self;
	self.createMobiAccountTableView.dataSource = self;
	self.createMobiAccountTableView.userInteractionEnabled = YES;
	self.createMobiAccountTableView.scrollEnabled = NO;
	self.createMobiAccountTableView.layer.cornerRadius = 3.0f;
	[self addSubview:self.createMobiAccountTableView];
}

- (void)initNewAccountPageContinueButtonWithFrame:(CGRect)viewFrame
{
	self.createMobiAccountContinueButton = [UIButton buttonWithType:UIButtonTypeCustom];
	CGRect buttonFrame = self.createMobiAccountContinueButton.frame;
	buttonFrame.size = CGSizeMake(viewFrame.size.width - (kEdgeMargin * 2.0f), kButtonHeight);
	buttonFrame.origin = CGPointMake(kEdgeMargin, self.createMobiAccountTableView.frame.origin.y + self.createMobiAccountTableView.frame.size.height + 15.0f);
	self.createMobiAccountContinueButton.frame = buttonFrame;
	[self.createMobiAccountContinueButton setTitle:NSLocalizedString(@"Continue", @"Continue") forState:UIControlStateNormal];
	self.createMobiAccountContinueButton.titleLabel.font = [UIFont systemFontOfSize:kButtonTextFontSize];
	[self.createMobiAccountContinueButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
	[self.createMobiAccountContinueButton addTarget:self action:@selector(handleContinueButtonTap) forControlEvents:UIControlEventTouchUpInside];
	self.createMobiAccountContinueButton.backgroundColor = [UIColor colorWithRed:0.4f green:0.5f blue:1.0f alpha:1.0f];
	self.createMobiAccountContinueButton.layer.cornerRadius = 3.0f;
	[self addSubview:self.createMobiAccountContinueButton];
}

- (void) initNewAccountPageInputDoneButtonWithFrame:(CGRect)viewFrame
{
	self.createMobiAccountInputDoneButton = [UIButton buttonWithType:UIButtonTypeCustom];
	CGRect buttonFrame = self.createMobiAccountInputDoneButton.frame;
	buttonFrame.size = CGSizeMake(60.0f, kButtonHeight);
	float yOffset = (viewFrame.size.height == 568.0f) ? 25.0f : 15.0f;
	buttonFrame.origin = CGPointMake(260.0f, yOffset);
	self.createMobiAccountInputDoneButton.frame = buttonFrame;
	[self.createMobiAccountInputDoneButton setTitle:NSLocalizedString(@"Done", @"Done") forState:UIControlStateNormal];
	[self.createMobiAccountInputDoneButton setTitleColor:[UIColor colorWithRed:0.5f green:0.5f blue:1.0f alpha:1.0f] forState:UIControlStateNormal];
	[self.createMobiAccountInputDoneButton setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
	[self.createMobiAccountInputDoneButton addTarget:self action:@selector(inputDone) forControlEvents:UIControlEventTouchUpInside];
	self.createMobiAccountInputDoneButton.enabled = NO;
	self.createMobiAccountInputDoneButton.layer.opacity = 0.0f;			// hide button until user has actually typed into a text field
	[self addSubview:self.createMobiAccountInputDoneButton];
}

- (void)initWebServicesEngine
{
	createNewMobiAccountViewWebServicesEngine = [WebServicesEngine webServicesEngine];
}

- (void)initYOffsets
{
	// quick adjustment for the two current iphone screen sizes.  will need to change when apple releases higher-res iPhone in fall 2014.
	tableViewNormalYOffset = (self.frame.size.height == 568.0f) ? 270.0f : 180.0f;
	tableViewEditingYOffset = (self.frame.size.height == 568.0f) ? 140.0f : 52.0f;
}

#pragma mark - Misc utility methods

// move the whole table above the keyboard when user begins entering account information.
// this is less finicky and annoying than scrolling each cell up over the keyboard as user enters data in each text field.

- (void)moveTableAboveKeyboard
{
	[UIView beginAnimations:nil context:NULL];
	CGRect frame = self.createMobiAccountTableView.frame;
	frame.origin.y = tableViewEditingYOffset;
	self.createMobiAccountTableView.frame = frame;
	[UIView commitAnimations];
}

- (void)moveTableToNormalPosition
{
	[UIView beginAnimations:nil context:NULL];
	CGRect frame = self.createMobiAccountTableView.frame;
	frame.origin.y = tableViewNormalYOffset;
	self.createMobiAccountTableView.frame = frame;
	[UIView commitAnimations];
}

- (void)inputDone
{
	[self.createMobiAccountFullNameTextField resignFirstResponder];
	[self.createMobiAccountEmailTextField resignFirstResponder];
	[self.createMobiAccountPasswordTextField resignFirstResponder];
	[self.createMobiAccountRetypePasswordTextField resignFirstResponder];
	[self moveTableToNormalPosition];

	[UIView beginAnimations:nil context:NULL];
	self.createMobiAccountInputDoneButton.layer.opacity = 0.0f;
	self.createMobiAccountInputDoneButton.enabled = NO;
	[UIView commitAnimations];
}

- (void)showDoneButton
{
	[UIView beginAnimations:nil context:NULL];
	self.createMobiAccountInputDoneButton.layer.opacity = 1.0f;
	self.createMobiAccountInputDoneButton.enabled = YES;
	[UIView commitAnimations];
}

- (void)handleContinueButtonTap
{
	if ([self allUserInputIsOK])
	{
		NSDictionary *accountDataDict = [NSDictionary dictionaryWithObjectsAndKeys:
										 self.createMobiAccountFullNameTextField.text, @"name",					// these keys must match those in web services engine
										 self.createMobiAccountEmailTextField.text, @"email",
										 self.createMobiAccountPasswordTextField.text, @"password",
										 @"1", @"ageCheck",
										 nil];
		[createNewMobiAccountViewWebServicesEngine requestLoginWithRealAccount:accountDataDict];				// send new account data to web services engine
		// don't dismiss the login view until the server returns a user info message and no error (e.g. no already-used email error etc.)
//		[[NSNotificationCenter defaultCenter] postNotificationName:@"loginViewDoneNotification" object:nil];
	}
	else
	{
		[self showAlertWithTitle:@"Incomplete account" messageString:@"Please fill in all fields"];
	}
}

- (BOOL)allUserInputIsOK
{
	BOOL allOK = YES;
	
	allOK = [self checkAllFieldsForInputText];					// let the user continue if they don't want to fill in all the fields
	
	if (allOK)
		allOK = [self checkInputTextForErrors];					// but if they've filled in all fields, don't continue until everything is OK

	return allOK;
}

- (BOOL)checkAllFieldsForInputText
{
	BOOL allTextExists = YES;
	
	if (self.createMobiAccountFullNameTextField.text == nil || self.createMobiAccountFullNameTextField.text.length == 0)
		allTextExists = NO;
	
	if (self.createMobiAccountEmailTextField.text == nil || self.createMobiAccountEmailTextField.text.length == 0)
		allTextExists = NO;
	
	if (self.createMobiAccountPasswordTextField.text == nil || self.createMobiAccountPasswordTextField.text.length == 0)
		allTextExists = NO;
	
	if (self.createMobiAccountRetypePasswordTextField.text == nil || self.createMobiAccountRetypePasswordTextField.text.length == 0)
		allTextExists = NO;
	
	return allTextExists;
}

- (BOOL)checkInputTextForErrors
{
	BOOL inputAllOK = YES;
	
	if ([self verifyNameCorrectness] == NO)
	{
		[self showAlertWithTitle:@"Full Name" messageString:@"Please enter a longer name"];
		inputAllOK = NO;
	}
	
	if (inputAllOK && [self verifyEmailCorrectness] == NO)
	{
		[self showAlertWithTitle:@"Email" messageString:@"Please enter a valid email address"];
		inputAllOK = NO;
	}
	
	if (inputAllOK && [self verifyPasswordCorrectness] == NO)
	{
		[self showAlertWithTitle:@"Password" messageString:@"Please enter a longer password"];
		inputAllOK = NO;
	}

	if (inputAllOK && [self verifyRetypedPasswordCorrectness] == NO)
	{
		[self showAlertWithTitle:@"Re-Type Password" messageString:@"Please make sure the password and re-typed passwords are the same"];
		inputAllOK = NO;
	}

	return inputAllOK;
}

- (BOOL)verifyNameCorrectness
{
	int nameLength = self.createMobiAccountFullNameTextField.text.length;
	BOOL nameOK = (nameLength >= kMinimumNameLength) && (nameLength <= kMaximumNameLength);
	return nameOK;
}

- (BOOL)verifyEmailCorrectness
{
	BOOL emailOK = YES;
	
	if (self.createMobiAccountEmailTextField.text.length < 6)
		emailOK = NO;
	
	emailOK = [self emailIsValid];
	return emailOK;
}

// note: this method checks basic email address correctness, but still allows addresses like "john@abc.xyzzy" which has an invalid top-level domain name.
// this may be ok for now, but there should be a way for a user to go back and edit their account data later if they mis-type their email address.

- (BOOL)emailIsValid
{
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\\.)+[a-z0-9]?"
																		   options:0
																			 error:&error];
//	NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[A-Z]{2}|com|org|net|edu|gov|mil|biz|info|mobi|name|aero|asia|jobs|museum)?"
//																		   options:0
//																			 error:&error];
	NSString *lowerCaseEmailString = [self.createMobiAccountEmailTextField.text lowercaseStringWithLocale:[NSLocale currentLocale]];
	NSUInteger numberOfMatches = [regex numberOfMatchesInString:lowerCaseEmailString options:0 range:NSMakeRange(0, lowerCaseEmailString.length)];
    return (numberOfMatches > 0);
}

// note: we could enforce a "at least one capital plus at least one lower-case plus at least one number" password rule here if we want

- (BOOL)verifyPasswordCorrectness
{
	int passwordLength = self.createMobiAccountPasswordTextField.text.length;
	BOOL passwordOK = (passwordLength >= kMinimumPasswordLength && passwordLength <= kMaximumPasswordLength);
	return passwordOK;
}

- (BOOL)verifyRetypedPasswordCorrectness
{
	BOOL retypedPasswordOK = YES;
	int retypedPasswordLength = self.createMobiAccountPasswordTextField.text.length;

	if (retypedPasswordLength <= kMinimumPasswordLength || retypedPasswordLength >= kMaximumPasswordLength)
		retypedPasswordOK = NO;
	
	if (retypedPasswordOK)
		retypedPasswordOK = [self.createMobiAccountRetypePasswordTextField.text isEqualToString:self.createMobiAccountPasswordTextField.text];
	
	return retypedPasswordOK;
}

#pragma mark - Alert popup

- (void) showAlertWithTitle:(NSString *)titleString messageString:(NSString *)messageString
{
	NSString *localizedMessage = NSLocalizedString(messageString, messageString);
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:titleString
													message:localizedMessage
												   delegate:self
										  cancelButtonTitle:@"OK"
										  otherButtonTitles:nil];
	[alert show];
}

- (void) alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	// probably not needed, but here it is anyway
}

#pragma mark - Table delegate methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return kNewAccountViewTableRowCount;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	return 0.0f;
}

- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
	return 0.0f;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50.0f;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NewAccountTableViewCell *cell = (NewAccountTableViewCell *)[tableView dequeueReusableCellWithIdentifier:kTableCellReuseIdentifier];
	
	if (cell == nil)
	{
        cell = [[NewAccountTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kTableCellReuseIdentifier];
		CGRect cellFrame = CGRectMake(20.0f, 5.0f, 240.0f, 40.0f);
		cell.accountTableViewCellTextField = [[UITextField alloc] initWithFrame:cellFrame];
		
		if (indexPath.row == kPasswordRowIndex || indexPath.row == kRetypePasswordRowIndex)
			cell.accountTableViewCellTextField.secureTextEntry = YES;
		
		[cell addSubview:cell.accountTableViewCellTextField];
	}
	
	cell.userInteractionEnabled = YES;
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	[self configureTextFieldForCell:cell atIndexPath:indexPath];
	return cell;
}

#pragma mark - Text field delegate methods

- (void) textFieldDidBeginEditing:(NSNotification*)aNotification
{
	[self moveTableAboveKeyboard];
	[self showDoneButton];
}

- (void) textFieldDidChange:(NSNotification*)aNotification
{
//	UITextField *field = (UITextField *)aNotification.object;
}

- (void) textFieldDidEndEditing:(NSNotification *)aNotification
{
//	UITextField *field = (UITextField *)aNotification.object;
}

#pragma mark - Table view cell methods

- (void)configureTextFieldForCell:(NewAccountTableViewCell *)newMobiAccountTableViewCell atIndexPath:(NSIndexPath *)indexPath
{
	newMobiAccountTableViewCell.accountTableViewCellTextField.text = nil;
	newMobiAccountTableViewCell.accountTableViewCellTextField.delegate = self;
	newMobiAccountTableViewCell.accountTableViewCellTextField.userInteractionEnabled = YES;
	
	switch (indexPath.row)
	{
		case 0:
			newMobiAccountTableViewCell.accountTableViewCellTextField.placeholder = NSLocalizedString(@"Full Name", @"Full Name");
			self.createMobiAccountFullNameTextField = newMobiAccountTableViewCell.accountTableViewCellTextField;
			break;
		case 1:
			newMobiAccountTableViewCell.accountTableViewCellTextField.placeholder = NSLocalizedString(@"Email", @"Email");
			self.createMobiAccountEmailTextField = newMobiAccountTableViewCell.accountTableViewCellTextField;
			break;
		case 2:
			newMobiAccountTableViewCell.accountTableViewCellTextField.placeholder = NSLocalizedString(@"Password", @"Password");
			self.createMobiAccountPasswordTextField = newMobiAccountTableViewCell.accountTableViewCellTextField;
			break;
		case 3:
			newMobiAccountTableViewCell.accountTableViewCellTextField.placeholder = NSLocalizedString(@"Re-Type Password", @"Re-Type Password");
			self.createMobiAccountRetypePasswordTextField = newMobiAccountTableViewCell.accountTableViewCellTextField;
			break;
		defaul:
			break;
	}
}

- (void) registerForNotifications
{
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(textFieldDidBeginEditing:)
												 name:UITextFieldTextDidBeginEditingNotification
											   object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(textFieldDidChange:)
												 name:UITextFieldTextDidChangeNotification
											   object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(textFieldDidEndEditing:)
												 name:UITextFieldTextDidEndEditingNotification
											   object:nil];
}

- (void) unRegisterForNotifications
{
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:UITextFieldTextDidBeginEditingNotification
												  object:nil];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:UITextFieldTextDidChangeNotification
												  object:nil];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:UITextFieldTextDidEndEditingNotification
												  object:nil];
}

- (void)dealloc
{
	[self unRegisterForNotifications];
}

@end
