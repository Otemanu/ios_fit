//
//  QuizDataController.h
//  Fit
//
//  Created by Richard Motofuji on 12/24/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CustomerDataEngine.h"
#import "ChapterDataController.h"

// Quiz Data Controller
//	- Keeps all current quiz data in memory, provides a data interface to the various views for populating table cells, collection view cells, quiz menus, etc.
//	- Reads all quiz data (if any) from local file system on launch
//	- Handles quiz data updates from web server and from quiz view as user works on quizzes
//	- Saves all quiz data to local file system when updates are received from web server or when user works on any quiz

// Notes
//	- We get most of our quiz data from sqlite now, but this class is still useful for building the quiz menu that the user sees
//		when they tap the "Quiz" button in the chapter "read" view.
//	- The quiz data dictionary is populated from three sources of quiz data:
//		1. the locally saved dictionary of all quiz data if it exists, and / or
//		1. the Web Services engine, which sends JSON-encoded customer quiz result data (if any) to us on launch, and / or
//		2. the Quiz view, with the user's quiz results as they work on each quiz.
//	- We use a timestamp in each individual quiz dictionary (key: "date") to make sure we only store and write the most recent quiz result.
//		This prevents older quiz status data from web services from overwriting newer data in case the user has worked on quizzes offline.
//		E.g. User launches app on device A, partially completes Quiz 1, then we successfully update web services.  Everything is now in sync on device and on server.
//			User then takes Device A offline, completes Quiz 1, then brings Device A back online.  Web services sends old quiz status data when we re-connect.
//			The timestamp of the completed Quiz 1, in memory, will be more recent than the timestamp of Quiz 1 sent by web services.  We ignore the web services info.
//	- There will be obscure race conditions, e.g.:
//		Device A (offline) -> user starts Quiz 2 and finishes it.
//		Device B (offline) -> user starts Quiz 2 again, but only partially completes it.
//		Now, if and when both Device A and B connect to web services, the user will see an incomplete Quiz 2 on both devices.  Their completed Quiz 2 score will be lost.
//		This is because the incomplete Device B Quiz 2 data is more recent than the Device A Quiz 2 data, and it will propagate through web services and all devices.
//		We won't bother trying to fix this condition and other conditions like it.  Most recent update wins.  Period.

// Structure
// Top level dictionary
//		key: <chapter name>		value:	<chapter dictionary>	(a dictionary containing quiz dictionaries for each chapter)
// Chapter dictionary
//		key: <quiz name>		value: <quiz dictionary>		a dictionary containing key-value data about a specific quiz)
// Quiz dictionary
//		key: "score"			value: 0 - 100					(the user's correctness percentage for the quiz)
//		key: "duration"			value: 0 - 1,000,000			(the cumulative number of seconds the user spent on the quiz)
//		key: "date"				value: <NSDate>					(timestamp of the last time the user started working on the quiz)

@interface QuizDataController : NSObject
{
	
}

// for dashboard
@property (nonatomic, strong) NSMutableDictionary *quizDataDictionary;				// zzzzz
@property (nonatomic, strong) NSMutableArray *quizDataArray;						// quiz id, name, duration
@property (nonatomic, strong) NSMutableArray *quizPercentageArray;					// correctness and completion percentages
@property (nonatomic, strong) NSDictionary *quizPageIdDictionary;					// page IDs for each quiz ID
@property (nonatomic, strong) NSMutableDictionary *quizQuestionCountDictionary;		// number of questions per quiz ID (for performance)
@property (nonatomic, strong) NSMutableArray *quizDurationArray;					// number of seconds the user has worked on each quiz
@property (nonatomic, strong) NSIndexPath *quizCurrentIndexPath;					// zzzzz


@property float quizTotalQuestionCount;
@property float quizAnsweredQuestionCount;
@property float quizCorrectlyAnsweredQuestionCount;
@property float quizTotalCompletenessPercentage;
@property float quizTotalCorrectnessPercentage;

// for timeline
@property (nonatomic, strong) NSDictionary *quizIdByPageIdDictionary;				// key: pageId, value: quizId (NSNumber *)
@property (nonatomic, strong) NSMutableDictionary *chapterQuizScoreDictionary;		// key: pageId, value: total chapter quiz score (NSNumber *)

@property (nonatomic, strong) DataController *quizSQLiteDataController;

- (NSDictionary *)quizChapterDictionaryForChapterTitle:(NSString *)chapterTitle;
- (NSDictionary *)quizDictionaryForChapterTitle:(NSString *)chapterTitle forQuizTitle:(NSString *)quizTitle;
- (void)saveQuizDictionary:(NSDictionary *)quizDict forChapterTitle:(NSString *)chapterTitle;
- (void)saveQuizAnswerDictionary:quizAnswerDict forChapterTitle:(NSString *)chapterTitle forQuizTitle:(NSString *)quizTitle;
- (void)updateQuizDataForQuestionDict:(NSDictionary *)questionDict;
- (void)updateQuizDataArrayForQuizId:(int)quizIdToUpdateInt;

+ (QuizDataController *)sharedQuizDataController;

@end
