 //
//  WebServicesEngine.m
//  Fit
//
//  Created by Rich on 11/9/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//

// todo: register for real web socket notifications from server, issue notifications to the client views when data is ready for them

#import "WebServicesEngine.h"
#import "Card.h"

@implementation WebServicesEngine

WebServicesEngine *webServicesEngine = nil;
MobiAnalyticsIncoming *mobiAnalyticsIncoming = nil;

// static NSString *kWebServerRoot = @"10.1.0.236:8080";		// for testing only, on mike's test server
static NSString *kWebServerRoot = @"54.205.253.32:8080";		// the real server
static NSString *kWebApp = @"/mobi-analytics/";
static NSString *normalizedTokenKey = @"token";					// actually either "TOKEN=" or "TOKEN-" but we only scan for the lower case word, not the "=" or "-"

typedef enum {
    kSocketStatusNotInitialized			= (-1),
    kSocketStatusConnecting				= 0,
    kSocketStatusConnected				= 1,
    kSocketStatusLoginExistingUser		= 2,
    kSocketStatusFacebookLogin			= 3,
    kSocketStatusTwitterLogin			= 4,
    kSocketStatusAnonymousLogin			= 5,
    kSocketStatusRealAccountLogin		= 6,
	kSocketStatusRequestingSessionInfo	= 7,
	kSocketStatusEstablishingSession	= 8,
	kSocketStatusSessionEstablished		= 9,
	kSocketStatusRequestingPageHistory	= 10,
	kSocketStatusFacebookLoginDone		= 11,
	kSocketStatusTwitterLoginDone		= 12,
	kSocketStatusPagePositionUpdate		= 13,
	kSocketStatusFlashCardHistory		= 14,
	kSocketStatusFlashCardCreated		= 15,
	kSocketStatusRequestingQuizHistory	= 16,
} WebSocketStates;

NSNumber *thothID = nil;

NSDictionary *publicationInfo;						// user name, thoth id, etc. for current publication

NSString *webServerHTTPURL;							// for creating a web socket and connection
NSString *webServerRegisterURL;						// for registering a new user
NSString *webServerLoginURL;						// for logging in an existing facebook, twitter, or mobi user
NSString *webServerFacebookURL;						// for facebook login
NSString *webServerTwitterURL;						// for twitter login
NSString *facebookToken;							// returned by server so it can track our specific facebook web socket
NSString *twitterToken;								// returned by server so it can track our specific twitter web socket
NSString *mobiAnalyticsOutgoingSessionID;			// maintain this for duration of app run

SRWebSocket *webSocketForAnalytics;					// for general web services requests
SRWebSocket *webSocketForRegisteringMobiUser;		// only for registering a new mobi user
SRWebSocket *webSocketForLogin;						// only for logging in an existing mobi user
SRWebSocket *webSocketForFacebook;					// only for logging in an existing facebook user
SRWebSocket *webSocketForTwitter;					// only for logging in an existing twitter user

int socketStatusForAnalytics;						// each socket requires a different status
int socketStatusForRegistration;
int socketStatusForLogin;
int socketStatusForFacebook;
int socketStatusForTwitter;

MobiAnalyticsOutgoing *anonymousUserOutgoingEvent = nil;
MobiAnalyticsOutgoing *registerNewAccountOutgoingEvent = nil;
MobiAnalyticsOutgoing *existingAccountOutgoingEvent = nil;
MobiAnalyticsOutgoing *facebookAccountOutgoingEvent = nil;
MobiAnalyticsOutgoing *twitterAccountOutgoingEvent = nil;
MobiAnalyticsOutgoing *sessionRequestOutgoingEvent = nil;
MobiAnalyticsOutgoing *sessionStartOutgoingEvent = nil;
MobiAnalyticsOutgoing *pagePositionOutgoingEvent = nil;
MobiAnalyticsOutgoing *pagePositionHistoryOutgoingEvent = nil;
MobiAnalyticsOutgoing *flashCardHistoryOutgoingEvent = nil;
MobiAnalyticsOutgoing *flashCardCreatedOutgoingEvent = nil;
MobiAnalyticsOutgoing *quizAnswerOutgoingEvent = nil;
MobiAnalyticsOutgoing *quizAnalyticsDataOutgoingEvent = nil;

CustomerDataEngine *webServicesEngineCustomerDataEngine;
CustomerJson *customerInfoJson;

BOOL waitingToLoginExistingAccount = NO;

#pragma mark - Server requests

- (void)attemptServerReconnect
{
	
}

- (void)requestLoginWithRealAccount:(NSDictionary*)accountDict
{
	if (socketStatusForLogin >= kSocketStatusConnected)
	{
		socketStatusForRegistration = kSocketStatusRealAccountLogin;
		registerNewAccountOutgoingEvent = [[MobiAnalyticsOutgoing alloc] initWithNewMobiAccountDictionary:accountDict];
		[registerNewAccountOutgoingEvent buildMobiAnalyticsOutgoingJsonWrapper];
		[registerNewAccountOutgoingEvent buildJsonString];
		[registerNewAccountOutgoingEvent sendOnSocket:webSocketForRegisteringMobiUser];
	}
}

- (void)requestLoginWithAnonymousAccount
{
	if (socketStatusForAnalytics >= kSocketStatusConnected)
	{
		socketStatusForAnalytics = kSocketStatusAnonymousLogin;
		NSString *createAnonymousUserAction = self.analyticFromClientActions.createAnonymousUserAction.nameString;
		anonymousUserOutgoingEvent = [[MobiAnalyticsOutgoing alloc] initWithActionString:createAnonymousUserAction];
		[anonymousUserOutgoingEvent buildMobiAnalyticsOutgoingJsonWrapper];
		[anonymousUserOutgoingEvent buildJsonString];
		[anonymousUserOutgoingEvent sendOnSocket:webSocketForAnalytics];
	}
}

- (void)performLoginWithExistingAccount:(NSDictionary *)accountDict
{
	if (socketStatusForLogin >= kSocketStatusConnected)
	{
		socketStatusForLogin = kSocketStatusLoginExistingUser;
		existingAccountOutgoingEvent = [[MobiAnalyticsOutgoing alloc] initWithActionString:nil];
		[existingAccountOutgoingEvent buildMobiAnalyticsOutgoingJsonWrapper];
		[existingAccountOutgoingEvent buildJsonString];
		[existingAccountOutgoingEvent sendOnSocket:webSocketForLogin];
	}
}

- (void)performFacebookLoginWithExistingAccount:(NSDictionary *)accountDict
{
	if (socketStatusForFacebook >= kSocketStatusConnected)
	{
		socketStatusForFacebook = kSocketStatusFacebookLogin;
		facebookAccountOutgoingEvent = [[MobiAnalyticsOutgoing alloc] initWithActionString:nil];
		[facebookAccountOutgoingEvent buildMobiAnalyticsOutgoingJsonWrapper];
		[facebookAccountOutgoingEvent buildJsonString];
		[existingAccountOutgoingEvent sendOnSocket:webSocketForFacebook];
	}
}

