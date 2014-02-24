//
//  CardViewController.m
//  Fit
//
//  Created by Rich on 10/31/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
///

#import "CardViewController.h"
#import "AppDelegate.h"
@interface CardViewController ()

@end

@implementation CardViewController


#define Top_Padding 34
#define Right_Padding 34
#define Left_Padding 34

- (void)viewDidLoad
{
    [self initDataEngines];
	//[self initWebServicesEngine];
}

- (void)initWebServicesEngine
{
	listViewWebServicesEngine = [WebServicesEngine webServicesEngine];
    [listViewWebServicesEngine requestFlashCardHistory];
}

- (void)initDataEngines
{
	listViewChapterDataController = [ChapterDataController sharedChapterDataController];
	listViewQuizDataController = [QuizDataController sharedQuizDataController];
}

-(void)addInitialContent
{
    selectedIndex = 0;
    [self getAllCardsFromDatabase];
    if(self.cardsArray.count>0)
    {
        [self addNullObjectsToTextViewsArray];
        [self loadScrollViewContents];
        [self removeGesturesFromView];
        [self addSwipeRecognizerForDirection:UISwipeGestureRecognizerDirectionUp];
        [self addSwipeRecognizerForDirection:UISwipeGestureRecognizerDirectionDown];
        [self addTapGestureRecognizerToGoReadViewController];
        [self addPanGestureToView];
        [self addPageControl];
        [self.view setBackgroundColor:[UIColor whiteColor]];
    }
    else
    {
        [self.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"NoCardsImage"]]];
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    [self.tabBarController.tabBar setHidden:NO];
    [self.navigationController setNavigationBarHidden:YES];
    AppDelegate *delegate = XAppDelegate;
    if (delegate.isFromReadViewController) {
        for (UIView *subView in self.view.subviews)
            [subView removeFromSuperview];
        
        [self addInitialContent];
        delegate.isFromReadViewController = NO;
    }
    else{
        if (self.cardsArray == nil) {
            [self addInitialContent];
        }
    }
}

-(void) removeGesturesFromView
{
    for (UIGestureRecognizer *recognizer in self.view.gestureRecognizers) {
        
        [self.view removeGestureRecognizer:recognizer];
    }
}

-(void)addPageControl
{
    self.pageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(20, self.view.frame.size.height - 80, self.view.frame.size.width-40, 36)];
    [self.view addSubview:self.pageControl];
    self.pageControl.numberOfPages = self.cardsArray.count;
    self.pageControl.currentPage = 0;
    self.pageControl.pageIndicatorTintColor = [UIColor grayColor];
    
    self.pageControl.backgroundColor = [UIColor clearColor];
    [self.view bringSubviewToFront:self.pageControl];
}

-(CGRect)getToFrameForCardView:(UIView *)cardView
{
    CGRect frame = cardView.frame;
    frame.origin.y = -(self.view.frame.size.height);
    return frame;
}

-(void)addPanGestureToView
{
    self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didReceivePanGestureEvent:)];
 //   activeCard = [self.cardViewsArray objectAtIndex:0];
    [self.view addGestureRecognizer:self.panGesture];
}

-(void)addShadow:(BOOL)shouldAdd{
    
    UIView *view = activeCard;
    CALayer *layer=[view layer];
    [layer setShadowPath:[UIBezierPath bezierPathWithRect:layer.bounds].CGPath];
    [layer setShadowColor:[UIColor blackColor].CGColor];
    [layer setShadowOffset:CGSizeMake(0, 4)];
    [layer setShadowOpacity:0.80];
}

-(CGFloat)getAnimationDurationForFrame:(CGRect)fromFrame toFrame:(CGRect)toFrame velocity:(CGFloat)velocity{
    
    velocity=fabs(velocity)>0.0?velocity:1;
    CGFloat displacement=fromFrame.origin.x-toFrame.origin.x;
    CGFloat deltaT=fabs(displacement/velocity);
    if(deltaT>0.4){
        deltaT=0.4;
    }else if(deltaT<0.01){
        deltaT=0.01;
    }
    return deltaT;
}

