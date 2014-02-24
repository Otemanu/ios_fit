//
//  TimelineViewController
//  Fit
//
//  Created by Rich on 10/31/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//

#import "TimelineViewController.h"
#import "ReadViewController.h"
#import "CustomerDataEngine.h"
#import "WebServicesEngine.h"

@interface TimelineViewController ()

@end

@implementation TimelineViewController

// note: we need to use data directly from the ChapterDataController singleton's array-of-arrays.  we'll use that in the timeline data source.
// but the timeline view only has two sections: section 0, which contains only chapters that are partially or fully read, and section 1, which
// contains the chapter the user is currently reading along with the first unread chapters and all subsequent chapters, whether they are read or not.
// (we put the current chapter in the "unread" chapter section because we use the collection view's section 0 footer to show the user's avatar etc.)
//
// so we need to translate indexing to and from the chapter data array and the two-section structure of the timeline view.
// translating between one or more sections to 2 sections is quick because of the small number of timeline cells visible at any one time.
// and it avoids duplicating (potentially hundreds of) chapter data objects in different arrangements (chapter data controller vs. timeline data source).
//
// the chapter progress array contains dictionaries with info about the user's progress in each chapter.  linear, single-level array.
// we only need populate it to quickly determine which chapter is the current chapter, then we can clear it out.

NSMutableArray *chapterDataArray;										// chapter information for cells in timeline (pointer to ChapterDataController's array)
NSMutableArray *chapterProgressArray;									// chapter reading progress percentages for cells in timeline

float currentChapterYOffset;											// for scrolling to current chapter on first view
NSTimer *autoScrollTimer;
BOOL firstView = YES;

NSString *kTimelineCellID = @"timelineCellID";                          // UICollectionViewCell storyboard ID
NSString *kTimelineHeaderID = @"timelineHeaderID";
NSString *kTimelineFooterID = @"timelineFooterID";

WebServicesEngine *timelineWebServicesEngine;
CustomerDataEngine *timelineCustomerDataEngine;
DataController *timelineViewDataController;
ChapterDataController *timelineViewChapterDataController;
QuizDataController *timelineViewQuizDataController = nil;

LoginScrollView *loginScrollView;										// login scroll view is only shown on first launch (similar to settings view code for logout/login)
UIPageControl *loginPageControl;
UIImageView *blurredLoginBackgroundView;
BOOL loginViewVisible = NO;
BOOL accountExists = NO;
BOOL statusDataReceived = NO;											// true after we have received user's status from the server
BOOL launchBannerShown = NO;
int currentLoginScrollviewPageIndex = 0;								// start at page index 0
int averageMaxReadPercentageInt = 0;									// average of all chapters' read percentages shown in the user avatar

NSIndexPath *currentChapterIndexPath = nil;								// "current" chapter index (in timeline view "2-section" indexing scheme)

int currentChapterIndexInt = 0;											// index of "current" chapter (in chapter progress array)

static float kTimelineCellTitleSection0YOffset = 95.0f;					// read and unread timeline cells have completely different designs and sizes
static float kTimelineCellNavigationSection0YOffset = 160.0f;
static float kTimelineCellUnreadCircleYOffset = 57.0f;					// unread timeline cells position their title and nav text labels around this circle
#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	[self initDataControllers];
	[self initWebServicesEngine];
	[self initCustomerDataEngine];
	[self registerForNotifications];
	[self setSolidBackgroundColor];
	[self adjustStatusBar];
	[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
}

- (void)viewWillAppear:(BOOL)animated
{
	[self fadeLanchImage];
    [self.tabBarController.tabBar setHidden:NO];
	[self.navigationController setNavigationBarHidden:YES];
    [self populateChapterDataArrays];
	[self initChapterData];
	[self initChapterProgressArray];
	[self findCurrentChapterIndex];
	[self findAverageMaxReadPercentage];
	[self.collectionView.collectionViewLayout invalidateLayout];		// must invalidate layout before trying to calculate current chapter offset ...
	[self.collectionView reloadData];
	[self calculateCurrentChapterYOffset];								// ... because otherwise the class numberOfItemsInSection: is called instead of our own
	[self findCustomerAccount];
	[self doCurrentChapterScrollAnimation];
}

- (void)viewDidAppear:(BOOL)animated
{
	[self presentLoginViewIfNecessary];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[self.navigationController setNavigationBarHidden:NO animated:animated];
	[autoScrollTimer invalidate];							// kill timer in case user taps away before auto-scroll animation finishes.  otherwise timer would stay around.
}

#pragma mark - Animations

- (void)doCurrentChapterScrollAnimation
{
	if (firstView)											// first view: scroll from top to current chapter.  subsequent views: do a short "ease out" to current.
		self.collectionView.contentOffset = CGPointMake(0.0f, 0.0f);
	else
		self.collectionView.contentOffset = CGPointMake(0.0f, currentChapterYOffset - 70.0f);
	
	float scrollDelay = 0.0f;
	
	if (firstView)
	{
		firstView = NO;
		scrollDelay = 0.6f;
	}
	
	[self performSelector:@selector(scrollToCurrentChapter) withObject:nil afterDelay:scrollDelay];
}

- (void)scrollToCurrentChapter
{
	autoScrollTimer = [NSTimer scheduledTimerWithTimeInterval:0.01f
													   target:self
													 selector:@selector(doAutomaticScroll)
													 userInfo:nil
													  repeats:YES];
}

- (void)doAutomaticScroll
{
	float minOffsetPerClockTick = 0.5f;						// scrollviews seem to ignore very small offset adjustments, so we stop when the minimum adjustment falls below this threshold
	float maxOffsetPerClockTick = 20.0f;					// change this to adjust maximum scrolling speed if there are many completed chapters
	float accelerationZoneHeight = 800.0f;					// change accel / decel zone heights to adjust abruptness of ease-in and ease-out to and from maximum speed
	float decelerationZoneHeight = 600.0f;
	float scrollYOffset = self.collectionView.contentOffset.y;
	float yOffsetPerClockTick;

	// gradually accelerate from rest, up to maximum speed after we clear the acceleration zone
	if (scrollYOffset < accelerationZoneHeight)
		yOffsetPerClockTick = maxOffsetPerClockTick *  scrollYOffset / accelerationZoneHeight;
	else
		yOffsetPerClockTick = maxOffsetPerClockTick;
	
	// gradually decelerate to a stop from  max speed when we hit the deceleration zone.  note that deceleration overrides acceleration if there are only  few completed chapters.
	if (currentChapterYOffset - scrollYOffset < decelerationZoneHeight)
		yOffsetPerClockTick = maxOffsetPerClockTick * (currentChapterYOffset - scrollYOffset) / decelerationZoneHeight;
	else
		yOffsetPerClockTick = maxOffsetPerClockTick;
	
	if (yOffsetPerClockTick < minOffsetPerClockTick)
		[autoScrollTimer invalidate];						// stop scrolling after the adjustment has fallen below the minimum offset per click
	
	float newYOffset = scrollYOffset + yOffsetPerClockTick;
	[self.collectionView setContentOffset:CGPointMake(0.0f, newYOffset) animated:NO];
}

- (void)fadeLanchImage
{
	if (launchBannerShown)
		return;
	
	UIImageView *launchBannerView = [[UIImageView alloc] initWithFrame:self.view.frame];
	launchBannerView.image = [UIImage imageNamed:@"LaunchImage-700-568h"];		// @"LaunchImage-700" for iPhone 4/4S
	[self.tabBarController.view addSubview:launchBannerView];
	launchBannerShown = YES;

	[UIView animateWithDuration:0.5f
						  delay:0.0
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^{
						 launchBannerView.layer.opacity = 0.0f;
					 }
					 completion:^(BOOL finished){
						 [launchBannerView removeFromSuperview];
					 }
	 ];
}

