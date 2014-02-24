//
//  Card.h
//  Fit
//
//  Created by Mobi on 19/11/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Card : NSObject

@property (nonatomic, strong) NSString *cardText;
@property (nonatomic, strong) NSString *mongoIdString;
@property int pageInstanceId;
@property int deletedInt;
@property long long timeStamp;

@end