-(void) addCards
{
    [self loadScrollViewWithPage:selectedIndex-1];
    [self loadScrollViewWithPage:selectedIndex];
    [self loadScrollViewWithPage:selectedIndex+1];
    
    [self.view addSubview:self.pageControl];
    self.pageControl.numberOfPages = self.cardViewsArray.count;
    self.pageControl.currentPage = selectedIndex;
}

-(void) cardsChanged
{
    for (int index = 0; index < [self.cardViewsArray count]; index++) {
        if (index != selectedIndex - 1 && index != selectedIndex && index != selectedIndex + 1) {
            
            [self.cardViewsArray replaceObjectAtIndex:index withObject:[NSNull null]];
        }
    }
    [self addCards];
}

-(CGRect)getCardViewFrameForState:(BOOL)isHiding{
    
    CGRect frame = activeCard.frame;
    if(isHiding){
        
        frame.origin.x = self.view.frame.size.width;
    }
    else
    {
        frame.origin.x = 0;
    }
    return frame;
}

-(void)performPanEndActivitiesWithVelocity:(CGPoint)velocityPoint
{
    CGFloat velocity = velocityPoint.x;
    CGFloat constraintX = self.view.frame.size.width/2;
    CGRect fromFrame = activeCard.frame;
    BOOL isHidingCards;
    if (activeCard.frame.origin.x > constraintX) {
        isHidingCards = YES;
    }
    else
    {
        isHidingCards = NO;
    }
    CGRect toFrame = [self getCardViewFrameForState:isHidingCards];
    CGFloat animationDuration=[self getAnimationDurationForFrame:fromFrame toFrame:toFrame velocity:velocity];
    [UIView animateWithDuration:animationDuration animations:^{
        [activeCard setFrame:toFrame];
    }completion:^(BOOL finished) {
        if ((isHidingCards && newCardAdding) || (!isHidingCards && currentCardRemoving)) {
            
        }
        else if(isHidingCards && currentCardRemoving)
        {
            --selectedIndex;
            [self cardsChanged];
        }
        else if(!isHidingCards && newCardAdding)
        {
            ++selectedIndex;
            [self cardsChanged];
        }
        NSLog(@"selected index====%d",selectedIndex);
    }];
}

-(void) setActiveCardForTransitionDelta:(CGFloat) translationDelta
{
    if (translationDelta < 0) {
        currentCardRemoving = NO;
        if (selectedIndex >= 0 && selectedIndex < [self.cardsArray count]-1) {
            newCardAdding = YES;
            activeCard = [self.cardViewsArray objectAtIndex:selectedIndex+1];
        }
        else
        {
            newCardAdding = NO;
            activeCard = nil;
        }
    }
    else
    {
        newCardAdding = NO;
        currentCardRemoving = YES;
        if (selectedIndex != 0) {
            activeCard = [self.cardViewsArray objectAtIndex:selectedIndex];
        }
        else
            activeCard = nil;
    }
    
    [self addShadow:YES];

}

-(IBAction)didReceivePanGestureEvent:(UIPanGestureRecognizer *)recognizer
{
    static CGFloat previousTranslation=0;
    CGPoint translationPoint = [recognizer translationInView:self.view];
    CGFloat currentTranslation = translationPoint.x;
    CGFloat translationDelta=0;
    switch(recognizer.state)
    {
        case UIGestureRecognizerStateBegan:{
            panDraggingStarted = YES;
         
        }break;
            
        case UIGestureRecognizerStateEnded:{
            
            translationDelta=currentTranslation-previousTranslation;
            previousTranslation=currentTranslation;
            CGPoint velocity=[recognizer velocityInView:self.view];
            [self performPanEndActivitiesWithVelocity:velocity];
            return;
        }break;
            
        case UIGestureRecognizerStateChanged:{
            if (panDraggingStarted) {
                [self setActiveCardForTransitionDelta:currentTranslation];
                previousTranslation=currentTranslation;
                panDraggingStarted = NO;
            }
            translationDelta=currentTranslation-previousTranslation;
            previousTranslation=currentTranslation;
        }break;
            
        default:{
            return;
        }break;
    }
    CGRect frame = activeCard.frame;
    frame.origin.x+=translationDelta;
    float minX = 0;
    float maxX = self.view.frame.size.width;
    if(frame.origin.x<minX){
        frame.origin.x=minX;
    }else if(frame.origin.x>maxX){
        frame.origin.x=maxX;
    }
    [activeCard setFrame:frame];
}

