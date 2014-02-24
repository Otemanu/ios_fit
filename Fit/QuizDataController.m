//
//  QuizDataController.m
//  Fit
//
//  Created by Richard Motofuji on 12/24/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//

#import "QuizDataController.h"

@implementation QuizDataController

static QuizDataController *sharedController = nil;

#pragma mark - Chapter and quiz dictionary access

- (NSDictionary *)quizChapterDictionaryForChapterTitle:(NSString *)chapterTitle;
{
	return [self.quizDataDictionary valueForKey:chapterTitle];
}

- (NSDictionary *)quizDictionaryForChapterTitle:(NSString *)chapterTitle forQuizTitle:(NSString *)quizTitle;
{
	NSDictionary *quizDict = nil;
	NSDictionary *chapterDict = [self.quizDataDictionary valueForKey:chapterTitle];
	
	if (chapterDict)
		quizDict = [chapterDict valueForKey:quizTitle];
	
	return quizDict;
}

- (void)saveQuizDictionary:(NSDictionary *)quizDict forChapterTitle:(NSString *)chapterTitle;
{
	BOOL added = [self addQuizDictionaryIfNecessary:quizDict forChapterTitle:chapterTitle];
	
	if (added)
		[[CustomerDataEngine customerDataEngine] writeQuizDataDictionaryToLocalFilesystem:self.quizDataDictionary];
}

- (BOOL)addQuizDictionaryIfNecessary:(NSDictionary *)quizDict forChapterTitle:(NSString *)chapterTitle
{
	NSString *quizTitle = quizDict[@"title"];
	NSNumber *quizOrdinal = quizDict[@"ordinal"];
	
	if (quizTitle == nil || quizOrdinal == nil)
		return NO;
	
	BOOL added = NO;
	NSDictionary *existingDict = [self quizDictionaryForChapterTitle:chapterTitle forQuizTitle:quizTitle];

	if (existingDict == nil)
		added = [self addNewQuizDictionary:quizDict forChapterTitle:chapterTitle];
	
	return added;
}

- (BOOL)addNewQuizDictionary:(NSDictionary *)quizDict forChapterTitle:(NSString *)chapterTitle
{
	NSMutableDictionary *chapterDict = [[self quizChapterDictionaryForChapterTitle:chapterTitle] mutableCopy];
	
	if (chapterDict == nil)
		chapterDict = [[NSMutableDictionary alloc] initWithCapacity:0];
	
	[chapterDict setObject:[[NSMutableDictionary alloc] init] forKey:quizDict[@"title"]];		// create a new, empty dictionary for quiz score
	[self.quizDataDictionary setObject:chapterDict forKey:chapterTitle];
	return YES;
}

- (void)saveQuizAnswerDictionary:(NSDictionary *)quizAnswerDict forChapterTitle:(NSString *)chapterTitle forQuizTitle:(NSString *)quizTitle;
{
	// note: the quiz data dictionary is populated on launch from a dictionary saved to local file system.
	// if this is the first launch, the dictionary has been populated by parsing the quiz page javascript and inserting empty dictionaries for chapters and quizzes.
	// therefore there is no need to check whether the chapter or problem set dictionaries are nil.  they are already there.
	
	NSMutableDictionary *chapterMutableDict = [self.quizDataDictionary objectForKey:chapterTitle];
	NSMutableDictionary *quizMutableDict = [chapterMutableDict objectForKey:quizTitle];
	[quizMutableDict setObject:quizAnswerDict forKey:[quizAnswerDict objectForKey:@"questionId"]];
	[[CustomerDataEngine customerDataEngine] writeQuizDataDictionaryToLocalFilesystem:self.quizDataDictionary];
}

#pragma mark - Updating data

// note: we update the quiz array and percentage numbers immediately after the user answers questions.
// we used to populate arrays and generate percentages in its viewWillAppear: method,
// which was fine with small amounts of quiz data, but is too slow with large numbers of quizzes and/or questions.
// doing quiz statistics updates in the background maintains UI responsiveness.
// a simple mutex lock should be enough, because quiz data updates happen at leisurely intervals as the user answers questions.
// and only Dashboard and Timeline ever need to look at quiz data, and never concurrently.
// (and the reason why we put the arrays in a separate controller from Dashboard and Timeline is so we can update the quiz data
// while Dashboard and Timeline aren't even instantiated.  user can answer quiz questions without ever opening Dashboard or Timeline.)

- (void)updateQuizDataForQuestionDict:(NSDictionary *)questionDict;
{
	int quizIdToUpdateInt = [questionDict[@"quizId"] intValue];
	[self updateQuizDataArrayForQuizId:quizIdToUpdateInt];
	[self updateQuizTotalPercentages];
	[self updateQuizPercentageForQuizIdInt:quizIdToUpdateInt];
	[self populateChapterQuizScoreDictionary];
}

