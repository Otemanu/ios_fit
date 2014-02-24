//
//  MobiRegisterCustomerBase.h
//  Fit
//
//  Created by Rich on 12/4/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//

#import "MobiLoginCustomerBase.h"

@interface MobiRegisterCustomerBase : MobiLoginCustomerBase

@property (nonatomic, strong) NSString *nameString;
@property (nonatomic, strong) NSString *confirmPasswordString;

@property BOOL ageCheckBool;

@property int anonymousMobiUserIdInt;

@end
