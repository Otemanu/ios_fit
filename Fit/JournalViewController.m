//
//  JournalViewController.m
//  Fit
//
//  Created by Rich on 2/6/14.
//  Copyright (c) 2014 mobifusion. All rights reserved.
//

#import "JournalViewController.h"
#import <CoreImage/CoreImage.h>
#import <MobileCoreServices/MobileCoreServices.h>

@interface JournalViewController ()

@property (strong, nonatomic) NSMutableArray *photoDataArray;		// 2-d array: [week index][photo index] and it contains a dictionary per photo
@property (strong, nonatomic) NSMutableArray *tempPhotoDataArray;	// needed to check for missing photo assets (when user deletes photos from the yogalosophy album)
@property (strong, nonatomic) UILabel *journalViewTitleLabel;
@property (strong, atomic) ALAssetsLibrary *assetsLibrary;

@end

@implementation JournalViewController

#pragma mark - Private constants and variables

static int currentWeekIndex = 0;									// the current week and photo indices are both set when the user taps on an "add photo" button
static int currentPhotoIndex = 0;
static int currentEmotionIndex = kNeutral;							// this is set when the user taps an emotion button in the emotion view
static BOOL takingPhoto = NO;										// don't check for deleted photos when we return from taking a photo
static const float kTableRowHeight = 120.0f;
static const float kPhotoWidth = 150.0f;
static const float kPhotoHeight = 100.0f;
static const float kSectionHeaderHeight = 15.0f;
static const float kPhotoFrameXOffset = 0.0f;
static const float kPhotoFrameYOffset = 20.0f;
static const float kPhotoFrameGap = 20.0f;
static const float kPhotoFrameLeftMargin = 20.0f;
static const int kWeekCount = 4;
static const int kAddPhotoTag = 99999;
static NSString *kCellIdentifier = @"JournalViewTableCell";
static NSString *kImageAssetURLKey = @"url";
static NSString *kEmotionIndexKey = @"emo";
static CGRect cellPhotoReferenceFrame;

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	[self initTitle];
	[self initCellPhotoReferenceFrame];
	[self initAssetsLibrary];
	[self configureTable];
	[self registerForNotifications];
//	[[CustomerDataEngine customerDataEngine] writeJournalPhotoDataToLocalFilesystem:nil];	// for testing only: erase the file by passing in nil value
}

- (void)viewWillAppear:(BOOL)animated
{
	[self initPhotoDataArray];
	[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
	[self hideTableCells];
	
	if (takingPhoto)
	{
		[self showTableCells];
		takingPhoto = NO;
	}
	else
	{
		[self updatePhotoDataArrayIfNecessary];
	}
}

- (void)viewDidAppear:(BOOL)animated
{
}

#pragma mark - View delegate methods

- (BOOL)prefersStatusBarHidden
{
    return NO;
}

-(UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleDefault;
}

#pragma mark - View initialization

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
	
    if (self)
	{
        // custom initialization
    }
	
    return self;
}

- (void)initTitle
{
	if (self.journalViewTitleLabel == nil)
	{
		float insetWidth = 100.0f;
		CGFloat titleWidth = self.view.frame.size.width - (insetWidth * 2.0f);
		CGFloat titleHeight = self.navigationController.navigationBar.frame.size.height;
		CGRect titleRect = CGRectMake(insetWidth, 0.0f, titleWidth, titleHeight);
		self.journalViewTitleLabel = [[UILabel alloc] initWithFrame:titleRect];
		self.journalViewTitleLabel.text = @"Journal";
		self.journalViewTitleLabel.textColor = [UIColor grayColor];
		self.journalViewTitleLabel.textAlignment = NSTextAlignmentCenter;
		self.journalViewTitleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:20.0f];
		[self.navigationItem setTitleView:self.journalViewTitleLabel];
	}
}

- (void)initCellPhotoReferenceFrame
{
	// note: the assets library returns 157x157 pixel thumbnails, so the best we can do is center them in each rectangular uiimageview in table cells
	cellPhotoReferenceFrame = CGRectMake(kPhotoFrameXOffset, kPhotoFrameYOffset, kPhotoWidth, kPhotoHeight);
}