#pragma mark - Initialization

- (void)calculateCurrentChapterYOffset
{
	// this must be the exact same calculation that the TimelineCollectionViewLayout class uses (in its calculateSizes method)
	// at some point we could simply refer to the layout object's properties to eliminate duplication and ensure accuracy
	int section0CellCount = (int)[self.collectionView numberOfItemsInSection:0];
	int section0Adjustment = (section0CellCount == 2 ? kTimelineSection0AdjustmentZero : kTimelineSection0Adjustment);
	currentChapterYOffset = kTimelineHeader0Height + section0Adjustment + kTimelineFooter0Height + section0CellCount * (((float)kTimelineChapterCellHeight / 2.0f) + kTimelineChapterCellYGap);
	currentChapterYOffset -= 160.0f;
}

- (void)initChapterData
{
	chapterDataArray = [timelineViewChapterDataController chapterDataTitleArray];
}

- (void)initWebServicesEngine
{
	timelineWebServicesEngine = [WebServicesEngine webServicesEngine];
}

- (void)initCustomerDataEngine
{
	timelineCustomerDataEngine = [CustomerDataEngine customerDataEngine];
}

- (void)initChapterProgressArray
{
	chapterProgressArray = [[NSMutableArray alloc] initWithCapacity:0];
	[self populateChapterProgressArray];
}

- (void)populateChapterProgressArray
{
	[chapterProgressArray removeAllObjects];
	[timelineViewDataController populateChapterProgressArray:chapterProgressArray];
}

- (void)initDataControllers
{
	timelineViewDataController = [DataController sharedController];
	timelineViewChapterDataController = [ChapterDataController sharedChapterDataController];
	timelineViewQuizDataController = [QuizDataController sharedQuizDataController];
}

- (void)findCurrentChapterIndex
{
	int prevPercent = 0, curPercent = 0;
	int readArrayIndex = 0;
	BOOL partiallyReadChapterFound = NO;

	while (readArrayIndex < chapterProgressArray.count)			// get the current chapter index in the (linear) chapterProgressArray
	{
		NSDictionary *readDict = chapterProgressArray[readArrayIndex];
		curPercent = [readDict[@"maxPercentage"] intValue];
		
		if (curPercent == 0)
		{
			partiallyReadChapterFound = YES;
			curPercent = prevPercent;
			break;
		}
		
		prevPercent = curPercent;
		readArrayIndex++;
	}
	
	// if the current chapter is 100% read, and if there are any chapters after it, we need to find the next chapter that is not 100% read.
	// that will become the new current chapter because we no longer allow the current chapter to be 100% read.
	if (curPercent == 100 && readArrayIndex < (chapterProgressArray.count - 1))
	{
		while (readArrayIndex < chapterProgressArray.count)
		{
			NSDictionary *readDict = chapterProgressArray[++readArrayIndex];
			curPercent = [readDict[@"maxPercentage"] intValue];
			
			if (curPercent < 100)
			{
				partiallyReadChapterFound = YES;
				break;
			}
		}
	}

	if (partiallyReadChapterFound == NO)
		readArrayIndex = chapterProgressArray.count;
	
	currentChapterIndexInt = readArrayIndex;
	currentChapterIndexPath = [self timelinePathForIndexInt:currentChapterIndexInt];
}

- (void)findAverageMaxReadPercentage
{
	averageMaxReadPercentageInt = [timelineViewDataController getAverageMaxReadPercentage];
}

#pragma mark - Data for view

- (void)populateChapterDataArrays
{
	[timelineViewChapterDataController populateSectionArray];
	[timelineViewChapterDataController populateChapterArray];
}

#pragma mark - Index path translation methods

// create a timeline collection view index path (with exactly 2 sections) from a 1-dimensional progress array index

- (NSIndexPath *)timelinePathForIndexInt:(int)indexInt
{
	int sectionIndex = (indexInt >= currentChapterIndexInt ? 1 : 0);
	int chapterIndex = (sectionIndex == 0 ? indexInt : indexInt - currentChapterIndexInt);
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:chapterIndex inSection:sectionIndex];
	return indexPath;
}

// generate a linear index into a 1-dimensional array from the collection view index path (with exactly 2 sections: roughly "read" and "unread")
// this is tricky because the collection view's sections contain more than just the visible cells.  some footer cells are visible (e.g. user avatar
// footer cell in section 0) and others are not (e.g. the footer cell after the last chapter in section 1.)  and we need to check explicitly for
// index over- and under-runs.  just couldn't find a clean solution to the translation problem.

- (int)indexIntForTimelinePath:(NSIndexPath *)indexPath
{
	int indexInt = 0;
	
	if (indexPath.section == 0)											// there are only two sections in the timeline collection view: 0 and 1
	{
		indexInt = indexPath.row - 1;									// for section 0 the index is just the path row component (minus 1 because cell 0-0 is the header cell)
	}
	else if (indexPath.section == 1)									// section 1 starts with the current chapter and contains all chapters after the current chapter
	{
		indexInt = [self.collectionView numberOfItemsInSection:0];		// start with the number of items in section 0
		indexInt += indexPath.row;										// add the row component of the index path
		indexInt -= 2;													// and subtract 2, because we don't count the header cells of section 0 or section 1 when calculating the linear index
	}
	
	return indexInt;
}

- (NSIndexPath *)timelinePathForChapterDataSectionIndex:(int)dataSectionIndex chapterIndex:(int)dataChapterIndex
{
	int linearIndex = [self indexIntForChapterDataSectionIndex:dataSectionIndex chapterIndex:dataChapterIndex];
	return [self timelinePathForIndexInt:linearIndex];
}

- (int)indexIntForChapterDataSectionIndex:(int)dataSectionIndex chapterIndex:(int)dataChapterIndex
{
	int linearIndex = dataChapterIndex;
	
	for (int sIndex = 0; sIndex < dataSectionIndex; sIndex++)
		linearIndex += [chapterDataArray[sIndex] count];
	
	return linearIndex;
}

- (NSIndexPath *)timelinePathForChapterDataPath:(NSIndexPath *)chapterDataPath
{
	int linearIndex = [self indexIntForChapterDataSectionIndex:(int)chapterDataPath.section chapterIndex:(int)chapterDataPath.row];
	return [self timelinePathForIndexInt:linearIndex];
}

- (NSIndexPath *)chapterDataPathForTimelinePath:(NSIndexPath *)timelinePath
{
	int linearIndex = [self indexIntForTimelinePath:timelinePath];
	return [self chapterDataPathForIndexInt:linearIndex];
}

- (NSIndexPath *)chapterDataPathForIndexInt:(int)indexInt
{
	int sectionIndex = 0, chapterIndex  = 0, tempIndex = 0;
	
	while (tempIndex < indexInt)
	{
		int sectionCount = (int)[chapterDataArray[sectionIndex] count];
		
		if ((tempIndex + sectionCount) > indexInt)
		{
			chapterIndex = indexInt - tempIndex;														// increment index by the number of chapters in this section
			break;
		}

		tempIndex += sectionCount;
		sectionIndex++;
	}

	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:chapterIndex inSection:sectionIndex];
	return indexPath;
}

#pragma mark - Collection view delegate methods

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == 0 && indexPath.row == 0)													// don't perform any segue if user taps the title image
		return;

	currentChapterIndexPath = [self adjustSelectedIndexPathIfNecessary:indexPath];						// for some reason sometimes the index path is beyond last item!!!
	[self performSegueWithIdentifier:@"segueFromCollectionItemToReadView" sender:self];
}

