//
//  AppDelegate.h
//  Fit
//
//  Created by Rich on 10/31/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) NSMutableDictionary *facebookResults;
@property BOOL isFromReadViewController;
@property UIUserInterfaceIdiom deviceIdiom;

@end