- (void)addAddPhotoBackgroundToPhoto:(JournalCellPhoto *)journalCellPhoto
{
	journalCellPhoto.layer.borderColor = [[UIColor lightGrayColor] CGColor];
	journalCellPhoto.layer.borderWidth = 1.0f;

	CGRect plusLabelFrame = CGRectMake(0.0f, 10.0f, cellPhotoReferenceFrame.size.width, 60.0f);
	UILabel *addPhotoPlusLabel = [[UILabel alloc] initWithFrame:plusLabelFrame];
	addPhotoPlusLabel.textAlignment = NSTextAlignmentCenter;
	addPhotoPlusLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:50.0f];
	addPhotoPlusLabel.textColor = [UIColor lightGrayColor];
	addPhotoPlusLabel.text = @"+";
	[journalCellPhoto addSubview:addPhotoPlusLabel];
	
	CGRect addPhotoLabelFrame = CGRectMake(0.0f, 60.0f, cellPhotoReferenceFrame.size.width, 30.0f);
	UILabel *addPhotoLabel = [[UILabel alloc] initWithFrame:addPhotoLabelFrame];
	addPhotoLabel.textAlignment = NSTextAlignmentCenter;
	addPhotoLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:16.0f];
	addPhotoLabel.textColor = [UIColor lightGrayColor];
	addPhotoLabel.text = NSLocalizedString(@"add photo", @"add photo");
	[journalCellPhoto addSubview:addPhotoLabel];
}

- (void)initAssetsLibrary
{
	if (self.assetsLibrary == nil)
		self.assetsLibrary = [[ALAssetsLibrary alloc] init];
}

- (void)initPhotoDataArray
{
	// note: photo data array contains only serializable "property list" objects like NSString, NSDictionary, etc.
	// this allows us to save it directly to disk with writeToFile:, then read it back later with arrayWithContentsOfFile:
	
	if (self.photoDataArray == nil)
	{
		self.photoDataArray = [[CustomerDataEngine customerDataEngine] readJournalPhotoDataFromLocalFilesystem];

		if (self.photoDataArray == nil)
		{
			self.photoDataArray = [[NSMutableArray alloc] initWithCapacity:kWeekCount];
			[self.photoDataArray addObject:[[NSMutableArray alloc] initWithCapacity:0]];
			[self.photoDataArray addObject:[[NSMutableArray alloc] initWithCapacity:0]];
			[self.photoDataArray addObject:[[NSMutableArray alloc] initWithCapacity:0]];
			[self.photoDataArray addObject:[[NSMutableArray alloc] initWithCapacity:0]];
		}
	}
}

- (void)configureTable
{
	CGPoint offsetPoint = CGPointMake(0.0f, -20.0f);
	[self.tableView setContentOffset:offsetPoint animated:NO];
}

#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JournalViewTableCell *journalCell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier forIndexPath:indexPath];
	journalCell.journalCellPhotoScrollView.alpha = 0.0f;			// hide cell contents until animation
	[self populatePhotoScrollView:journalCell.journalCellPhotoScrollView forIndexPath:indexPath];
	[self adjustScrollViewSizeForCell:journalCell];
	[self showCell:journalCell forIndexPath:indexPath];
	return journalCell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
	float headerYOffset = 10.0f;
	UIView *sectionTitleView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, headerYOffset, self.view.frame.size.width, kSectionHeaderHeight)];
	sectionTitleView.backgroundColor = [UIColor whiteColor];
	
	float labelXOffset = 20.0f;
	float labelYOffset = 10.0f;
	UILabel *sectionTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(labelXOffset, labelYOffset, self.view.frame.size.width, kSectionHeaderHeight)];
	[sectionTitleView addSubview:sectionTitleLabel];
	sectionTitleLabel.backgroundColor = [UIColor clearColor];
	sectionTitleLabel.text = [NSString stringWithFormat:@"%@ %d", NSLocalizedString(@"WEEK", @"WEEK"), section + 1];
	sectionTitleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:14.0f];
	sectionTitleLabel.textColor = [UIColor lightGrayColor];
	return sectionTitleView;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return kWeekCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kTableRowHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	return kSectionHeaderHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
	return 0.0f;
}