// if user selects the very last item, occasionally collectionView:didSelectItemAtIndexPath: will receive an indexPath beyond the last element.
// no idea why this could happen.  we need to correct that before attempting to segue to the read view, or else we'll crash with out-of-bounds array index.

- (NSIndexPath *)adjustSelectedIndexPathIfNecessary:(NSIndexPath *)selectedIndexPath
{
	int sectionIndex = selectedIndexPath.section;
	int itemIndex = selectedIndexPath.item;
	int maxItemIndex = [self.collectionView numberOfItemsInSection:sectionIndex] - 2;
	
	if (itemIndex > maxItemIndex)
		itemIndex = maxItemIndex;
	
	NSIndexPath *adjustedIndexPath = [NSIndexPath indexPathForItem:itemIndex inSection:sectionIndex];
	return adjustedIndexPath;
}

#pragma mark - Collection view data source

- (UICollectionViewCell *)collectionView:(UICollectionView *)cView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
	UICollectionViewCell *cell = nil;
	
	if (indexPath.row == 0)																				// section 0: title cell, section 1: "current" chapter
		cell = [self headerCellForCollectionView:cView cellForItemAtIndexPath:indexPath];
	else if (indexPath.row == ([self.collectionView numberOfItemsInSection:indexPath.section] - 1))		// section 0: user avatar, section 1: empty
		cell = [self footerCellForCollectionView:cView cellForItemAtIndexPath:indexPath];
	else																								// normal cell (read or unread in either section)
		cell = [self timelineCellForCollectionView:cView cellForItemAtIndexPath:indexPath];

	return cell;
}

- (UICollectionViewCell *)timelineCellForCollectionView:(UICollectionView *)cView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    TimelineCollectionViewCell *cell = [cView dequeueReusableCellWithReuseIdentifier:kTimelineCellID forIndexPath:indexPath];
	[self populateTimelineCell:cell forIndexPath:indexPath];
	[self adjustTimelineLineCapForCell:cell forIndexPath:indexPath];
	[self adjustTimelineCellPosition:cell forIndexPath:indexPath];
	[self adjustTimelineConnectorForCell:cell forIndexPath:indexPath];
	[self adjustTimelineForCell:cell forIndexPath:indexPath];
	[self adjustUnreadCircleForCell:cell forIndexPath:indexPath];
	[self adjustOpacityForCell:cell forIndexPath:indexPath];
	[self animateTimelineCell:cell forIndexPath:indexPath];
	return cell;
}

- (TimelineSectionHeaderView *)headerCellForCollectionView:(UICollectionView *)cView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    TimelineSectionHeaderView *cell = [cView dequeueReusableCellWithReuseIdentifier:kTimelineHeaderID forIndexPath:indexPath];
	[self populateBookHeaderCell:cell withVisiblity:(indexPath.section == 0)];
	[self populateCurrentChapterHeaderCell:cell withVisiblity:(indexPath.section == 1)];
	[self adjustChapterHeaderCellPosition:cell forIndexPath:indexPath];
	return cell;
}

- (TimelineSectionFooterView *)footerCellForCollectionView:(UICollectionView *)cView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
	TimelineSectionFooterView *cell = [cView dequeueReusableCellWithReuseIdentifier:kTimelineFooterID forIndexPath:indexPath];
	[self populateFooterCell:cell forIndexPath:indexPath];
	return cell;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
	return 2;
}

// note: just for clarification on the sections, what they contain, and their item counts
// - the timeline collection view contains two sections:
// - section 0
//		row index 0: header cell with book title
//		row indices 1-n (for n chapters read): cells for chapters with read percentage > 0 that are in a contiguous sequence starting from chapter 1
//		footer cell with user avatar
// - section 1
//		current chapter cell
//		all unread chapter cells: all chapters that have been read but are not continguous with the sequence of "read chapters" starting with chapter 0

- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section
{
	int itemCount = 0;
	
	if (section == 0)
	{
		int section0AdjustmentInt = (currentChapterIndexInt == 0 ? 2 : 1);			// actual read chapter count + header cell + footer cell
		itemCount = currentChapterIndexInt + section0AdjustmentInt;
	}
	else
	{
		if (currentChapterIndexInt == 0)
			itemCount = chapterProgressArray.count + 1;								// +1 for the header (the large current chapter cell)
		else
			itemCount = chapterProgressArray.count - currentChapterIndexInt + 2;	// +1 for header and +1 for footer (empty cell at bottom of view)
	}

	return itemCount;
}

#pragma mark - Collection view utility methods

- (void)populateBookHeaderCell:(TimelineSectionHeaderView *)cell withVisiblity:(BOOL)isVisible
{
	if (isVisible)
	{
//		cell.sectionHeaderImageView.image = [UIImage imageNamed:@"LaunchImage-700-568h"];	// we no longer show the header image
		NSDictionary *pubInfo = [[WebServicesEngine webServicesEngine] publicationInfo];
		cell.sectionHeaderTitleLabel.text = pubInfo[@"Name"];
		cell.sectionHeaderTitleLabel.frame = CGRectMake(20.0f, 0.0f, self.view.frame.size.width-40, 100.0f);
		[self shrinkTitleLabelFontToFitLabelInCell:cell];
		cell.sectionHeaderTitleLabel.hidden = NO;
	}
	else
	{
		cell.sectionHeaderTitleLabel.hidden = YES;
	}
}

// note: we shrink the font until two things happen:
//	1. no single word in the title gets split because it's too wide to fit (which does happen even though we specify NSLineBreakByWordWrapping)
//	2. all words in the title fit vertically into the specified CGRect

- (void)shrinkTitleLabelFontToFitLabelInCell:(TimelineSectionHeaderView *)cell
{
	CGRect labelRect = cell.sectionHeaderTitleLabel.frame;
	float fontSize = 40.0f;
	UIFont *labelFont = [UIFont fontWithName:@"HelveticaNeue-CondensedBold" size:fontSize];
	CGRect oneLineRect = [@"X" boundingRectWithSize:labelRect.size
											options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
										 attributes:@{NSFontAttributeName:labelFont}
											context:nil];
	
	NSArray *titleWordArray = [cell.sectionHeaderTitleLabel.text componentsSeparatedByString:@" "];
	CGRect textSizeRect;
	
	for (NSString *titleWordString in titleWordArray)					// if necessary, shrink font to make sure each word in title remains un-split
	{
		do
		{
			labelFont = [UIFont fontWithName:@"HelveticaNeue-CondensedBold" size:fontSize];
			textSizeRect = [titleWordString boundingRectWithSize:labelRect.size
														 options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
													  attributes:@{NSFontAttributeName:labelFont}
														 context:nil];
			fontSize -= 1.0f;
		} while (textSizeRect.size.height > oneLineRect.size.height);
	}
	
	fontSize = labelFont.pointSize;
	
	do
	{
		labelFont = [UIFont fontWithName:@"HelveticaNeue-CondensedBold" size:fontSize];
		textSizeRect = [cell.sectionHeaderTitleLabel.text boundingRectWithSize:labelRect.size
																	   options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
																	attributes:@{NSFontAttributeName:labelFont}
																	   context:nil];
		fontSize -= 1.0f;
	} while (textSizeRect.size.height > labelRect.size.height);
	
	cell.sectionHeaderTitleLabel.font = labelFont;
}

