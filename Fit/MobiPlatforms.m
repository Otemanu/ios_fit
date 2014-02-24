//
//  MobiPlatforms.m
//  Fit
//
//  Created by Rich on 12/4/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//

#import "MobiPlatforms.h"

NSArray *mobiPlatformsEnumsArray;

@implementation MobiPlatforms

- (MobiPlatforms *)init
{
	self.iOSPlatform = [[MobiEnum alloc] initWithString:@"IOS"];
	self.androidPlatform = [[MobiEnum alloc] initWithString:@"Android"];
	return self;
}

@end
