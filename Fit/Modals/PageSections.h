//
//  PageSections.h
//  MinarvaFrameworkTest
//
//  Created by Pratap Shaik on 9/20/12.
//  Copyright (c) 2012 mmotio. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PageSections : NSObject
//Tags Table in the dataset
@property(nonatomic,assign) NSInteger TagsId;
@property(nonatomic,assign) NSInteger OrderNum;
@property(nonatomic,strong) NSString *tagName;
@property(nonatomic,assign) NSInteger PagesId;
@end