- (void)populateCurrentChapterHeaderCell:(TimelineSectionHeaderView *)cell withVisiblity:(BOOL)isVisible
{
	TimelineCurrentChapterViewCell *currentChapterCell = (TimelineCurrentChapterViewCell *)cell.sectionHeaderChapterGroupView;
	
	if (isVisible)
	{
		// note: currentChapterIndexInt is the current chapter index into the progress array (and "current chapter" is the first chapter in timeline section 1)
		NSIndexPath *chapterDataPath = [self chapterDataPathForIndexInt:(currentChapterIndexInt - 1)];
		NSArray *sectionArray = chapterDataArray[chapterDataPath.section];
		PageInstance *pageInstance = sectionArray[chapterDataPath.row];
		currentChapterCell.timelineCurrentChapterTitleLabel.text = pageInstance.Title;
		currentChapterCell.timelineCurrentChapterNavigationTargetLabel.text = [self navigationTextForChapterAtChapterDataIndexPath:chapterDataPath];
		currentChapterCell.timelineCurrentChapterChapterImageView.image = [UIImage imageNamed:pageInstance.Image];

		if (currentChapterCell.timelineCurrentChapterChapterImageView.image == nil)
			currentChapterCell.timelineCurrentChapterChapterImageView.image = [UIImage imageNamed:@"LaunchImage-700-568h"];
		
		[currentChapterCell adjustImageToFitCurrentChapterCell];
	}
	currentChapterCell.hidden = (isVisible == NO);
}

- (void)adjustChapterHeaderCellPosition:(TimelineSectionHeaderView *)cell forIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == 0)
	{
		TimelineSectionHeaderView *headerViewCell = (TimelineSectionHeaderView *)cell;
		CGRect headerCellFrame = headerViewCell.frame;
		headerCellFrame.origin.x = 0.0f;
		headerViewCell.frame = headerCellFrame;
	}
	else
	{
		TimelineCurrentChapterViewCell *currentChapterCell = (TimelineCurrentChapterViewCell *)cell.sectionHeaderChapterGroupView;
		CGRect currentGroupingFrame = currentChapterCell.frame;
        currentGroupingFrame.origin.x = 0.0f;
		currentChapterCell.frame = currentGroupingFrame;
	}
}

- (void)populateFooterCell:(TimelineSectionFooterView *)cell forIndexPath:(NSIndexPath *)indexPath
{
	CGRect footerCellFrame = cell.frame;
	footerCellFrame.size.width = self.view.frame.size.width;
	cell.frame = footerCellFrame;
	[self configureTimelineContinuationViewForCell:cell forIndexPath:indexPath];
	[self configureFooterProgressViewForCell:cell forIndexPath:indexPath];
	[self configureFooterImageViewForCell:cell forIndexPath:indexPath];
	[self configureFooterProgressPointerViewForCell:cell forIndexPath:indexPath];
	[self configureFooterUserNameLabelForCell:cell forIndexPath:indexPath];
	[self configureFooterProgressLabelForCell:cell forIndexPath:indexPath];
	[self configureFooterUserButtonForCell:cell forIndexPath:indexPath];
}

- (void)configureTimelineContinuationViewForCell:(TimelineSectionFooterView *)cell forIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == 0)
	{
		CGRect continuationViewFrame = cell.sectionFooterTimelineContinuationView.frame;
		
		if (currentChapterIndexInt == 0 || currentChapterIndexInt == 1)
		{
			continuationViewFrame.size.height = 6.0f;
			continuationViewFrame.origin.y = 0.0f;
		}
		else
		{
			continuationViewFrame.size.height = 26.0f;
			continuationViewFrame.origin.y = -20.0f;
		}

		cell.sectionFooterTimelineContinuationView.frame = continuationViewFrame;
		cell.sectionFooterTimelineContinuationView.hidden = NO;
	}
	else
	{
		cell.sectionFooterTimelineContinuationView.hidden = YES;
	}
}

- (void)configureFooterProgressViewForCell:(TimelineSectionFooterView *)cell forIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section > 0)
	{
		cell.sectionFooterProgressView.hidden = YES;
	}
	else
	{
		cell.sectionFooterProgressView.hidden = NO;
		cell.sectionFooterProgressView.completionFraction = ((float)averageMaxReadPercentageInt / 100.0f);
		[cell.sectionFooterProgressView setNeedsDisplay];
	}
}

- (void)configureFooterImageViewForCell:(TimelineSectionFooterView *)cell forIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section > 0)
	{
		cell.sectionFooterUserImageView.hidden = YES;
	}
	else
	{
		cell.sectionFooterUserImageView.hidden = NO;
		cell.sectionFooterUserImageView.image = timelineCustomerDataEngine.customerAvatarImage;
		cell.sectionFooterUserImageView.layer.cornerRadius = cell.sectionFooterUserImageView.frame.size.width / 2.0f;
		cell.sectionFooterUserImageView.layer.borderColor = [[UIColor whiteColor] CGColor];
		cell.sectionFooterUserImageView.layer.borderWidth = 4.0f;
	}
}

- (void)configureFooterProgressPointerViewForCell:(TimelineSectionFooterView *)cell forIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section > 0)
	{
		cell.sectionFooterProgressPointer.hidden = YES;
	}
	else
	{
		cell.sectionFooterProgressPointer.hidden = (averageMaxReadPercentageInt < 54);
		CGRect pointerFrame = cell.sectionFooterProgressPointer.frame;
		pointerFrame.size.width = 12.0f;
		pointerFrame.size.height = 12.0f;
		pointerFrame.origin.x = (cell.sectionFooterProgressView.frame.size.width / 2.0f) - (pointerFrame.size.width / 2.0f);
		pointerFrame.origin.y = cell.sectionFooterProgressView.frame.size.height;
		pointerFrame.origin.y -= 2.0f;					// change this to adjust the "length" of the pointer
		cell.sectionFooterProgressPointer.frame = pointerFrame;
	}
}

- (void)configureFooterUserNameLabelForCell:(TimelineSectionFooterView *)cell forIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section > 0)
	{
		cell.sectionFooterUserNameLabel.hidden = YES;
	}
	else
	{
		cell.sectionFooterUserNameLabel.hidden = NO;
		cell.sectionFooterUserNameLabel.text = [timelineCustomerDataEngine getCustomerName];
	}
}

- (void)configureFooterProgressLabelForCell:(TimelineSectionFooterView *)cell forIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section > 0)
	{
		cell.sectionFooterProgressPercentageLabel.hidden = YES;
	}
	else
	{
		cell.sectionFooterProgressPercentageLabel.hidden = NO;
		cell.sectionFooterProgressPercentageLabel.text = [self totalReadPercentageString];
	}
	
//	float rComponent = 31.0f;
//	float gComponent = 172.0f;
//	float bComponent = 237.0f;
//	cell.sectionFooterProgressPercentageLabel.textColor = [UIColor colorWithRed:(rComponent / 255.0f) green:(gComponent / 255.0f) blue:(bComponent / 255.0f) alpha:1.0f];
	cell.sectionFooterProgressPercentageLabel.textColor = [UIColor colorWithWhite:1.0f alpha:0.5f];
}

- (void)configureFooterUserButtonForCell:(TimelineSectionFooterView *)cell forIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section > 0)
	{
		cell.sectionFooterUserButton.hidden = YES;
	}
	else
	{
		cell.sectionFooterUserButton.hidden = NO;
		cell.sectionFooterUserButton.userInteractionEnabled = YES;
		[cell.sectionFooterUserButton addTarget:self action:@selector(navigateToSettingsView:) forControlEvents:UIControlEventTouchUpInside];
	}
}

- (NSString *)totalReadPercentageString
{
	NSMutableString *percentageString = [NSMutableString new];
	[percentageString appendString:[NSString stringWithFormat:@"%d%% %@", averageMaxReadPercentageInt, NSLocalizedString(@"COMPLETE", @"COMPLETE")]];
	return percentageString;
}