-(void)tappedOnView:(UITapGestureRecognizer *)tapGesture
{
    //hide delete button and change cardview frame to its original position when tapped on view
    [UIView animateWithDuration:0.3f animations:^{
        UIView *cardView = [self.cardViewsArray objectAtIndex:selectedIndex];
        [self.deleteButton setTitleEdgeInsets:UIEdgeInsetsMake(50, 0, 0, 0)];
        self.deleteButton.frame =  CGRectMake(0, self.view.frame.size.height-48, self.view.frame.size.width, 00);
        cardView.frame = CGRectMake(cardView.frame.origin.x, cardView.frame.origin.y+30, cardView.frame.size.width, cardView.frame.size.height);
    }];
    [self.view addGestureRecognizer:self.readTapGesture];
    [self.view addGestureRecognizer:self.panGesture];
    [self.view removeGestureRecognizer:self.tapGestureRecognizer];
    isDeleteVisible = NO;
}

-(void)deleteCard:(UIButton *) sender
{
    deleteIndex = selectedIndex;
    UIView *cardView = [self.cardViewsArray objectAtIndex:deleteIndex];
    CGRect toFrame = [self getToFrameForCardView:cardView];
    [UIView animateWithDuration:0.3 animations:^{
        [cardView setFrame:toFrame];
        [self.deleteButton setTitleEdgeInsets:UIEdgeInsetsMake(50, 0, 0, 0)];
        self.deleteButton.frame =  CGRectMake(0, self.view.frame.size.height-48, self.view.frame.size.width, 00);
        [self.view addGestureRecognizer:self.readTapGesture];
         [self.view addGestureRecognizer:self.panGesture];
        [self.view removeGestureRecognizer:self.tapGestureRecognizer];
        isDeleteVisible = NO;
    }completion:^(BOOL finished) {
        
        [cardView removeFromSuperview];
        int pageIndex = selectedIndex;
        Card *card = [self.cardsArray objectAtIndex:pageIndex];
        [[DataController sharedController]deleteCardFromDatabaseForTimeStamp:card.timeStamp];
        [self.cardViewsArray removeObjectAtIndex:pageIndex];
        [self.cardsArray removeObjectAtIndex:pageIndex];
        
        if (self.cardsArray.count > 0) {
            
            if (selectedIndex != 0)
                --selectedIndex;
            
            [self addCards];
        }
        else
        {
            for (UIView *subView in self.view.subviews)
                [subView removeFromSuperview];
            self.pageControl.numberOfPages = 0;
            [self removeGesturesFromView];

            [self.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"NoCardsImage.png"]]];
        }
    }];
}