- (void)performTwitterLoginWithExistingAccount:(NSDictionary *)accountDict
{
	if (socketStatusForTwitter >= kSocketStatusConnected)
	{
		socketStatusForTwitter = kSocketStatusTwitterLogin;
		twitterAccountOutgoingEvent = [[MobiAnalyticsOutgoing alloc] initWithActionString:nil];
		[twitterAccountOutgoingEvent buildMobiAnalyticsOutgoingJsonWrapper];
		[twitterAccountOutgoingEvent buildJsonString];
		[existingAccountOutgoingEvent sendOnSocket:webSocketForTwitter];
	}
}

- (void)sendHelloMessage
{
	if (socketStatusForAnalytics >= kSocketStatusConnected)
	{
		socketStatusForAnalytics = kSocketStatusRequestingSessionInfo;
		NSString *helloActionString = self.analyticFromClientActions.helloAction.nameString;
		sessionRequestOutgoingEvent = [[MobiAnalyticsOutgoing alloc] initWithActionString:helloActionString];
		mobiAnalyticsOutgoingSessionID = [sessionRequestOutgoingEvent.mobiAnalyticsOutgoingSessionID copy];
		sessionRequestOutgoingEvent.mobiAnalyticsOutgoingThothID = [self thothIdFromPublicationInfo];
		sessionRequestOutgoingEvent.mobiAnalyticsOutgoingCustomerID = [NSNumber numberWithInt:customerInfoJson.mobiIdInteger];
		[sessionRequestOutgoingEvent buildMobiAnalyticsOutgoingJsonWrapper];
		[sessionRequestOutgoingEvent buildJsonString];
		[sessionRequestOutgoingEvent sendOnSocket:webSocketForAnalytics];
	}
}

// note: if we've gotten this far in the server dance, we no longer need the facebook or twitter sockets.
// everything from now on happens on the analytics socket.

- (void)sendStartMessage
{
	socketStatusForAnalytics = kSocketStatusSessionEstablished;
	NSString *startActionString = self.analyticFromClientActions.startAction.nameString;
	sessionStartOutgoingEvent = [[MobiAnalyticsOutgoing alloc] initWithActionString:startActionString];
	[self setValuesForSessionStartOutgoingEvent];
	[sessionStartOutgoingEvent buildMobiAnalyticsOutgoingJsonWrapper];
	[sessionStartOutgoingEvent buildMobiAnalyticsOutgoingPayloadJsonString];
	[sessionStartOutgoingEvent buildJsonString];
	[sessionStartOutgoingEvent sendOnSocket:webSocketForAnalytics];
}

- (void)sendPagePositionHistoryMessage
{
	if (socketStatusForAnalytics >= kSocketStatusConnected)
	{
		socketStatusForAnalytics = kSocketStatusRequestingPageHistory;
		NSString *pageRequestActionString = self.analyticFromClientActions.pagePositionHistoryAction.nameString;
		pagePositionHistoryOutgoingEvent = [[MobiAnalyticsOutgoing alloc] initWithActionString:pageRequestActionString];
		[self setValuesForPageHistoryRequestOutgoingEvent];
		[pagePositionHistoryOutgoingEvent buildMobiAnalyticsOutgoingJsonWrapper];
		[pagePositionHistoryOutgoingEvent buildMobiAnalyticsOutgoingPayloadJsonString];
		[pagePositionHistoryOutgoingEvent buildJsonString];
		[pagePositionHistoryOutgoingEvent sendOnSocket:webSocketForAnalytics];
	}
}

- (void)handlePagePositions:(id)message
{
	if ([message respondsToSelector:@selector(hasPrefix:)])											// check that the message object is a string
	{
		NSData *jsonData = [message dataUsingEncoding:NSUTF8StringEncoding];
		id jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:NULL];
		
		if ([jsonObject isKindOfClass:[NSDictionary class]])
		{
			NSString *percentagesString = jsonObject[@"json"];
			NSData *percentagesData = [percentagesString dataUsingEncoding:NSUTF8StringEncoding];
			NSArray *percentagesArray = [NSJSONSerialization JSONObjectWithData:percentagesData options:NSJSONReadingAllowFragments error:NULL];
			[self updateProgressIfNecessaryForServerPagePercentagesArray:percentagesArray];
		}
	}
}

- (void)updateProgressIfNecessaryForServerPagePercentagesArray:(NSArray *)serverPagePercentagesArray
{
	for (NSDictionary *serverPagePercentageDict in serverPagePercentagesArray)						// iterate through all percentages dicts sent by the server
	{
		NSNumber *pageInstanceIdNum = serverPagePercentageDict[@"pageInstanceId"];
		
		if (pageInstanceIdNum)
		{
			NSInteger pageInstanceIdInt = [pageInstanceIdNum integerValue];
			NSArray *sqlPercentagesArray = [[DataController sharedController] getChapterReadPercentageForPageInstanceId:pageInstanceIdInt];
			NSDictionary *sqlPercentageDict = sqlPercentagesArray[0];
			
			NSNumber *sqlLastUpdateNum = sqlPercentageDict[@"lastUpdate"];
			NSNumber *serverLastUpdateNum = serverPagePercentageDict[@"lastUpdateTimeStamp"];

			long long sqlLastUpdateLongLong = [sqlLastUpdateNum longLongValue];
			long long serverLastUpdateLongLong = [serverLastUpdateNum longLongValue];
			
			if (sqlLastUpdateLongLong == serverLastUpdateLongLong)									// do nothing if sqlite and web services timestamps are the same
				continue;
			
			NSNumber *sqlCurPercentageNum = sqlPercentageDict[@"currentPercentage"];
			NSNumber *sqlMaxPercentageNum = sqlPercentageDict[@"maxPercentage"];

			NSNumber *serverCurPercentageNum = serverPagePercentageDict[@"currentPercentage"];
			NSNumber *serverMaxPercentageNum = serverPagePercentageDict[@"maxPercentage"];
			
			if ([sqlCurPercentageNum intValue] == [serverCurPercentageNum intValue] && [sqlMaxPercentageNum intValue] == [serverMaxPercentageNum intValue])
				continue;																			// do nothing if the sqlite and web services current and max percentages are the same
			
			if (serverLastUpdateLongLong > sqlLastUpdateLongLong)									// update sqlite with web services percentages if web services timestamp is newer
			{
				NSDictionary *sqlDict = [NSDictionary dictionaryWithObjectsAndKeys:
										 serverMaxPercentageNum, @"maxPercentage",
										 serverCurPercentageNum, @"currentPercentage",
										 nil];
				[[DataController sharedController] saveChapterReadPercentage:sqlDict forPageInstanceId:pageInstanceIdInt];
			}
			else if (serverLastUpdateLongLong < sqlLastUpdateLongLong)								// update web services with sqlite percentages if sqlite timestamp is newer
			{
				PageInstance *pageInstance = [[ChapterDataController sharedChapterDataController] pageInstanceForPageInstanceId:pageInstanceIdInt];
				NSDictionary *serverDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
											sqlCurPercentageNum, @"currentPercentage",
											sqlMaxPercentageNum, @"maxPercentage",
											pageInstanceIdNum, @"payLoadInteger",
											[[NSNumber numberWithInteger:pageInstance.PagesId] stringValue], @"payLoadString",
											nil];
				[self sendCurrentChapterProgressToServer:serverDict];
			}
		}
	}
}

