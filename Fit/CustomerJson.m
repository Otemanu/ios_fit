//
//  CustomerJson.m
//  Fit
//
//  Created by Rich on 12/4/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//

#import "CustomerJson.h"

@implementation CustomerJson

// called when anonymous user is created or when real account is first created

- (CustomerJson *)initWithString:(NSString *)customerInfoString;
{
	NSData *customerInfoData = [customerInfoString dataUsingEncoding:NSUTF8StringEncoding];
	NSDictionary *customerInfoDict = [NSJSONSerialization JSONObjectWithData:customerInfoData options:0 error:NULL];
	return [self initWithDictionary:customerInfoDict];
}

// called by above method or when logging in with existing account data stored in sqlite

- (CustomerJson *)initWithDictionary:(NSDictionary *)customerInfoDictionary;
{
	NSString *jsonPayloadString = customerInfoDictionary[@"json"];
	
	if (jsonPayloadString)
	{
		NSData *jsonPayloadData = [jsonPayloadString dataUsingEncoding:NSUTF8StringEncoding];
		NSDictionary *jsonPayloadDict = [NSJSONSerialization JSONObjectWithData:jsonPayloadData options:0 error:NULL];
		
		if (jsonPayloadDict)
		{
			self.nameString = jsonPayloadDict[@"name"];
			self.typeString = jsonPayloadDict[@"type"];
			self.mobiIdInteger = [jsonPayloadDict[@"mobiId"] intValue];
			self.haveAvatarInteger = [jsonPayloadDict[@"haveAvatar"] intValue];
		}
	}
	else
	{
		self.nameString = customerInfoDictionary[@"name"];
		self.typeString = customerInfoDictionary[@"type"];
		self.mobiIdInteger = [customerInfoDictionary[@"mobiId"] intValue];
		self.haveAvatarInteger = 0;
	}
	
	return self;
}

@end