-(void) swipeGestureRecognized:(UISwipeGestureRecognizer *) swipeGesture
{
    if (isDeleteVisible) {
        [UIView animateWithDuration:0.3f animations:^{
            UIView *cardView = [self.cardViewsArray objectAtIndex:selectedIndex];
            [self.deleteButton setTitleEdgeInsets:UIEdgeInsetsMake(50, 0, 0, 0)];
            self.deleteButton.frame =  CGRectMake(0, self.view.frame.size.height-48, self.view.frame.size.width, 00);
            cardView.frame = CGRectMake(cardView.frame.origin.x, cardView.frame.origin.y+30, cardView.frame.size.width, cardView.frame.size.height);
        }];
        // remove tapGesture when delete button not visible
        [self.view addGestureRecognizer:self.readTapGesture];
        [self.view addGestureRecognizer:self.panGesture];
        [self.view removeGestureRecognizer:self.tapGestureRecognizer];
        isDeleteVisible = NO;
    }
    else
    {
        //Create delete button if its not in memory
        if (self.deleteButton == nil) {
            
            self.deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [self.deleteButton setTitle:@"Delete" forState:UIControlStateNormal];
            [self.deleteButton setBackgroundColor:[UIColor redColor]];
            [self.deleteButton addTarget:self action:@selector(deleteCard:) forControlEvents:UIControlEventTouchUpInside];
        }
        [self.view addSubview:self.deleteButton];
        [self.deleteButton setTitleEdgeInsets:UIEdgeInsetsMake(00, 0, 0, 0)];
        self.deleteButton.frame =  CGRectMake(00, self.view.frame.size.height-48, self.view.frame.size.width, 00);
        [UIView animateWithDuration:0.3f animations:^{
            UIView *cardView = [self.cardViewsArray objectAtIndex:selectedIndex];
            self.deleteButton.frame =  CGRectMake(00, self.view.frame.size.height-98, self.view.frame.size.width, 50);
            cardView.frame = CGRectMake(cardView.frame.origin.x, cardView.frame.origin.y-30, cardView.frame.size.width, cardView.frame.size.height);
        }];
        //Add TapGesture for view when delete button is visible
        
        self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedOnView:)];
        [self.view addGestureRecognizer:self.tapGestureRecognizer];
        [self.view removeGestureRecognizer:self.readTapGesture];
        [self.view removeGestureRecognizer:self.panGesture];
        //[self.view removeGestureRecognizer:self.swipeGestureRecognizer];
        isDeleteVisible = YES;
    }
}

-(void)goToReadViewController
{
    [self performSegueWithIdentifier:@"goToReadViewController" sender:self];
    NSLog(@"go to read view controller");
}

-(int) getTheIndexOfCardInArray:(NSMutableArray *)contentArray ForPageInstanceId:(int) pageInstanceId
{
    for (int index = 0; index < contentArray.count; index++) {
        PageInstance *instance = [contentArray objectAtIndex:index];
        if (pageInstanceId == instance.PageInstanceId) {
            return index;
        }
    }
    return 0;
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	
    if ([segue.identifier isEqualToString:@"goToReadViewController"]) {
        
        if ([segue.identifier isEqualToString:@"goToReadViewController"]) {
            
            Card *card = [self.cardsArray objectAtIndex:selectedIndex];
            ReadViewController *readViewController = segue.destinationViewController;
            NSArray *sectionsArray = [[DataController sharedController] getSectionsList];
            NSDictionary *sectionDict = [[DataController sharedController] tagID:card.pageInstanceId];
            NSMutableArray *contentArray = [[NSMutableArray alloc] init];
            for (int index = 0; index < sectionsArray.count ; index++) {
                [contentArray addObjectsFromArray:[[ChapterDataController sharedChapterDataController] sectionArrayForIndex:index]];
            }
            readViewController.contentArray = [contentArray mutableCopy];
            readViewController.sectionName = [sectionDict objectForKey:@"Section Name"];
            readViewController.selectedPage = [self getTheIndexOfCardInArray:contentArray ForPageInstanceId:card.pageInstanceId];
            readViewController.readViewChapterDataController = listViewChapterDataController;
            readViewController.readViewQuizDataController = listViewQuizDataController;
            readViewController.oldCurProgressPercentageInt = 0;// [[ChapterDataController sharedChapterDataController] getChapterCurrentProgressForIndexPath:currentChapterIndex];
            readViewController.oldMaxProgressPercentageInt = 0;
            readViewController.readViewWebServicesEngine = listViewWebServicesEngine;
            readViewController.parentViewIsTimeline = NO;
        }
    }
}


-(void)addTapGestureRecognizerToGoReadViewController
{
    self.readTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(goToReadViewController)];
    [self.view addGestureRecognizer:self.readTapGesture];
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (void)addSwipeRecognizerForDirection:(UISwipeGestureRecognizerDirection)direction
{
    // Create a swipe recognizer for the wanted direction
    UISwipeGestureRecognizer *swipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeGestureRecognized:)];
    swipeGestureRecognizer.delegate = self;
    swipeGestureRecognizer.direction = direction;
    [self.view addGestureRecognizer:swipeGestureRecognizer];
}