- (void)populateTimelineCell:(TimelineCollectionViewCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
	[self setChapterInfoForCell:cell forIndexPath:indexPath];
	[self setQuizScoreForCell:cell forIndexPath:indexPath];
	[self setNavigationTextForCell:cell forIndexPath:indexPath];
	[self adjustLabelPositionsInCell:cell forIndexPath:indexPath];
}

- (void)setChapterInfoForCell:(TimelineCollectionViewCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
	NSIndexPath *chapterDataPath = [self chapterDataPathForTimelinePath:indexPath];
	NSArray *sectionArray = chapterDataArray[chapterDataPath.section];
	PageInstance *pageInstance = sectionArray[chapterDataPath.row];
	cell.timelineCellChapterTitleLabel.text = pageInstance.Title;

	// cells for read chapters (including current) have an image, and text is dark gray.  cells below current chapter are simpler and have white text.
	if (indexPath.section == 0)
	{
		// all chapters in section 0 are at least partially read.  current chapter (also partially read) is row 0 of section 1.
		cell.timelineCellChapterImageView.image = [UIImage imageNamed:pageInstance.Image];
		
		if (cell.timelineCellChapterImageView.image == nil)
			cell.timelineCellChapterImageView.image = [UIImage imageNamed:@"LaunchImage-700-568h"];		// @"LaunchImage-700" for iPhone 4/4S

		[cell adjustImageToFitTimelineCell];
		cell.timelineCellChapterImageView.hidden = NO;
		
		cell.timelineCellChapterTitleLabel.textColor = [UIColor darkGrayColor];
		cell.timelineCellChapterTitleLabel.textAlignment = NSTextAlignmentCenter;
		cell.timelineCellChapterTitleLabel.font = [UIFont fontWithName:@"HelveticaNeue-CondensedBold" size:14.0f];
		cell.timelineCellChapterTitleLabel.clipsToBounds = YES;
	}
	else
	{
		// cells below current chapter: title and "start" text are left- or right-justified depending on which column the cell is in
		cell.timelineCellChapterImageView.hidden = YES;
		cell.timelineCellChapterTitleLabel.textColor = [UIColor whiteColor];
		cell.timelineCellChapterTitleLabel.font = [UIFont fontWithName:@"HelveticaNeue-CondensedBold" size:18.0f];
		cell.timelineCellChapterTitleLabel.clipsToBounds = NO;
	
		if ((indexPath.row % 2) == 0)
			cell.timelineCellChapterTitleLabel.textAlignment = NSTextAlignmentRight;
		else
			cell.timelineCellChapterTitleLabel.textAlignment = NSTextAlignmentLeft;
	}
}

- (void)setQuizScoreForCell:(TimelineCollectionViewCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section > 0)
	{
		cell.timelineCellQuizScoreLabel.hidden = YES;
		cell.timelineCellQuizScoreCircleView.hidden = YES;
		return;
	}
	NSIndexPath *chapterDataPath = [self chapterDataPathForTimelinePath:indexPath];
	NSArray *sectionArray = chapterDataArray[chapterDataPath.section];
	PageInstance *pageInstance = sectionArray[chapterDataPath.row];
	NSNumber *quizScoreNumber = timelineViewQuizDataController.chapterQuizScoreDictionary[[NSString stringWithFormat:@"%d", pageInstance.PageInstanceId]];
	
	if (quizScoreNumber == nil)										// if the user hasn't answered any questions, don't show the quiz score
	{
		cell.timelineCellQuizScoreLabel.hidden = YES;
		cell.timelineCellQuizScoreCircleView.hidden = YES;
		return;
	}
	
	NSInteger scoreInt = [quizScoreNumber integerValue];
	NSString *scoreString = [NSString stringWithFormat:@"%d", scoreInt];

	if (scoreInt >= 100)
	{
		scoreInt = 100;
		scoreString = @"100";
	}
	
	cell.timelineCellQuizScoreLabel.text = scoreString;

	if (scoreInt >= 100)
		cell.timelineCellQuizScoreCircleView.backgroundColor = [UIColor colorWithRed:0.0f green:0.706f blue:1.0f alpha:1.0f];	// blue for perfect score
	else if (scoreInt >= 80)
		cell.timelineCellQuizScoreCircleView.backgroundColor = [UIColor colorWithRed:0.722f green:0.808f blue:0.0f alpha:1.0f];
	else if (scoreInt >= 60)
		cell.timelineCellQuizScoreCircleView.backgroundColor = [UIColor colorWithRed:0.906f green:0.812f blue:0.02f alpha:1.0f];
	else
		cell.timelineCellQuizScoreCircleView.backgroundColor = [UIColor colorWithRed:0.788f green:0.043f blue:0.2f alpha:1.0f];
	
	cell.timelineCellQuizScoreCircleView.layer.cornerRadius = cell.timelineCellQuizScoreCircleView.frame.size.width / 2.0f;		// turn the square into a circle
	cell.timelineCellQuizScoreCircleView.layer.borderColor = [[UIColor whiteColor] CGColor];
	cell.timelineCellQuizScoreCircleView.layer.borderWidth = 2.0f;
	cell.timelineCellQuizScoreCircleView.layer.shadowColor = [[UIColor blackColor] CGColor];
	cell.timelineCellQuizScoreCircleView.layer.shadowOpacity = 0.50f;
	cell.timelineCellQuizScoreCircleView.layer.shadowRadius = 1.0f;
	cell.timelineCellQuizScoreCircleView.layer.shadowOffset = CGSizeMake(0.0f, 1.0f);
	cell.timelineCellQuizScoreLabel.hidden = NO;
	cell.timelineCellQuizScoreCircleView.hidden = NO;
}

- (void)setNavigationTextForCell:(TimelineCollectionViewCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
	NSIndexPath *chapterDataPath = [self chapterDataPathForTimelinePath:indexPath];
	cell.timelineCellNavigationTargetLabel.text = [self navigationTextForChapterAtChapterDataIndexPath:chapterDataPath];

	if (indexPath.section == 0)
	{
		cell.timelineCellNavigationTargetLabel.textColor = [UIColor darkGrayColor];
		cell.timelineCellNavigationTargetLabel.textAlignment = NSTextAlignmentCenter;
		cell.timelineCellNavigationTargetLabel.font = [UIFont fontWithName:@"HelveticaNeue-CondensedBold" size:11.0f];
	}
	else
	{
		cell.timelineCellNavigationTargetLabel.textColor = [UIColor whiteColor];
		cell.timelineCellNavigationTargetLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:9.0f];

		if ((indexPath.row % 2) == 0)
			cell.timelineCellNavigationTargetLabel.textAlignment = NSTextAlignmentRight;
		else
			cell.timelineCellNavigationTargetLabel.textAlignment = NSTextAlignmentLeft;
	}
}

// normally i wouldn't adjust two different labels in one method, but they need to be positioned together.
// the title text and nav text labels should be very close, and centered vertically in the unread cell.
// if this is a "read" cell then both label positions are fixed.

