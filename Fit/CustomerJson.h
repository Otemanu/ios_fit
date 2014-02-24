//
//  CustomerJson.h
//  Fit
//
//  Created by Rich on 12/4/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CustomerJson : NSObject

@property (nonatomic, strong) NSString *nameString;
@property (nonatomic, strong) NSString *typeString;

@property int mobiIdInteger;
@property int haveAvatarInteger;

- (CustomerJson *)initWithString:(NSString *)customerInfoString;
- (CustomerJson *)initWithDictionary:(NSDictionary *)customerInfoDictionary;

@end
