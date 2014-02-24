//
//  CardViewController.h
//  Fit
//
//  Created by Rich on 10/31/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WebServicesEngine.h"
#import "CardView.h"
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>
#import <Twitter/Twitter.h>
#import "DataController.h"
#import "Card.h"
#import "settings.h"
#import<AudioToolbox/AudioToolbox.h>
#import "ReadViewController.h"
#import "DataController.h"

@interface CardViewController : UIViewController<UIScrollViewDelegate, UIActionSheetDelegate, UIGestureRecognizerDelegate,MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate>
{
    int selectedIndex, deleteIndex;
    BOOL isDeleteVisible, isDataAlreadyLoaded, newCardAdding, currentCardRemoving;
    BOOL panDraggingStarted;
    UIView *activeCard;
    WebServicesEngine *listViewWebServicesEngine;						// singleton engine instantiations
    ChapterDataController *listViewChapterDataController;
    QuizDataController *listViewQuizDataController;
}
@property (nonatomic, strong) CardView *cardView;
@property (nonatomic,weak) WebServicesEngine *cardViewWebServicesEngine;
@property (readwrite)	CFURLRef		soundFileURLRef;
@property (readonly)	SystemSoundID	soundFileObject;

@property (nonatomic, strong) NSMutableArray *cardsArray, *cardViewsArray ;
@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer, *readTapGesture;
@property (nonatomic, strong) UISwipeGestureRecognizer *swipeGestureRecognizer;
@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;
@property (nonatomic, strong) UIPageControl *pageControl;
@property (nonatomic, strong) UIButton *deleteButton;

@end
