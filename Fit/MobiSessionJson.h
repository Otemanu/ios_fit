//
//  MobiSessionJson.h
//  Fit
//
//  Created by Rich on 12/4/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MobiSessionJson : NSObject

@property (nonatomic, strong) NSString *deviceVersionString;
@property (nonatomic, strong) NSString *modelString;
@property (nonatomic, strong) NSString *manufacturerString;
@property (nonatomic, strong) NSString *platformString;
@property (nonatomic, strong) NSString *thothDbCreatedString;
@property (nonatomic, strong) NSString *minervaVersionString;
@property (nonatomic, strong) NSString *networkTypeString;

@property int thothIdInteger;

@property double latitudeDouble;
@property double longitudeDouble;

@end