- (void)adjustLabelPositionsInCell:(TimelineCollectionViewCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
	CGRect titleLabelFrame = cell.timelineCellChapterTitleLabel.frame;			// just for simplicity, we never change the label frame sizes.  just move them.
	CGRect navLabelFrame = cell.timelineCellNavigationTargetLabel.frame;
	titleLabelFrame.origin.y = kTimelineCellTitleSection0YOffset;
	navLabelFrame.origin.y = kTimelineCellNavigationSection0YOffset;

	if (indexPath.section == 1)
	{
		titleLabelFrame.origin.x = 0.0f;										// reset the frame origin because we move it to center the title + navigation labels around the unread "circle"
		CGRect titleTextSizeFrame = [cell.timelineCellChapterTitleLabel.text boundingRectWithSize:cell.timelineCellChapterTitleLabel.frame.size
																						  options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
																					   attributes:@{NSFontAttributeName:cell.timelineCellChapterTitleLabel.font}
																						  context:nil];
		CGRect navTextSizeFrame = [cell.timelineCellNavigationTargetLabel.text boundingRectWithSize:cell.timelineCellNavigationTargetLabel.frame.size
																						  options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
																					   attributes:@{NSFontAttributeName:cell.timelineCellNavigationTargetLabel.font}
																						  context:nil];
		CGRect timelineCircleFrame = cell.timelineUnreadCircleView.frame;
		timelineCircleFrame.origin.y = kTimelineCellUnreadCircleYOffset;
		float centerlineYOffset = timelineCircleFrame.origin.y + (timelineCircleFrame.size.height / 2.0f);
		float navLabelGap = 3.0f;
		float totalHeight = titleTextSizeFrame.size.height + navTextSizeFrame.size.height + navLabelGap;	// two label height + gap between them
		float virtualYOffset = centerlineYOffset - (totalHeight / 2.0f);
		float actualTitleTextYOffsetWithinLabelFrame = (titleLabelFrame.size.height - titleTextSizeFrame.size.height) / 2.0f;
		titleLabelFrame.origin.y = virtualYOffset - actualTitleTextYOffsetWithinLabelFrame;
		navLabelFrame.origin.y = titleLabelFrame.origin.y + actualTitleTextYOffsetWithinLabelFrame + titleTextSizeFrame.size.height + navLabelGap;
		navLabelFrame.origin.y -= (navLabelFrame.size.height - navTextSizeFrame.size.height) / 2.0f;
	}
	
	cell.timelineCellChapterTitleLabel.frame = titleLabelFrame;
	cell.timelineCellNavigationTargetLabel.frame = navLabelFrame;
}

- (int)percentageReadIntForChapterAtIndexPath:(NSIndexPath *)indexPath
{
	int linearIndexInt = [self indexIntForTimelinePath:indexPath];
	return [self percentageReadForChapterAtLinearIndex:linearIndexInt];
}

- (int)percentageReadForChapterAtLinearIndex:(int)linearIndexInt
{
	NSDictionary *chapterReadDictionary = chapterProgressArray[linearIndexInt];
	int chapterReadPercentageInt = [chapterReadDictionary[@"maxPercentage"] intValue];
	return chapterReadPercentageInt;
}

- (NSString *)navigationTextForChapterAtChapterDataIndexPath:(NSIndexPath *)chapterDataIndexPath
{
	int linearIndexInt = [self indexIntForChapterDataSectionIndex:chapterDataIndexPath.section chapterIndex:chapterDataIndexPath.row];
	int readPercentageInt = [self percentageReadForChapterAtLinearIndex:linearIndexInt];
	
	NSString *readPercentageString = nil;
	
	if (linearIndexInt < currentChapterIndexInt)
	{
		if (readPercentageInt == 0)
			readPercentageString = NSLocalizedString(@"Start", @"Start");
		else if (readPercentageInt == 100)
			readPercentageString = NSLocalizedString(@"Re-read", @"Re-read");
		else
			readPercentageString = NSLocalizedString(@"Continue", @"Continue");
	}
	else
	{
		if (readPercentageInt == 0)
			readPercentageString = NSLocalizedString(@"START", @"START");
		else if (readPercentageInt == 100)
			readPercentageString = NSLocalizedString(@"RE-READ", @"RE-READ");
		else
			readPercentageString = NSLocalizedString(@"CONTINUE", @"CONTINUE");
	}
	
	return readPercentageString;
}

- (void)adjustTimelineLineCapForCell:(TimelineCollectionViewCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == 0 && indexPath.row == 1)							// row index 1 because row index 0 is for the "section header row"
		[self showLineCapForTimelineInCell:cell];
	else
		[self hideLineCapForTimelineInCell:cell];
}

- (void)showLineCapForTimelineInCell:(TimelineCollectionViewCell *)cell
{
	UIView *lineCapView = cell.timelineCellLineCapView;
	lineCapView.layer.cornerRadius = lineCapView.frame.size.width / 2.0f;		// round the square into a circle
	lineCapView.hidden = NO;
}

- (void)hideLineCapForTimelineInCell:(TimelineCollectionViewCell *)cell
{
	UIView *lineCapView = cell.timelineCellLineCapView;
	lineCapView.hidden = YES;
}

- (void)adjustTimelineCellPosition:(TimelineCollectionViewCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
	CGRect cellFrame = cell.frame;
	UIView *lineView = cell.timelineCellLineView;
	CGRect lineViewFrame = lineView.frame;
	float halfScreenWidth = self.view.frame.size.width / 2.0f;
	float lineToCellGap = halfScreenWidth - cell.timelineCellChapterInfoGroupingView.frame.size.width;

	if ((indexPath.row) % 2 == 0)							// put odd-row-index cells (even chapter numbers) on the left edge of collection view
	{
		lineViewFrame.origin.x = cellFrame.size.width + lineToCellGap;
		if (indexPath.section == 0)
        {
            if (DEVICE_IS_IPAD)
                cellFrame.origin.x = 225.0f;
            else
                cellFrame.origin.x = 0.0f;
        }
		else
        {
            if (DEVICE_IS_IPAD)
                cellFrame.origin.x = 230;
            else
                cellFrame.origin.x = 10.0f;
        }
		lineViewFrame.origin.x -= cellFrame.origin.x;
	}
	else													// put even-row-index cells (odd chapter numbers) on the right edge of collection view
	{
		if (indexPath.section > 0)
		{
            if(DEVICE_IS_IPAD)
            {
                cellFrame.origin.x = 408;
                lineViewFrame.origin.x = -24;
            }
			else
            {
                cellFrame.origin.x = 180;
                lineViewFrame.origin.x = -20;
            }
		}
        else
        {
            if (DEVICE_IS_IPAD) {
                cellFrame.origin.x = halfScreenWidth + lineToCellGap-225;
                lineViewFrame.origin.x = (-lineToCellGap)+225;			// the "timeline line" can be moved outside cell boundary, so left- and right-edge cells' time lines will look like one
            }
            else
            {
                cellFrame.origin.x = halfScreenWidth + lineToCellGap;
                lineViewFrame.origin.x = (-lineToCellGap);
            }
        }
	}
	cellFrame.size.height = kTimelineChapterCellHeight;
	cell.frame = cellFrame;
	cell.timelineCellLineView.frame = lineViewFrame;
}

- (void)adjustTimelineConnectorForCell:(TimelineCollectionViewCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section != 0)
	{
		cell.timelineCellBranchLeftView.hidden = YES;
		cell.timelineCellBranchRightView.hidden = YES;
		cell.timelineUnreadPointerLeftView.hidden = YES;
		cell.timelineUnreadPointerRightView.hidden = YES;
	}
	else
	{
		cell.timelineUnreadPointerLeftView.hidden = YES;
		cell.timelineUnreadPointerRightView.hidden = YES;
		
		if ((indexPath.row % 2) == 0)
			[self adjustLeftTimelineBranchForCell:cell];
		else
			[self adjustRightTimelineBranchForCell:cell];
	}
}

- (void)adjustLeftUnreadChapterPointerForCell:(TimelineCollectionViewCell *)cell
{
	CGRect frame = cell.timelineUnreadPointerLeftView.frame;
	cell.timelineUnreadPointerLeftView.backgroundColor = [UIColor clearColor];
	frame.origin.x = cell.timelineCellChapterInfoGroupingView.frame.size.width;
	cell.timelineUnreadPointerLeftView.frame = frame;
	cell.timelineUnreadPointerLeftView.hidden = NO;
	cell.timelineUnreadPointerRightView.hidden = YES;
	cell.timelineUnreadPointerLeftView.alpha = 0.5f;
}