- (void)updateQuizDataArrayForQuizId:(int)quizIdToUpdateInt;
{
	int quizIdInt = (-1);
	int arrayIndex = (-1);
	
	while (++arrayIndex < self.quizDataArray.count)
	{
		NSDictionary *quizDict = self.quizDataArray[arrayIndex];
		quizIdInt = [quizDict[@"quizId"] intValue];
		
		if (quizIdToUpdateInt == quizIdInt)
			break;
	}
	
	if (quizIdToUpdateInt == quizIdInt)					// just fetch the dictionary for the one row for the current quiz id, and update the array with that new dictionary
	{
		NSDictionary *quizDataDict = [self.quizSQLiteDataController getQuizDataDictionaryForQuizId:quizIdInt];
		[self.quizDataArray removeObjectAtIndex:arrayIndex];
		[self.quizDataArray insertObject:quizDataDict atIndex:arrayIndex];
	}
}

- (void)updateQuizTotalPercentages
{
	int answerInt = [self.quizSQLiteDataController getAnsweredQuestionCount];
	int correctInt = [self.quizSQLiteDataController getCorrectlyAnsweredQuestionCount];
	
	double completenessDouble = (double)answerInt / (double)self.quizTotalQuestionCount * 100.0f;
	self.quizTotalCompletenessPercentage = (int)round(completenessDouble);
	
	double correctnessDouble = 0.0f;
	
	if (answerInt > 0)
		correctnessDouble = (double)correctInt / (double)answerInt * 100.0f;

	self.quizTotalCorrectnessPercentage = (int)round(correctnessDouble);
}

- (void)updateQuizPercentageForQuizIdInt:(int)quizIdToUpdateInt
{
	for (NSDictionary *quizDict in self.quizDataArray)
	{
		NSNumber *quizIdNum = quizDict[@"quizId"];
		int quizIdInt = quizIdNum.intValue;
		
		if (quizIdToUpdateInt == quizIdInt)
		{
			int arrayIndex = [self.quizDataArray indexOfObject:quizDict];
			[self.quizPercentageArray removeObjectAtIndex:arrayIndex];
			
			int quizQuestionCount = [self.quizQuestionCountDictionary[quizIdNum.stringValue] intValue];
			int quizAnsweredQuestionCount = [self.quizSQLiteDataController getAnsweredQuestionCountForQuizId:quizIdInt];
			int quizCorrectlyAnsweredQuestionCount = [self.quizSQLiteDataController getCorrectlyAnsweredQuestionCountForQuizId:quizIdInt];
			double completenessPercentageDouble = 0.0f;
			double correctnessPercentageDouble = 0.0f;
			
			if (quizQuestionCount > 0)
				completenessPercentageDouble = (double)quizAnsweredQuestionCount / (double)quizQuestionCount * 100.0f;
			
			if (quizAnsweredQuestionCount > 0)
				correctnessPercentageDouble = (double)quizCorrectlyAnsweredQuestionCount / (double)quizAnsweredQuestionCount * 100.0f;
			
			NSNumber *completenessPercentageNumber = [NSNumber numberWithInt:(int)round(completenessPercentageDouble)];
			NSNumber *correctnessPercentageNumber = [NSNumber numberWithInt:(int)round(correctnessPercentageDouble)];
			[self.quizPercentageArray insertObject:[NSDictionary dictionaryWithObjectsAndKeys:
													completenessPercentageNumber, @"completeness",
													correctnessPercentageNumber, @"correctness",
													nil]
										   atIndex:(NSUInteger)arrayIndex];
		}
	}
}

#pragma mark - Notifications

- (void) registerForNotifications
{
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(resetAllQuizAndProgressData)
												 name:@"resetAllQuizAndProgressData"
											   object:nil];
}

#pragma mark - Resetting data

- (void)resetAllQuizAndProgressData
{
	[self populateQuizDataArray];
	[self updateQuizTotalPercentages];
	[self populateQuizPercentageArray];
	[self populateChapterQuizScoreDictionary];
}

#pragma mark - Initialization

+ (QuizDataController *)sharedQuizDataController;
{
    @synchronized(self)
	{
        if (sharedController == nil)
            sharedController = [[self alloc] init];
    }
	
    return sharedController;
}

+ (id)allocWithZone:(NSZone *)zone;
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

- (id)copyWithZone:(NSZone *)zone;
{
    return self;
}

- (id)init
{
	self = [super init];
	[self initDataController];
	[self initQuizData];
	[self initQuestionCountDictionary];
	[self initQuizNumbers];
	[self initQuizPercentageArray];
	[self initQuizIdByPageIdDictionary];
	[self initChapterQuizScoreDictionary];
	[self registerForNotifications];
	return self;
}

- (void)initQuizData
{
	// zzzzz do we really need quizDataDictionary for anything?
	self.quizDataDictionary = [[[CustomerDataEngine customerDataEngine] readQuizDataDictionaryFromLocalFilesystem] mutableCopy];
	self.quizPageIdDictionary = [self.quizSQLiteDataController dictionaryOfPageInstanceIdsByQuizIds];
	self.quizDataArray = [[NSMutableArray alloc] initWithCapacity:0];
	[self populateQuizDataArray];
}

- (void)populateQuizDataArray
{
	[self.quizDataArray removeAllObjects];
	[self.quizSQLiteDataController populateArrayWithAllQuizInfo:self.quizDataArray];
}

