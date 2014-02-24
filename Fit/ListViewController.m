//
//  ListViewController.m
//  Fit
//
//  Created by Rich on 11/3/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//

#import "ListViewController.h"
#import "ProgressBarView.h"
#import "ReadViewController.h"
#import "settings.h"
#import "PageInstance.h"
#import "WebServicesEngine.h"

@interface ListViewController ()

@property UILabel *tableHeaderContinueReadingLabel;
@property UILabel *tableHeaderCurrentChapterTitleLabel;
@property UIImageView *tableHeaderCurrentChapterBackgroundImageView;
@property(nonatomic) NSInteger categoryCount;

@property NSMutableArray *chapterTitleArray;

@end

enum ListViewTableCellTags
{
	kListViewTableCellChapterNumberTag	= 1001,
	kListViewTableCellChapterTitleTag	= 1002,
};

static float kTableRowHeight = 90.0f;
static float kFirstPartPercentage  = 19.0f;
static float kSecondPartPercentage = 39.0f;
static float kThirdPartPercentage  = 59.0f;
static float kFourthPartPercentage = 79.0f;
static float kFifthPartPercentage  = 99.0f;
static float headerDisclosureIndicatorThreshold  = 80.0f;
static CGFloat titleLabelFontSizeMax = 36.0f;

UIImageView *headerImageMaskView;
ProgressBarView *progressBarView = nil;
ProgressBarView *progressBarShadowView = nil;
NSIndexPath *currentChapterIndex;
int curProgressPercentageInt = 0;
int maxProgressPercentageInt = 0;
UILabel *progressMessageLabel = nil;									// create new class for label with rounded rect
RoundedRectView *progressMessageRoundedRect = nil;

@implementation ListViewController

WebServicesEngine *listViewWebServicesEngine = nil;						// singleton engine instantiations
ChapterDataController *listViewChapterDataController = nil;
QuizDataController *listViewQuizDataController = nil;

#pragma mark - Initialization

- (void)initWebServicesEngine
{
	listViewWebServicesEngine = [WebServicesEngine webServicesEngine];
}

- (void)initDataEngines
{
	listViewChapterDataController = [ChapterDataController sharedChapterDataController];
	listViewQuizDataController = [QuizDataController sharedQuizDataController];
}

- (void)initProgressView
{
	CGRect progressFrame = CGRectMake(0.0f, self.chapterHeaderView.frame.size.height - 30.0f, self.view.frame.size.width, 20.0f);
	progressBarView = [[ProgressBarView alloc] initWithFrame:progressFrame];
	progressBarView.progressBarColor = [UIColor whiteColor];
	progressBarView.layer.zPosition = 20;
	[self.chapterHeaderView addSubview:progressBarView];
	curProgressPercentageInt = [listViewChapterDataController getChapterCurrentProgressForIndexPath:currentChapterIndex];
	maxProgressPercentageInt = [listViewChapterDataController getChapterMaxProgressForIndexPath:currentChapterIndex];
	[progressBarView createOffscreenProgressBarForPercentage:maxProgressPercentageInt];
	
	CGRect progressShadowFrame = progressFrame;
	progressShadowFrame.origin.y += 0.5f;
	progressBarShadowView = [[ProgressBarView alloc] initWithFrame:progressShadowFrame];
	progressBarShadowView.progressBarColor = [UIColor whiteColor];
	progressBarShadowView.layer.zPosition = 19;
	progressBarShadowView.layer.shadowRadius = 10.0f;
	progressBarShadowView.layer.shadowOpacity = 0.6f;
	progressBarShadowView.clipsToBounds = NO;
	[self.chapterHeaderView addSubview:progressBarShadowView];
	[progressBarShadowView createOffscreenProgressBarForPercentage:maxProgressPercentageInt];
}

- (void)configureTable
{
	[self.chapterTableView.layer setMasksToBounds:YES];
	self.chapterTableView.layer.zPosition = 0.0f;
	self.chapterTableView.scrollsToTop = YES;
	[self configureChapterTableHeaderView];
	[self configureTableHeaderView];
	[self configureTableFooterView];
}