- (void)setValuesInMobiAnalyticsOutgoingWrapper:(MobiAnalyticsOutgoing *)outgoing
{
	outgoing.mobiAnalyticsOutgoingThothID = thothID;
	outgoing.mobiAnalyticsOutgoingCustomerID = [NSNumber numberWithInt:customerInfoJson.mobiIdInteger];
}

- (void)setValuesForSessionStartOutgoingEvent
{
	sessionStartOutgoingEvent.mobiAnalyticsOutgoingSessionID = mobiAnalyticsOutgoingSessionID;
	sessionStartOutgoingEvent.mobiAnalyticsOutgoingCustomerID = [NSNumber numberWithInt: customerInfoJson.mobiIdInteger];
	sessionStartOutgoingEvent.mobiAnalyticsOutgoingMinervaVersion = [self minervaVersionFromPublicationInfo];
	sessionStartOutgoingEvent.mobiAnalyticsOutgoingThothID = thothID;
	sessionStartOutgoingEvent.mobiAnalyticsOutgoingPlatform = self.mobiPlatforms.iOSPlatform.nameString;
	sessionStartOutgoingEvent.mobiAnalyticsOutgoingNetworkType = [self getNetworkType];
	sessionStartOutgoingEvent.mobiAnalyticsOutgoingDeviceVersion = [[UIDevice currentDevice] systemVersion];
	sessionStartOutgoingEvent.mobiAnalyticsOutgoingDeviceManufacturer = @"Apple";	// it's OK to hard code this
	sessionStartOutgoingEvent.mobiAnalyticsOutgoingThothDBCreated = [self creationDateStringFromPublicationInfo];
	sessionStartOutgoingEvent.mobiAnalyticsOutgoingDeviceModel = [[UIDevice currentDevice] model];
	
	// note: apple will reject the app if location services is used but isn't actually needed for a real feature in the app.
	// would require activating the location services manager and prompting the user.
	// we can get the user's approximate location from their IP address anyway, if we really want to get that.
//	sessionStartOutgoingEvent.mobiAnalyticsOutgoingLatitude = [NSNumber numberWithFloat:23.44369f];
//	sessionStartOutgoingEvent.mobiAnalyticsOutgoingLongitude = [NSNumber numberWithFloat:23.44369f];
}

- (void)setValuesForPageHistoryRequestOutgoingEvent
{
	pagePositionHistoryOutgoingEvent.mobiAnalyticsOutgoingCustomerID = [NSNumber numberWithInt: customerInfoJson.mobiIdInteger];
	pagePositionHistoryOutgoingEvent.mobiAnalyticsOutgoingSessionID = mobiAnalyticsOutgoingSessionID;
	pagePositionHistoryOutgoingEvent.mobiAnalyticsOutgoingThothID = thothID;
}

- (void)sendCurrentChapterProgressToServer:(NSDictionary *)progressDict
{
	if (socketStatusForAnalytics >= kSocketStatusConnected)
	{
		socketStatusForAnalytics = kSocketStatusPagePositionUpdate;
		NSString *pagePositionActionString = self.analyticFromClientActions.pagePositionAction.nameString;
		pagePositionOutgoingEvent = [[MobiAnalyticsOutgoing alloc] initWithActionString:pagePositionActionString];
		[self setValuesForPagePositionOutgoingEventForDict:progressDict];
		[pagePositionOutgoingEvent buildMobiAnalyticsOutgoingJsonWrapper];
		[pagePositionOutgoingEvent buildMobiAnalyticsOutgoingPayloadJsonString];
		[pagePositionOutgoingEvent buildJsonString];
		[pagePositionOutgoingEvent sendOnSocket:webSocketForAnalytics];
	}
}

- (void)setValuesForPagePositionOutgoingEventForDict:(NSDictionary *)progressDict
{
	pagePositionOutgoingEvent.mobiAnalyticsOutgoingSessionID = mobiAnalyticsOutgoingSessionID;
	pagePositionOutgoingEvent.mobiAnalyticsOutgoingThothID = [self thothIdFromPublicationInfo];
	pagePositionOutgoingEvent.mobiAnalyticsOutgoingCustomerID = [NSNumber numberWithInt: customerInfoJson.mobiIdInteger];
	pagePositionOutgoingEvent.mobiAnalyticsOutgoingPageCompletionCurrentPercentage = progressDict[@"currentPercentage"];
	pagePositionOutgoingEvent.mobiAnalyticsOutgoingPageCompletionMaxPercentage = progressDict[@"maxPercentage"];
	pagePositionOutgoingEvent.mobiAnalyticsOutgoingPageCompletionLastUpdateTimestamp = progressDict[@"lastUpdateTimeStamp"];
	pagePositionOutgoingEvent.mobiAnalyticsOutgoingPageCompletionPageInstanceID = progressDict[@"payLoadInteger"];
	pagePositionOutgoingEvent.mobiAnalyticsOutgoingPageCompletionPageID = progressDict[@"payLoadString"];
	id dateReadTimestamp = progressDict[@"dateReadTimeStamp"];
	
	if (dateReadTimestamp)
		pagePositionOutgoingEvent.mobiAnalyticsOutgoingPageCompletionDateReadTimestamp = dateReadTimestamp;
}

- (void)requestFlashCardHistory
{
	if (socketStatusForAnalytics >= kSocketStatusConnected)
	{
		socketStatusForAnalytics = kSocketStatusFlashCardHistory;
		NSString *flashCardHistoryActionString = self.analyticFromClientActions.flashCardHistoryAction.nameString;
		flashCardHistoryOutgoingEvent = [[MobiAnalyticsOutgoing alloc] initWithActionString:flashCardHistoryActionString];
		flashCardHistoryOutgoingEvent.mobiAnalyticsOutgoingSessionID = mobiAnalyticsOutgoingSessionID;
		flashCardHistoryOutgoingEvent.mobiAnalyticsOutgoingThothID = [self thothIdFromPublicationInfo];
		flashCardHistoryOutgoingEvent.mobiAnalyticsOutgoingCustomerID = [NSNumber numberWithInt: customerInfoJson.mobiIdInteger];
		[flashCardHistoryOutgoingEvent buildMobiAnalyticsOutgoingJsonWrapper];
		[flashCardHistoryOutgoingEvent buildJsonString];
		[flashCardHistoryOutgoingEvent sendOnSocket:webSocketForAnalytics];
	}
}

- (void)sendNewFlashCardToServer:(NSDictionary *)flashCardCreatedDict
{
	if (socketStatusForAnalytics >= kSocketStatusConnected)
	{
		socketStatusForAnalytics = kSocketStatusFlashCardCreated;
		NSString *flashCardCreatedActionString = self.analyticFromClientActions.flashCardCreatedAction.nameString;
		flashCardCreatedOutgoingEvent = [[MobiAnalyticsOutgoing alloc] initWithActionString:flashCardCreatedActionString];
		[self setValuesForFlashCardCreatedOutgoingEventForDict:flashCardCreatedDict];
		[self setValuesInMobiAnalyticsOutgoingWrapper:flashCardCreatedOutgoingEvent];
		[flashCardCreatedOutgoingEvent buildMobiAnalyticsOutgoingJsonWrapper];
		[flashCardCreatedOutgoingEvent buildMobiAnalyticsOutgoingPayloadJsonString];
		[flashCardCreatedOutgoingEvent buildJsonString];
		[flashCardCreatedOutgoingEvent sendOnSocket:webSocketForAnalytics];
	}
}

