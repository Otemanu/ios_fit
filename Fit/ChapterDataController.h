//
//  ChapterDataController.h
//  Fit
//
//  Created by Rich on 12/20/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ChapterDataController : NSObject
{
    
}

@property (nonatomic, strong) NSMutableArray *chapterDataTitleArray;
@property (nonatomic, strong) NSMutableArray *chapterDataSectionArray;

- (void)populateSectionArray;
- (void)populateChapterArray;
- (PageInstance *)pageInstanceForPageInstanceId:(NSInteger)pageInstanceId;
- (PageInstance *)pageInstanceForIndexPath:(NSIndexPath *)indexPath;
- (NSArray *)sectionArrayForIndex:(NSInteger)index;
- (int)getChapterCurrentProgressForIndexPath:(NSIndexPath *)chapterIndexPath;
- (int)getChapterMaxProgressForIndexPath:(NSIndexPath *)chapterIndexPath;
-(NSMutableArray *) getAllChaptersContent;
+ (ChapterDataController *)sharedChapterDataController;

@end
