//
//  MobiLoginCustomerBase.h
//  Fit
//
//  Created by Rich on 12/4/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MobiLoginCustomerBase : NSObject

@property (nonatomic, strong) NSString *validEmailRegexString;
@property (nonatomic, strong) NSString *emailFieldNameString;
@property (nonatomic, strong) NSString *emailString;;
@property (nonatomic, strong) NSString *passwordString;;

@end