- (void)setValuesForFlashCardCreatedOutgoingEventForDict:(NSDictionary *)flashCardCreatedDict
{
	flashCardCreatedOutgoingEvent.mobiAnalyticsOutgoingCardCreatedText = flashCardCreatedDict[@"cardText"];
	flashCardCreatedOutgoingEvent.mobiAnalyticsOutgoingCardCreatedPageInstanceID = flashCardCreatedDict[@"pageInstanceId"];
}

- (void)sendQuizAnswerToServer:(NSDictionary *)quizAnswerDictionary forQuizAnswerJsonString:(NSString *)quizAnswerJsonString;
{
	if (socketStatusForAnalytics >= kSocketStatusConnected)
	{
		socketStatusForAnalytics = kSocketStatusFlashCardCreated;
		NSString *sendAnswerSelectedActionString = self.analyticFromClientActions.quizSelectAnswerAction.nameString;
		quizAnswerOutgoingEvent = [[MobiAnalyticsOutgoing alloc] initWithActionString:sendAnswerSelectedActionString];
		[self setValuesForQuizAnswerOutgoingEventForDict:quizAnswerDictionary forQuizAnswerJsonString:quizAnswerJsonString];
		[self setValuesInMobiAnalyticsOutgoingWrapper:quizAnswerOutgoingEvent];
		[quizAnswerOutgoingEvent buildMobiAnalyticsOutgoingJsonWrapper];
		[quizAnswerOutgoingEvent buildMobiAnalyticsOutgoingPayloadJsonString];
		[quizAnswerOutgoingEvent buildJsonString];
		[quizAnswerOutgoingEvent sendOnSocket:webSocketForAnalytics];
	}
}

- (void)setValuesForQuizAnswerOutgoingEventForDict:(NSDictionary *)quizAnswerDictionary forQuizAnswerJsonString:(NSString *)quizAnswerJsonString
{
	quizAnswerOutgoingEvent.mobiAnalyticsOutgoingQuizID = quizAnswerDictionary[@"quizId"];
	quizAnswerOutgoingEvent.mobiAnalyticsOutgoingQuizAnswerJsonString = quizAnswerJsonString;
}

// xyzzy call this only when user taps to a quiz.  we need the quiz id of that quiz.

- (void)requestQuizAnalyticsForQuizIdNumber:(NSNumber *)quizIdNumber
{
	if (socketStatusForAnalytics >= kSocketStatusConnected)
	{
		socketStatusForAnalytics = kSocketStatusRequestingQuizHistory;
		NSString *quizAnalyticsActionString = self.analyticFromClientActions.getQuizAnalyticsAction.nameString;
		quizAnalyticsDataOutgoingEvent = [[MobiAnalyticsOutgoing alloc] initWithActionString:quizAnalyticsActionString];
		[self setValuesForQuizAnalyticsOutgoingEventForQuizIdNumber:quizIdNumber];
		[quizAnalyticsDataOutgoingEvent buildMobiAnalyticsOutgoingJsonWrapper];
		[quizAnalyticsDataOutgoingEvent buildMobiAnalyticsOutgoingPayloadJsonString];
		[quizAnalyticsDataOutgoingEvent buildJsonString];
		[quizAnalyticsDataOutgoingEvent sendOnSocket:webSocketForAnalytics];
	}
}

- (void)setValuesForQuizAnalyticsOutgoingEventForQuizIdNumber:(NSNumber *)quizIdNumber
{
	quizAnalyticsDataOutgoingEvent.mobiAnalyticsOutgoingQuizID = quizIdNumber;
	quizAnalyticsDataOutgoingEvent.mobiAnalyticsOutgoingSessionID = mobiAnalyticsOutgoingSessionID;
	quizAnalyticsDataOutgoingEvent.mobiAnalyticsOutgoingCustomerID = [NSNumber numberWithInt: customerInfoJson.mobiIdInteger];
	quizAnalyticsDataOutgoingEvent.mobiAnalyticsOutgoingThothID = thothID;
}

- (void)handleQuizStatus:(id)message
{
//	NSLog(@"handleQuizStatus: message = %@", message);
}

- (void)sendCurrentUserStatusToServer;
{
	// zzzzz is this needed?  is sending all quiz data at once in the spec?
}

- (void)sendCurrentQuizCompletionStatusToServer;
{
	// zzzzz: Mike hasn't done this yet.
}

#pragma mark - Publication info from server

- (NSNumber *)thothIdFromPublicationInfo
{
	NSString *thothIdString = publicationInfo[@"ThothId"];
	
	if (thothIdString && thothIdString.length > 0)
		thothID = [NSNumber numberWithInt:[thothIdString intValue]];
	else
		thothID = [NSNumber numberWithInt:(-1000)];									// negative value for error
	
	return thothID;
}

- (NSString *)minervaVersionFromPublicationInfo
{
	NSString *minervaVersionString = publicationInfo[@"Version"];					// nil on error
	return minervaVersionString;
}

- (NSString *)creationDateStringFromPublicationInfo
{
	NSString *creationDateString = publicationInfo[@"Created"];						// nil on error
	return creationDateString;
}

- (NSDictionary *)publicationInfo;
{
	return publicationInfo;
}

#pragma mark - Network reachability

// allowable network connection type strings are:
// @"None"
// @"BlueTooth"	(not possible with any iOS device)
// @"Ethernet"	(not possible with any iOS device)
// @"Wifi"
// @"WiMax"		(not possible with any iOS device)
// @"Mobile_2G"
// @"Mobile_3G"
// @"Mobile_4G"
// @"Unknown"

- (NSString *)getNetworkType
{
	NSString *networkType = nil;
	Reachability *reach = [Reachability reachabilityWithHostName:@"www.mobifusion.com"];

	if (reach)
	{
		switch (reach.currentReachabilityStatus)
		{
			case NotReachable:
				networkType = @"None";
				break;
			case ReachableViaWiFi:
				networkType = @"Wifi";
				break;
			case ReachableViaWWAN:
				networkType = [self getCellNetworkProtocol];
				break;
			default:
				networkType = @"Unknown";
				break;
		}
	}

	return networkType;
}

- (NSString *)getCellNetworkProtocol
{
	NSString *protocolString = @"None";
	NSArray *subviews = [[[[UIApplication sharedApplication] valueForKey:@"statusBar"] valueForKey:@"foregroundView"]subviews];
	NSNumber *dataNetworkItemView = nil;
	
	for (id subview in subviews)
	{
		if([subview isKindOfClass:[NSClassFromString(@"UIStatusBarDataNetworkItemView") class]])
		{
			dataNetworkItemView = subview;
			break;
		}
	}
	
	if (dataNetworkItemView)
	{
		switch ([[dataNetworkItemView valueForKey:@"dataNetworkType"]integerValue])
		{
			case 0:		// no cell connection
				protocolString = @"None";
				break;
			case 1:		// 2G
				protocolString = @"Mobile_2G";
				break;
			case 2:		// 3G
				protocolString = @"Mobile_3G";
				break;
			case 3:		// 4G
				protocolString = @"Mobile_4G";
				break;
			case 4:		// LTE
				protocolString = @"Mobile_4G";
				break;
			case 5:		// Wifi (but we should never call this method if we know we have a wifi connection)
				protocolString = @"@Wifi";
				break;
			default:
				protocolString = @"None";
				break;
		}
	}
	
	return protocolString;
}