- (void)configureChapterTableHeaderView
{
	self.chapterHeaderView.layer.opacity = 1.0f;
	self.chapterHeaderView.hidden = NO;
	self.chapterHeaderView.opaque = YES;
	self.chapterHeaderView.layer.zPosition = 0.0f;
	CGRect backgroundImageFrame = CGRectMake(0.0f, (self.chapterHeaderView.frame.size.height / 2.0f) - (self.view.frame.size.height / 2.0f), self.view.frame.size.width, self.view.frame.size.height);
	self.tableHeaderCurrentChapterBackgroundImageView = [[UIImageView alloc] initWithFrame:backgroundImageFrame];
	self.tableHeaderCurrentChapterBackgroundImageView.image = nil;
	self.tableHeaderCurrentChapterBackgroundImageView.layer.zPosition = 0.0f;
	self.tableHeaderCurrentChapterBackgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
	[self.chapterHeaderView addSubview:self.tableHeaderCurrentChapterBackgroundImageView];
}

- (void)configureTableHeaderContinueReadingLabel
{
	self.tableHeaderContinueReadingLabel = [[UILabel alloc] init];
	self.tableHeaderContinueReadingLabel.textAlignment = NSTextAlignmentCenter;
	[self setContinueReadingLabelPosition];
	self.tableHeaderContinueReadingLabel.text = NSLocalizedString(@"CONTINUE READING", @"CONTINUE READING");
	
	self.tableHeaderContinueReadingLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:11.0f];
	self.tableHeaderContinueReadingLabel.textColor = [UIColor whiteColor];
	self.tableHeaderContinueReadingLabel.shadowColor = [UIColor colorWithWhite:0.0f alpha:0.5];		// traditional sharp text "drop shadow"
	self.tableHeaderContinueReadingLabel.shadowOffset = CGSizeMake(0.0f, 1.0f);
	self.tableHeaderContinueReadingLabel.layer.shadowRadius = 10.0f;								// soft shadow "glow"
	self.tableHeaderContinueReadingLabel.layer.shadowOpacity = 0.6f;
	self.tableHeaderContinueReadingLabel.clipsToBounds = NO;
	[self.chapterHeaderView addSubview:self.tableHeaderContinueReadingLabel];
}

- (void)setContinueReadingLabelPosition
{
    if (DEVICE_IS_IPAD)
    {
        CGRect frame = self.chapterHeaderView.frame;
        frame.origin.x = 0.0f;
        frame.origin.y = (self.chapterHeaderView.frame.size.height * 0.25f)-25.0f;
        frame.size.width = self.view.frame.size.width;
        frame.size.height = 30.0f;
        self.tableHeaderContinueReadingLabel.frame = frame;
    }
    else
    {
        
        CGRect frame = self.chapterHeaderView.frame;
        frame.origin.x = 0.0f;
        frame.origin.y = (self.chapterHeaderView.frame.size.height * 0.25f) - 10.0f;
        frame.size.width = self.view.frame.size.width;
        frame.size.height = 30.0f;
        self.tableHeaderContinueReadingLabel.frame = frame;
    }
}

- (void)configureTableHeaderCurrentChapterTitleLabel
{
	if (self.tableHeaderCurrentChapterTitleLabel == nil)
		self.tableHeaderCurrentChapterTitleLabel = [[UILabel alloc] init];
	
	CGRect labelFrame = self.tableHeaderContinueReadingLabel.frame;
	labelFrame.origin.x = self.chapterHeaderView.frame.size.width * 0.20f;
	labelFrame.origin.y = self.tableHeaderContinueReadingLabel.frame.size.height + 20.0f;
	labelFrame.size.height = self.chapterHeaderView.frame.size.height - labelFrame.origin.y;
	labelFrame.size.width = self.chapterHeaderView.frame.size.width * 0.60f;
    
	self.tableHeaderCurrentChapterTitleLabel.frame = labelFrame;
	self.tableHeaderCurrentChapterTitleLabel.textColor = [UIColor whiteColor];
	[self.chapterHeaderView addSubview:self.tableHeaderCurrentChapterTitleLabel];

	self.tableHeaderCurrentChapterTitleLabel.font = [UIFont fontWithName:@"HelveticaNeue-CondensedBold" size:titleLabelFontSizeMax];
	self.tableHeaderCurrentChapterTitleLabel.textAlignment = NSTextAlignmentCenter;
	self.tableHeaderCurrentChapterTitleLabel.lineBreakMode = NSLineBreakByWordWrapping;
//	self.tableHeaderCurrentChapterTitleLabel.minimumScaleFactor = 0;
	self.tableHeaderCurrentChapterTitleLabel.numberOfLines = 0;		// unlimited number of lines
	self.tableHeaderCurrentChapterTitleLabel.adjustsFontSizeToFitWidth = YES;
	self.tableHeaderCurrentChapterTitleLabel.clipsToBounds = NO;
	self.tableHeaderCurrentChapterTitleLabel.shadowColor = [UIColor colorWithWhite:0.0f alpha:0.5];		// traditional sharp drop shadow
	self.tableHeaderCurrentChapterTitleLabel.shadowOffset = CGSizeMake(0.0f, 1.0f);
	self.tableHeaderCurrentChapterTitleLabel.layer.shadowRadius = 15.0f;								// soft shadow "glow"
	self.tableHeaderCurrentChapterTitleLabel.layer.shadowOpacity = 0.6f;
	self.tableHeaderCurrentChapterTitleLabel.clipsToBounds = NO;
}

