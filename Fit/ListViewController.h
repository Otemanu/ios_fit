//
//  ListViewController.h
//  Fit
//
//  Created by Rich on 11/3/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//Test Change

#import <UIKit/UIKit.h>
#import "Scalars.h"
#import "Pages.h"
#import "PageSections.h"
#import "RoundedRectView.h"
#import "ListTableViewCell.h"
#import "UIImage+ImageEffects.h"
#import "ChapterDataController.h"
#import "QuizDataController.h"
#import "ListViewHeaderDisclosureIndicator.h"

@interface ListViewController : UIViewController <UITableViewDataSource,UITableViewDelegate,UITabBarControllerDelegate,UIScrollViewDelegate>{
    
    int selectedCategory,selectedSection,isRecordBookAvailable;
    NSMutableDictionary *categoriesList;
    NSMutableArray *countsArray,*sections,*pagesList;
    CGPoint touchEndPoint;
    
}

@property IBOutlet UIView *chapterHeaderView;

@property IBOutlet UITableView *chapterTableView;

@property (nonatomic, strong) UIButton *chapterDisclosureButton;

@property (nonatomic, strong) ListViewHeaderDisclosureIndicator *chapterDisclosureIndicator;

@end
