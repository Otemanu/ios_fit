//
//  AnalyticFromClientActions.m
//  Fit
//
//  Created by Rich on 12/4/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//

#import "AnalyticFromClientActions.h"

NSArray *analyticFromClientActionsEnumsArray;

@implementation AnalyticFromClientActions

- (AnalyticFromClientActions *)init
{
	self.startAction = [[MobiEnum alloc] initWithString:@"Start"];
	self.pausedAction = [[MobiEnum alloc] initWithString:@"Paused"];
	self.tagSelectedAction = [[MobiEnum alloc] initWithString:@"TagSelected"];
	self.pageViewAction = [[MobiEnum alloc] initWithString:@"PageView"];
	self.restartAction = [[MobiEnum alloc] initWithString:@"Restart"];
	self.pagePositionAction = [[MobiEnum alloc] initWithString:@"PagePosition"];
	self.pagePositionHistoryAction = [[MobiEnum alloc] initWithString:@"PagePositionHistory"];
	self.createAnonymousUserAction = [[MobiEnum alloc] initWithString:@"CreateAnonymousUser"];
	self.helloAction = [[MobiEnum alloc] initWithString:@"Hello"];
	self.flashCardCreatedAction = [[MobiEnum alloc] initWithString:@"FlashCardCreated"];
	self.flashCardHistoryAction = [[MobiEnum alloc] initWithString:@"FlashCardHistory"];
	self.flashCardHistoryAction = [[MobiEnum alloc] initWithString:@"FlashCardHistory"];
	self.quizSelectAnswerAction = [[MobiEnum alloc] initWithString:@"QuizSelectAnswerEvent"];
	self.getQuizAnalyticsAction = [[MobiEnum alloc] initWithString:@"GetQuizAnalytics"];
	self.getQuizAnalyticsAction = [[MobiEnum alloc] initWithString:@"GetQuizAnalytics"];
	return self;
}

@end
