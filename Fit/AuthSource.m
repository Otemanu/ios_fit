//
//  AuthSource.m
//  Fit
//
//  Created by Rich on 12/4/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//

#import "AuthSource.h"

NSArray *authSourceEnumsArray;

@implementation AuthSource

- (NSString *)authSourceEnumForString:(NSString *)requestString
{
	NSString *enumString = nil;
	
	if ([authSourceEnumsArray containsObject:requestString])
		enumString = requestString;
	
	return enumString;
}

- (void)initAuthSourceEnums
{
	authSourceEnumsArray = @[
							@"Facebook",
							@"Twitter",
							@"MobiFusion",
							@"Anonymous",
							];
}

@end
