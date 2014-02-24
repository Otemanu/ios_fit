//
//  MobiAnalyticsOutgoing.m
//  Fit
//
//  Created by Rich on 11/12/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//

#import "MobiAnalyticsOutgoing.h"

@implementation MobiAnalyticsOutgoing

// web socket actions (deprecated)
static NSString *kCreateAnonymousUserActionString = @"CreateAnonymousUser";
static NSString *kSessionInfoRequestActionString = @"Hello";
static NSString *kStartNewSessionActionString = @"Start";
static NSString *kRequestPageHistoryActionString = @"PagePositionHistory";
static NSString *kNoActionString = @"NoAction";

// key strings for the mobi analytics outgoing "wrapper" json
static NSString *kTimestampKey = @"timestamp";
static NSString *kThothIDKey = @"thothId";
static NSString *kJsonKey = @"json";
static NSString *kActionKey = @"action";
static NSString *kCustomerIDKey = @"customerId";
static NSString *kSessionIDKey = @"sessionId";
static NSString *kNameKey = @"name";
static NSString *kPasswordKey = @"password";
static NSString *kConfirmPasswordKey = @"confirmPassword";
static NSString *kEmailKey = @"email";
static NSString *kAgeCheckKey = @"ageCheck";

// key strings for the mobi analytics outgoing "payload" json
static NSString *kMinervaVersionKey = @"minervaVersion";
static NSString *kThothDbCreatedKey = @"thothDbCreated";
static NSString *kDeviceManufacturerKey = @"manufacturer";
static NSString *kPlatformKey = @"platform";
static NSString *kNetworkTypeKey = @"networkType";
static NSString *kDeviceVersionKey = @"deviceVersion";
static NSString *kDeviceModelKey = @"model";
static NSString *kLongitudeKey = @"longitude";
static NSString *kLatitudeKey = @"latitude";

// key strings for page position update message
static NSString *kPageCompletionMaxPercentageKey = @"maxPercentage";
static NSString *kPageCompletionCurrentPercentageKey = @"currentPercentage";
static NSString *kPageCompletionDateReadTimestampKey = @"dateReadTimeStamp";
static NSString *kPageCompletionLastUpdateTimestampKey = @"lastUpdateTimeStamp";

// key strings for several types of messages
static NSString *kPayloadStringKey = @"payLoadString";
static NSString *kPayLoadIntegerKey = @"payLoadInteger";

NSMutableDictionary *jsonDictionary = nil;
NSMutableDictionary *jsonPayloadDictionary = nil;

#pragma mark - Initialization

- (MobiAnalyticsOutgoing *)initWithActionString:(NSString *)actionString
{
	[self initAnalyticFromClientActions];
	[self clearJsonValues];
	[self setOutgoingActionString:actionString];
	[self setTimestamp];
	[self populateJsonDictForAction];
	return self;
}

- (MobiAnalyticsOutgoing *)initWithNewMobiAccountDictionary:(NSDictionary *)newAccountDict
{
	[self initAnalyticFromClientActions];
	[self clearJsonValues];
	[self setOutgoingActionString:nil];								// nil action string for new mobi account registration and loggin in with existing account
	[self setTimestamp];
	[self populateJsonDictFromNewMobiAccountDict:newAccountDict];
	return self;
}