#pragma mark - Table view methods

- (void)populatePhotoScrollView:(JournalCellPhotoScrollView *)photoScrollView forIndexPath:(NSIndexPath *)indexPath
{
	[[photoScrollView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
	photoScrollView.tag = indexPath.section;						// same tag in the scrollview to make it easier to determine which cell everything is in

	currentWeekIndex = indexPath.section;							// we use currentWeekIndex and currentPhotoIndex in the add* methods below
	CGRect currentPhotoFrame = cellPhotoReferenceFrame;				// start at 0 x offset
	float xOffset = kPhotoFrameLeftMargin;

	for (currentPhotoIndex = 0; currentPhotoIndex <= [self.photoDataArray[indexPath.section] count]; currentPhotoIndex++)
	{
		currentPhotoFrame.origin.x = xOffset;
		[self addJournalCellPhotoToScrollView:photoScrollView forFrame:currentPhotoFrame];
		[self addNavigationButtonToScrollView:photoScrollView forFrame:currentPhotoFrame];
		xOffset += cellPhotoReferenceFrame.size.width + kPhotoFrameGap;
	}
}

- (void)addJournalCellPhotoToScrollView:(JournalCellPhotoScrollView *)photoScrollView forFrame:(CGRect)currentPhotoFrame
{
	JournalCellPhoto *journalCellPhoto = [[JournalCellPhoto alloc] initWithFrame:currentPhotoFrame];

	if (currentPhotoIndex == [self.photoDataArray[currentWeekIndex] count])
	{
		journalCellPhoto.tag = kAddPhotoTag;
		journalCellPhoto.image = nil;
		journalCellPhoto.backgroundColor = [UIColor whiteColor];
		[self addAddPhotoBackgroundToPhoto:journalCellPhoto];
		[photoScrollView addSubview:journalCellPhoto];
	}
	else
	{
		ALAssetsLibraryAssetForURLResultBlock resultblock = ^(ALAsset *imageAsset)
		{
			journalCellPhoto.image = [UIImage imageWithCGImage:imageAsset.thumbnail];
			[photoScrollView addSubview:journalCellPhoto];
		};
		
		ALAssetsLibraryAccessFailureBlock failureblock = ^(NSError *error )
		{
			NSLog(@"ALAssetsLibraryAccessFailureBlock: error %@", error);
		};
		
		NSString *journalCellImageAssetString = [self.photoDataArray[currentWeekIndex][currentPhotoIndex] valueForKey:kImageAssetURLKey];
		NSURL *journalCellImageAssetURL = [NSURL URLWithString:journalCellImageAssetString];
		[self.assetsLibrary assetForURL:journalCellImageAssetURL resultBlock:resultblock failureBlock:failureblock];
	}
}

- (void)addNavigationButtonToScrollView:(UIScrollView *)photoScrollView forFrame:(CGRect)currentPhotoFrame
{
	UIButton *journalCellPhotoButton = [[UIButton alloc] initWithFrame:currentPhotoFrame];
	journalCellPhotoButton.backgroundColor = [UIColor clearColor];
	
	if (currentPhotoIndex == [self.photoDataArray[currentWeekIndex] count])
	{
		[journalCellPhotoButton addTarget:self action:@selector(showAddPhotoActionSheet:) forControlEvents:UIControlEventTouchUpInside];
		journalCellPhotoButton.tag = kAddPhotoTag;					// use a special tag to make it easier to determine whether user tapped "add" button or real photo button
	}
	else
	{
		[journalCellPhotoButton addTarget:self action:@selector(segueToPhotoView:) forControlEvents:UIControlEventTouchUpInside];
		journalCellPhotoButton.tag = currentPhotoIndex;				// we'll need the real photo index later, when the user taps on the button
	}

	[photoScrollView addSubview:journalCellPhotoButton];
}

- (void)addNavigationButtonForNewlyAddedThumbnailInCell:(JournalViewTableCell *)journalCell
{
	int rowIndex = journalCell.journalCellPhotoScrollView.tag;
	int photoCount = [self.photoDataArray[rowIndex] count];
	float xOffset = kPhotoFrameLeftMargin + (photoCount - 1) * (kPhotoFrameGap + kPhotoWidth);
	CGRect currentPhotoFrame = cellPhotoReferenceFrame;
	currentPhotoFrame.origin.x = xOffset;
	currentPhotoIndex = [self.photoDataArray[currentWeekIndex] count] - 1;
	[self addNavigationButtonToScrollView:journalCell.journalCellPhotoScrollView forFrame:currentPhotoFrame];
}

- (void)adjustScrollViewSizeForCell:(JournalViewTableCell *)journalViewTableCell
{
	int weekIndex = journalViewTableCell.journalCellPhotoScrollView.tag;	// scrollview's tag is the week index (and row index and data array 1st index)
	int imageCount = [self.photoDataArray[weekIndex] count] + 1;			// add 1 for the "add photo" button after the thumbnails
	float scrollWidth =  (float)imageCount * (kPhotoWidth + kPhotoFrameLeftMargin) + kPhotoFrameLeftMargin;
	
	if ((float)scrollWidth < self.view.frame.size.width)
		scrollWidth = self.view.frame.size.width;
	
	CGSize scrollViewSize = CGSizeMake(scrollWidth, kPhotoHeight);
	journalViewTableCell.journalCellPhotoScrollView.contentSize = scrollViewSize;
}

#pragma mark - Table cell animation

- (void)animateNewPhotoIntoTableCell
{
	// simultaneously move the "add photo" cell to the right one spot and fade-in + zoom in the new photo in its place
	JournalViewTableCell *journalCell = (JournalViewTableCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:currentWeekIndex]];
	[self adjustScrollViewSizeForCell:journalCell];
	[self moveAddPhotoImageToRightInCell:journalCell];
	[self moveAddPhotoButtonToRightInCell:journalCell];
	[self fadeInNewPhotoInCell:journalCell];
	[self addNavigationButtonForNewlyAddedThumbnailInCell:journalCell];
}

- (void)moveAddPhotoImageToRightInCell:(JournalViewTableCell *)journalCell
{
	JournalCellPhoto *addPhoto = nil;
	
	for (id journalCellSubview in journalCell.journalCellPhotoScrollView.subviews)
	{
		if ([journalCellSubview isMemberOfClass:[JournalCellPhoto class]])
		{
			JournalCellPhoto *journalCellPhoto = (JournalCellPhoto *)journalCellSubview;

			if (journalCellPhoto.image == nil)						// the 'add photo' image is nil
			{
				addPhoto = journalCellPhoto;
				break;
			}
		}
	}
	
	if (addPhoto)
	{
		CGRect newFrame = addPhoto.frame;
		newFrame.origin.x += (cellPhotoReferenceFrame.size.width + kPhotoFrameGap);
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationDuration:0.4f];
		addPhoto.frame = newFrame;
		[UIView commitAnimations];
	}
}

