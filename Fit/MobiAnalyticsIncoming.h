//
//  MobiAnalyticsIncoming.h
//  Fit
//
//  Created by Rich on 11/13/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Scalars.h"

@interface MobiAnalyticsIncoming : NSObject

- (void)populateFromMessageString:(NSString *)jsonString;

@end
