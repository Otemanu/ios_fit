//
//  AnalyticFromServerActions.m
//  Fit
//
//  Created by Rich on 12/4/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//

#import "AnalyticFromServerActions.h"

NSArray *analyticFromServerActionsEnumsArray;

@implementation AnalyticFromServerActions

- (NSString *)analyticsFromServerActionsEnumForString:(NSString *)requestString
{
	NSString *enumString = nil;
	
	if ([analyticFromServerActionsEnumsArray containsObject:requestString])
		enumString = requestString;
	
	return enumString;
}

- (void)initAnalyticFromServerActionsEnums
{
	analyticFromServerActionsEnumsArray = @[
										   @"Confirm",
										   @"Error"
										   @"PagePositions"
										   @"SessionCreated"
										   @"PagePositionUpdated"
										   @"AnonymousCustomerCreated"
										   @"HelloReturningSession"
										   @"HelloNewSession"
										   @"CustomerCreated"
										   @"MobifusionUserCreated"
										   @"FlashCardCreated"
										   @"QuizAnalyticsData"
										   ];
}

@end