- (void)moveAddPhotoButtonToRightInCell:(JournalViewTableCell *)journalCell
{
	UIButton *addPhotoButton = nil;
	
	for (id journalCellSubview in journalCell.journalCellPhotoScrollView.subviews)
	{
		if ([journalCellSubview isMemberOfClass:[UIButton class]])
		{
			UIButton *journalCellButton = (UIButton *)journalCellSubview;

			if (journalCellButton.tag == kAddPhotoTag)
			{
				addPhotoButton = journalCellButton;
				break;
			}
		}
	}
	
	if (addPhotoButton)
	{
		CGRect newFrame = addPhotoButton.frame;
		newFrame.origin.x += (cellPhotoReferenceFrame.size.width + kPhotoFrameGap);
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationDuration:0.4f];
		addPhotoButton.frame = newFrame;
		[UIView commitAnimations];
	}
}

- (void)fadeInNewPhotoInCell:(JournalViewTableCell *)journalCell
{
	// the new photo's thumbnail has already been added to the array, so all we do is fade it in where the "add photo" button was before we moved it
	int rowIndex = journalCell.journalCellPhotoScrollView.tag;
	int photoCount = [self.photoDataArray[rowIndex] count];
	float xOffset = kPhotoFrameLeftMargin + (photoCount - 1) * (kPhotoFrameGap + kPhotoWidth);

	CGRect photoStartFrame = cellPhotoReferenceFrame;				// create start/end frames for fade-in + zoom animation
	photoStartFrame.origin.x = xOffset;
	CGRect photoEndFrame = photoStartFrame;
	photoStartFrame.size.width = photoEndFrame.size.width * 0.80f;
	photoStartFrame.size.height = photoEndFrame.size.height * 0.80f;
	photoStartFrame.origin.x += (photoEndFrame.size.width / 2.0f) - (photoStartFrame.size.width / 2.0f);
	photoStartFrame.origin.y += (photoEndFrame.size.height / 2.0f) - (photoStartFrame.size.height / 2.0f);
	JournalCellPhoto *journalCellPhoto = [[JournalCellPhoto alloc] initWithFrame:photoStartFrame];

	ALAssetsLibraryAssetForURLResultBlock resultblock = ^(ALAsset *imageAsset)
	{
		journalCellPhoto.image = [UIImage imageWithCGImage:imageAsset.thumbnail];
		journalCellPhoto.alpha = 0.0f;
		[journalCell.journalCellPhotoScrollView addSubview:journalCellPhoto];
		
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationDuration:0.4f];
		journalCellPhoto.frame = photoEndFrame;
		journalCellPhoto.alpha = 1.0f;
		[UIView commitAnimations];
	};
	
	ALAssetsLibraryAccessFailureBlock failureblock = ^(NSError *error )
	{
		NSLog(@"ALAssetsLibraryAccessFailureBlock: error %@", error);
	};
	
	NSString *journalCellImageAssetString = [self.photoDataArray[rowIndex][photoCount - 1] valueForKey:kImageAssetURLKey];
	NSURL *journalCellImageAssetURL = [NSURL URLWithString:journalCellImageAssetString];
	[self.assetsLibrary assetForURL:journalCellImageAssetURL resultBlock:resultblock failureBlock:failureblock];
}

