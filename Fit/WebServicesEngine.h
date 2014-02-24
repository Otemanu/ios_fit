//
//  WebServicesEngine.h
//  Fit
//
//  Created by Rich on 11/9/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CustomerDataEngine.h"
#import "ChapterDataController.h"
#import "SRWebSocket.h"
#import "MobiAnalyticsIncoming.h"
#import "MobiAnalyticsOutgoing.h"
#import "Reachability.h"
#import "DataController.h"
#import "AnalyticFromClientActions.h"
#import "MobiPlatforms.h"
#import "CustomerJson.h"
#import "Scalars.h"

@interface WebServicesEngine : NSObject <UIApplicationDelegate, SRWebSocketDelegate>

@property NSMutableDictionary *customerLoginDictionary;				// generalized object containing user's login id data
@property NSMutableDictionary *sessionDictionary;					// customer id, analytics, etc.
@property NSMutableDictionary *userStatusDictionary;				// key/values for user's status (current chapter, quiz progress, etc.)

@property (nonatomic, strong) UIImage *userAvatarImage;

@property (nonatomic, strong) AnalyticFromClientActions *analyticFromClientActions;
@property (nonatomic, strong) MobiPlatforms *mobiPlatforms;

@property BOOL accountExists;										// don't initialize web sockets etc. for registering users if there already is an customer account
@property BOOL testingLogin;										// for testing only

- (void)attemptServerReconnect;										// re-establish a connection if it was dropped while the app is active or backgrounded
- (void)performLoginWithExistingAccount:(NSDictionary *)accountDict;
- (void)performFacebookLoginWithExistingAccount:(NSDictionary *)accountDict;
- (void)performTwitterLoginWithExistingAccount:(NSDictionary *)accountDict;
- (void)startFacebookLogin;											// start webview-based facebook oauth login
- (void)startTwitterLogin;											// start webview-based twitter oauth login
- (void)requestLoginWithRealAccount:(NSDictionary*)accountDict;		// send facebook, twitter, or mobi id-based customer login data to the server
- (void)requestLoginWithAnonymousAccount;							// send an anonymous customer login data to the server
- (void)sendCurrentUserStatusToServer;								// send all (???) current user status (current chapter, reading completion, etc.) to server
- (void)sendCurrentQuizCompletionStatusToServer;					// send quiz completion data to server
- (BOOL)customerExists;												// returns yes if user has already created a FB, Twitter, or Mobi "customer" object
- (void)establishServerConnectionWithExistingAccount;
- (void)sendCurrentChapterProgressToServer:(NSDictionary *)progressDict;	// send current chapter reading completion data to server
- (void)requestFlashCardHistory;									// get flash cards from server in case cards were created on another device
- (void)sendNewFlashCardToServer:(NSDictionary *)flashCardCreatedDict;
- (void)sendQuizAnswerToServer:(NSDictionary *)quizDictionary forQuizAnswerJsonString:(NSString *)quizAnswerJsonString;
+ (id)webServicesEngine;
- (NSDictionary *)publicationInfo;
- (void)closeAllLoginWebSockets;

@end
