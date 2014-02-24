//
//  DataController.h
//  MemoryTics
//
//  Created by pavan mandhani on 8/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PageInstance.h"
#import "CustomerJson.h"
#import <sqlite3.h>

@interface DataController : NSObject
{
    
}
@property(nonatomic,strong)  NSMutableArray *categoriesArray;
@property(nonatomic,strong)  NSMutableArray *getCantentDetails;
@property(nonatomic,strong)  NSMutableArray *getSections;
@property(nonatomic,strong)  NSMutableArray *getSectionsPages;
@property(nonatomic,strong)  NSMutableArray *searchresults,*favIds;
+ (id)allocWithZone:(NSZone *)zone;
- (id)copyWithZone:(NSZone *)zone;

+ (DataController*)sharedController;

//get MainCategory List
-(NSMutableArray *)getMainCategoryList;
//getSections
-(NSMutableArray *)getSectionsList;
//get Pages List based on Sections
-(NSMutableArray *)getChapterReadPercentageForTagId:(NSInteger)tagIdInt forOrderNum:(NSInteger)orderNumInt;
-(NSMutableArray *)getChapterReadPercentageForPageInstanceId:(NSInteger)pageInstanceId;
-(void)populateChapterProgressArray:(NSMutableArray *)chapterProgressArray;
-(int)getAverageMaxReadPercentage;
-(void)saveChapterReadPercentage:(NSDictionary *)completionDict forPageInstanceId:(NSInteger)tagsIdInt;
- (void)resetAllProgress;
- (void)saveQuestionResultForDictionary:(NSDictionary *)questionDict forQuizId:(int)quizIdInt;
- (void)saveQuestionResultToDatabaseIfNecessary:(NSDictionary *)questionDict forQuizId:(int)quizIdInt;

-(NSMutableArray *)getPagesListForTagid:(NSInteger)tagid;
-(NSMutableArray *)getCountsOfTotalPages:(NSInteger)pageid tagsid:(NSInteger)tagid;
//get search list
//set bookmark
-(void)bookMarkText:(NSInteger)pageid;
//remove bookmark
-(void)removebookMarkText:(NSInteger)pageid;
//getAdvanced Search
-(NSMutableArray*)getAdvancedSearchList:(NSString*)searchText;
-(NSDictionary *)tagID:(NSInteger)pageid;
-(NSMutableArray *)getFavorites:(int)noOfRecords;
-(NSString *)getFavoritesCount;
-(NSMutableArray *)getPageHtmls:(NSInteger)pageid tagsid:(NSInteger)tagid limit:(int)noOfRecords;
-(NSString *)getRecentCount;
-(NSMutableArray *)getRecents:(int)noOfRecords;
-(NSString *)title;
-(void)sethistory:(NSInteger)pageid;
-(void)deleteallRecents:(NSString *)tableName;
-(NSString *)getpagesCount;
-(NSInteger)RecordBookID;
-(NSMutableDictionary *)getInfo;
-(NSMutableArray *)getTotalTime;
-(int) isRecordBookAvailable;
// -(NSMutableDictionary *)getInfo_rb;	// not used any more
-(NSMutableArray *)getSearchResults:(NSMutableArray *)ids;
-(int)isRecoredbook;
-(NSMutableArray *)getPageHtmlsForDetailedPage:(NSInteger)pageid tagsid:(NSInteger)tagid limit:(int)noOfRecords;
-(void)updateDatabase:(int)pageInstanceId htmlString:(NSString *)htmlString;
-(NSString *) getFileNameForChapterId:(NSString *)chapterId;
-(void) updateIsActivateStateForAppId:(NSString *)appId;
-(NSString *)getInAppsCount;
-(NSString *) isExtraForPageInstance:(NSInteger) pageInstanceId;
-(NSInteger) hasAudioForInstance:(NSInteger) pageInstanceId;
-(PageInstance *) getElementsForPageInstance:(NSInteger) pageInstanceId;
-(void)saveCardInDatabaseWithString:(NSString *)card pageInstanceIdInteger:(NSInteger)pageInstanceIdInteger;
-(void)saveCardInDatabaseWithString:(NSString *)cardString pageInstanceIdInteger:(NSInteger)pageInstanceIdInteger timeStampLongLong:(long long)timeStampLongLong mongoIdString:(NSString *)mongoIdString;
-(NSMutableArray *) getAllCardsFromDatabase;
-(void) deleteCardFromDatabaseForTimeStamp:(long long)timeStamp;
-(void)saveCustomerInfoInDatabaseWithDictionary:(NSDictionary *)customerDictionary;		// deprecated
-(void)saveCustomerInfoInDatabaseWithCustomerJson:(CustomerJson *)customerJson;
-(NSDictionary *)customerInfoDictionary;
-(BOOL)customerInfoExistsInDatabase;
- (void)deleteExistingCustomerInfoIfNecessary;
- (NSString *)getQuizJsonForQuizId:(int)quizIdInt;
- (int)getCurrentQuizSecondsForQuizId:(int)quizIdInt;
- (void)updateSecondsCount:(int)addedSecondsInt forQuizId:(int)quizIdInt;
- (int)getTotalQuestionCount;
- (int)getAnsweredQuestionCount;
- (int)getCorrectlyAnsweredQuestionCount;
- (int)getQuizCount;
- (void)populateArrayWithAllQuizInfo:(NSMutableArray *)quizInfoArray;
- (int)getQuestionCountForQuizId:(int)quizIdInt;
- (int)getAnsweredQuestionCountForQuizId:(int)quizIdInt;
- (int)getCorrectlyAnsweredQuestionCountForQuizId:(int)quizIdInt;
- (NSDictionary *)getQuizDataDictionaryForQuizId:(int)quizIdInt;
- (NSDictionary *)dictionaryOfQuizIdsByPageInstanceId;
- (NSDictionary *)dictionaryOfPageInstanceIdsByQuizIds;

@end