#pragma mark - Parsing JSON

- (BOOL)parseSessionInfo:(NSString *)sessionInfoString
{
	BOOL parsedOK = YES;
	NSData *sessionInfoData = [sessionInfoString dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *sessionInfoDict = [NSJSONSerialization JSONObjectWithData:sessionInfoData options:0 error:NULL];
	
	parsedOK = ([self foundErrorInDictionary:sessionInfoDict] == NO);

	if (parsedOK)
		[self handleCustomerInfo:sessionInfoString];
	
	return parsedOK;
}

- (BOOL)foundErrorInDictionary:(NSDictionary *)sessionInfoDict
{
	BOOL foundError = NO;
	NSNumber *errNum = sessionInfoDict[@"error"];
	
	if (errNum)
	{
		int errInt = [errNum intValue];
		foundError = (errInt != 0);
	}

	return foundError;
}

- (void)handleCustomerInfo:(NSString *)customerInfoString
{
	if ([customerInfoString rangeOfString:@"CustomerCreated"].length == 0 && [customerInfoString rangeOfString:@"MobifusionUserCreated"].length == 0)
		return;

	customerInfoJson = [[CustomerJson alloc] initWithString:customerInfoString];
	
	if (customerInfoJson.nameString && customerInfoJson.typeString)
	{
		[[DataController sharedController] deleteExistingCustomerInfoIfNecessary];
		[[DataController sharedController] saveCustomerInfoInDatabaseWithCustomerJson:customerInfoJson];
		[self dismissLoginView];
	}
}

- (void)handleAvatarImageFromMessageBinary:(id)messageBinary
{
	self.userAvatarImage = [[UIImage imageWithData:messageBinary] copy];
	webServicesEngineCustomerDataEngine.customerAvatarImage = self.userAvatarImage;
	[webServicesEngineCustomerDataEngine saveAvatarImageToLocalFilesystem];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"avatarImageReadyNotification" object:nil];
}

/* example of "flashcards" message from server
{
	"timestamp": 1389045263695,
	"json": "[\n  {\n    \"customerId\": 1,\n    \"thothId\": 914,\n    \"data\": \"page 1 test data\",\n    \"pageId\": 503974,\n    \"mongoId\": \"529fbb16da06080f96f4fa31\"\n  },\n  {\n    \"customerId\": 1,\n    \"thothId\": 914,\n    \"data\": \"sdfghjuytrfd\\n\\nProblem Set B_Test\",\n    \"pageId\": 503979,\n    \"mongoId\": \"529fb6e8da065a27620c0e1e\"\n  },\n  {\n    \"customerId\": 1,\n    \"thothId\": 914,\n    \"data\": \"page 8 teaw\",\n    \"pageId\": 503981,\n    \"mongoId\": \"529fb7e7da065a27620c0e22\"\n  },\n  {\n    \"customerId\": 1,\n    \"thothId\": 914,\n    \"data\": \"page 10\\ndfgbhn\",\n    \"pageId\": 503983,\n    \"mongoId\": \"529fba82da06080f96f4fa2e\"\n  }\n]",
	"error": false,
	"action": "FlashCards"
}
*/

// note: timestamps are not necessarily going to be unique for each row in the flash_cards table.  if we create 3 flash cards on device a,
// then turn on device b and it gets udpated with flash card data from the server, then the json message contains only one timestamp.
// we'll be forced to either 1. use the same timestamp for the 3 new flash cards in device b's sqlite, or 2. create new, unique timestamps
// as we add the rows to sqlite on device b.  not sure which is better, and not sure if timestamps are really necessary in the flash_cards table.

- (void)handleFlashCards:(id)message
{
	if ([message respondsToSelector:@selector(hasPrefix:)])											// check that the message object is a string
	{
		NSData *jsonData = [message dataUsingEncoding:NSUTF8StringEncoding];
		id jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:NULL];
		
		if ([jsonObject isKindOfClass:[NSDictionary class]])
		{
			NSNumber *flashCardTimestampNumber = jsonObject[@"timestamp"];							// one timestamp for all flash cards per message
			long long flashCardTimestampLongLong = flashCardTimestampNumber.longLongValue;
			NSString *flashCardsString = jsonObject[@"json"];
			NSData *flashCardsData = [flashCardsString dataUsingEncoding:NSUTF8StringEncoding];
			NSArray *flashCardsArray = [NSJSONSerialization JSONObjectWithData:flashCardsData options:NSJSONReadingAllowFragments error:NULL];
			NSMutableArray *existingCardsArray = [[DataController sharedController] getAllCardsFromDatabase];
			
			for (NSDictionary *flashCardDict in flashCardsArray)
			{
				flashCardTimestampNumber = [NSNumber numberWithLongLong:flashCardTimestampLongLong++];
				[self addPossibleNewFlashCardToDatabaseForDict:flashCardDict forTimestampNumber:flashCardTimestampNumber forExistingCardsArray:existingCardsArray];
			}
		}
	}
}

- (void)handleNewFlashCard:(id)message
{
	if ([message respondsToSelector:@selector(hasPrefix:)])											// check that the message object is a string
	{
		NSData *jsonData = [message dataUsingEncoding:NSUTF8StringEncoding];
		id jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:NULL];
		
		if ([jsonObject isKindOfClass:[NSDictionary class]])
		{
			NSNumber *flashCardTimestampNumber = jsonObject[@"timestamp"];							// one timestamp for all flash cards per message
			NSString *flashCardsString = jsonObject[@"json"];
			NSData *flashCardsData = [flashCardsString dataUsingEncoding:NSUTF8StringEncoding];
			NSDictionary *flashCardDict = [NSJSONSerialization JSONObjectWithData:flashCardsData options:NSJSONReadingAllowFragments error:NULL];
			NSMutableArray *existingCardsArray = [[DataController sharedController] getAllCardsFromDatabase];
			[self addPossibleNewFlashCardToDatabaseForDict:flashCardDict forTimestampNumber:flashCardTimestampNumber forExistingCardsArray:existingCardsArray];
		}
	}
}

// set exitingCardsArray to nil if we're handling the server's "NewFlashCardCreated" message in response to our "FlashCardCreated" action