- (void)populateJsonDictForAction
{
	if (self.mobiAnalyticsOutgoingAction == nil)					// will be nil when user logs in with existing customer account
		[self populateJsonDictForExistingAccountAction];
	else if ([self.mobiAnalyticsOutgoingAction isEqualToString:self.analyticFromClientActions.createAnonymousUserAction.nameString])
		[self populateJsonDictForAnonymousUserAction];
	else if ([self.mobiAnalyticsOutgoingAction isEqualToString:self.analyticFromClientActions.helloAction.nameString])
		[self populateJsonDictForHelloAkaRequestSessionAction];
	else if ([self.mobiAnalyticsOutgoingAction isEqualToString:self.analyticFromClientActions.startAction.nameString])
		[self populateJsonDictForStartAkaNewSessionAction];
	else if ([self.mobiAnalyticsOutgoingAction isEqualToString:self.analyticFromClientActions.pagePositionAction.nameString])
		[self populateJsonDictForPagePositionAction];
	else if ([self.mobiAnalyticsOutgoingAction isEqualToString:self.analyticFromClientActions.pagePositionHistoryAction.nameString])
		[self populateJsonDictForPagePositionHistoryAction];
	else if ([self.mobiAnalyticsOutgoingAction isEqualToString:self.analyticFromClientActions.flashCardHistoryAction.nameString])
		[self populateJsonDictForFlashCardHistoryAction];
	else if ([self.mobiAnalyticsOutgoingAction isEqualToString:self.analyticFromClientActions.flashCardCreatedAction.nameString])
		[self populateJsonDictForFlashCardCreatedAction];
	else if ([self.mobiAnalyticsOutgoingAction isEqualToString:self.analyticFromClientActions.quizSelectAnswerAction.nameString])
		[self populateJsonDictForSelectAnswerAction];
	else if ([self.mobiAnalyticsOutgoingAction isEqualToString:self.analyticFromClientActions.getQuizAnalyticsAction.nameString])
		[self populateJsonDictForGetQuizAnalyticsAction];
}

- (void)populateJsonDictFromNewMobiAccountDict:(NSDictionary *)newAccountDict
{
	self.mobiAnalyticsOutgoingName = [newAccountDict valueForKey:kNameKey];
	self.mobiAnalyticsOutgoingPassword = [newAccountDict valueForKey:kPasswordKey];
	self.mobiAnalyticsOutgoingEmail = [newAccountDict valueForKey:kEmailKey];
	self.mobiAnalyticsOutgoingAgeCheck = [newAccountDict valueForKey:kAgeCheckKey];
}

- (void)resetJsonDictionary
{
	if (jsonDictionary)
		[jsonDictionary removeAllObjects];
	else
		jsonDictionary = [[NSMutableDictionary alloc] initWithCapacity:0];
}

- (void)initSessionID
{
	if (self.mobiAnalyticsOutgoingSessionID == nil)
	{
		CFUUIDRef uuid = CFUUIDCreate(NULL);
		self.mobiAnalyticsOutgoingSessionID = (NSString *) CFBridgingRelease(CFUUIDCreateString(NULL, uuid));
	}
}

- (void)setOutgoingActionString:(NSString *)actionString
{
	self.mobiAnalyticsOutgoingAction = actionString;	// note: action string will be nil when user is logging in with existing customer id
}

- (void)setTimestamp
{
	self.mobiAnalyticsOutgoingTimeStamp = [NSNumber numberWithLongLong:(long long)(1000.0f * [[NSDate date] timeIntervalSince1970])];
}

- (void)initAnalyticFromClientActions
{
	if (self.analyticFromClientActions == nil)
		self.analyticFromClientActions = [[AnalyticFromClientActions alloc] init];
}

// don't clear the session id: it should persist throughout app invocation, and must be unique (hence it is a uuid)

- (void)clearJsonValues
{
	self.mobiAnalyticsOutgoingAction = nil;
	self.mobiAnalyticsOutgoingAgeCheck = nil;
	self.mobiAnalyticsOutgoingCustomerID = nil;
	self.mobiAnalyticsOutgoingDeviceManufacturer = nil;
	self.mobiAnalyticsOutgoingDeviceModel = nil;
	self.mobiAnalyticsOutgoingDeviceVersion = nil;
	self.mobiAnalyticsOutgoingJSON = nil;
	self.mobiAnalyticsOutgoingLatitude = nil;
	self.mobiAnalyticsOutgoingLongitude = nil;
	self.mobiAnalyticsOutgoingMinervaVersion = nil;
	self.mobiAnalyticsOutgoingNetworkType = nil;
	self.mobiAnalyticsOutgoingPlatform = nil;
	self.mobiAnalyticsOutgoingThothDBCreated = nil;
	self.mobiAnalyticsOutgoingThothID = nil;
	self.mobiAnalyticsOutgoingTimeStamp = nil;
	self.mobiAnalyticsOutgoingPageCompletionPageInstanceID = nil;
	self.mobiAnalyticsOutgoingPageCompletionCurrentPercentage = nil;
	self.mobiAnalyticsOutgoingPageCompletionCurrentPercentage = nil;
	self.mobiAnalyticsOutgoingPageCompletionLastUpdateTimestamp = nil;

}