- (void)initQuizNumbers
{
	self.quizTotalQuestionCount = [self.quizSQLiteDataController getTotalQuestionCount];
	[self updateQuizTotalPercentages];
}


- (void)initQuizPercentageArray
{
	self.quizPercentageArray = [[NSMutableArray alloc] initWithCapacity:0];
	[self populateQuizPercentageArray];
}

- (void)populateQuizPercentageArray
{
	[self.quizPercentageArray removeAllObjects];
	
	for (NSDictionary *quizDict in self.quizDataArray)
	{
		NSNumber *quizIdNum = quizDict[@"quizId"];
		int quizQuestionCountInt = [self.quizQuestionCountDictionary[quizIdNum.stringValue] intValue];
		int quizAnsweredQuestionCountInt = [self.quizSQLiteDataController getAnsweredQuestionCountForQuizId:quizIdNum.intValue];
		int quizCorrectlyAnsweredQuestionCountInt = [self.quizSQLiteDataController getCorrectlyAnsweredQuestionCountForQuizId:quizIdNum.intValue];
		
		double completenessPercentageDouble = 0.0f;
		double correctnessPercentageDouble = 0.0f;
		
		if (quizQuestionCountInt > 0)
			completenessPercentageDouble = (double)quizAnsweredQuestionCountInt / (double)quizQuestionCountInt * 100.0f;
		
		if (quizAnsweredQuestionCountInt > 0)
			correctnessPercentageDouble = (double)quizCorrectlyAnsweredQuestionCountInt / (double)quizAnsweredQuestionCountInt * 100.0f;
		
		NSNumber *completenessPercentageNumber = [NSNumber numberWithInt:(int)round(completenessPercentageDouble)];
		NSNumber *correctnessPercentageNumber = [NSNumber numberWithInt:(int)round(correctnessPercentageDouble)];
		
		[self.quizPercentageArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:
											 completenessPercentageNumber, @"completeness",
											 correctnessPercentageNumber, @"correctness",
											 nil]];
	}
}

- (void)initQuestionCountDictionary
{
	self.quizQuestionCountDictionary = [[NSMutableDictionary alloc] initWithCapacity:0];
	
	for (NSDictionary *quizDict in self.quizDataArray)
	{
		NSNumber *quizIdNum = quizDict[@"quizId"];
		int quizQuestionCount = [self.quizSQLiteDataController getQuestionCountForQuizId:quizIdNum.intValue];
		[self.quizQuestionCountDictionary setObject:[NSNumber numberWithInt:quizQuestionCount] forKey:quizIdNum.stringValue];
	}
}

- (void)initDataController
{
	self.quizSQLiteDataController = [DataController sharedController];
}

- (void)initQuizIdByPageIdDictionary
{
	self.quizIdByPageIdDictionary = [self.quizSQLiteDataController dictionaryOfQuizIdsByPageInstanceId];
}

- (void)initChapterQuizScoreDictionary
{
	self.chapterQuizScoreDictionary = [[NSMutableDictionary alloc] initWithCapacity:0];
	[self populateChapterQuizScoreDictionary];
}

- (void)populateChapterQuizScoreDictionary
{
	[self.chapterQuizScoreDictionary removeAllObjects];

	NSArray *allPageIdKeys = [self.quizIdByPageIdDictionary allKeys];
	
	for (NSString *pageIdKey in allPageIdKeys)
	{
		NSArray *quizIdArray = self.quizIdByPageIdDictionary[pageIdKey];
		int quizQuestionCount = 0, quizAnsweredQuestionCount = 0, quizCorrectlyAnsweredQuestionCount = 0;
		
		for (NSNumber *quizIdNumber in quizIdArray)
		{
			int quizIdInt = quizIdNumber.intValue;
			quizQuestionCount += [self.quizSQLiteDataController getQuestionCountForQuizId:quizIdInt];
			quizAnsweredQuestionCount += [self.quizSQLiteDataController getAnsweredQuestionCountForQuizId:quizIdInt];
			quizCorrectlyAnsweredQuestionCount += [self.quizSQLiteDataController getCorrectlyAnsweredQuestionCountForQuizId:quizIdInt];
		}
		
		if (quizAnsweredQuestionCount > 0)						// only show the quiz correctness number if the user has actually tried answering questions
		{
			double completionPercentageDouble = 0.0f;
			double correctnessPercentageDouble = 0.0f;
			
			if (quizQuestionCount > 0)
				completionPercentageDouble = (double)quizAnsweredQuestionCount / (double)quizQuestionCount * 100.0f;
			
			if (quizAnsweredQuestionCount > 0)
				correctnessPercentageDouble = (double)quizCorrectlyAnsweredQuestionCount / (double)quizAnsweredQuestionCount * 100.0f;
			
			NSNumber *correctnessPercentageNumber = [NSNumber numberWithInt:(int)round(correctnessPercentageDouble)];
			[self.chapterQuizScoreDictionary setValue:correctnessPercentageNumber forKey:pageIdKey];
		}
	}
}

@end