- (void)showTableCells
{
	int rowCount = [self numberOfSectionsInTableView:self.tableView];
	
	for (int rowIndex = 0; rowIndex < rowCount; rowIndex++)
	{
		NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:rowIndex];
		JournalViewTableCell *journalCell = (JournalViewTableCell *)[self.tableView cellForRowAtIndexPath:indexPath];
		[self showCell:journalCell forIndexPath:indexPath];
	}
}

- (void)showCell:(JournalViewTableCell *)journalCell forIndexPath:(NSIndexPath *)indexPath
{
	float delayFloat = indexPath.section * 0.1f;

	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delayFloat * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
		[self performCellAnimation:journalCell];
	});
}

- (void)performCellAnimation:(JournalViewTableCell *)journalCell
{
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.4f];
	journalCell.journalCellPhotoScrollView.alpha = 1.0f;
	[UIView commitAnimations];
}

- (void)hideTableCells
{
	int rowCount = [self numberOfSectionsInTableView:self.tableView];
	
	for (int rowIndex = 0; rowIndex < rowCount; rowIndex++)
	{
		NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:rowIndex];
		JournalViewTableCell *journalCell = (JournalViewTableCell *)[self.tableView cellForRowAtIndexPath:indexPath];
		journalCell.journalCellPhotoScrollView.alpha = 0.0f;
	}
}

#pragma mark - Handling removed photos