#pragma mark - Populating JSON dictionary

- (void)populateJsonDictForExistingAccountAction
{
	self.mobiAnalyticsOutgoingAgeCheck = @"1";
}

- (void)populateJsonDictForAnonymousUserAction
{
	// no-op.  anonymous user object only needs action and timestamp, both of which are already set in every outgoing object.
}

- (void)populateJsonDictForHelloAkaRequestSessionAction
{
	[self initSessionID];		// the web services engine populates all the values we need except session id.
}

- (void)populateJsonDictForStartAkaNewSessionAction
{
	// no-op.  all necessary values are known at a higher level (in the web services engine).
}

- (void)populateJsonDictForPagePositionAction
{
	
}

- (void)populateJsonDictForPagePositionHistoryAction
{
	// no-op.  all necessary values are known at a higher level (in the web services engine).
}

- (void)populateJsonDictForFlashCardHistoryAction
{
	// no-op.
}

- (void)populateJsonDictForFlashCardCreatedAction
{
	[self initSessionID];
}

- (void)populateJsonDictForSelectAnswerAction
{
	// no-op.
}

- (void)populateJsonDictForGetQuizAnalyticsAction
{
	// no-op.
}

#pragma mark - Generating JSON

// try adding everything, even though only a few will actually be set in any outgoing message

- (void)buildMobiAnalyticsOutgoingJsonWrapper
{
	[self resetJsonDictionary];
	[jsonDictionary setValue:self.mobiAnalyticsOutgoingTimeStamp forKey:kTimestampKey];
	[jsonDictionary setValue:self.mobiAnalyticsOutgoingThothID forKey:kThothIDKey];
	[jsonDictionary setValue:self.mobiAnalyticsOutgoingAction forKey:kActionKey];
	[jsonDictionary setValue:self.mobiAnalyticsOutgoingCustomerID forKey:kCustomerIDKey];
	[jsonDictionary setValue:self.mobiAnalyticsOutgoingSessionID forKey:kSessionIDKey];

	[jsonDictionary setValue:self.mobiAnalyticsOutgoingName forKey:kNameKey];
	[jsonDictionary setValue:self.mobiAnalyticsOutgoingEmail forKey:kEmailKey];
	[jsonDictionary setValue:self.mobiAnalyticsOutgoingPassword forKey:kPasswordKey];
	[jsonDictionary setValue:self.mobiAnalyticsOutgoingPassword forKey:kConfirmPasswordKey];

	if (self.mobiAnalyticsOutgoingAgeCheck != nil)								// must be either nil or @"0" or @"1", for "not needed, no and yes repectively
	{
		if ([self.mobiAnalyticsOutgoingAgeCheck isEqualToString:@"0"])
			[jsonDictionary setValue:[NSNumber numberWithBool:NO] forKey:kAgeCheckKey];
		else if ([self.mobiAnalyticsOutgoingAgeCheck isEqualToString:@"1"])
			[jsonDictionary setValue:[NSNumber numberWithBool:YES] forKey:kAgeCheckKey];
	}
}

