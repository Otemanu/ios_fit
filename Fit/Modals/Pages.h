//
//  Pages.h
//  MinarvaFrameworkTest
//
//  Created by Pratap Shaik on 9/20/12.
//  Copyright (c) 2012 mmotio. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Pages : NSObject

  //show MainCategory List

@property(nonatomic,assign) NSInteger PagesId;
@property(nonatomic,assign) NSInteger OrderNum,isActivated;
@property(nonatomic,strong) NSString *Name,*appId;
@property(nonatomic) float price;
@end