// it is possible that the user has deleted photos from the yogalosophy album.  we handle that here.
// yes, the ALAssetsLibraryChangedNotification is sent and we receive it the next time we become active.
// but that notification is always sent for every change, including when user adds existing photos or newly taken photos.
// and when photos are deleted, the notification doesn't tell us which one(s) is/are now gone.
// so we'd still need to find the missing photos and remove their dictionaries from the photo data array anyway.

- (void)updatePhotoDataArrayIfNecessary
{
	[self createTempPhotoDataArray];
	[self populateTempPhotoDataArray];
}

- (void)createTempPhotoDataArray
{
	if (self.tempPhotoDataArray)
		[self.tempPhotoDataArray removeAllObjects];
	else
		self.tempPhotoDataArray = [[NSMutableArray alloc] initWithCapacity:0];

	[self.tempPhotoDataArray addObject:[[NSMutableArray alloc] initWithCapacity:0]];
	[self.tempPhotoDataArray addObject:[[NSMutableArray alloc] initWithCapacity:0]];
	[self.tempPhotoDataArray addObject:[[NSMutableArray alloc] initWithCapacity:0]];
	[self.tempPhotoDataArray addObject:[[NSMutableArray alloc] initWithCapacity:0]];
}

- (void)populateTempPhotoDataArray
{
	__block int currentImageCount = [self getCountForPhotoDataArray:self.photoDataArray];
	__block int imagesHandledCount = 0;
	
	for (int weekIndex = 0; weekIndex < kWeekCount; weekIndex++)
	{
		NSMutableArray *tempWeekPhotoArray = self.tempPhotoDataArray[weekIndex];
		
		for (NSDictionary *photoDict in self.photoDataArray[weekIndex])
		{
			ALAssetsLibraryAssetForURLResultBlock resultblock = ^(ALAsset *imageAsset)
			{
				if (imageAsset)										// asset will be nil if user has removed the photo from the yogalosophy album
					[tempWeekPhotoArray addObject:photoDict];
				
				if (++imagesHandledCount == currentImageCount)		// quit when we've checked all assets for existence
					[[NSNotificationCenter defaultCenter] postNotificationName:@"updatePhotoAssetsNotification" object:nil];
			};
			
			ALAssetsLibraryAccessFailureBlock failureblock = ^(NSError *error )
			{
				NSLog(@"populateTempPhotoDataArray: error = %@", error);
			};
			
			NSString *imageAssetString = photoDict[kImageAssetURLKey];
			NSURL *imageAssetURL = [NSURL URLWithString:imageAssetString];
			[self.assetsLibrary assetForURL:imageAssetURL resultBlock:resultblock failureBlock:failureblock];
		}
	}
}

- (int)getCountForPhotoDataArray:(NSArray *)photoArray
{
	int imageCount = 0;
	
	for (int weekIndex = 0; weekIndex < kWeekCount; weekIndex++)
		imageCount += [photoArray[weekIndex] count];
	
	return imageCount;
}

- (void)updatePhotoAssets
{
	int currentPhotoCount = [self getCountForPhotoDataArray:self.photoDataArray];
	int updatedPhotoCount = [self getCountForPhotoDataArray:self.tempPhotoDataArray];
	
	if (currentPhotoCount == updatedPhotoCount)
	{
		[self showTableCells];
	}
	else
	{
		[self updatePhotoDataArray];
		[self.tableView reloadData];
		[[CustomerDataEngine customerDataEngine] writeJournalPhotoDataToLocalFilesystem:self.photoDataArray];
	}
	
	[self.tempPhotoDataArray removeAllObjects];
}

- (void)updatePhotoDataArray
{
	[self.photoDataArray removeAllObjects];
	[self.photoDataArray addObjectsFromArray:self.tempPhotoDataArray];
}

#pragma mark - Image picker launch methods

