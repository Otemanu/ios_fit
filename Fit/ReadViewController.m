//
//  ReadViewController.m
//  Fit
//
//  Created by Mobi on 21/11/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//

#import "ReadViewController.h"
#import "DataController.h"
#import "PageInstance.h"
#import "PageSections.h"
#import <QuartzCore/QuartzCore.h>
#import "CardView.h"

@interface ReadViewController () <UIAlertViewDelegate, UIActionSheetDelegate>

@end

@implementation ReadViewController
@synthesize contentArray, selectedSection,selectedPage,selectedCat;
@synthesize aScrollView;
@synthesize webViewsArray;
@synthesize detailedWebView;
@synthesize readViewChapterDataController;

int currentScrollYOffsetInt = 0, maxScrollYOffsetInt = 0;
int currentChapterProgressInt = 0, maxChapterProgressInt = 0;
int currentQuizMenuDataArrayIndex = 0;
int currentQuizId = 0;

BOOL quizVisible = NO;
BOOL quizMenuTapped = NO;

PageInstance *currentPageInstance = nil;

NSString *jsonString = nil;

#pragma mark - Card creation

-(NSString *) parseForStartingBreaksAndEndBreaksForText:(NSString *)selectedText
{
    while (selectedText.length > 0) {
        if ([[selectedText substringToIndex:1] isEqualToString:@"\n"]) {
            selectedText = [selectedText substringFromIndex:1];
        }
        else
        {
            break;
        }
    }
    while (selectedText.length > 0) {
        if ([[selectedText substringFromIndex:selectedText.length-1] isEqualToString:@"\n"]) {
            selectedText = [selectedText substringToIndex:selectedText.length-1];
        }
        else
        {
            break;
        }
    }
    return selectedText;
}

-(void) makeCard:(UIMenuController *) sender
{
    [[UIApplication sharedApplication] sendAction:@selector(copy:) to:nil from:self forEvent:nil];
    UIPasteboard *pasteBoard = [UIPasteboard generalPasteboard];
    NSString *selectedText = [pasteBoard string];

    if (selectedText == NULL) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Failed to save card" message:nil delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil];
        [alertView show];
        return;
    }
    selectedText = [self parseForStartingBreaksAndEndBreaksForText:selectedText];
    PageInstance *aTempPageInstance = [contentArray objectAtIndex:pageIndex];
    cardText = [NSString stringWithFormat:@"%@$$$%@$$$%@",selectedText,self.sectionName,aTempPageInstance.Title];
	// note: we don't have the "mongoId" yet, which is one of the columns in flash_cards (and which is required for deleting cards later)
	// the server will send the mongoId back to us after we send it the "NewFlashCardCreated" message.
    [[DataController sharedController] saveCardInDatabaseWithString:cardText pageInstanceIdInteger:tempPageInstance.PageInstanceId];
    [sender setMenuVisible:NO animated:YES];
	NSDictionary *newFlashCardDict = [NSDictionary dictionaryWithObjectsAndKeys:
									  cardText, @"cardText",
									  [NSNumber numberWithInteger:tempPageInstance.PageInstanceId], @"pageInstanceId",
									  nil];
	[self.readViewWebServicesEngine sendNewFlashCardToServer:newFlashCardDict];
    AppDelegate *delegate = XAppDelegate;
    delegate.isFromReadViewController = YES;
    if (self.tabBarController.selectedIndex == 4) {
        [self.navigationController popViewControllerAnimated:NO];
    }
    else
        [self.tabBarController setSelectedIndex:4];
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    if (action == @selector(copy:)  || action == @selector(selectAll:) || action == @selector(cut:) || action == @selector(paste:))
    {
        return NO;
    }
    else if (action == @selector(makeCard:) || action == @selector(highlightText:) || action == @selector(removeHighlightedText))
    {
        return YES;
    }
    return NO;
}

#pragma mark Highlighting Text

- (void) highlightText: (UIMenuController *) sender
{
    tempPageInstance.Html = [detailedWebView hightlightSelectedText];
    [[DataController sharedController] updateDatabase:tempPageInstance.PageInstanceId htmlString:tempPageInstance.Html];
    [sender setMenuVisible:NO animated:YES];
}

-(void) removeHighlightedText
{
    NSString *startSearch   = [NSString stringWithFormat:@"uiWebview_RemoveAllHighlights()"];
	[detailedWebView stringByEvaluatingJavaScriptFromString:startSearch];
    NSString *stringByEvaluate=[detailedWebView stringByEvaluatingJavaScriptFromString:@"document.getElementById(\"container\").innerHTML"];
    stringByEvaluate = [stringByEvaluate stringByReplacingOccurrencesOfString:@"'" withString:@""];
    [[DataController sharedController] updateDatabase:tempPageInstance.PageInstanceId htmlString:stringByEvaluate];
    [sharedController setMenuVisible:NO animated:YES];
}

-(void) addMenuItemsToSharedController
{
    UIMenuItem *menuItem = [[UIMenuItem alloc] initWithTitle:@"Make Card" action:@selector(makeCard:)];
    UIMenuItem *highlightItem = [[UIMenuItem alloc] initWithTitle:@"Highlight" action:@selector(highlightText:)];
	UIMenuItem *removeHighlightItem = [[UIMenuItem alloc] initWithTitle:@"Remove Highlighted text" action:@selector(removeHighlightedText)];
    sharedController.menuItems = [NSArray arrayWithObjects:menuItem,highlightItem,removeHighlightItem,nil];
}