- (void)adjustRightUnreadChapterPointerForCell:(TimelineCollectionViewCell *)cell
{
	CGRect frame = cell.timelineUnreadPointerRightView.frame;
	cell.timelineUnreadPointerRightView.backgroundColor = [UIColor clearColor];
	frame.origin.x = cell.timelineCellChapterInfoGroupingView.frame.origin.x - frame.size.width;
	cell.timelineUnreadPointerRightView.frame = frame;
	cell.timelineUnreadPointerLeftView.hidden = YES;
	cell.timelineUnreadPointerRightView.hidden = NO;
	cell.timelineUnreadPointerRightView.alpha = 0.5f;
}

- (void)adjustLeftTimelineBranchForCell:(TimelineCollectionViewCell *)cell
{
	CGRect frame = cell.timelineCellBranchLeftView.frame;
	frame.size.width = 30.0f;
	frame.size.height = 30.0f;
	cell.timelineCellBranchLeftView.backgroundColor = [UIColor clearColor];
	frame.origin.x = cell.timelineCellChapterInfoGroupingView.frame.size.width;
	cell.timelineCellBranchLeftView.frame = frame;
	cell.timelineCellBranchLeftView.hidden = NO;
	cell.timelineCellBranchRightView.hidden = YES;
}

- (void)adjustRightTimelineBranchForCell:(TimelineCollectionViewCell *)cell
{
	CGRect frame = cell.timelineCellBranchRightView.frame;
	frame.size.width = 30.0f;
	frame.size.height = 30.0f;
	cell.timelineCellBranchRightView.backgroundColor = [UIColor clearColor];
	frame.origin.x = cell.timelineCellLineView.frame.origin.x;
	cell.timelineCellBranchRightView.frame = frame;
	cell.timelineCellBranchLeftView.hidden = YES;
	cell.timelineCellBranchRightView.hidden = NO;
}

- (void)adjustTimelineForCell:(TimelineCollectionViewCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
	CGRect lineFrame = cell.timelineCellLineView.frame;
	lineFrame.size.width = 1.0f;
	cell.timelineCellLineView.backgroundColor = [UIColor whiteColor];

	if (indexPath.section == 0)								// completed chapters have a full-height white timeline
	{
		lineFrame.size.height = cell.frame.size.height;
		lineFrame.origin.y = 0.0f;
	}
	else													// unread chapters have a half-height gray timeline pointing upward from a hollow gray circle
	{
		CGRect circleFrame = cell.timelineUnreadCircleView.frame;
		lineFrame.size.height = (kTimelineUnreadChapterCellHeight/ 2.0f + kTimelineUnreadChapterCellYGap - circleFrame.size.height);		// adjust for circle radius and gap between cells
		lineFrame.origin.y = (circleFrame.size.height / 2.0f) + kTimelineUnreadChapterCellYGap;
	}
	
	cell.timelineCellLineView.frame = lineFrame;
}

- (void)adjustUnreadCircleForCell:(TimelineCollectionViewCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == 1)
	{
		CGRect frame = cell.timelineUnreadCircleView.frame;
		frame.origin.x = cell.timelineCellLineView.frame.origin.x - (cell.timelineCellLineView.frame.size.width / 2.0f) - (frame.size.width / 2.0f) + 1.0f;
		frame.origin.y = cell.timelineCellLineView.frame.origin.y + cell.timelineCellLineView.frame.size.height;
		cell.timelineUnreadCircleView.frame = frame;
		cell.timelineUnreadCircleView.layer.borderColor = [[UIColor whiteColor] CGColor];
		cell.timelineUnreadCircleView.backgroundColor = [UIColor clearColor];
		cell.timelineUnreadCircleView.layer.cornerRadius = frame.size.width / 2.0f;
		cell.timelineUnreadCircleView.layer.borderWidth = 1.0f;
	}
}

- (void)adjustOpacityForCell:(TimelineCollectionViewCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
	cell.timelineCellLineView.backgroundColor = [UIColor whiteColor];				// same opacity and/or color for all cells
	cell.timelineCellNavigationTargetLabel.layer.opacity = 1.0f;
	cell.timelineCellChapterTitleLabel.layer.opacity = 1.0f;
	
	if (indexPath.section == 0)
	{
		cell.timelineCellChapterInfoGroupingView.layer.opacity = 1.0f;
		cell.timelineCellChapterImageView.layer.opacity = 1.0f;
		cell.timelineCellChapterTitleLabel.backgroundColor = [UIColor whiteColor];
		cell.timelineCellNavigationTargetLabel.backgroundColor = [UIColor colorWithWhite:0.85f alpha:1.0f];
		cell.timelineCellNavigationIndicatorView.layer.opacity = 1.0f;
		cell.timelineCellLineView.layer.opacity = 1.0f;
		cell.timelineUnreadCircleView.layer.opacity = 0.0f;
	}
	else
	{
		cell.timelineCellChapterInfoGroupingView.layer.opacity = 0.0f;
		cell.timelineCellChapterImageView.layer.opacity = 0.0f;
		cell.timelineCellChapterTitleLabel.backgroundColor = [UIColor clearColor];
		cell.timelineCellNavigationTargetLabel.backgroundColor = [UIColor clearColor];
		cell.timelineCellNavigationIndicatorView.layer.opacity = 0.0f;
		cell.timelineCellLineView.layer.opacity = 0.5f;
		cell.timelineUnreadCircleView.layer.opacity = 0.5f;
	}
}

- (void)animateTimelineCell:(TimelineCollectionViewCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
	float xOffset = ((indexPath.row % 2) == 0) ? 10.0f : (-10.0f);

	CGRect cellFrame = cell.frame;
	cellFrame.origin.x += xOffset;
	cell.frame = cellFrame;
	cellFrame.origin.x -= xOffset;
	
	UIView *timelineBranchView = ((indexPath.row % 2) == 0) ? cell.timelineCellBranchLeftView : cell.timelineCellBranchRightView;
	CGRect timelineBranchFrame = timelineBranchView.frame;
	timelineBranchFrame.origin.x -= xOffset;
	timelineBranchFrame.size.height += 40.0f;
	timelineBranchView.frame = timelineBranchFrame;
	timelineBranchFrame.origin.x += xOffset;
	timelineBranchFrame.size.height -= 40.0f;
	
	CGRect timelineCenterlineFrame = cell.timelineCellLineView.frame;
	timelineCenterlineFrame.origin.x -= xOffset;
	cell.timelineCellLineView.frame = timelineCenterlineFrame;
	timelineCenterlineFrame.origin.x += xOffset;
	
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.5f];
	cell.frame = cellFrame;
	timelineBranchView.frame = timelineBranchFrame;
	cell.timelineCellLineView.frame = timelineCenterlineFrame;
	[UIView commitAnimations];
}

#pragma mark - View delegate methods

- (BOOL)prefersStatusBarHidden
{
    return NO;
}

//- (UIStatusBarStyle)preferredStatusBarStyle
//{
//    return UIStatusBarStyleDefault;
//}

#pragma mark - Login scrollview

- (void)presentLoginViewIfNecessary
{
	if (accountExists == NO && loginViewVisible == NO)
		[self performSelector:@selector(presentLoginView) withObject:nil afterDelay:0.8f];
}

- (void)presentLoginView
{
	loginViewVisible = YES;
	[self createBlurredLoginViewBackground];
	[self createLoginScrollView];
	[self initPageControl];
}

