//
//  PageInstance.h
//  MinarvaFrameworkTest
//
//  Created by Pratap Shaik on 9/20/12.
//  Copyright (c) 2012 mmotio. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PageInstance : NSObject
@property(nonatomic,assign) NSInteger PageInstanceId;
@property(nonatomic,assign) NSInteger OrderNum;
@property(nonatomic,strong) NSString *Title;
@property(nonatomic,strong) NSString *Image;
@property(nonatomic,strong) NSString *Intro;
@property(nonatomic,strong) NSString *Html;
@property(nonatomic,strong) NSString *Date;
@property(nonatomic,assign) NSInteger PagesId;
@property(nonatomic,assign) NSInteger Bookmark;
@property(nonatomic,assign) NSInteger Recent,hasAudio;
@property(nonatomic,strong) NSString *fileName,*extra;
@end