// note: we shrink the font until two things happen:
//	1. no single word in the title gets split because it's too wide to fit (which does happen even though we specify NSLineBreakByWordWrapping)
//	2. all words in the title fit vertically into the specified CGRect

- (void)shrinkTitleLabelFontToFitLabelRect:(CGRect)labelRect
{
	float fontSize = titleLabelFontSizeMax;
	UIFont *labelFont = [UIFont fontWithName:@"HelveticaNeue-CondensedBold" size:fontSize];
	CGRect oneLineRect = [@"X" boundingRectWithSize:labelRect.size
											options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
										 attributes:@{NSFontAttributeName:labelFont}
											context:nil];

	NSArray *titleWordArray = [self.tableHeaderCurrentChapterTitleLabel.text componentsSeparatedByString:@" "];
	CGRect textSizeRect;
	
	for (NSString *titleWordString in titleWordArray)				// if necessary, shrink font to make sure each word in title remains un-split
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
		textSizeRect = [self.tableHeaderCurrentChapterTitleLabel.text boundingRectWithSize:labelRect.size
																				   options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
																				attributes:@{NSFontAttributeName:labelFont}
																				   context:nil];
		fontSize -= 1.0f;
	} while (textSizeRect.size.height > labelRect.size.height);

	self.tableHeaderCurrentChapterTitleLabel.font = labelFont;
}

- (void)adjustContinueReadingLabelPosition
{
	[self setContinueReadingLabelPosition];						// reset to default position on each viewWillAppear:
	float titleFrameHeight = self.tableHeaderCurrentChapterTitleLabel.frame.size.height;
	UIFont *labelFont = self.tableHeaderCurrentChapterTitleLabel.font;
	CGRect textSizeRect = [self.tableHeaderCurrentChapterTitleLabel.text boundingRectWithSize:self.tableHeaderCurrentChapterTitleLabel.frame.size
																					  options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
																				   attributes:@{NSFontAttributeName:labelFont}
																					  context:nil];
	float titleTextYOffsetWithinLabel = (titleFrameHeight - textSizeRect.size.height) / 2.0f;
	CGRect continueLabelRect = self.tableHeaderContinueReadingLabel.frame;
    if(DEVICE_IS_IPAD)
        continueLabelRect.origin.y = continueLabelRect.origin.y + titleTextYOffsetWithinLabel - 50.0f;
    else
        continueLabelRect.origin.y = continueLabelRect.origin.y + titleTextYOffsetWithinLabel - 15.0f;
    
	self.tableHeaderContinueReadingLabel.frame = continueLabelRect;
}

- (void)configureTableHeaderView
{
	self.chapterTableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, self.chapterHeaderView.frame.size.height - 20.0f)];
}

- (void)configureTableFooterView
{
	self.chapterTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, 50.0f)];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	[self initDataEngines];
	[self initWebServicesEngine];
    [self populateChapterDataArrays];
	[self configureTable];
	[self configureTableHeaderContinueReadingLabel];
	[self configureTableHeaderCurrentChapterTitleLabel];
	[self initDisclosureButtonInHeader];
}