-(void) showMenuController
{
	sharedController = [UIMenuController sharedMenuController];
	[self addMenuItemsToSharedController];
	[sharedController setTargetRect:CGRectMake(100, 100, 300, 400) inView:self.view];
    [sharedController setMenuVisible:YES animated:YES];
}

#pragma mark Trimming Html text

- (NSString *)stripTags:(NSString *)str
{
    NSMutableString *aHtml = [NSMutableString stringWithCapacity:[str length]];
    NSScanner *scanner = [NSScanner scannerWithString:str];
    scanner.charactersToBeSkipped = NULL;
    NSString *tempText = nil;
    
    while (![scanner isAtEnd])
    {
        [scanner scanUpToString:@"<audio controls=\"controls\""intoString:&tempText];
        
        if (tempText != nil)
            [aHtml appendString:tempText];
        
        [scanner scanUpToString:@"/>" intoString:NULL];
        if (![scanner isAtEnd])
            [scanner setScanLocation:[scanner scanLocation] +2];
        
        tempText = nil;
    }
    return aHtml;
}

-(NSString *) trimHtmlTextForHtml:(NSString *)htmlText
{
    htmlText = [htmlText stringByReplacingOccurrencesOfString:@"<img src=\"multimedia/"
                                                   withString:@"<img src=\""];
    htmlText = [self stripTags:htmlText];
    NSString* textPath = [[NSBundle mainBundle] pathForResource:@"contentHtmlText" ofType:@"txt"];
    NSString *textContent = [NSString stringWithContentsOfFile:textPath
                                                      encoding:NSUTF8StringEncoding
                                                         error:NULL];
    htmlText = [htmlText stringByReplacingOccurrencesOfString:@"<html><head>" withString:[NSString stringWithFormat:@"<html><head>%@",textContent]];
    htmlText = [htmlText stringByReplacingOccurrencesOfString:@"multimedia/" withString:@""];
    htmlText = [htmlText stringByReplacingOccurrencesOfString:@"scripts/" withString:@""];
    htmlText = [htmlText stringByReplacingOccurrencesOfString:@"styles/" withString:@""];
    htmlText = [htmlText stringByReplacingOccurrencesOfString:@"js/" withString:@""];
    
    // we need to add the NativeBridge.js so we can return the quiz json string to javascript
    NSString *nativeBridgeText = @"<script type=\"text/javascript\" src=\"NativeBridge.js\"></script>";
    htmlText=[htmlText stringByReplacingOccurrencesOfString:@"</head>" withString:[NSString stringWithFormat:@"%@</head>", nativeBridgeText]];
    
    // we need to convert other-platform file path to iOS-specific file path.  e.g. "/MyCSS.css" to "multimedia/MyCSS.css".
    htmlText =[htmlText stringByReplacingOccurrencesOfString:@"<link rel=\"stylesheet\" type=\"text/css\" href=\"template_Test_Prep.css\" />"
                                                  withString:@"<link rel=\"stylesheet\" type=\"text/css\" href=\"multimedia/template_Test_Prep.css\" />"];
    // and now we need to do a hack to fix incorrectly-named .css file generated by Thoth
    htmlText = [htmlText stringByReplacingOccurrencesOfString:@"<link rel=\"stylesheet\" type=\"text/css\" href=\"multimedia/template_Test_Prep.css\" />"
                                                   withString:@"<link rel=\"stylesheet\" type=\"text/css\" href=\"template_Test_Prep.css\" />"];
    return htmlText;
}

#pragma mark - Web view with page text

-(void)loadScrollViewWithPage:(int)index
{
	if (index >= 0 && index < [contentArray count]) {
        ReadWebView * aWebView = nil;
        PageInstance *pInstance = [contentArray objectAtIndex:index];
        if (pInstance.Html == NULL) {
            
            PageInstance *aTempPageInstance = [[DataController sharedController] getElementsForPageInstance:pInstance.PageInstanceId];
            pInstance.Html = aTempPageInstance.Html;
        }
        NSString *html = [self trimHtmlTextForHtml:[pInstance Html]];
        NSString *path = [[NSBundle mainBundle] bundlePath];
        NSURL *baseURL = [NSURL fileURLWithPath:path];

        if ([webViewsArray objectAtIndex:index] == [NSNull null]) {
            aWebView = [[ReadWebView alloc] init];
            aWebView.delegate = self;
            [aScrollView addSubview:aWebView];
            [webViewsArray replaceObjectAtIndex:index withObject:aWebView];
            [aWebView loadHTMLString:html baseURL:baseURL];
        }
        else
        {
			aWebView = [webViewsArray objectAtIndex:index];
        }
        if (index == pageIndex) {
            detailedWebView = aWebView;
            self.navigationItem.title = pInstance.Title;
            tempPageInstance = pInstance;
        }
        aWebView.frame = CGRectMake(0, (index * aScrollView.frame.size.height) + 10, aScrollView.frame.size.width, aScrollView.frame.size.height-20);
	}
}

-(void)closeTopNavigationBar
{
    if(!isTopBarClosed) {
        isTopBarClosed = YES;
        [self.view addGestureRecognizer:singleTap];
        [UIView animateWithDuration:0.2 animations:^{
            [self.navigationController.navigationBar setFrame:CGRectMake(0, -24, self.navigationController.navigationBar.frame.size.width, self.navigationController.navigationBar.frame.size.height)];
            [self.aScrollView setFrame:CGRectMake(self.aScrollView.frame.origin.x, 10, self.aScrollView.frame.size.width, self.aScrollView.frame.size.height)];
        }];
    }
}

#pragma mark - Scrollview delegate methods

