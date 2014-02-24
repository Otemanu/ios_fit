//
//  MobiNetworkTypes.m
//  Fit
//
//  Created by Rich on 12/4/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//

#import "MobiNetworkTypes.h"

NSArray *mobiNetworkTypesEnumsArray;

@implementation MobiNetworkTypes

- (NSString *)mobiNetworkTypesEnumForString:(NSString *)requestString
{
	NSString *enumString = nil;
	
	if ([mobiNetworkTypesEnumsArray containsObject:requestString])
		enumString = requestString;
	
	return enumString;
}

- (void)initMobiNetworkTypesEnums
{
	mobiNetworkTypesEnumsArray = @[
								  @"None",
								  @"BlueTooth",
								  @"Ethernet",
								  @"Wifi",
								  ];
}

@end