- (BOOL)startCameraControllerFromViewController:(UIViewController*)controller
								  usingDelegate:(id <UIImagePickerControllerDelegate, UINavigationControllerDelegate>)delegate
{
	if (delegate == nil || controller == nil)
		return NO;

	if (([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] == NO))
		return NO;

	UIImagePickerController *cameraUI = [[UIImagePickerController alloc] init];
	cameraUI.sourceType = UIImagePickerControllerSourceTypeCamera;
	cameraUI.mediaTypes = [[NSArray alloc] initWithObjects: (NSString *)kUTTypeImage, nil];
	// the following line allows all media types: still image and video
//	cameraUI.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
	cameraUI.allowsEditing = NO;									// 'no' hides the controls for moving & scaling pictures
	cameraUI.delegate = delegate;

	[controller presentViewController:cameraUI animated:YES completion:^{
	}];

	return YES;
}

- (BOOL)startMediaBrowserFromViewController:(UIViewController*)controller
							   usingDelegate:(id <UIImagePickerControllerDelegate, UINavigationControllerDelegate>)delegate
{
	if (delegate == nil || controller == nil)
		return NO;
	
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary] == NO)
        return NO;
	
    UIImagePickerController *mediaUI = [[UIImagePickerController alloc] init];
    mediaUI.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    mediaUI.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    mediaUI.allowsEditing = NO;										// hides the controls for moving & scaling pictures
    mediaUI.delegate = delegate;

	[controller presentViewController:mediaUI animated:YES completion:^{
	}];

    return YES;
}

#pragma mark - Image picker delegate methods

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
	// un-hide the status bar before the completion block, otherwise the animation will complete before image picker's animtion completes
	[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];

    [self dismissViewControllerAnimated:YES completion:^{
	}];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSString *mediaType = [info objectForKey: UIImagePickerControllerMediaType];
    UIImage *originalImage, *editedImage, *imageToSave;
	
    if (CFStringCompare ((CFStringRef)mediaType, kUTTypeImage, 0) == kCFCompareEqualTo)
	{
        editedImage = (UIImage *)[info objectForKey:UIImagePickerControllerEditedImage];
        originalImage = (UIImage *)[info objectForKey:UIImagePickerControllerOriginalImage];
		
        if (editedImage)
            imageToSave = editedImage;
        else
            imageToSave = originalImage;

		// saves to camera roll *and* "Yogalosophy" album
		[self.assetsLibrary saveImage:imageToSave toAlbum:@"Yogalosophy" withCompletionBlock:^(NSError *error)
		{
			if (error)
				NSLog(@"saveImage: failed with error %@", error);
		}];
    }
//	else if (CFStringCompare ((CFStringRef)mediaType, kUTTypeMovie, 0) == kCFCompareEqualTo)	// movie capture if and when we add this feature
//	{
//		NSString *moviePath = (NSString *)[[info objectForKey:UIImagePickerControllerMediaURL] path];
//
//		if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum (moviePath))
//			UISaveVideoAtPathToSavedPhotosAlbum (moviePath, nil, nil, nil);
//	}
	
	// un-hide the status bar before the completion block, otherwise the animation will complete before image picker's animtion completes
	[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];

    [self dismissViewControllerAnimated:YES completion:^{
	}];
}

#pragma mark - Add photo action sheet

- (void)showAddPhotoActionSheet:(id)sender
{
	UIButton *senderButton = (UIButton *)sender;
	JournalCellPhotoScrollView *journalScrollView = (JournalCellPhotoScrollView *)senderButton.superview;
	currentWeekIndex = journalScrollView.tag;						// tag = row index of the table to which we will add the thumbnail, etc.
	takingPhoto = YES;
	
	NSString *addPhotoTitle = NSLocalizedString(@"Add Photo", @"Add Photo");
	NSString *cancelTitle = NSLocalizedString(@"Cancel", @"Cancel");
	NSString *takeTitle = NSLocalizedString(@"Take new photo", @"Take new photo");
	NSString *chooseTitle = NSLocalizedString(@"Choose existing photo", @"Choose existing photo");
	
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:addPhotoTitle
															 delegate:self
													cancelButtonTitle:cancelTitle
											   destructiveButtonTitle:nil
													otherButtonTitles:takeTitle, chooseTitle, nil];
	[actionSheet showFromTabBar:self.tabBarController.tabBar];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == 0)
		[self startCameraControllerFromViewController:self usingDelegate:self];
	else if (buttonIndex == 1)
		[self startMediaBrowserFromViewController:self usingDelegate:self];
}

