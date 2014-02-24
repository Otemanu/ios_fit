//
//  PosesViewController.m
//  Fit
//
//  Created by Rich on 2/21/14.
//  Copyright (c) 2014 mobifusion. All rights reserved.
//

// to-do:
//	- determine how many pre-built routines to include (just two? sample 1 and sample 2?)
//	- determine how many views we need to navigate to:
//		1. All Poses
//		2. pre-built read-only "recommended" routines put together by the author
//		3. user-built editable routines (add poses, remove poses, re-order poses, delete entire routine, re-order routines in view)
//		4? favorite poses?
//		5? favorite routines?
//	- pre-built routines and user-built routines can be the same view, just read-only for the pre-built ones from the author
//	- will user be able to remove the suggested routines? if so, can they get them back with a "reset" or "clear all" option?

#import "PosesViewController.h"

@interface PosesViewController ()

@property (strong, nonatomic) UILabel *posesViewTitleLabel;

@property NSIndexPath *currentIndexPath;

@end

@implementation PosesViewController

#pragma mark - Private constants and variables

static int rowCount = 3;										// row 0: "all poses," row 1: morning routine, row 2: afternoon routine
static const float kTableRowHeight = 80.0f;
static NSString *kCellIdentifier = @"PosesViewTableCell";
static NSString *kAllPosesImageName = @"PosesAll";
static NSString *kMorningRoutineImageName = @"PosesMorning";
static NSString *kAfternoonRoutineImageName = @"PosesAfternoon";
static NSString *kAllPosesLabelText = @"All Poses";
static NSString *kMorningRoutineLabelText = @"Morning Routine";
static NSString *kAfternoonRoutineLabelText = @"Afternoon Routine";

#pragma mark - Initialization

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
	
    if (self)
	{
        // Custom initialization
    }
	
    return self;
}

- (void)initTitle
{
	if (self.posesViewTitleLabel == nil)
	{
		float insetWidth = 100.0f;
		CGFloat titleWidth = self.view.frame.size.width - (insetWidth * 2.0f);
		CGFloat titleHeight = self.navigationController.navigationBar.frame.size.height;
		CGRect titleRect = CGRectMake(insetWidth, 0.0f, titleWidth, titleHeight);
		self.posesViewTitleLabel = [[UILabel alloc] initWithFrame:titleRect];
		self.posesViewTitleLabel.text = @"YOGALOSOPHY";
		self.posesViewTitleLabel.textColor = [UIColor grayColor];
		self.posesViewTitleLabel.textAlignment = NSTextAlignmentCenter;
		self.posesViewTitleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:20.0f];
		[self.navigationItem setTitleView:self.posesViewTitleLabel];
	}
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	[self initTitle];
    self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated
{
	if (self.currentIndexPath == nil)
		self.currentIndexPath = [NSIndexPath indexPathForItem:0 inSection:0];
	
	[self hideTableCells];
	[self showTableCells];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return rowCount;
}

//- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
//{
//}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    PosesViewTableCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier forIndexPath:indexPath];
    
	if (indexPath.row == 0)
	{
		cell.posesCellImageView.image = [UIImage imageNamed:kAllPosesImageName];
		cell.posesCellLabel.text = NSLocalizedString(kAllPosesLabelText, kAllPosesLabelText);
		cell.posesCellLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:22.0f];
	}
	else if (indexPath.row == 1)
	{
		cell.posesCellImageView.image = [UIImage imageNamed:kMorningRoutineImageName];
		cell.posesCellLabel.text = NSLocalizedString(kMorningRoutineLabelText, kMorningRoutineLabelText);
		cell.posesCellLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:20.0f];
	}
	else if (indexPath.row == 2)
	{
		cell.posesCellImageView.image = [UIImage imageNamed:kAfternoonRoutineImageName];
		cell.posesCellLabel.text = NSLocalizedString(kAfternoonRoutineLabelText, kAfternoonRoutineLabelText);
		cell.posesCellLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:20.0f];
	}
    
    return cell;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	self.currentIndexPath = indexPath;
	return indexPath;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	PosesViewTableCell *cell = (PosesViewTableCell *)[tableView cellForRowAtIndexPath:indexPath];
	cell.posesCellLabel.textColor = [UIColor whiteColor];
	cell.posesCellBackgroundView.backgroundColor = [UIColor orangeColor];
	// zzzzz figure out why we can't set an arbitrary color here.  only well-known color names work.
//	cell.posesCellBackgroundView.backgroundColor = [UIColor colorWithRed:214.0f green:95.0f blue:144.0f alpha:1.0f];
	
	if (indexPath.row == 0)
		[self performSegueWithIdentifier:@"segueFromPosesViewToPosesTable" sender:self];
	else
		[self performSegueWithIdentifier:@"segueFromPosesViewToRoutineTable" sender:self];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
	PosesViewTableCell *cell = (PosesViewTableCell *)[tableView cellForRowAtIndexPath:indexPath];
	cell.posesCellLabel.textColor = [UIColor blackColor];
	cell.posesCellBackgroundView.backgroundColor = [UIColor clearColor];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return kTableRowHeight;
}

#pragma mark - Table cell animation

- (void)showTableCells
{
	for (int rowIndex = 0; rowIndex < rowCount; rowIndex++)
	{
		NSIndexPath *indexPath = [NSIndexPath indexPathForItem:rowIndex inSection:0];
		PosesViewTableCell *posesCell = (PosesViewTableCell *)[self.tableView cellForRowAtIndexPath:indexPath];
		[self showCell:posesCell forIndexPath:indexPath];
	}
}

- (void)showCell:(PosesViewTableCell *)posesCell forIndexPath:(NSIndexPath *)indexPath
{
	float delayFloat = indexPath.row * 0.1f;
	
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delayFloat * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
		[self performCellAnimation:posesCell];
	});
}

- (void)performCellAnimation:(PosesViewTableCell *)posesCell
{
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.4f];
	posesCell.alpha = 1.0f;
	[UIView commitAnimations];
}

- (void)hideTableCells
{
	for (int rowIndex = 0; rowIndex < rowCount; rowIndex++)
	{
		NSIndexPath *indexPath = [NSIndexPath indexPathForItem:rowIndex inSection:0];
		PosesViewTableCell *posesCell = (PosesViewTableCell *)[self.tableView cellForRowAtIndexPath:indexPath];
		posesCell.alpha = 0.0f;
	}
}

#pragma mark - Table view delegate methods

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSLog(@"prepareForSegue:%@", segue);
}

#pragma mark - Memory

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