- (void)addPossibleNewFlashCardToDatabaseForDict:(NSDictionary *)flashCardDict forTimestampNumber:(NSNumber *)timestampNumber forExistingCardsArray:(NSArray *)existingCardsArray
{
	NSString *flashCardDataString = flashCardDict[@"data"];
	NSNumber *flashCardPageIdNumber = flashCardDict[@"pageId"];
	NSString *flashCardMongoIdString = flashCardDict[@"mongoId"];
	
	BOOL cardFound = NO, mongoIdFound = NO;
	for (Card *existingCard in existingCardsArray)
	{
		if ([flashCardDataString hasPrefix:@"From the above definition,"] || [flashCardDataString hasPrefix:@"Translating"])
		{
			if ([existingCard.cardText hasPrefix:@"From the above definition,"] || [existingCard.cardText hasPrefix:@"Translating"])
				NSLog(@"existingCard = %@", existingCard);
		}
		if ([flashCardDataString isEqualToString:existingCard.cardText] && flashCardPageIdNumber.intValue == existingCard.pageInstanceId)
		{
			mongoIdFound = (existingCard.mongoIdString != nil);
			cardFound = YES;
			break;
		}
	}
	
	if (cardFound == NO || mongoIdFound == NO)
	{
		NSLog(@"addPossibleNew: flashCardDataString = '%@'", flashCardDataString);
		[[DataController sharedController] saveCardInDatabaseWithString:flashCardDataString pageInstanceIdInteger:[flashCardPageIdNumber integerValue] timeStampLongLong:[timestampNumber longLongValue] mongoIdString:flashCardMongoIdString];
	}
}

- (void)handleQuizAnalyticsData:(id)message
{
	if ([message respondsToSelector:@selector(hasPrefix:)])											// check that the message object is a string
	{
		NSData *jsonData = [message dataUsingEncoding:NSUTF8StringEncoding];
		id jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:NULL];
		
		if ([jsonObject isKindOfClass:[NSDictionary class]])
		{
			NSNumber *quizAnswerTimestampNumber = jsonObject[@"timestamp"];
			NSString *quizAnswerJsonString = jsonObject[@"json"];
			NSData *quizAnswerData = [quizAnswerJsonString dataUsingEncoding:NSUTF8StringEncoding];
			NSDictionary *quizAnswerDict = [NSJSONSerialization JSONObjectWithData:quizAnswerData options:NSJSONReadingAllowFragments error:NULL];
			[self addPossibleNewQuizAnswersToDatabaseForDict:quizAnswerDict forTimestampNumber:quizAnswerTimestampNumber];
		}
	}
}

- (void)addPossibleNewQuizAnswersToDatabaseForDict:(NSDictionary *)quizAnswerDict forTimestampNumber:(NSNumber *)timestampNumber
{
	NSNumber *quizIdNumber = quizAnswerDict[@"quizId"];
	NSArray *answerArray = quizAnswerDict[@"answers"];
	
	for (NSDictionary *answerDict in answerArray)
		[[DataController sharedController] saveQuestionResultToDatabaseIfNecessary:answerDict forQuizId:quizIdNumber.intValue];
}