- (void)viewWillAppear:(BOOL)animated
{
//	self.hidesBottomBarWhenPushed = YES;
    [self.tabBarController.tabBar setHidden:NO];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
	[self initCurrentChapterIndex];
	[self setChapterTitleInHeader];
	[self shrinkTitleLabelFontToFitLabelRect:self.tableHeaderCurrentChapterTitleLabel.frame];
	[self adjustContinueReadingLabelPosition];
	[self setChapterBackgroundImageInHeader];
	[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
}

- (void)viewDidAppear:(BOOL)animated
{
	[self initProgressView];
	[progressBarView showProgressBarWithAnimation:YES];
	[progressBarShadowView showProgressBarWithAnimation:YES];
	[self performSelector:@selector(showProgressMessage) withObject:nil afterDelay:0.7f];		// show progress message after the progress bar has stopped
	[self performSelector:@selector(hideProgressMessagePopup) withObject:nil afterDelay:1.7f];  // hide progress message 1 second after it has appeared
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:NO animated:animated];
	[progressBarView hideProgressBar];
	[progressBarShadowView hideProgressBar];
//	self.hidesBottomBarWhenPushed = NO;
}

-(BOOL)prefersStatusBarHidden
{
    return NO;
}

-(UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleDefault;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return listViewChapterDataController.chapterDataSectionArray.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *chaptersArray = [listViewChapterDataController sectionArrayForIndex:section];
    return chaptersArray.count;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
	UIView *sectionTitleView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, 25.0f)];
	sectionTitleView.backgroundColor = [UIColor colorWithWhite:0.95f alpha:1.0f];
	
	UILabel *sectionTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(5.0f, -2.0f, self.view.frame.size.width, 25.0f)];
	[sectionTitleView addSubview:sectionTitleLabel];
	sectionTitleLabel.backgroundColor = [UIColor clearColor];
    PageSections *pageSection = [listViewChapterDataController.chapterDataSectionArray objectAtIndex:section];
	sectionTitleLabel.text = pageSection.tagName;
	sectionTitleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:12.0f];
	sectionTitleLabel.textColor = [UIColor blackColor];
	return sectionTitleView;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *SimpleTableIdentifier = @"ListTableViewCell";
    ListTableViewCell *cell = (ListTableViewCell *)[tableView dequeueReusableCellWithIdentifier: SimpleTableIdentifier];
    if (cell == nil)
    {
        NSArray *Objects = [[NSBundle mainBundle] loadNibNamed:@"ListTableViewCell" owner:nil options:nil];
        for(id object in Objects){
            if ([object isKindOfClass:[ListTableViewCell class]]) {
                cell = (ListTableViewCell *) object;
            }
        }
    }
    cell.sectionNo = indexPath.section;
    PageInstance *pageInstance = [listViewChapterDataController pageInstanceForIndexPath:indexPath];
    cell.pageInstance = pageInstance;
    cell.isExtraAvailable = pageInstance.extra;
    cell.hasAudio = pageInstance.hasAudio;
    cell.tagValue = [[sections objectAtIndex:indexPath.section] TagsId];
    cell.titleLabel.text = pageInstance.Title;
    cell.selectedPage = indexPath.row;
    cell.introLabel.text = [pageInstance.Intro stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	cell.backgroundColor = [UIColor colorWithWhite:1.0f alpha:1.0f];
    return cell;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	currentChapterIndex = [indexPath copy];
	curProgressPercentageInt = [listViewChapterDataController getChapterCurrentProgressForIndexPath:currentChapterIndex];
	maxProgressPercentageInt = [listViewChapterDataController getChapterMaxProgressForIndexPath:currentChapterIndex];
	return currentChapterIndex;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return kTableRowHeight;
}

#pragma mark - Table view utility methods

- (void)deselectRowAtIndexPath:(NSIndexPath *)indexPath afterDelay:(float)delayFloat
{
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delayFloat * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
		[self.chapterTableView deselectRowAtIndexPath:indexPath animated:NO];
	});
}

#pragma mark - Header view progress bars etc.

- (void)setChapterTitleInHeader
{
	self.tableHeaderCurrentChapterTitleLabel.text = nil;
	self.tableHeaderCurrentChapterTitleLabel.layer.opacity = 0.0f;
    NSArray *chaptersArray = [listViewChapterDataController sectionArrayForIndex:currentChapterIndex.section];
    PageInstance *pageInstance = [chaptersArray objectAtIndex:currentChapterIndex.row];
	self.tableHeaderCurrentChapterTitleLabel.text = pageInstance.Title;
	CGRect titleFrame = self.tableHeaderCurrentChapterTitleLabel.frame;
	titleFrame.origin.x += 200.0f;
	self.tableHeaderCurrentChapterTitleLabel.frame = titleFrame;
	
	[UIView beginAnimations:nil context:NULL];			// animate the chapter title into the header view
	[UIView setAnimationDuration:0.4f];
	self.tableHeaderCurrentChapterTitleLabel.layer.opacity = 1.0f;
	titleFrame.origin.x -= 200.0f;
	self.tableHeaderCurrentChapterTitleLabel.frame = titleFrame;
	[UIView commitAnimations];
}