- (void)createLoginScrollView
{
	loginScrollView = [[LoginScrollView alloc] initWithFrame:self.view.bounds];
	loginScrollView.userInteractionEnabled = YES;
	loginScrollView.delegate = self;
	[blurredLoginBackgroundView addSubview:loginScrollView];
	[blurredLoginBackgroundView bringSubviewToFront:loginScrollView];
}

- (void)finishLogin
{
	[UIView animateWithDuration:0.5f
						  delay:0.0
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^{
						 blurredLoginBackgroundView.layer.opacity = 0.0f;
					 }
					 completion:^(BOOL finished){
						 [blurredLoginBackgroundView removeFromSuperview];
						 [loginScrollView removeFromSuperview];
						 [loginPageControl removeFromSuperview];
					 }];

	[timelineWebServicesEngine closeAllLoginWebSockets];
	[self updateUserAvatar];											// update image and name
}

- (void)updateUserAvatar
{
	[timelineCustomerDataEngine readAvatarImageFromLocalFilesystem];
	[self.collectionView.collectionViewLayout invalidateLayout];
	[self.collectionView reloadData];
}

- (void)initPageControl
{
	float pageControlWidth = 200.0f;
	float pageControlHeight = 50.0f;
	CGRect frame = CGRectMake((self.view.frame.size.width / 2.0f) - (pageControlWidth / 2.0f), self.view.frame.size.height - pageControlHeight, pageControlWidth, pageControlHeight);
	loginPageControl = [[UIPageControl alloc] initWithFrame:frame];
	loginPageControl.numberOfPages = 4;
	loginPageControl.currentPage = 0;
	loginPageControl.opaque = YES;
	loginPageControl.alpha = 1.0f;
	loginPageControl.pageIndicatorTintColor = [UIColor blackColor];
	loginPageControl.currentPageIndicatorTintColor = [UIColor lightGrayColor];
	loginPageControl.backgroundColor = [UIColor clearColor];
	[loginPageControl addTarget:self action:@selector(loginScrollViewPageChanged) forControlEvents:UIControlEventValueChanged];
	[blurredLoginBackgroundView addSubview:loginPageControl];
	[blurredLoginBackgroundView bringSubviewToFront:loginPageControl];
}

- (void)loginScrollViewPageChanged
{
	CGFloat xOffset = self.view.frame.size.width * loginPageControl.currentPage;
	[loginScrollView setContentOffset:CGPointMake(xOffset, 0.0f) animated:YES];
}

- (void)addFifthPageToPageControl
{
	loginPageControl.numberOfPages = 5;		// ordinal count
	loginPageControl.currentPage = 4;		// index
}

- (BOOL)findCustomerAccount
{
//	return NO;								// for testing login / customer data saving etc. - simulate not having an account by returning NO
	
	if (accountExists == NO)
	{
		accountExists = [timelineWebServicesEngine customerExists];
		
		if (accountExists)
		{
			[timelineWebServicesEngine establishServerConnectionWithExistingAccount];
			[timelineWebServicesEngine closeAllLoginWebSockets];
		}
	}
	
	return accountExists;
}

#pragma mark - Notifications

- (void)registerForNotifications
{
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(finishLogin)
												 name:@"loginViewDoneNotification"
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(updateUserAvatar)
												 name:@"avatarImageReadyNotification"
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(addFifthPageToPageControl)
												 name:@"addFifthPageToPageControl"
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(navigateToSettingsView:)
												 name:@"navigateToSettingsView"
											   object:nil];
}

- (void)unRegisterForNotifications
{
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:@"loginViewDoneNotification"
												  object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:@"avatarImageReadyNotification"
												  object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:@"loginScrollViewPageChange"
												  object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:@"navigateToSettingsView"
												  object:nil];
}

#pragma mark - Scroll view delegate

// note: this is only for the login scroll view, not for the table view

- (void)scrollViewDidScroll:(UIScrollView *)aScrollView
{
	if (aScrollView == self.collectionView)												// ignore normal collection view scroll events
		return;

	float pageWidth = self.view.frame.size.width;
	float speedupThreshold = pageWidth * 2.0f;
	float xOffset = aScrollView.contentOffset.x;
	
	if (xOffset > speedupThreshold)
		xOffset -= (450.0f * (xOffset - speedupThreshold) / xOffset);
	
    int pageIndex = floor((loginScrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
	
	if (pageIndex != currentLoginScrollviewPageIndex)
	{
		currentLoginScrollviewPageIndex = pageIndex;
		loginPageControl.currentPage = currentLoginScrollviewPageIndex;
	}
	
	[loginScrollView positionPageImagesForXOffset:xOffset];
	[loginScrollView determineCurrentScrollDirection];
}

#pragma mark - Blurred backgrounds

- (void)createBlurredLoginViewBackground
{
	UIGraphicsBeginImageContextWithOptions(self.view.frame.size, NO, 1.0f);
	[self.view drawViewHierarchyInRect:self.view.bounds afterScreenUpdates:NO];
	UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	UIImage *blurredImage = [newImage applyDarkEffect];
	blurredImage = [blurredImage applyPartialDarkEffect];								// for some stupid reason, we need to blur again on collection views
	blurredLoginBackgroundView = [[UIImageView alloc] initWithImage:blurredImage];
	blurredLoginBackgroundView.layer.opacity = 0.0f;
	blurredLoginBackgroundView.userInteractionEnabled = YES;							// prevent taps and swipes from passing through to the tab bar and table view
	blurredLoginBackgroundView.layer.zPosition = 2000;
	[self.tabBarController.view addSubview:blurredLoginBackgroundView];					// make sure the blurred background image covers the tab bar as well
	
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.5f];
	blurredLoginBackgroundView.layer.opacity = 1.0f;
	[UIView commitAnimations];
}

- (void)adjustStatusBar
{
	[self.statusBarBackground removeFromSuperview];
	self.statusBarBackground.backgroundColor = [UIColor whiteColor];
	[self.tabBarController.view addSubview:self.statusBarBackground];					// note: adding to tab bar controller will show this status bar in *all* views
}

#pragma mark - Solid background

- (void)setSolidBackgroundColor
{
	UIColor *color = [UIColor colorWithRed:0.925f green:0.522f blue:0.0f alpha:1.0f];
	self.tabBarController.view.backgroundColor = color;
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"segueFromCollectionItemToReadView"])
	{
		NSIndexPath *chapterDataPath = [self chapterDataPathForTimelinePath:currentChapterIndexPath];
		ReadViewController *readViewController = segue.destinationViewController;
        NSArray *sectionsArray = [timelineViewDataController getSectionsList];
		PageSections *pageSection = sectionsArray[chapterDataPath.section];
        NSMutableArray *contentArray = [[timelineViewChapterDataController getAllChaptersContent] mutableCopy];
		readViewController.contentArray = contentArray;
        readViewController.selectedPage = 0;
        for (int index = 0; index < chapterDataPath.section; index++) {
            readViewController.selectedPage += [[timelineViewChapterDataController sectionArrayForIndex:index] count];
        }
        readViewController.selectedPage += chapterDataPath.row;
		readViewController.sectionName = pageSection.tagName;
		readViewController.oldCurProgressPercentageInt = [timelineViewChapterDataController getChapterCurrentProgressForIndexPath:chapterDataPath];
		readViewController.oldMaxProgressPercentageInt = [timelineViewChapterDataController getChapterMaxProgressForIndexPath:chapterDataPath];
		readViewController.parentViewIsTimeline = YES;
		readViewController.readViewQuizDataController = timelineViewQuizDataController;
		readViewController.readViewWebServicesEngine = timelineWebServicesEngine;
	}
}

- (void)navigateToSettingsView:(id)sender;
{
	[self.tabBarController setSelectedIndex:3];
}

#pragma mark - Memory

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