- (void)buildMobiAnalyticsOutgoingPayloadJsonString
{
	if (jsonPayloadDictionary)
		[jsonPayloadDictionary removeAllObjects];
	else
		jsonPayloadDictionary = [[NSMutableDictionary alloc] initWithCapacity:0];

	[jsonPayloadDictionary setValue:self.mobiAnalyticsOutgoingMinervaVersion forKey:kMinervaVersionKey];
	[jsonPayloadDictionary setValue:self.mobiAnalyticsOutgoingThothDBCreated forKey:kThothDbCreatedKey];
	[jsonPayloadDictionary setValue:self.mobiAnalyticsOutgoingDeviceManufacturer forKey:kDeviceManufacturerKey];
	[jsonPayloadDictionary setValue:self.mobiAnalyticsOutgoingPlatform forKey:kPlatformKey];
	[jsonPayloadDictionary setValue:self.mobiAnalyticsOutgoingNetworkType forKey:kNetworkTypeKey];
	[jsonPayloadDictionary setValue:self.mobiAnalyticsOutgoingDeviceVersion forKey:kDeviceVersionKey];
	[jsonPayloadDictionary setValue:self.mobiAnalyticsOutgoingDeviceModel forKey:kDeviceModelKey];

	if (self.mobiAnalyticsOutgoingPageCompletionCurrentPercentage)
	{
		[jsonPayloadDictionary setValue:self.mobiAnalyticsOutgoingPageCompletionCurrentPercentage forKey:kPageCompletionCurrentPercentageKey];
		[jsonPayloadDictionary setValue:self.mobiAnalyticsOutgoingPageCompletionCurrentPercentage forKey:kPageCompletionMaxPercentageKey];
		[jsonPayloadDictionary setValue:self.mobiAnalyticsOutgoingPageCompletionLastUpdateTimestamp forKey:kPageCompletionLastUpdateTimestampKey];
		[jsonPayloadDictionary setValue:self.mobiAnalyticsOutgoingPageCompletionPageInstanceID forKey:kPayLoadIntegerKey];
		[jsonPayloadDictionary setValue:self.mobiAnalyticsOutgoingPageCompletionPageID forKey:kPayloadStringKey];
		
		if (self.mobiAnalyticsOutgoingPageCompletionDateReadTimestamp)
			[jsonPayloadDictionary setValue:self.mobiAnalyticsOutgoingPageCompletionDateReadTimestamp forKey:kPageCompletionDateReadTimestampKey];
	}
	else if (self.mobiAnalyticsOutgoingCardCreatedText)
	{
		[jsonPayloadDictionary setValue:self.mobiAnalyticsOutgoingCardCreatedText forKey:kPayloadStringKey];
		[jsonPayloadDictionary setValue:self.mobiAnalyticsOutgoingCardCreatedPageInstanceID forKey:kPayLoadIntegerKey];
	}
	else if ([self.mobiAnalyticsOutgoingAction isEqualToString:self.analyticFromClientActions.quizSelectAnswerAction.nameString])
	{
		[jsonPayloadDictionary setValue:self.mobiAnalyticsOutgoingQuizID forKey:kPayLoadIntegerKey];
		[jsonPayloadDictionary setValue:self.mobiAnalyticsOutgoingQuizAnswerJsonString forKey:kPayloadStringKey];
		
	}
	else if ([self.mobiAnalyticsOutgoingAction isEqualToString:self.analyticFromClientActions.pagePositionHistoryAction.nameString])
	{
		// no-op
	}
	else if ([self.mobiAnalyticsOutgoingAction isEqualToString:self.analyticFromClientActions.getQuizAnalyticsAction.nameString])
	{
		// note: we fetch each quiz' data individually as user taps to it.  this minimizes the load on the server and minimizes web traffic to/from device.
		[jsonPayloadDictionary setValue:self.mobiAnalyticsOutgoingQuizID forKey:kPayLoadIntegerKey];
	}
	else
	{
		[jsonPayloadDictionary setValue:self.mobiAnalyticsOutgoingThothID forKey:kThothIDKey];
	}

	// note: apple will reject the app if location services isn't used for a real feature
//	[jsonPayloadDictionary setValue:self.mobiAnalyticsOutgoingLongitude forKey:kLongitudeKey];
//	[jsonPayloadDictionary setValue:self.mobiAnalyticsOutgoingLatitude forKey:kLatitudeKey];
	
	NSString *jsonPayloadString = [self jsonStringFromDictionary:jsonPayloadDictionary];
	
	if (jsonPayloadString)
		[jsonDictionary setValue:jsonPayloadString forKey:kJsonKey];
}

- (void)buildJsonString
{
	self.jsonString = [self jsonStringFromDictionary:jsonDictionary];
}

- (NSString *)jsonStringFromDictionary:(NSDictionary *)jsonDictionary
{
	NSString *jString = nil;
	NSError *error;
    NSData *result = [NSJSONSerialization dataWithJSONObject:jsonDictionary options:NSJSONReadingAllowFragments|NSJSONWritingPrettyPrinted error:&error];
	
    if (result)
		jString = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
	else
        NSLog(@"%@", error.description);
	
	return jString;
}

#pragma mark - Sending

- (void)sendOnSocket:(SRWebSocket *)socket
{
//	NSLog(@"sendOnSocket: sending '%@'", self.jsonString);
	[socket send:self.jsonString];
}

@end