- (void)setChapterBackgroundImageInHeader
{
	[UIView beginAnimations:nil context:NULL];
    NSArray *chaptersArray = [listViewChapterDataController sectionArrayForIndex:currentChapterIndex.section];
    PageInstance *pageInstance = [chaptersArray objectAtIndex:currentChapterIndex.row];
	self.tableHeaderCurrentChapterBackgroundImageView.image = [UIImage imageNamed:pageInstance.Image];

	if (self.tableHeaderCurrentChapterBackgroundImageView.image == nil)
		self.tableHeaderCurrentChapterBackgroundImageView.image = [UIImage imageNamed:@"LaunchImage-700-568h"];

//	[self maskHeaderViewImage];					// masking and vignetting are not used.  left code in below just in case.
//	[self applyVignetteFilterToHeaderView];
	[UIView commitAnimations];
}

- (void)maskHeaderViewImage
{
	if (headerImageMaskView == nil)					// make the mask big enough to cover the background image even as user pulls down to scale it
	{
		CGRect maskFrame = CGRectMake(-(self.view.frame.size.width / 2.0f), -(self.view.frame.size.height / 2.0f), self.view.frame.size.width * 2.0f, self.view.frame.size.height * 2.0f);
		headerImageMaskView = [[UIImageView alloc] initWithFrame:maskFrame];
		headerImageMaskView.layer.zPosition = 200.0f;
		[self.tableHeaderCurrentChapterBackgroundImageView addSubview:headerImageMaskView];
	}

	headerImageMaskView.backgroundColor = [UIColor clearColor];
	headerImageMaskView.layer.opacity = 1.0f;
	[UIView beginAnimations:nil context:NULL];		// do the animation, even though it won't be visible because we navigate to the actual chapter view on row tap
	[UIView setAnimationDuration:0.7f];
	headerImageMaskView.backgroundColor = [UIColor blackColor];
	headerImageMaskView.layer.opacity = 0.6f;
	[UIView commitAnimations];
}

- (void)applyVignetteFilterToHeaderView
{
	UIImage *vignetteImage = [self vignetteImageOfSize:self.chapterHeaderView.frame.size withImage:self.tableHeaderCurrentChapterBackgroundImageView.image];
	self.tableHeaderCurrentChapterBackgroundImageView.image = vignetteImage;
}

