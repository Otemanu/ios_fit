//
//  ChapterDataController.m
//  Fit
//
//  Created by Rich on 12/20/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//

#import "ChapterDataController.h"
#import "PageSections.h"

@implementation ChapterDataController

static ChapterDataController *sharedController = nil;

#pragma mark - Initialization 

+ (ChapterDataController *)sharedChapterDataController
{
    @synchronized(self)
	{
        if (sharedController == nil)
            sharedController = [[self alloc] init]; // assignment not done here
    }

    return sharedController;
}

+ (id)allocWithZone:(NSZone *)zone
{
    @synchronized(self)
	{
        if (sharedController == nil)
		{
            sharedController = [super allocWithZone:zone];
            return sharedController;  // assignment and return on first allocation
        }
    }
	
    return nil; //on subsequent allocation attempts return nil
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (id)init
{
	self = [super init];
	return self;
}

- (void)populateSectionArray
{
	if (self.chapterDataSectionArray == nil)
		self.chapterDataSectionArray = [NSMutableArray arrayWithCapacity:0];
	else
		[self.chapterDataSectionArray removeAllObjects];
	
	NSMutableArray *dataSectionArray = [[DataController sharedController] getSectionsList];
	[self.chapterDataSectionArray addObjectsFromArray:dataSectionArray];
}

- (void)populateChapterArray
{
	if (self.chapterDataTitleArray == nil)
		self.chapterDataTitleArray = [NSMutableArray arrayWithCapacity:0];
	else
		[self.chapterDataTitleArray removeAllObjects];
	
    for (PageSections *pageSection in self.chapterDataSectionArray)
	{
        NSMutableArray *sectionChaptersArray = [[DataController sharedController] getPagesListForTagid:pageSection.TagsId];
        [self.chapterDataTitleArray addObject:sectionChaptersArray];
    }
}

- (PageInstance *)pageInstanceForPageInstanceId:(NSInteger)pageInstanceId;
{
	PageInstance *pageInstance = nil;
	
	for (int sectionIndex = 0; sectionIndex < self.chapterDataTitleArray.count; sectionIndex++)
	{
		NSArray *sectionArray = [self sectionArrayForIndex:sectionIndex];
		
		for (PageInstance *pInstance in sectionArray)
		{
			if (pInstance.PageInstanceId == pageInstanceId)
			{
				pageInstance = pInstance;
				break;
			}
		}
	}
	
	return pageInstance;
}

-(NSMutableArray *) getAllChaptersContent
{
    NSMutableArray *contentArray = [[NSMutableArray alloc] init];
    for (int index = 0; index < self.chapterDataSectionArray.count ; index++) {
        [contentArray addObjectsFromArray:[[self sectionArrayForIndex:index] mutableCopy]];
    }
    return contentArray;
}

- (PageInstance *)pageInstanceForIndexPath:(NSIndexPath *)indexPath;
{
	return [[self.chapterDataTitleArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
}

- (NSArray *)sectionArrayForIndex:(NSInteger)index;
{
	return [self.chapterDataTitleArray objectAtIndex:index];
}

- (int)getChapterCurrentProgressForIndexPath:(NSIndexPath *)chapterIndexPath;
{
	int curProgressInt = 0;
	NSDictionary *progressDict = [self currentChapterProgressDictForIndexPath:chapterIndexPath];
	
	if (progressDict)
		curProgressInt = [[progressDict valueForKey:@"currentPercentage"] intValue];
	
	return curProgressInt;
}

- (int)getChapterMaxProgressForIndexPath:(NSIndexPath *)chapterIndexPath;
{
	int maxProgressInt = 0;
	NSDictionary *progressDict = [self currentChapterProgressDictForIndexPath:chapterIndexPath];
	
	if (progressDict)
		maxProgressInt = [[progressDict valueForKey:@"maxPercentage"] intValue];
	
	return maxProgressInt;
}

- (NSDictionary *)currentChapterProgressDictForIndexPath:(NSIndexPath *)chapterIndexPath
{
	NSDictionary *progressDict = nil;
	NSArray *chaptersArray = [self sectionArrayForIndex:chapterIndexPath.section];
    PageInstance *pageInstance = [chaptersArray objectAtIndex:chapterIndexPath.row];
	NSMutableArray *sectionProgressArray = [[DataController sharedController] getChapterReadPercentageForPageInstanceId:pageInstance.PageInstanceId];
	
	if (sectionProgressArray && sectionProgressArray.count > 0)
		progressDict = [sectionProgressArray objectAtIndex:0];
	
	return progressDict;
}

@end
