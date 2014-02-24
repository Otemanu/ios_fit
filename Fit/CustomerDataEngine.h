//
//  CustomerDataEngine.h
//  Fit
//
//  Created by Richard Motofuji on 12/3/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DataController.h"

@interface CustomerDataEngine : NSObject

@property (nonatomic, strong) NSString *customerName;
@property (nonatomic, strong) UIImage *customerAvatarImage;

- (NSString *)getCustomerName;

- (void)saveAvatarImageToLocalFilesystem;
- (void)removeAvatarImageFromLocalFilesystem;
- (UIImage *)readAvatarImageFromLocalFilesystem;
- (NSDictionary *)readQuizDataDictionaryFromLocalFilesystem;
- (BOOL)writeQuizDataDictionaryToLocalFilesystem:(NSDictionary *)quizDataDictionary;
- (NSMutableArray *)readJournalPhotoDataFromLocalFilesystem;
- (BOOL)writeJournalPhotoDataToLocalFilesystem:(NSArray *)journalThumbnails;
+ (id)customerDataEngine;

@end