- (UIImage *)vignetteImageOfSize:(CGSize)size withImage:(UIImage *)image
{
    UIGraphicsBeginImageContextWithOptions(size, YES, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextFillRect(context, CGRectMake(0.0, 0.0, size.width, size.height));
	
    CIImage *coreImage = [CIImage imageWithCGImage:image.CGImage];
    CGPoint origin = [coreImage extent].origin;
    CGAffineTransform translation = CGAffineTransformMakeTranslation(-origin.x, -origin.y);
    coreImage = [coreImage imageByApplyingTransform:translation];
	
    CIFilter *vignette = [CIFilter filterWithName:@"CIVignette"];
    [vignette setValue:@1.5 forKey:@"inputRadius"];
    [vignette setValue:@4.0 forKey:@"inputIntensity"];
    [vignette setValue:coreImage forKey:@"inputImage"];
	
    UIImage *vignetteImage = [UIImage imageWithCIImage:vignette.outputImage];
	
    CGRect imageFrame = CGRectMake(0.0, 0.0, size.width, size.height);
    [vignetteImage drawInRect:imageFrame];
    UIImage *renderedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return renderedImage;
}

- (void)showProgressMessage
{
	CGRect progressMessageFrame = CGRectMake(0.0f, 0.0f, 300.0f, 100.0f);

	if (progressMessageLabel)
	{
		progressMessageLabel.frame = progressMessageFrame;
	}
	else
	{
		progressMessageLabel = [[UILabel alloc] initWithFrame:progressMessageFrame];		// create super-large label, shrink it down to size later
		progressMessageLabel.font = [UIFont systemFontOfSize:12.0f];
		progressMessageLabel.textAlignment = NSTextAlignmentCenter;
		progressMessageLabel.textColor = [UIColor blackColor];
		progressMessageLabel.layer.opacity = 0.0f;
	}

	progressMessageLabel.text = [self getMessageStringForPercentage:maxProgressPercentageInt];

	NSDictionary *attributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:progressMessageLabel.font, NSFontAttributeName, nil];
	CGSize size = CGSizeMake(progressMessageLabel.frame.size.width, progressMessageLabel.frame.size.height);
	CGRect messageLabelFrame = [progressMessageLabel.text boundingRectWithSize:size
															   options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
															attributes:attributesDictionary
															   context:nil];
	
	progressMessageLabel.frame = messageLabelFrame;
	
	float messageWidth = messageLabelFrame.size.width;
	float messageHeight = messageLabelFrame.size.height;
	float messageXOffset = [self getMessageViewXOffsetForPercentage:(float)maxProgressPercentageInt forMessageWidth:messageWidth];

	messageLabelFrame.size.width = messageWidth;
	messageLabelFrame.size.height = messageHeight;
	messageLabelFrame.origin.x = messageXOffset;
	messageLabelFrame.origin.y = [self getMessageViewYOffsetForXOffset:messageXOffset forMessageWidth:messageWidth forMessageHeight:messageHeight];
	
	CGRect messageViewFrame = messageLabelFrame;
	messageViewFrame.origin.x -= 5.0f;
	messageViewFrame.origin.y -= 5.0f;
	messageViewFrame.size.width += 10.0f;
	messageViewFrame.size.height += 10.0f;
	
	if (progressMessageRoundedRect)
	{
		progressMessageRoundedRect.frame = messageViewFrame;
	}
	else
	{
		progressMessageRoundedRect = [[RoundedRectView alloc] initWithFrame:messageViewFrame];
		progressMessageRoundedRect.clipsToBounds = NO;
		progressMessageRoundedRect.layer.borderColor = [progressBarView.progressBarColor CGColor];
		progressMessageRoundedRect.backgroundColor = progressBarView.progressBarColor;
		progressMessageRoundedRect.alpha = 0.0f;
		progressMessageRoundedRect.layer.zPosition = 0.0f;

		progressMessageRoundedRect.layer.shadowOffset = CGSizeMake(0.0f, 0.5f);
		progressMessageRoundedRect.layer.shadowColor = [[UIColor blackColor] CGColor];
		progressMessageRoundedRect.layer.shadowRadius = 8.0f;
		progressMessageRoundedRect.layer.shadowOpacity = 0.3f;
	}

	if (progressMessageRoundedRect.frame.origin.x + progressMessageRoundedRect.frame.size.width > self.view.frame.size.width)
	{
		CGRect rectFrame = progressMessageRoundedRect.frame;
		rectFrame.origin.x = self.view.frame.size.width - progressMessageRoundedRect.frame.size.width;
		progressMessageRoundedRect.frame = rectFrame;
	}
	
	CGRect shadowFrame = progressMessageRoundedRect.frame;
	shadowFrame.size.width *= 2.0f;
	shadowFrame.size.height *= 2.0f;
	shadowFrame.origin.y += 0.5f;
	messageLabelFrame.origin.x = 5.0f;
	messageLabelFrame.origin.y = 5.0f;
	progressMessageLabel.frame = messageLabelFrame;
	shadowFrame.origin.x = 5.0f;
	shadowFrame.origin.y = 6.0f;
	[progressMessageRoundedRect addSubview:progressMessageLabel];
	[self.chapterHeaderView addSubview:progressMessageRoundedRect];
	[UIView beginAnimations:nil context:NULL];		// do the animation, even though it won't be visible because we navigate to the actual chapter view on row tap
	[UIView setAnimationDuration:0.5f];
	progressMessageLabel.layer.opacity = 0.8f;
	progressMessageRoundedRect.alpha = 1.0f;
	[UIView commitAnimations];
	
	[self performSelector:@selector(hideProgressMessagePopup) withObject:nil afterDelay:1.0f];
}