#pragma mark - Notifications and actions

- (void)registerForNotifications
{
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleJournalImageSavedNotification:)
												 name:@"journalViewControllerImageSavedNotification"
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(updatePhotoAssets)
												 name:@"updatePhotoAssetsNotification"
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(updatePhotoDataArrayIfNecessary)
												 name:@"updatePhotoAssetsEnteringForegroundNotification"
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleEmoticonButtonTap:)
												 name:@"emoticonButtonTappedNotification"
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleEmoticonViewOKButtonTap:)
												 name:@"emoticonViewOKButtonTappedNotification"
											   object:nil];
}

- (void)unRegisterForNotifications
{
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:@"journalViewControllerImageSavedNotification"
												  object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:@"updatePhotoAssetsNotification"
												  object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:@"updatePhotoAssetsEnteringForegroundNotification"
												  object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:@"emoticonButtonTappedNotification"
												  object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:@"emoticonViewOKButtonTappedNotification"
												  object:nil];
}

- (void)handleJournalImageSavedNotification:(NSNotification *)aNotification
{
	NSURL *photoURL = (NSURL *)aNotification.object;
	NSMutableDictionary *photoDict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
									  photoURL.absoluteString, kImageAssetURLKey,					// the photo asset
									  [NSNumber numberWithInt:kNeutral], kEmotionIndexKey,			// associate the default neutral emotion with the new photo
									  nil];
	[self.photoDataArray[currentWeekIndex] addObject:photoDict];
	[[CustomerDataEngine customerDataEngine] writeJournalPhotoDataToLocalFilesystem:self.photoDataArray];
	[self animateNewPhotoIntoTableCell];
}

- (void)handleEmoticonButtonTap:(NSNotification *)aNotification
{
	NSNumber *emotionIndexNumber = (NSNumber *)aNotification.object;
	currentEmotionIndex = emotionIndexNumber.intValue;
	NSMutableDictionary *photoDict = self.photoDataArray[currentWeekIndex][currentPhotoIndex];
	[photoDict setObject:[NSNumber numberWithInt:currentEmotionIndex] forKey:kEmotionIndexKey];		// update the emotion associated with the photo, but don't save the photo data array yet
}

- (void)handleEmoticonViewOKButtonTap:(NSNotification *)aNotification
{
	// save the photo data array only after user confirms by tapping OK button
	[[CustomerDataEngine customerDataEngine] writeJournalPhotoDataToLocalFilesystem:self.photoDataArray];
}

#pragma mark - Navigation

- (void)segueToPhotoView:(id)sender
{
	if ([sender isMemberOfClass:[UIButton class]])
	{
		UIButton *photoButton = (UIButton *)sender;
		JournalCellPhotoScrollView *scrollView = (JournalCellPhotoScrollView *)photoButton.superview;
		currentWeekIndex = scrollView.tag;															// set week and photo indices so we can give the correct image asset URL to the photo view in prepareForSegue:
		currentPhotoIndex = photoButton.tag;
		currentEmotionIndex = [[self.photoDataArray[currentWeekIndex][currentPhotoIndex] valueForKey:kEmotionIndexKey] intValue];
		[self performSegueWithIdentifier:@"photoViewSegue" sender:self];
	}
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	JournalPhotoViewController *photoViewController = (JournalPhotoViewController *)segue.destinationViewController;
	NSString *journalCellImageAssetString = [self.photoDataArray[currentWeekIndex][currentPhotoIndex] valueForKey:kImageAssetURLKey];
	NSURL *journalCellImageAssetURL = [NSURL URLWithString:journalCellImageAssetString];
	photoViewController.journalPhotoAssetURL = journalCellImageAssetURL;
	photoViewController.emotionalStateIndex = currentEmotionIndex;
	photoViewController.assetsLibrary = self.assetsLibrary;
}

#pragma mark - Memory

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
