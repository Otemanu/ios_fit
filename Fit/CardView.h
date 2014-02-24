//
//  CardView.h
//  Fit
//
//  Created by Mobi on 19/11/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>
#import <Twitter/Twitter.h>
#import "DataController.h"
#import "Card.h"
#import "settings.h"

@interface CardView : UIView<UIScrollViewDelegate, UIActionSheetDelegate, UIGestureRecognizerDelegate>
{
    int selectedIndex, deleteIndex;
    BOOL isDeleteVisible, isDataAlreadyLoaded, newCardAdding, currentCardRemoving;
    UIView *activeCard;
    
    
}
@property (nonatomic, strong) UILabel *selectedTextLabel, *chapterLable, *sectionNameLabel;
@property (nonatomic, strong) UIButton *shareButton;
@property (nonatomic, strong) Card *card;


@property (nonatomic, strong) NSMutableArray *cardsArray, *cardViewsArray ;
@property (nonatomic, strong) UIScrollView *cardsScrollView;
@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer, *readTapGesture;
@property (nonatomic, strong) UISwipeGestureRecognizer *swipeGestureRecognizer;
@property (nonatomic, strong) UIPageControl *pageControl;
@property (nonatomic, strong) UIButton *deleteButton;

-(id)initWithCard:(Card *)card;
@end