- (void) hideProgressMessagePopup
{
	[UIView beginAnimations:nil context:NULL];		// do the animation, even though it won't be visible because we navigate to the actual chapter view on row tap
	[UIView setAnimationDuration:0.3f];
	progressMessageLabel.layer.opacity = 0.0f;
	progressMessageRoundedRect.alpha = 0.0f;
	[UIView commitAnimations];
}

- (float) getMessageViewXOffsetForPercentage:(float)progressPercentageFloat forMessageWidth:(float)messageWidth
{
	float xOffset = progressPercentageFloat * self.view.frame.size.width / 100.0f + 20.0f;
	
	if ((xOffset + messageWidth) > self.view.frame.size.width)
		xOffset = self.view.frame.size.width - messageWidth - 20.0f;

	return xOffset;
}

- (float) getMessageViewYOffsetForXOffset:(float)xOffset forMessageWidth:(float)messageWidth forMessageHeight:(float)messageHeight
{
	float messageYOffset = self.chapterHeaderView.frame.size.height - progressBarView.frame.size.height - messageHeight;
	
	if ((xOffset + messageWidth) > (self.view.frame.size.width - 30.0f))
		messageYOffset -= (messageHeight + 10.0f);
	
	return messageYOffset;
}

- (NSString *)getMessageStringForPercentage:(int)percentageInt
{
	NSString *firstPartMessage = NSLocalizedString(@"JUST STARTING", @"JUST STARTING");		//  0% to 19%
	NSString *secondPartMessage = NSLocalizedString(@"LESS THAN HALF", @"LESS THAN HALF");	// 20% to 39%
	NSString *thirdPartMessage = NSLocalizedString(@"ABOUT HALF", @"ABOUT HALF");			// 40% to 59%
	NSString *fourthPartMessage = NSLocalizedString(@"ALMOST DONE", @"ALMOST DONE");		// 60% to 79%
	NSString *fifthPartMessage = NSLocalizedString(@"NEAR END", @"NEAR END");				// 80% to 99%
	NSString *doneMessage = NSLocalizedString(@"DONE", @"DONE");							// 100%
	
	NSString *messageString = nil;
	
	if (percentageInt <= kFirstPartPercentage)
		messageString = firstPartMessage;
	else if (percentageInt <= kSecondPartPercentage)
		messageString = secondPartMessage;
	else if (percentageInt < kThirdPartPercentage)
		messageString = thirdPartMessage;
	else if (percentageInt <= kFourthPartPercentage)
		messageString = fourthPartMessage;
	else if (percentageInt <= kFifthPartPercentage)
		messageString = fifthPartMessage;
	else
		messageString = doneMessage;

	return messageString;
}

- (void)initDisclosureButtonInHeader
{
	float disclosureRectWidth = 40.0f, disclosureRectHeight = 40.0f;					// we add a programatically-drawn ">"
	CGRect disclosureRectFrame = CGRectMake(self.chapterHeaderView.frame.size.width - disclosureRectWidth, (self.chapterHeaderView.frame.size.height / 2.0f) - (disclosureRectHeight / 2.0f), disclosureRectWidth, disclosureRectHeight);
	self.chapterDisclosureIndicator = [[ListViewHeaderDisclosureIndicator alloc] initWithFrame:disclosureRectFrame];
	self.chapterDisclosureIndicator.backgroundColor = [UIColor clearColor];
	[self.chapterHeaderView.superview addSubview:self.chapterDisclosureIndicator];
	self.chapterDisclosureIndicator.hidden = YES;										// don't show the disclosure indicator.  just enable the button.
	
	self.chapterDisclosureButton = [UIButton buttonWithType:UIButtonTypeCustom];		// add transparent button on top of the disclosure indicator view
	float disclosureButtonWidth = self.chapterHeaderView.frame.size.width, disclosureButtonHeight = self.chapterHeaderView.frame.size.height;
	CGRect disclosureButtonFrame = CGRectMake(self.chapterHeaderView.frame.size.width - disclosureButtonWidth, (self.chapterHeaderView.frame.size.height / 2.0f) - (disclosureButtonHeight / 2.0f), disclosureButtonWidth, disclosureButtonHeight);
	self.chapterDisclosureButton.frame = disclosureButtonFrame;
	[self.chapterDisclosureButton addTarget:self action:@selector(navigateToCurrentChapter:) forControlEvents:UIControlEventTouchUpInside];
	self.chapterDisclosureButton.backgroundColor = [UIColor clearColor];
	[self.chapterHeaderView.superview addSubview:self.chapterDisclosureButton];
}