-(UIImage *) getShareText
{
    CardView *cardView = [self.cardViewsArray objectAtIndex:selectedIndex];
    [cardView.shareButton removeFromSuperview];
    UIGraphicsBeginImageContext(cardView.bounds.size);
    [cardView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [cardView addSubview:cardView.shareButton];
    return image;
}

-(void)displayComposerSheet
{
	MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
	picker.mailComposeDelegate = self;
	
	NSString *subject = [NSString stringWithFormat:@"%@", [[DataController sharedController]title]];
    
	[picker setSubject:subject];
    
	NSArray *toRecipients = [NSArray arrayWithObject:@""];
	[picker setToRecipients:toRecipients];
    
//	[picker setMessageBody:[self getShareText] isHTML:YES];
    
    NSData *imageData = UIImageJPEGRepresentation([self getShareText], 1.0);
    [picker addAttachmentData:imageData mimeType:@"image/png" fileName:@"Card.png"];
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
	static NSString *message=@"";
	// Notifies users about errors associated with the interface
	switch (result)
	{
		case MFMailComposeResultCancelled:
			message = @"Result: cancelled";
			break;
		case MFMailComposeResultSaved:
			message = @"Result: saved";
			break;
		case MFMailComposeResultSent:{
			// Get the main bundle for the app
			
			CFBundleRef mainBundle;
			mainBundle = CFBundleGetMainBundle ();
			self.soundFileURLRef = nil;
			// Get the URL to the sound file to play
			self.soundFileURLRef  = CFBundleCopyResourceURL (
															 mainBundle,
															 CFSTR ("mailSent"),
															 CFSTR ("wav"),
															 NULL
															 );
			
			// Create a system sound object representing the sound file
			AudioServicesCreateSystemSoundID (
											  self.soundFileURLRef,
											  &_soundFileObject
											  );
			AudioServicesPlaySystemSound (self.soundFileObject);
			
			message = @"Result: sent";
			break;}
		case MFMailComposeResultFailed:
			message = @"Result: failed";
			break;
		default:
			message = @"Result: not sent";
			break;
	}
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result;
{
	// added to eliminate compiler warning about missing delegate method
}

-(void)launchMailAppOnDevice
{
	NSString *recipients = @"mailto:support@mmotio.com&subject=Review for spts App";
	
	NSString *model = [UIDevice currentDevice].model;
	NSString *version = [[UIDevice currentDevice] systemVersion];
	NSString *body = [NSString stringWithFormat:@"\n\n\nMy device is %@ and version is %@", model,version];
	NSString *email = [NSString stringWithFormat:@"%@%@", recipients, body];
	email = [email stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:email]];
}

-(void)shareEmail
{
	Class mailClass = (NSClassFromString(@"MFMailComposeViewController"));
	if (mailClass != nil)
	{
		// We must always check whether the current device is configured for
		//sending emails
		if ([mailClass canSendMail])
		{
			[self displayComposerSheet];
		}
		else
		{
			[self launchMailAppOnDevice];
		}
	}
	else
	{
		[self launchMailAppOnDevice];
	}
}

- (void)shareToSialNetworkWithId:(NSString *)string {
    
    float version = [[[UIDevice currentDevice] systemVersion] floatValue];
    if (version >= 6.0){
        
        if([SLComposeViewController isAvailableForServiceType:string]) {
            
            SLComposeViewController *controller = [SLComposeViewController composeViewControllerForServiceType:string];
            
            SLComposeViewControllerCompletionHandler myBlock = ^(SLComposeViewControllerResult result){
                if (result == SLComposeViewControllerResultCancelled) {
                    UIAlertView *postalrt = [[UIAlertView alloc] initWithTitle:@"Alert" message:@"Your post unsuccessful" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                    [postalrt show];
                }
                else
                {
                    UIAlertView *postalrt2 = [[UIAlertView alloc] initWithTitle:@"Alert" message:@"Your post successful" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                    [postalrt2 show];
                }
                [controller dismissViewControllerAnimated:YES completion:Nil];
            };
            controller.completionHandler =myBlock;
            [controller addURL:[NSURL URLWithString:@"http://www.floreomedia.mobi/"]];
            [controller addImage:[self getShareText]];
             [self presentViewController:controller animated:YES completion:Nil];
        }
        else{
            UIAlertView *myalert = [[UIAlertView alloc] initWithTitle:@"Facebook Alert" message:@"Please sign in to Facebook in Settings" delegate:nil cancelButtonTitle:@"OK"otherButtonTitles:nil];
            [myalert show];
            NSLog(@"UnAvailable");
        }
    }
    else{
        
        UIAlertView *myalert = [[UIAlertView alloc] initWithTitle:@"Facebook Alert" message:@"Sorry this version of iOS is not sufficient" delegate:nil cancelButtonTitle:@"OK"otherButtonTitles:nil];
        [myalert show];
    }
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex == 0)
    {
        [self shareToSialNetworkWithId:SLServiceTypeFacebook];
    }
    else if(buttonIndex == 1)
    {
        [self shareToSialNetworkWithId:SLServiceTypeTwitter];
    }
    else if (buttonIndex == 2)
    {
        [self shareEmail];
    }
}

-(void)shareCard:(UIButton *)sender
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Share" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Facebook",@"Twitter",@"Email", nil];
    [actionSheet showInView:self.view];
}

