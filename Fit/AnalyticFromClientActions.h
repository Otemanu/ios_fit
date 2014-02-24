//
//  AnalyticFromClientActions.h
//  Fit
//
//  Created by Rich on 12/4/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//

#import "MobiEnum.h"

@interface AnalyticFromClientActions : MobiEnum

@property (nonatomic, strong) MobiEnum *startAction;
@property (nonatomic, strong) MobiEnum *pausedAction;
@property (nonatomic, strong) MobiEnum *tagSelectedAction;
@property (nonatomic, strong) MobiEnum *pageViewAction;
@property (nonatomic, strong) MobiEnum *restartAction;
@property (nonatomic, strong) MobiEnum *pagePositionAction;
@property (nonatomic, strong) MobiEnum *pagePositionHistoryAction;
@property (nonatomic, strong) MobiEnum *createAnonymousUserAction;
@property (nonatomic, strong) MobiEnum *helloAction;
@property (nonatomic, strong) MobiEnum *flashCardCreatedAction;
@property (nonatomic, strong) MobiEnum *flashCardHistoryAction;
@property (nonatomic, strong) MobiEnum *quizSelectAnswerAction;
@property (nonatomic, strong) MobiEnum *getQuizAnalyticsAction;
@property (nonatomic, strong) MobiEnum *quizAnalyticsDataAction;

@end