#pragma mark - Disclosure button methods

-(void)navigateToCurrentChapter:(UIButton *)sender
{
	[self performSegueWithIdentifier:@"CardViewIdentifier" sender:self];
}

- (void)showOrHideHeaderViewDisclosureIndicatorForYOffset:(float)yOffset
{
	if (yOffset > headerDisclosureIndicatorThreshold && self.chapterDisclosureIndicator.isHidden == NO)
	{
		self.chapterDisclosureIndicator.hidden = YES;
		self.chapterDisclosureButton.hidden = YES;
		self.chapterDisclosureButton.enabled = NO;
	}
	else if (yOffset < headerDisclosureIndicatorThreshold && self.chapterDisclosureIndicator.hidden == YES)
	{
//		self.chapterDisclosureIndicator.hidden = NO;									// don't show the disclosure indicator.  just enable the button.
		self.chapterDisclosureButton.hidden = NO;
		self.chapterDisclosureButton.enabled = YES;
	}
}

#pragma mark - Data for table view

- (void)populateChapterDataArrays
{
	[listViewChapterDataController populateSectionArray];
	[listViewChapterDataController populateChapterArray];
}

- (void)initCurrentChapterIndex
{
    if (currentChapterIndex == nil)
        currentChapterIndex = [NSIndexPath indexPathForRow:0 inSection:0];
}

#pragma mark - Tab bar delegate

- (BOOL)tabBarController:(UITabBarController *)tbc shouldSelectViewController:(UIViewController *)vc
{
    return NO;
}

#pragma mark - Scrollview delegate methods

- (void)scrollViewDidScroll:(UIScrollView *)aScrollView
{
	float yOffset = aScrollView.contentOffset.y;
	
	if (yOffset <= 0.0f)
		[self scaleBackgroundImageForYOffset:yOffset];
}

#pragma mark - Scrollview effects

- (void)scaleBackgroundImageForYOffset:(float)yOffset
{
	float scalePercentage = 100.0f;
	
	if (yOffset < 0.0f)
	{
		scalePercentage = 100.0f - (yOffset / 5.0f);				// scale up 0.2 percent for every pixel pulled down...
	}
	
	if (scalePercentage > 115.0f)									// ...up to 15 percent greater than normal.
		scalePercentage = 115.0f;
	
	float imageWidth = scalePercentage * self.view.frame.size.width / 100.0f;
	float imageHeight = scalePercentage * self.view.frame.size.height / 100.0f;
	CGRect frame = self.tableHeaderCurrentChapterBackgroundImageView.frame;
	frame.size.width = imageWidth;
	frame.size.height = imageHeight;
	frame.origin.x = 0.0f - ((imageWidth - self.view.frame.size.width) / 2.0f);
	self.tableHeaderCurrentChapterBackgroundImageView.frame = frame;
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	
    if ([segue.identifier isEqualToString:@"CardViewIdentifier"]) {
        ReadViewController *readViewController = segue.destinationViewController;
		NSArray *sectionsArray = [[DataController sharedController] getSectionsList];
		PageSections *pageSection = [sectionsArray objectAtIndex:currentChapterIndex.section];
		readViewController.sectionName = pageSection.tagName;
        NSMutableArray *contentArray = [listViewChapterDataController getAllChaptersContent];
        readViewController.contentArray = contentArray;
        readViewController.selectedPage = 0;
        for (int index = 0; index < currentChapterIndex.section; index++) {
            
            readViewController.selectedPage += [[listViewChapterDataController sectionArrayForIndex:index] count];
        }
		readViewController.selectedPage += currentChapterIndex.row;
		readViewController.readViewChapterDataController = listViewChapterDataController;
		readViewController.readViewQuizDataController = listViewQuizDataController;
		readViewController.oldCurProgressPercentageInt = curProgressPercentageInt;
		readViewController.oldMaxProgressPercentageInt = maxProgressPercentageInt;
		readViewController.readViewWebServicesEngine = listViewWebServicesEngine;
		readViewController.parentViewIsTimeline = NO;
   }
	else if ([segue.identifier isEqualToString:@"loginScrollViewSegue"]) {
		NSLog(@"loginScrollViewIdentifier segue");		// zzzzz
	}
}

#pragma mark - Memory

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
