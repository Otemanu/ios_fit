//
//  MobiAnalyticsOutgoing.h
//  Fit
//
//  Created by Rich on 11/12/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MobiSessionJson.h"
#import "AnalyticFromClientActions.h"
#import "SRWebSocket.h"
#import "Scalars.h"

@interface MobiAnalyticsOutgoing : NSObject

@property (nonatomic, strong) NSNumber *mobiAnalyticsOutgoingTimeStamp;
@property (nonatomic, strong) NSNumber *mobiAnalyticsOutgoingThothID;
@property (nonatomic, strong) NSString *mobiAnalyticsOutgoingJSON;
@property (nonatomic, strong) NSString *mobiAnalyticsOutgoingAction;
@property (nonatomic, strong) NSNumber *mobiAnalyticsOutgoingCustomerID;
@property (nonatomic, strong) NSString *mobiAnalyticsOutgoingSessionID;

// zzzzz these should be moved out into a MobiRegisterCustomerBase object
@property (nonatomic, strong) NSString *mobiAnalyticsOutgoingPassword;
@property (nonatomic, strong) NSString *mobiAnalyticsOutgoingEmail;
@property (nonatomic, strong) NSString *mobiAnalyticsOutgoingName;
@property (nonatomic, strong) NSString *mobiAnalyticsOutgoingAgeCheck;

@property (nonatomic, strong) NSString *mobiAnalyticsOutgoingMinervaVersion;
@property (nonatomic, strong) NSString *mobiAnalyticsOutgoingDeviceVersion;
@property (nonatomic, strong) NSString *mobiAnalyticsOutgoingDeviceModel;
@property (nonatomic, strong) NSString *mobiAnalyticsOutgoingDeviceManufacturer;
@property (nonatomic, strong) NSString *mobiAnalyticsOutgoingPlatform;
@property (nonatomic, strong) NSString *mobiAnalyticsOutgoingNetworkType;
@property (nonatomic, strong) NSString *mobiAnalyticsOutgoingThothDBCreated;
@property (nonatomic, strong) NSNumber *mobiAnalyticsOutgoingLongitude;
@property (nonatomic, strong) NSNumber *mobiAnalyticsOutgoingLatitude;

@property (nonatomic, strong) NSNumber *mobiAnalyticsOutgoingPageCompletionCurrentPercentage;
@property (nonatomic, strong) NSNumber *mobiAnalyticsOutgoingPageCompletionMaxPercentage;
@property (nonatomic, strong) NSNumber *mobiAnalyticsOutgoingPageCompletionPageInstanceID;
@property (nonatomic, strong) NSNumber *mobiAnalyticsOutgoingPageCompletionPageID;
@property (nonatomic, strong) NSNumber *mobiAnalyticsOutgoingPageCompletionLastUpdateTimestamp;
@property (nonatomic, strong) NSNumber *mobiAnalyticsOutgoingPageCompletionDateReadTimestamp;

@property (nonatomic, strong) NSString *mobiAnalyticsOutgoingCardCreatedText;
@property (nonatomic, strong) NSNumber *mobiAnalyticsOutgoingCardCreatedPageInstanceID;

@property (nonatomic, strong) NSString *mobiAnalyticsOutgoingQuizAnswerJsonString;
@property (nonatomic, strong) NSNumber *mobiAnalyticsOutgoingQuizID;

@property (nonatomic, strong) AnalyticFromClientActions *analyticFromClientActions;

@property (nonatomic, strong) NSString *jsonString;
@property (nonatomic, strong) NSString *jsonInteger;

- (MobiAnalyticsOutgoing *)initWithActionString:(NSString *)actionString;
- (MobiAnalyticsOutgoing *)initWithNewMobiAccountDictionary:(NSDictionary *)newAccountDict;
- (void)setTimestamp;
- (void)sendOnSocket:(SRWebSocket *)socket;
- (void)buildMobiAnalyticsOutgoingPayloadJsonString;
- (void)buildMobiAnalyticsOutgoingJsonWrapper;
- (void)buildJsonString;
- (void)clearJsonValues;

@end