// note: there can be a conflict between the parent scroll view and the child web view.
// we don't want the parent scrollview to scroll until the webview has reached the bottom or top of its content.
// but we do want to detect the position of the webview so we can tell how far the user has read in each page for progress reporting.
// so we clear the scrollview delegate of the parent scroll view and set the webview scroll delegate until it reaches top or bottom.
// then we re-establish the parent scrollview delegate so the user can move between pages.

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self closeTopNavigationBar];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView == detailedWebView.scrollView)
    {
        [self calculateCurrentAndMaxYOffsets];
    }
    if (scrollView == self.aScrollView)
    {
//        NSLog(@"handle ===scrool frame===%f,scroll y===%f",aScrollView.frame.size.height,aScrollView.frame.origin.y);
        if (scrollView.contentOffset.y < 100)
            scrollView.contentInset = UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f);
        
        float yOffset = scrollView.contentOffset.y;
        float pageHeight = scrollView.frame.size.height;
        int newPageIndex = yOffset / pageHeight;
        
        if (pageIndex != newPageIndex)
        {
            if (newPageIndex > pageIndex)						// before we load the next chapter, save completed current chapter progress to local sqlite and server
            {
                currentChapterProgressInt = maxChapterProgressInt = 100;
                [self setProgressInDatabase];
                [self sendProgressToServer];
            }
            pageIndex = newPageIndex;
            for (int i=0; i<[[aScrollView subviews] count]; i++)
            {
                ReadWebView *addedWebView = [[aScrollView subviews] objectAtIndex:i];
                int addedTxtIndex = addedWebView.frame.origin.y/aScrollView.frame.size.height;
                if(addedTxtIndex != pageIndex-1 && addedTxtIndex != pageIndex && addedTxtIndex != pageIndex+1)
                {
                    [addedWebView removeFromSuperview];
                    [webViewsArray replaceObjectAtIndex:addedTxtIndex withObject:[NSNull null]];
                }
            }
            if(pageIndex>=0 && pageIndex<[contentArray count])
            {
                [self loadScrollViewWithPage:pageIndex-1];
                [self loadScrollViewWithPage:pageIndex];
                [self loadScrollViewWithPage:pageIndex+1];
                [self populateCurrentPageQuizArrayForQuizMenu];
				[self showOrHideQuizButton];
            }
        }
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
	if (scrollView == aScrollView)
	{
		detailedWebView.scrollView.delegate = self;
		detailedWebView.scrollView.scrollEnabled = YES;		// let the uiwebview scroll its contents
		//aScrollView.scrollEnabled = NO;
	}
	else if (scrollView == (UIScrollView *)([webViewsArray[pageIndex] scrollView]))
	{
		if (quizVisible == NO)
		{
			// note: we need to update current (and possibly max) read position in sqlite every time scrolling ends.
			// this is so we can transition back to List or Timeline view and have instant access to current read progress.
			// updating positions in viewWillDisappear: is too late because List and Timeline viewWillAppear: methods can be called
			// concurrently with the Read view's viewWillDisappear: method. (but we can send progress to server in viewWillDisappear:.)
			[self calculateCurrentProgressPercentage];
			[self calculateMaxProgressPercentage];
			[self setProgressInDatabase];
		}
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	
	UITouch *touch = [[event allTouches] anyObject];
	touchEndPoint = [touch locationInView:self.view];
}

-(void)loadScrollViewContents
{
    aScrollView.delegate = NULL;
    aScrollView.contentSize = CGSizeMake(aScrollView.frame.size.width, aScrollView.frame.size.height * [contentArray count]);
    aScrollView.showsVerticalScrollIndicator = NO;
    [self loadScrollViewWithPage:pageIndex-1];
    [self loadScrollViewWithPage:pageIndex];
    [self loadScrollViewWithPage:pageIndex+1];
	[self populateCurrentPageQuizArrayForQuizMenu];
	[self showOrHideQuizButton];
}

#pragma mark - Gesture Recognizer delegate

// This method receive touch event first
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if (touch.tapCount ==1) {
        self.timer = [NSTimer timerWithTimeInterval:0.2 target:self selector:@selector(handleSingleTap:) userInfo:nil repeats:NO];
        [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
        self.gestureState = UIGestureRecognizerStateBegan;
        return YES;
    }
    else if (touch.tapCount == 2 && self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
    return NO;
}

// This is the second method to recognize touch event
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    
    self.gestureState = gestureRecognizer.state;
    return YES;
}

-(void) setScrollViewDelegateToSelf
{
    self.aScrollView.delegate = self;
}

// Handler will be called from timer
- (void)handleSingleTap:(UITapGestureRecognizer*)sender {
    
	if (quizVisible)
		return;

    if (self.gestureState==UIGestureRecognizerStateRecognized) {
        
        if (isTopBarClosed) {
            [UIView animateWithDuration:0.2 animations:^{
                
                [self.navigationController.navigationBar setFrame:CGRectMake(0, 20, self.navigationController.navigationBar.frame.size.width, self.navigationController.navigationBar.frame.size.height)];
                [self.aScrollView setFrame:CGRectMake(self.aScrollView.frame.origin.x, 54, self.aScrollView.frame.size.width, self.aScrollView.frame.size.height)];
            }];
            isTopBarClosed = NO;
            [self.view removeGestureRecognizer:singleTap];
       
        }
    }
}

-(void) startButtonPressed:(UIButton *)sender
{
    [UIView animateWithDuration:0.5 animations:^{
        [self.instructionView setFrame:CGRectMake(self.instructionView.frame.origin.x, self.view.frame.size.height, self.instructionView.frame.size.width, self.instructionView.frame.size.height)];
    } completion:^(BOOL finished) {
        [self.instructionView removeFromSuperview];
        self.instructionView = nil;
        self.navigationItem.rightBarButtonItem = self.quizButton;
         [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"Instruction View Showed"];
    }];
}

