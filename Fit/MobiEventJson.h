//
//  MobiEventJson.h
//  Fit
//
//  Created by Rich on 12/4/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MobiEventJson : NSObject

@property (nonatomic, strong) NSString *notesString;
@property (nonatomic, strong) NSString *payloadString;

@property int payloadInteger;
@property int durationInteger;
@property int maxPercentageInteger;
@property int currentPercentageInteger;

@end
