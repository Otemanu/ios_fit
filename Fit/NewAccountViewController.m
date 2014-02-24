//
//  NewAccountView.m
//  Fit
//
//  Created by Rich on 10/31/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//

// this should be removed later if we continue to use the programatically-created login scroll view

#import "NewAccountViewController.h"

@implementation NewAccountViewController

static int kNewAccountViewTableRowCount = 4;

float storyboardTableViewYOffset = 0.0f;

#pragma mark - Initialization

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];

    if (self)
	{
        // Custom initialization
    }

    return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	[self configureView];
	[self registerForNotifications];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[self unRegisterForNotifications];
}

- (void)configureView
{
	self.accountTableView.layer.cornerRadius = 4.0f;
	self.continueButton.layer.cornerRadius = 4.0f;
	storyboardTableViewYOffset = self.accountTableView.frame.origin.y;
    [self.navigationController setNavigationBarHidden:YES animated:NO];
}

#pragma mark - Text field delegate methods

- (void) textFieldDidBeginEditing:(NSNotification*)aNotification
{
	[self moveTableAboveKeyboard];
}

- (void) textFieldDidChange:(NSNotification*)aNotification
{
	UITextField *field = (UITextField *)aNotification.object;
	NSLog(@"textFieldDidChange: field.text =' %@'", field.text);
}

- (void) textFieldDidEndEditing:(NSNotification *)aNotification
{
}

#pragma mark - Misc input utility methods

// move the whole table above the keyboard when user begins entering account information.
// this is less finicky and annoying than scrolling each cell up over the keyboard as user enters data in each text field.

- (void)moveTableAboveKeyboard
{
	[UIView beginAnimations:nil context:NULL];
	CGRect frame = self.accountTableView.frame;
	frame.origin.y = 80.0f;
	self.accountTableView.frame = frame;
	[UIView commitAnimations];
}

- (void)moveTableToNormalPosition
{
	[UIView beginAnimations:nil context:NULL];
	CGRect frame = self.accountTableView.frame;
	frame.origin.y = storyboardTableViewYOffset;
	self.accountTableView.frame = frame;
	[UIView commitAnimations];
}

- (IBAction)inputDone:(id)sender
{
	[self.fullNameTextField resignFirstResponder];
	[self.emailTextField resignFirstResponder];
	[self.passwordTextField resignFirstResponder];
	[self.retypePasswordTextField resignFirstResponder];
	[self moveTableToNormalPosition];
}

#pragma mark - Table View delegate methods

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
    NewAccountTableViewCell *cell = (NewAccountTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"newAccountViewTableCell"];
 
	if (cell == nil)
    {
        NSArray *Objects = [[NSBundle mainBundle] loadNibNamed:@"newAccountViewTableCell" owner:nil options:nil];
        for(id object in Objects){
            if ([object isKindOfClass:[NewAccountTableViewCell class]]) {
                cell = (NewAccountTableViewCell *) object;
            }
        }
    }
	
	[self configureTextFieldForCell:cell atIndexPath:indexPath];
	return cell;
}

#pragma mark - Table view cell methods

- (void)configureTextFieldForCell:(NewAccountTableViewCell *)newAccountTableViewCell atIndexPath:(NSIndexPath *)indexPath
{
	newAccountTableViewCell.accountTableViewCellTextField.text = nil;
	newAccountTableViewCell.accountTableViewCellTextField.delegate = self;
	
	switch (indexPath.row)
	{
		case 0:
			newAccountTableViewCell.accountTableViewCellTextField.placeholder = NSLocalizedString(@"Full Name", @"Full Name");
			self.fullNameTextField = newAccountTableViewCell.accountTableViewCellTextField;
			break;
		case 1:
			newAccountTableViewCell.accountTableViewCellTextField.placeholder = NSLocalizedString(@"Email", @"Email");
			self.emailTextField = newAccountTableViewCell.accountTableViewCellTextField;
			break;
		case 2:
			newAccountTableViewCell.accountTableViewCellTextField.placeholder = NSLocalizedString(@"Password", @"Password");
			self.passwordTextField = newAccountTableViewCell.accountTableViewCellTextField;
			break;
		case 3:
			newAccountTableViewCell.accountTableViewCellTextField.placeholder = NSLocalizedString(@"Re-Type Password", @"Re-Type Password");
			self.retypePasswordTextField = newAccountTableViewCell.accountTableViewCellTextField;
			break;
		defaul:
			break;
	}
}

#pragma mark - Notifications

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


#pragma mark - Memory

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