-(void) addInstructionView
{
    self.navigationItem.rightBarButtonItem = nil;
    self.instructionView = [[UIView alloc] initWithFrame:CGRectMake(0, self.navigationController.navigationBar.frame.size.height+20, self.view.frame.size.width, self.view.frame.size.height-(self.navigationController.navigationBar.frame.size.height+20))];
    self.instructionView.opaque = YES;
    [self.view addSubview:self.instructionView];
    
    UIImageView *instructionImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.instructionView.frame.size.width, self.instructionView.frame.size.height)];
    instructionImageView.image = [UIImage imageNamed:@"InstructionImage"];
    [self.instructionView addSubview:instructionImageView];
    
    UIButton *startButton = [UIButton buttonWithType:UIButtonTypeCustom];
    CGRect buttonFrame;
    buttonFrame.size = CGSizeMake(158, 56);
    buttonFrame.origin = CGPointMake((self.view.frame.size.width/2)-(buttonFrame.size.width/2), self.instructionView.frame.size.height - 78);
    startButton.frame = buttonFrame;
    [startButton.titleLabel setFont:[UIFont fontWithName:@"Helvetica-Light" size:27.0]];
    [startButton.titleLabel setTextColor:[UIColor whiteColor]];
    [startButton setTitle:@"START" forState:UIControlStateNormal];
    [startButton setOpaque:YES];
    [startButton setAlpha:0.5];
    [[startButton layer] setCornerRadius:8.0f];
    [[startButton layer] setMasksToBounds:YES];
    [[startButton layer] setBorderWidth:2.0f];
    [[startButton layer] setBorderColor:[UIColor whiteColor].CGColor];
    [startButton addTarget:self action:@selector(startButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    startButton.showsTouchWhenHighlighted = YES;
    [self.instructionView addSubview:startButton];
    
    UILabel *titleLabel = [[UILabel alloc] init];
    CGRect titleLabelFrame;
    
    if (DEVICE_IS_IPAD) {
        titleLabelFrame.size = CGSizeMake(600, 80);
        titleLabelFrame.origin = CGPointMake((self.view.frame.size.width/2)-(titleLabelFrame.size.width/2), 140);
        [titleLabel setFont:[UIFont fontWithName:@"Helvetica-Condensed" size:40.0]];
    }
    else
    {
        titleLabelFrame.size = CGSizeMake(280, 68);
        titleLabelFrame.origin = CGPointMake((self.view.frame.size.width/2)-(titleLabelFrame.size.width/2), 60);
        [titleLabel setFont:[UIFont fontWithName:@"Helvetica-Condensed" size:30.0]];
    }
    titleLabel.frame = titleLabelFrame;
    titleLabel.opaque = YES;
    [titleLabel setAlpha:0.5f];
    titleLabel.text = [[[DataController sharedController] title] uppercaseString];
    titleLabel.numberOfLines = 2;
    [titleLabel setTextColor:[UIColor whiteColor]];
    [titleLabel setTextAlignment:NSTextAlignmentCenter];
    [self.instructionView addSubview:titleLabel];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    isTopBarClosed = YES;
    //if (self.parentViewIsTimeline)		// compensate for not having a top nav bar in dashboard and timeline views
    
    pageIndex = self.selectedPage;
    pageInstance = [contentArray objectAtIndex:pageIndex];
    webViewsArray = [[NSMutableArray alloc] init];
	self.aScrollView.delegate = nil;
    for (int i=0; i<[contentArray count]; i++)
        [webViewsArray addObject:[NSNull null]];

    [self showMenuController];
	json = [SBJSON new];
	
	[self.navigationController setNavigationBarHidden:NO animated:YES];
	
    BOOL isInstructionViewShowed = [[NSUserDefaults standardUserDefaults] boolForKey:@"Instruction View Showed"];
    if (!isInstructionViewShowed) {
        [self addInstructionView];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
  //  if (self.parentViewIsTimeline)
        
    [self loadScrollViewContents];
    aScrollView.contentOffset = CGPointMake(0, pageIndex*aScrollView.frame.size.height);
	detailedWebView.scrollView.delegate = self;
	detailedWebView.scrollView.scrollEnabled = YES;		// let the uiwebview scroll its contents
	//[self adjustScrollViewPosition];
	[self setScrollViewYOffsetWithAnimation:(self.parentViewIsDashboard == NO)];

    singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:nil];
    singleTap.numberOfTapsRequired = 1;
    singleTap.delegate = self;
    [self.view addGestureRecognizer:singleTap];
    [self.tabBarController.tabBar setHidden:YES];
  	jsonString = nil;
	currentQuizId = 0;
	maxScrollYOffsetInt = 0;
	maxChapterProgressInt = 0;
}

-(void)viewDidAppear:(BOOL)animated
{
    aScrollView.delegate = self;
	isTopBarClosed = NO;
    quizVisible = NO;
    [self toggleScrollViewScrollingWithBool:YES];
	[self showQuizIfCalledFromDashboard];
}

- (void)viewWillDisappear:(BOOL)animated
{
	// zzzzz todo:
	// insert a row for the progress message into mobi_analytics table (which acts as a queue of events we sent to the server)
	// later, we should attempt to send all non-obsolete messages in the queue immediately (not here, but somewhere else, on launch)
	[self sendProgressToServer];
    aScrollView.delegate = NULL;
}

-(void)viewDidDisappear:(BOOL)animated
{
}

#pragma mark - Quiz view & javascript

- (void)showQuizIfCalledFromDashboard
{
	if (self.parentViewIsDashboard && self.quizName && self.quizName.length > 0)
	{
		for (int quizIndex = 0; quizIndex < quizMenuDataArray.count; quizIndex++)
		{
			NSDictionary *currentQuizMenuDataDict = quizMenuDataArray[quizIndex];
			NSString *currentQuizTitle = [currentQuizMenuDataDict objectForKey:@"title"];
			
			if ([currentQuizTitle localizedCaseInsensitiveCompare:self.quizName] == NSOrderedSame)
			{
				currentQuizMenuDataArrayIndex = quizIndex;
				int quizOrdinalInt = [currentQuizMenuDataDict[@"ordinal"] intValue];
				[self showQuizWithOrdinalIntId:quizOrdinalInt];
				[self requestQuizResultsForQuizId:quizOrdinalInt];
				break;
			}
		}
	}
}

- (void)fetchJsonFromSqliteForQuizId:(int)quizId
{
	// sometimes there is a spurious 2nd call, so prevent them from changing jsonString
	if (jsonString == nil)
		jsonString = [[DataController sharedController] getQuizJsonForQuizId:quizId];
}

- (void)handleQuizAnswerForArgs:(NSArray *)args
{
	NSData *jsonData = [args[0] dataUsingEncoding:NSUTF8StringEncoding];
	id jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:NULL];
	NSDictionary *quizAnswerDict = [self parseJsonQuizAnswerString:jsonObject];
	
	if (quizAnswerDict && currentQuizId > 0)
	{
		NSDictionary *currentQuizMenuDataDict = quizMenuDataArray[currentQuizMenuDataArrayIndex];
		NSString *currentQuizTitle = [currentQuizMenuDataDict objectForKey:@"title"];
		[self.readViewQuizDataController saveQuizAnswerDictionary:quizAnswerDict forChapterTitle:currentPageInstance.Title forQuizTitle:currentQuizTitle];
		[[DataController sharedController] saveQuestionResultForDictionary:quizAnswerDict forQuizId:currentQuizId];
		[self.readViewQuizDataController updateQuizDataForQuestionDict:quizAnswerDict];
		[self.readViewWebServicesEngine sendQuizAnswerToServer:quizAnswerDict forQuizAnswerJsonString:(NSString *)jsonObject];
	}
}

