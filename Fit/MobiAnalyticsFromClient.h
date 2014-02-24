//
//  MobiAnalyticsFromClient.h
//  Fit
//
//  Created by Rich on 12/4/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MobiAnalyticsFromClient : NSObject

@property double timeStampDouble;

@property (nonatomic, strong) NSString *jsonString;
@property (nonatomic, strong) NSString *sessionIdString;
@property (nonatomic, strong) NSString *actionString;

@property int customerIdInt;
@property int thothIdInt;

@end
