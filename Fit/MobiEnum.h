//
//  MobiAnalyticsEnum.h
//  Fit
//
//  Created by Rich on 12/4/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MobiEnum : NSObject

@property (nonatomic, strong) NSString *nameString;

@property int ordinalInt;

- (MobiEnum *)initWithString:(NSString *)nameString;

@end