- (void)handleQuizSecondsJsonForArgs:(NSArray *)args
{
	NSDecimalNumber *arg0Num = [args objectAtIndex:0];
	NSDecimalNumber *arg1Num = [args objectAtIndex:1];
	
	if (arg0Num && arg1Num)
	{
		int quizIdInt = [arg0Num intValue];
		int secondsInt = [arg1Num
						  intValue];
		[[DataController sharedController] updateSecondsCount:secondsInt forQuizId:quizIdInt];
		[self.readViewQuizDataController updateQuizDataArrayForQuizId:quizIdInt];
	}
}

- (NSDictionary *)parseJsonQuizAnswerString:(NSString *)jsonString
{
	NSDictionary *quizAnswerDict = nil;
	NSString *questionIdString = nil, *isCorrectString = nil, *isGradedString = nil;
	NSNumber *quizIdNumber = [NSNumber numberWithInt:currentQuizId];
	questionIdString = [self parseQuestionIdFromResultString:jsonString];
	isCorrectString = [self parseIsCorrectFromResultString:jsonString];
	isGradedString = [self parseIsGradedFromResultString:jsonString];
	BOOL isCorrectBool = [isCorrectString isEqualToString:@"true"];
	BOOL isGradedBool = [isGradedString isEqualToString:@"true"];
	
	if (questionIdString && isCorrectString)
		quizAnswerDict = [NSDictionary dictionaryWithObjectsAndKeys:
						  questionIdString, @"questionId",
						  (isCorrectBool == YES) ? @"1" : @"0", @"isCorrect",
						  (isGradedBool == YES) ? @"1" : @"0", @"isGraded",
						  quizIdNumber, @"quizId",
						  nil];

	return quizAnswerDict;
}

- (NSString *)parseQuestionIdFromResultString:(NSString *)jsonString
{
	NSString *questionIdString = nil;
	NSRange quizIdPrefixRange = [jsonString rangeOfString:@"questionId\":" options:NSCaseInsensitiveSearch range:NSMakeRange(0, 20)];
	NSRange quizIdSuffixRange = [jsonString rangeOfString:@"," options:NSCaseInsensitiveSearch range:NSMakeRange(0, 20)];

	if (quizIdPrefixRange.location != NSNotFound && quizIdSuffixRange.location != NSNotFound)
	{
		int quizIdLocation = quizIdPrefixRange.location + quizIdPrefixRange.length;
		int quizIdLength = quizIdSuffixRange.location - quizIdLocation;
		questionIdString = [jsonString substringWithRange:NSMakeRange(quizIdLocation, quizIdLength)];
	}
	return questionIdString;
}

- (NSString *)parseIsCorrectFromResultString:(NSString *)jsonString
{
	NSString *isCorrectString = nil;
	NSRange quizIsCorrectPrefixRange = [jsonString rangeOfString:@"isCorrect\":" options:NSCaseInsensitiveSearch range:NSMakeRange(0, jsonString.length)];
	NSRange quizIsCorrectSuffixRange = [jsonString rangeOfString:@",\"isGraded" options:NSCaseInsensitiveSearch range:NSMakeRange(0, jsonString.length)];
	
	if (quizIsCorrectPrefixRange.location != NSNotFound && quizIsCorrectSuffixRange.location != NSNotFound)
	{
		int quizIsCorrectLocation = quizIsCorrectPrefixRange.location + quizIsCorrectPrefixRange.length;
		int quizIsCorrectLength = quizIsCorrectSuffixRange.location - quizIsCorrectLocation;
		isCorrectString = [jsonString substringWithRange:NSMakeRange(quizIsCorrectLocation, quizIsCorrectLength)];
	}
	
	return isCorrectString;
}

