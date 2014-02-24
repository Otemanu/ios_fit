//
//  PageInstanceProgressJson.h
//  Fit
//
//  Created by Rich on 12/4/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PageInstanceProgressJson : NSObject

@property int pageInstanceIdInteger;
@property int maxPercentageInteger;
@property int currentPercentageInteger;

@property double dateReadTimeStampDouble;
@property double lastUpdateTimeStampDouble;

@end