-(UIColor *) backgroundColorForCardForIndex:(int) index
{
    UIColor *color;
    if (index == 0)
    {
        color = COLOR_1;
    }
    else if (index == 1)
    {
        color = COLOR_2;
    }
    else if (index == 2)
    {
        color = COLOR_3;
    }
    else if (index == 3)
    {
        color = COLOR_4;
    }
    else if (index == 4)
    {
        color = COLOR_5;
    }
    return color;
}

#pragma mark Gesture Methods

-(void)loadScrollViewWithPage:(int)index
{
    if (index >= 0 && index < [self.cardsArray count]) {
        
        Card *card = [self.cardsArray objectAtIndex:index];
        CardView *cardView = nil;
        if ([self.cardViewsArray objectAtIndex:index] == [NSNull null])
        {
            cardView = [[CardView alloc] initWithCard:card];
            int colorIndex = self.cardsArray.count - index;
            UIColor *cardBackgroundColor = [self backgroundColorForCardForIndex:(colorIndex % 5)];
            cardView.backgroundColor = cardBackgroundColor;
            if (isDeleteVisible) {
                [UIView animateWithDuration:0.3f animations:^{
                    UIView *cardView = [self.cardViewsArray objectAtIndex:selectedIndex];
                    [self.deleteButton setTitleEdgeInsets:UIEdgeInsetsMake(50, 0, 0, 0)];
                    self.deleteButton.frame =  CGRectMake(0, self.view.frame.size.height-48, self.view.frame.size.width, 00);
                    cardView.frame = CGRectMake(cardView.frame.origin.x, cardView.frame.origin.y+30, cardView.frame.size.width, cardView.frame.size.height);
                }];
                [self.view addGestureRecognizer:self.readTapGesture];
                [self.view removeGestureRecognizer:self.tapGestureRecognizer];
                isDeleteVisible = NO;
            }
            [self.cardViewsArray replaceObjectAtIndex:index withObject:cardView];
        }
        else
        {
            cardView = [self.cardViewsArray objectAtIndex:index];
        }
        [self.view addSubview:cardView];
        [cardView.shareButton addTarget:self action:@selector(shareCard:) forControlEvents:UIControlEventTouchUpInside];
        int xFrame = 0;
        if (index == selectedIndex+1) {
            xFrame = self.view.frame.size.width;
        }
        cardView.frame = CGRectMake(xFrame, 20, self.view.frame.size.width, self.view.frame.size.height-20);
    }
}

-(void)loadScrollViewContents
{
    [self loadScrollViewWithPage:0];
    [self loadScrollViewWithPage:1];
}

-(void) addNullObjectsToTextViewsArray
{
    self.cardViewsArray = [[NSMutableArray alloc] init];
    for (int i=0; i<[self.cardsArray count]; i++)
    {
        [self.cardViewsArray addObject:[NSNull null]];
    }
}

-(void) getAllCardsFromDatabase
{
    self.cardsArray = [[DataController sharedController] getAllCardsFromDatabase];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end