- (NSString *)parseIsGradedFromResultString:(NSString *)jsonString
{
	NSString *isGradedString = nil;
	NSRange quizIsGradedPrefixRange = [jsonString rangeOfString:@"isGraded\":" options:NSCaseInsensitiveSearch range:NSMakeRange(0, jsonString.length)];
	NSRange quizIsGradedSuffixRange = [jsonString rangeOfString:@"}" options:NSCaseInsensitiveSearch range:NSMakeRange(0, jsonString.length)];
	
	if (quizIsGradedPrefixRange.location != NSNotFound && quizIsGradedSuffixRange.location != NSNotFound)
	{
		int quizIsGradedLocation = quizIsGradedPrefixRange.location + quizIsGradedPrefixRange.length;
		int quizIsCorrectLength = quizIsGradedSuffixRange.location - quizIsGradedLocation;
		isGradedString = [jsonString substringWithRange:NSMakeRange(quizIsGradedLocation, quizIsCorrectLength)];
	}
	
	return isGradedString;
}

#pragma mark - Reading progress

- (void)calculateCurrentAndMaxYOffsets
{
    currentScrollYOffsetInt = (int)detailedWebView.scrollView.contentOffset.y;

	if (currentScrollYOffsetInt < 0)
		currentScrollYOffsetInt = 0;
	
	if (currentScrollYOffsetInt > maxScrollYOffsetInt)
		maxScrollYOffsetInt = currentScrollYOffsetInt;
}

- (void)calculateCurrentProgressPercentage
{
	currentChapterProgressInt = ((float)currentScrollYOffsetInt + self.view.frame.size.height) / (float)detailedWebView.scrollView.contentSize.height * 100.0f;
	
	if (currentChapterProgressInt > 95)
		currentChapterProgressInt = 100;
}

- (void)calculateMaxProgressPercentage
{
	int possibleMaxProgressInt = ((float)maxScrollYOffsetInt + self.view.frame.size.height) / (float)detailedWebView.scrollView.contentSize.height * 100.0f;
	
	if (possibleMaxProgressInt > 95)
		possibleMaxProgressInt = 100;
	
	if (possibleMaxProgressInt > maxChapterProgressInt)
		maxChapterProgressInt = possibleMaxProgressInt;
}

- (void)setProgressInDatabase
{
	if (self.oldCurProgressPercentageInt != currentChapterProgressInt || self.oldMaxProgressPercentageInt < maxChapterProgressInt)
	{
		NSDictionary *progressDictForSQLite = [NSDictionary dictionaryWithObjectsAndKeys:
											   [NSNumber numberWithInt:currentChapterProgressInt], @"currentPercentage",
											   [NSNumber numberWithInt:maxChapterProgressInt], @"maxPercentage",
											   nil];
		[[DataController sharedController] saveChapterReadPercentage:progressDictForSQLite forPageInstanceId:pageInstance.PageInstanceId];
	}
}

// example of json payload string for progress update:
//     "json": "{\n  \"currentPercentage\": 100,\n  \"maxPercentage\": 100,\n  \"payLoadInteger\": 503975,\n  \"payLoadString\": \"1206\"\n}",

- (void)sendProgressToServer
{
	NSMutableDictionary *progressDictForServer = [NSMutableDictionary dictionaryWithObjectsAndKeys:
												  [NSNumber numberWithInt:currentChapterProgressInt], @"currentPercentage",
												  [NSNumber numberWithInt:maxChapterProgressInt], @"maxPercentage",
												  [NSNumber numberWithInteger:pageInstance.PageInstanceId], @"payLoadInteger",
												  [[NSNumber numberWithInteger:pageInstance.PagesId] stringValue], @"payLoadString",
												  nil];

	[self.readViewWebServicesEngine sendCurrentChapterProgressToServer:progressDictForServer];
}

- (void)setScrollViewYOffsetWithAnimation:(BOOL)doAnimation
{
	if (self.oldCurProgressPercentageInt < 95)
		currentScrollYOffsetInt = (int)((float)self.oldCurProgressPercentageInt / 100.0f * detailedWebView.scrollView.contentSize.height);
	else
		currentScrollYOffsetInt = 0.0f;														// go back to top if user has completed the chapter
	
	CGPoint scrollViewYOffset = CGPointMake(0.0f, (float)currentScrollYOffsetInt);
	
	if (scrollViewYOffset.y < 0.0f)
		scrollViewYOffset.y = 0.0f;
	else if (scrollViewYOffset.y > (detailedWebView.scrollView.contentSize.height - detailedWebView.scrollView.frame.size.height))
		scrollViewYOffset.y = detailedWebView.scrollView.contentSize.height - detailedWebView.scrollView.frame.size.height;

	[detailedWebView.scrollView setContentOffset:scrollViewYOffset animated:doAnimation];	// animated scroll to previous read position is dizzying.  just go straight there.
}

#pragma mark - Web view delegate methods