- (void)handleErrorMessage:(id)message hideMessage:(BOOL)hideMessage
{
	NSData *messageData = [message dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *messageDict = [NSJSONSerialization JSONObjectWithData:messageData options:0 error:NULL];
	NSLog(@"handleErrorMessage: messageDict = %@", messageDict);
	
	if (hideMessage == NO && [self foundErrorInDictionary:messageDict])
	{
		NSString *titleString = messageDict[@"errorMessage"];
		
		if (titleString && titleString.length > 1)
			titleString = NSLocalizedString(titleString, titleString);
		
		NSString *messageString = NSLocalizedString(@"Please re-enter your login information", @"Please re-enter your login information");
		
		if ([titleString rangeOfString:NSLocalizedString(@"Email", @"Email")].length > 0)
			messageString = NSLocalizedString(@"Please enter a different email address", @"Please enter a different email address");

		[self showAlertWithTitle:titleString messageString:messageString];
	}
}

#pragma mark - Initialization

+ (id)webServicesEngine
{
    static dispatch_once_t onceToken;
	
    dispatch_once(&onceToken, ^{
        webServicesEngine = [[self alloc] init];
		mobiAnalyticsIncoming = [[MobiAnalyticsIncoming alloc] init];
    });

    return webServicesEngine;
}

- (id)init
{
	[self initURLs];
	[self initStatus];
	[self initCustomerDataEngine];
	
	[self initAnalyticsWebSocket];		// re-establish this socket if we ever lose the connection
	[self initRegistrationWebSocket];	// close these sockets after they are no longer needed
	[self initLoginWebSocket];
	[self initFacebookWebSocket];
	[self initTwitterWebSocket];

	[self initObjectEnums];
	[self initPublicationInfo];
	[self registerForNotifications];
	return self;
}

- (void)initURLs
{
	webServerHTTPURL = [NSString stringWithFormat:@"ws://%@%@websocket/mobi-analytics", kWebServerRoot, kWebApp];
	webServerRegisterURL = [NSString stringWithFormat:@"ws://%@%@websocket/register-activity", kWebServerRoot, kWebApp];
	webServerLoginURL = [NSString stringWithFormat:@"ws://%@%@websocket/login-activity", kWebServerRoot, kWebApp];
	webServerFacebookURL = [NSString stringWithFormat:@"ws://%@%@websocket/facebook-login", kWebServerRoot, kWebApp];
	webServerTwitterURL = [NSString stringWithFormat:@"ws://%@%@websocket/twitter-login", kWebServerRoot, kWebApp];
}

- (void)initStatus
{
	socketStatusForAnalytics = kSocketStatusNotInitialized;
	socketStatusForRegistration = kSocketStatusNotInitialized;
	socketStatusForLogin = kSocketStatusNotInitialized;
	socketStatusForFacebook = kSocketStatusNotInitialized;
	socketStatusForTwitter = kSocketStatusNotInitialized;
}

- (void)initCustomerDataEngine
{
	webServicesEngineCustomerDataEngine = [CustomerDataEngine customerDataEngine];
}

- (void)initObjectEnums
{
	self.analyticFromClientActions = [[AnalyticFromClientActions alloc] init];
	self.mobiPlatforms = [[MobiPlatforms alloc] init];
}

- (void)initPublicationInfo
{
	publicationInfo = [[DataController sharedController] getInfo];
}

#pragma mark - Account data handling

- (BOOL)customerExists
{
	BOOL exists = [[DataController sharedController] customerInfoExistsInDatabase];
	return exists;
}

- (void)establishServerConnectionWithExistingAccount
{
	NSDictionary *customerInfoDict = [[DataController sharedController] customerInfoDictionary];
	
	if (customerInfoDict && customerInfoDict.count > 0)
	{
		customerInfoJson = [[CustomerJson alloc] initWithDictionary:customerInfoDict];
		waitingToLoginExistingAccount = YES;
	}
}

#pragma mark - Web socket delegate methods

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message
{
//	NSLog(@"webSocket:didReceiveMessage: %@", message);
	BOOL isString = [message respondsToSelector:@selector(hasPrefix:)];						// determine whether object is serialized object or binary data
	NSString *actionString = nil;
	
	if (isString)			// server has sent us a JSON object
	{
		actionString = [self parseActionStringFromServerMessageJson:(NSString *)message];
		NSString *endpointString = [webSocket.url lastPathComponent];
		
		if ([endpointString rangeOfString:@"facebook"].length > 0)							// facebook login confirmation
		{
			[self handleFacebookLoginMessage:message];
		}
		else if ([endpointString rangeOfString:@"twitter"].length > 0)						// twitter login confirmation
		{
			[self handleTwitterLoginMessage:message];
		}
		else if (actionString == nil)														// token from facebook or twitter with existing login information
		{
			[self parseTokenFromString:(NSString *)message fromSocket:webSocket];
		}
		else if ([actionString isEqualToString:@"MobifusionUserCreated"])					// mobifusion login
		{
			[self handleMobiLoginMessage:message];
		}
		else if ([actionString isEqualToString:@"AnonymousCustomerCreated"])				// anonymous login
		{
			[self handleMobiLoginMessage:message];
		}
		else if ([actionString isEqualToString:@"HelloNewSession"])							// server's reply to our new session request
		{
			[self sendStartMessage];
		}
		else if ([actionString isEqualToString:@"SessionCreated"])							// acknowledgement of new session creation
		{
			[self sendPagePositionHistoryMessage];
		}
		else if ([actionString isEqualToString:@"PagePositions"])							// current page in all chapters
		{
			[self handlePagePositions:message];
		}
		else if ([actionString isEqualToString:@"FlashCards"])								// all flash cards on all devices
		{
			[self handleFlashCards:message];
		}
		else if ([actionString isEqualToString:@"NewFlashCardCreated"])						// new flash card (with mongo id that was missing on creation)
		{
			[self handleNewFlashCard:message];
		}
		else if ([actionString isEqualToString:@"QuizAnalyticsData"])
		{
			[self handleQuizAnalyticsData:message];
		}
		else if ([actionString isEqualToString:@"Error"])									// error (possibly after incompletely logging in)
		{
			[self handleErrorMessage:message hideMessage:YES];								// eventually we could un-hide the message, but not for 1.0
		}
	}
	else					// server has sent us binary data (currently only the user avatar image for facebook or twitter)
	{
		[self handleAvatarImageFromMessageBinary:message];
	}
}

- (void)webSocketDidOpen:(SRWebSocket *)webSocket
{
	int socketStatus;
	
	if ([webSocket isEqual:webSocketForRegisteringMobiUser])
		socketStatus = socketStatusForRegistration;
	else if ([webSocket isEqual:webSocketForLogin])
		socketStatus = socketStatusForLogin;
	else if ([webSocket isEqual:webSocketForFacebook])
		socketStatus = socketStatusForFacebook;
	else if ([webSocket isEqual:webSocketForTwitter])
		socketStatus = socketStatusForTwitter;
	else
		socketStatus = socketStatusForAnalytics;

	switch (socketStatus)
	{
		case kSocketStatusConnecting:
			socketStatus = kSocketStatusConnected;
			break;
		default:
			break;
	}

	if ([webSocket isEqual:webSocketForRegisteringMobiUser])
		socketStatusForRegistration = socketStatus;
	else if ([webSocket isEqual:webSocketForLogin])
		socketStatusForLogin = socketStatus;
	else if ([webSocket isEqual:webSocketForFacebook])
		socketStatusForFacebook = socketStatus;
	else if ([webSocket isEqual:webSocketForTwitter])
		socketStatusForTwitter = socketStatus;
	else
		socketStatusForAnalytics = socketStatus;
	
	if (waitingToLoginExistingAccount && socketStatus >= kSocketStatusConnected && [webSocket isEqual:webSocketForAnalytics])
		[self sendHelloMessage];
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error
{
	NSLog(@"webSocket:didFailWithError:");
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean
{
	NSLog(@"webSocket:didCloseWithCode: %d\nreason:%@\nwasClean:%d", code, reason, wasClean);
}

#pragma mark - Facebook login

// sample url:
// "https://www.facebook.com/dialog/oauth?client_id=602943776423099&redirect_uri=http://54.205.253.32:8080/mobi-analytics/facebook.mobi&scope=password,email&state=17"

- (void)startFacebookLogin
{
	NSString *facebookLoginParams = @"user_birthday,email";
	NSMutableArray *callbackPathComponents = [[NSMutableArray alloc] initWithCapacity:0];
	[callbackPathComponents addObject:[NSString stringWithFormat:@"http://%@", kWebServerRoot]];
	[callbackPathComponents addObject:kWebApp];
	[callbackPathComponents addObject:[NSString stringWithFormat:@"facebook.mobi&scope=%@&state=%@", facebookLoginParams, facebookToken]];
	NSString *facebookCallbackString = [callbackPathComponents componentsJoinedByString:@""];
	
	NSString *facebookAppID = @"602943776423099";
	NSMutableArray *oauthPathComponents = [[NSMutableArray alloc] initWithCapacity:0];
	[oauthPathComponents addObject:@"https://www.facebook.com"];
	[oauthPathComponents addObject:[NSString stringWithFormat:@"dialog/oauth?client_id=%@&redirect_uri=%@", facebookAppID, facebookCallbackString]];
	NSString *facebookOauthURLString = [oauthPathComponents componentsJoinedByString:@"/"];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"facebookURLNotification" object:facebookOauthURLString];
}

- (void)handleFacebookLoginMessage:(id)message
{
	if ([message respondsToSelector:@selector(hasPrefix:)])								// check that the message object is a string
	{
		NSString *messageString = (NSString *)message;
		
		if ([messageString rangeOfString:@"TOKEN"].length > 0 || [messageString rangeOfString:@"Token"].length > 0 || [messageString rangeOfString:@"token"].length > 0)
			[self getFacebookConnectionTokenFromMessageString:(NSString *)message];
		else if ([message rangeOfString:@"json"].length > 0 || [message rangeOfString:@"Json"].length > 0 || [message rangeOfString:@"JSON"].length > 0)
			[self parseSessionInfo:messageString];
	}
	else																				// not string, so must be binary image data
	{
		[self handleAvatarImageFromMessageBinary:message];
		[self dismissLoginView];
	}
}

- (void)getFacebookConnectionTokenFromMessageString:(NSString *)messageString
{
	if (messageString == nil || messageString.length < normalizedTokenKey.length)
	{
		facebookToken = nil;
		return;
	}

	NSString *messageStringStart = [[messageString substringToIndex:normalizedTokenKey.length] lowercaseString];
	
	if ([messageStringStart isEqualToString:normalizedTokenKey])
	{
		NSString *tokenValue = [messageString substringFromIndex:(normalizedTokenKey.length + 1)];
		
		if (tokenValue && tokenValue.length > 0)
			facebookToken = [tokenValue copy];
		else
			facebookToken = nil;
	}
}

#pragma mark - Twitter login

- (void)startTwitterLogin
{
	NSMutableArray *oauthPathComponents = [[NSMutableArray alloc] initWithCapacity:0];
	[oauthPathComponents addObject:@"https://api.twitter.com"];
	[oauthPathComponents addObject:@"oauth"];
	[oauthPathComponents addObject:[NSString stringWithFormat:@"authenticate?oauth_token=%@", twitterToken]];
	NSString *twitterOauthURLString = [oauthPathComponents componentsJoinedByString:@"/"];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"twitterURLNotification" object:twitterOauthURLString];
}

- (void)handleTwitterLoginMessage:(id)message
{
	if ([message respondsToSelector:@selector(hasPrefix:)])							// check that the message object is a string
	{
		NSString *messageString = (NSString *)message;

		if ([messageString rangeOfString:@"TOKEN"].length > 0 || [messageString rangeOfString:@"Token"].length > 0 || [messageString rangeOfString:@"token"].length > 0)
			[self getTwitterConnectionTokenFromMessageString:messageString];
		else if ([message rangeOfString:@"json"].length > 0 || [message rangeOfString:@"Json"].length > 0 || [message rangeOfString:@"JSON"].length > 0)
			[self parseSessionInfo:messageString];
	}
	else
	{
		[self handleAvatarImageFromMessageBinary:message];
		[self dismissLoginView];
	}
}

- (void)getTwitterConnectionTokenFromMessageString:(NSString *)messageString
{
	if (messageString == nil || messageString.length < normalizedTokenKey.length)
	{
		twitterToken = nil;
		return;
	}
	
	NSString *messageStringStart = [[messageString substringToIndex:normalizedTokenKey.length] lowercaseString];
	
	if ([messageStringStart isEqualToString:normalizedTokenKey])
	{
		NSString *tokenValue = [messageString substringFromIndex:(normalizedTokenKey.length + 1)];
		
		if (tokenValue && tokenValue.length > 0)
			twitterToken = [tokenValue copy];
		else
			twitterToken = nil;
	}
	else if ([messageString rangeOfString:@"json"].length > 0)
	{
		// handle json message with name, mobi id, have avatar, etc.
		// should also make sure that the action is "CustomerCreated"
		[self parseSessionInfo:messageString];
	}
}

#pragma mark - Mobi login

- (void)handleMobiLoginMessage:(id)message
{
	if ([message respondsToSelector:@selector(hasPrefix:)])							// check that the message object is a string
	{
		if ([message rangeOfString:@"json"].length > 0 || [message rangeOfString:@"Json"].length > 0 || [message rangeOfString:@"JSON"].length > 0)
		{
			[self parseSessionInfo:message];
			self.userAvatarImage = nil;												// no avatar for mobi users :-(
			[webServicesEngineCustomerDataEngine removeAvatarImageFromLocalFilesystem];
		}
		else if ([message rangeOfString:@"Error"].length > 0)
		{
			[self handleErrorMessage:message hideMessage:NO];
		}
	}
}

#pragma mark - Web socket methods

- (void)parseTokenFromString:(NSString *)message fromSocket:(SRWebSocket *)webSocket
{
	NSString *endpointString = [webSocket.url lastPathComponent];
	
	if ([endpointString rangeOfString:@"facebook"].length > 0)
		[self getFacebookConnectionTokenFromMessageString:(NSString *)message];
	else if ([endpointString rangeOfString:@"twitter"].length > 0)
		[self getTwitterConnectionTokenFromMessageString:(NSString *)message];
}

- (void)initAnalyticsWebSocket
{
	webSocketForAnalytics = [[SRWebSocket alloc] initWithURL:[NSURL URLWithString:webServerHTTPURL]];
	webSocketForAnalytics.delegate = self;
	socketStatusForAnalytics = kSocketStatusConnecting;
	[webSocketForAnalytics open];
}

- (void)initRegistrationWebSocket
{
	webSocketForRegisteringMobiUser = [[SRWebSocket alloc] initWithURL:[NSURL URLWithString:webServerRegisterURL]];
	webSocketForRegisteringMobiUser.delegate = self;
	socketStatusForRegistration = kSocketStatusConnecting;
	[webSocketForRegisteringMobiUser open];
}

- (void)initLoginWebSocket
{
	webSocketForLogin = [[SRWebSocket alloc] initWithURL:[NSURL URLWithString:webServerLoginURL]];
	webSocketForLogin.delegate = self;
	socketStatusForLogin = kSocketStatusConnecting;
	[webSocketForLogin open];
}

- (void)initFacebookWebSocket
{
	webSocketForFacebook = [[SRWebSocket alloc] initWithURL:[NSURL URLWithString:webServerFacebookURL]];
	webSocketForFacebook.delegate = self;
	socketStatusForFacebook = kSocketStatusConnecting;
	[webSocketForFacebook open];
}

- (void)initTwitterWebSocket
{
	webSocketForTwitter = [[SRWebSocket alloc] initWithURL:[NSURL URLWithString:webServerTwitterURL]];
	webSocketForTwitter.delegate = self;
	socketStatusForTwitter = kSocketStatusConnecting;
	[webSocketForTwitter open];
}

- (NSString *)parseActionStringFromServerMessageJson:(NSString *)messageJsonString
{
	NSString *actionString = nil;
	NSData *messageData = [messageJsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *messageDict = [NSJSONSerialization JSONObjectWithData:messageData options:0 error:NULL];
	
	if (messageDict)
		actionString = messageDict[@"action"];

	return actionString;
}

- (void)closeAllLoginWebSockets;
{
#if 1
	return;
#else
	[self closeRegistrationWebSocket];
	[self closeLoginWebSocket];
	[self closeFacebookWebSocket];
	[self closeTwitterWebSocket];
#endif
}

- (void)closeRegistrationWebSocket
{
	if (webSocketForRegisteringMobiUser)
	{
		[webSocketForRegisteringMobiUser close];
		webSocketForRegisteringMobiUser = nil;
		socketStatusForRegistration = kSocketStatusNotInitialized;
	}
}

- (void)closeLoginWebSocket
{
	if (webSocketForLogin)
	{
		[webSocketForLogin close];
		webSocketForLogin = nil;
		socketStatusForLogin = kSocketStatusNotInitialized;
	}
}

- (void)closeFacebookWebSocket
{
	if (webSocketForFacebook)
	{
		[webSocketForFacebook close];
		webSocketForFacebook = nil;
		socketStatusForFacebook = kSocketStatusNotInitialized;
	}
}

- (void)closeTwitterWebSocket
{
	if (webSocketForTwitter)
	{
		[webSocketForTwitter close];
		webSocketForTwitter = nil;
		socketStatusForTwitter = kSocketStatusNotInitialized;
	}
}

#pragma mark - Alert popup

- (void) showAlertWithTitle:(NSString *)titleString messageString:(NSString *)messageString
{
	NSString *localizedMessage = NSLocalizedString(messageString, messageString);
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:titleString
													message:localizedMessage
												   delegate:self
										  cancelButtonTitle:@"OK"
										  otherButtonTitles:nil];
	[alert show];
}

- (void) alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	// probably not needed, but here it is anyway
}

#pragma mark - Notifications

- (void)registerForNotifications
{
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleMobiLoginNotification)
												 name:@"createMobiAccountNotification"
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleFacebookLoginNotification)
												 name:@"facebookLoginNotification"
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleTwitterLoginNotification)
												 name:@"twitterLoginNotification"
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleRequestForQuizIdNotification:)
												 name:@"requestQuizResultsForQuizId"
											   object:nil];
}

- (void)handleMobiLoginNotification
{
	[self initRegistrationWebSocket];
}

- (void)handleFacebookLoginNotification
{
	[self initFacebookWebSocket];
}

- (void)handleTwitterLoginNotification
{
	[self initTwitterWebSocket];
}

- (void)handleRequestForQuizIdNotification:(NSNotification *)notification
{
	NSNumber *quizIdNum = (NSNumber *)notification.object;
	[self requestQuizAnalyticsForQuizIdNumber:quizIdNum];
}

- (void)dismissLoginView
{
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loginViewDoneNotification" object:nil];
}

@end
