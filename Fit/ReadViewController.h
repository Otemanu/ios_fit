//
//  ReadViewController.h
//  Fit
//
//  Created by Mobi on 21/11/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ReadWebView.h"
#import "UIWebView+HightlightText.h"
#import "SBJSON.h"
#import "QuizDataController.h"
#import "AppDelegate.h"

@interface ReadViewController : UIViewController<UIWebViewDelegate,UIScrollViewDelegate,UIGestureRecognizerDelegate>{
    
    PageInstance *pageInstance, *tempPageInstance;
    BOOL isselected,scrollViewDragging,orientationPotrait,isRotating;
    BOOL isTopBarClosed;
    int pageIndex;
    IBOutlet UIScrollView *aScrollView;
	CGPoint touchEndPoint;
    UIMenuController *sharedController;
    NSString *cardText;
	SBJSON *json;
	NSMutableArray *quizMenuDataArray;
    IBOutlet UINavigationItem *readNavigationItem;
    UITapGestureRecognizer *singleTap;
}

@property (nonatomic,strong) NSTimer *timer;
@property (nonatomic,assign) UIGestureRecognizerState gestureState;
@property IBOutlet UIBarButtonItem *quizButton;
@property(nonatomic,strong) NSMutableArray *contentArray,*webViewsArray;
@property int selectedSection,selectedPage,selectedCat;
@property(nonatomic,strong) IBOutlet UIScrollView *aScrollView;
@property(nonatomic,strong) UIWebView *detailedWebView;
@property (nonatomic, strong) NSMutableArray *chaptersArray;
@property (nonatomic, strong) NSString *sectionName;
@property (nonatomic, strong) NSString *quizName;
@property (nonatomic, strong) UIView *instructionView;
@property (nonatomic, strong) WebServicesEngine *readViewWebServicesEngine;
@property (nonatomic, strong) ChapterDataController *readViewChapterDataController;
@property (nonatomic, strong) QuizDataController *readViewQuizDataController;
@property int oldCurProgressPercentageInt;
@property int oldMaxProgressPercentageInt;
@property BOOL parentViewIsTimeline;
@property BOOL parentViewIsDashboard;

- (void)handleCall:(NSString*)functionName callbackId:(int)callbackId args:(NSArray*)args;
- (void)returnResult:(int)callbackId args:(id)firstObj, ...;
- (IBAction) handleQuizButtonTap:(id)sender;

@end