- (BOOL)webView:(UIWebView *)webView2
shouldStartLoadWithRequest:(NSURLRequest *)request
 navigationType:(UIWebViewNavigationType)navigationType {
	
	NSString *requestString = [[request URL] absoluteString];
	
	if ([requestString hasPrefix:@"js-frame:"]) {
		
		NSArray *components = [requestString componentsSeparatedByString:@":"];
		NSString *function = (NSString*)[components objectAtIndex:1];
		int callbackId = [((NSString*)[components objectAtIndex:2]) intValue];
		NSString *argsAsString = [(NSString*)[components objectAtIndex:3]
								  stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		NSArray *args = (NSArray*)[json objectWithString:argsAsString error:nil];

		if (args == nil)
			args = [NSArray arrayWithObjects:argsAsString, nil];

		if (currentQuizId == 0)										// only set currentQuizId once. called with wrong quiz id the second time (when user taps "quiz menu.")
			currentQuizId = callbackId;

		if (quizMenuTapped == NO && [function isEqualToString:@"fetchJson"])
		{
			// there are two ways of launching a quiz: 1. tap on the button in the text, 2. tap the quiz menu.
			// these are handled differently, but we need to make them look identical to the webview.
			// so we need to call handleCall:callbackId:args: with the correct args when user taps a text button.
			NSString *quizCallbackIdString = args[0];
			int quizCallbackIdInt = [quizCallbackIdString intValue];
			[self handleCall:function callbackId:quizCallbackIdInt args:nil];
		}

		[self handleCall:function callbackId:callbackId args:args];
		
		return NO;
	}
	
	return YES;
}

// Call this function when you have results to send back to javascript callbacks
// callbackId : int comes from handleCall function
// args: list of objects to send to the javascript callback
- (void)returnResult:(int)callbackId args:(id)arg, ...;
{
	va_list argsList;
	NSMutableArray *resultArray = [[NSMutableArray alloc] init];
	
	if(arg != nil){
		[resultArray addObject:arg];
		va_start(argsList, arg);
		while((arg = va_arg(argsList, id)) != nil)
			[resultArray addObject:arg];
		va_end(argsList);
	}
	
	NSString *resultArrayString = [json stringWithObject:resultArray allowScalar:YES error:nil];
	[detailedWebView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"NativeBridge.resultForCallback(%d,%@);",callbackId,resultArrayString]];
}

// Performs native calls by matching 'functionName' and parsing 'args'
// Use 'callbackId' with 'returnResult' selector when have results to send back to javascript
- (void)handleCall:(NSString *)functionName callbackId:(int)callbackId args:(NSArray*)args
{
	BOOL doCallback = YES;

	if ([functionName isEqualToString:@"fetchJson"])				// show the quiz
	{
        [self closeTopNavigationBar];
        [self toggleScrollViewScrollingWithBool:NO];
        sharedController.menuItems = nil;
        [sharedController setMenuVisible:NO animated:YES];
        quizVisible = YES;
		[self fetchJsonFromSqliteForQuizId:callbackId];

		if (currentQuizId == 0)										// only set currentQuizId once. called with wrong quiz id the second time (when user taps "quiz menu.")
			currentQuizId = callbackId;
	}
	else if ([functionName isEqualToString:@"setSelectAnswerDB"])	// user has selected an answer
	{
		[self handleQuizAnswerForArgs:args];
		doCallback = NO;
	}
	else if ([functionName isEqualToString:@"setQuizSecondsDB"])	// user has quit quiz, so now we add elapsed time to total
	{
		[self handleQuizSecondsJsonForArgs:args];
        [self toggleScrollViewScrollingWithBool:YES];
        [self addMenuItemsToSharedController];
		quizVisible = NO;
		currentQuizId = 0;
		jsonString = nil;
		doCallback = NO;
		quizMenuTapped = NO;
	}
	else
	{
		NSLog(@"Unimplemented method '%@'", functionName);
		doCallback = NO;
	}

	if (doCallback)
		[self returnResult:callbackId args:jsonString, nil];
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
}

- (void)webViewDidFinishLoad:(UIWebView *)aWebView
{
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
}

#pragma mark - Quiz button menu

// find the quiz ordinal number and title associated with each quiz button.  here's a sample with ordinal number 2 and title "Problem Set C:"
// <button onclick="showQuiz(2)" class="quiz-button">Problem Set C:</button>

- (void) populateCurrentPageQuizArrayForQuizMenu
{
	if (quizMenuDataArray == nil)
		quizMenuDataArray = [[NSMutableArray alloc] initWithCapacity:0];
	else
		[quizMenuDataArray removeAllObjects];
	
	currentPageInstance = [contentArray objectAtIndex:pageIndex];
	
	if (currentPageInstance == nil)
		return;
	
	NSString *currentHtml = currentPageInstance.Html;
	int currentSearchOffset = 0;
	NSString *quizKeyword = @"showQuiz(";
	NSRange quizStringStartRange = [currentHtml rangeOfString:quizKeyword
													  options:NSCaseInsensitiveSearch
														range:NSMakeRange(currentSearchOffset, currentHtml.length - currentSearchOffset)];
	
	while (quizStringStartRange.location != NSNotFound)			// scan html to find all quiz buttons so we can determine each quiz' ordinal number and title
	{
		currentSearchOffset = quizStringStartRange.location + quizStringStartRange.length;
		NSRange quizStringEndRange = [currentHtml rangeOfString:@")"
														options:NSCaseInsensitiveSearch
														  range:NSMakeRange(quizStringStartRange.location, 20)];
		int numberLocation = quizStringStartRange.location + quizStringStartRange.length;
		int numberLength = quizStringEndRange.location - numberLocation;
		NSString *quizOrdinalString = [currentHtml substringWithRange:NSMakeRange(numberLocation, numberLength)];
		
		if (quizOrdinalString && quizOrdinalString.length > 0)	// if we found the ordinal number, look for the title next
		{
			NSRange quizTitleStartRange = [currentHtml rangeOfString:@">" options:NSCaseInsensitiveSearch range:NSMakeRange(currentSearchOffset, 40)];
			
			if (quizTitleStartRange.location != NSNotFound)
			{
				int titleLocation = quizTitleStartRange.location + quizTitleStartRange.length;
				NSRange quizTitleEndRange = [currentHtml rangeOfString:@"<"
															   options:NSCaseInsensitiveSearch
																 range:NSMakeRange(titleLocation, currentHtml.length - titleLocation)];
				int titleLength = quizTitleEndRange.location - titleLocation;
				NSString *quizTitleString = [currentHtml substringWithRange:NSMakeRange(titleLocation, titleLength)];
				
				if (quizTitleString)
				{
					NSDictionary *quizDict = [self quizDictionaryWithTitle:quizTitleString ordinalInt:[quizOrdinalString intValue]];
					[quizMenuDataArray addObject:quizDict];
					[self.readViewQuizDataController saveQuizDictionary:quizDict forChapterTitle:currentPageInstance.Title];
				}
			}
		}
		
		currentSearchOffset = quizStringEndRange.location + 5;
		quizStringStartRange = [currentHtml rangeOfString:quizKeyword
												  options:NSCaseInsensitiveSearch
													range:NSMakeRange(currentSearchOffset, currentHtml.length - currentSearchOffset)];
	}
}


- (NSDictionary *)quizDictionaryWithTitle:(NSString *)rawQuizTitle ordinalInt:(int)ordinalInt
{
	NSString *cookedQuizTitle = [rawQuizTitle copy];

	if ([rawQuizTitle hasSuffix:@":"])
		cookedQuizTitle = [rawQuizTitle substringToIndex:rawQuizTitle.length - 1];
	else if ([rawQuizTitle hasSuffix:@"- "])
		cookedQuizTitle = [rawQuizTitle substringToIndex:rawQuizTitle.length - 2];
	else if ([rawQuizTitle hasSuffix:@" "])
		cookedQuizTitle = [rawQuizTitle substringToIndex:rawQuizTitle.length - 1];
	
	NSDictionary *quizDict = [NSDictionary dictionaryWithObjectsAndKeys:cookedQuizTitle, @"title", [NSNumber numberWithInt:ordinalInt], @"ordinal", nil];
	return quizDict;
}

- (void)showOrHideQuizButton
{
    if (quizMenuDataArray.count == 0)
        self.navigationItem.rightBarButtonItem = nil;
    else
        self.navigationItem.rightBarButtonItem = self.quizButton;
	//self.quizButton.title = (quizMenuDataArray.count == 0 ? @"" : NSLocalizedString(@"Quiz", @"Quiz"));   Quiz button tap action is triggering even text is nil..so I commented this line
}

#pragma mark - Quiz button's action sheet

// we refer to the list of quizzes as a "menu" but it's implemented in an action sheet for consistency with other apps

- (void)showQuizActionSheet
{
	NSString *sheetTitle = NSLocalizedString(@"Quizzes", nil);
	
	if (quizMenuDataArray.count == 0)
		sheetTitle = NSLocalizedString(@"No quizzes", nil);
	
	UIActionSheet *quizActionSheet = [[UIActionSheet alloc] initWithTitle:sheetTitle
																 delegate:self
														cancelButtonTitle:nil
												   destructiveButtonTitle:nil
														otherButtonTitles:nil];
	
	for (NSDictionary *quizDict in quizMenuDataArray)
		[quizActionSheet addButtonWithTitle:[quizDict valueForKey:@"title"]];
	
	[quizActionSheet addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
	quizActionSheet.cancelButtonIndex = quizMenuDataArray.count;
	quizActionSheet.actionSheetStyle = UIActionSheetStyleDefault;
	[quizActionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex < quizMenuDataArray.count)
	{
		NSDictionary *currentQuizMenuDataDict = quizMenuDataArray[buttonIndex];
		int quizOrdinalInt = [currentQuizMenuDataDict[@"ordinal"] intValue];
		quizMenuTapped = YES;
		[self showQuizWithOrdinalIntId:quizOrdinalInt];
		[self requestQuizResultsForQuizId:quizOrdinalInt];
	}
}

-(void) toggleScrollViewScrollingWithBool:(BOOL) boolValue
{
    [detailedWebView.scrollView setScrollEnabled:boolValue];
    [self.aScrollView setScrollEnabled:boolValue];
}

- (void)showQuizWithOrdinalIntId:(int)quizOrdinalInt
{
	[self handleCall:@"fetchJson" callbackId:quizOrdinalInt args:nil];
	[detailedWebView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"showQuiz(%d)", quizOrdinalInt]];
}

#pragma mark - Asynchronous quiz progress request

- (void)requestQuizResultsForQuizId:(int)quizIdInt
{
	[[NSNotificationCenter defaultCenter] postNotificationName:@"requestQuizResultsForQuizId" object:[NSNumber numberWithInt:quizIdInt]];
}

#pragma mark - Misc adjustments

- (void)adjustScrollViewPosition
{
	if (self.parentViewIsTimeline)				// for some reason, we need to adjust scrollview y offset depending on which main view is its parent
	{
		CGRect frame = aScrollView.frame;
		frame.origin.y = -10.0f;
		aScrollView.frame = frame;
	}
}

#pragma mark - Button actions

- (IBAction)handleQuizButtonTap:(id)sender;
{
	[self showQuizActionSheet];
}

#pragma mark - Memory

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
