//
//  DataController.m
//  MemoryTics
//
//  Created by pratap shaik on 8/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DataController.h"
#import "Pages.h"
#import "PageInstance.h"
#import "PageSections.h"
#import "Card.h"

@implementation DataController

@synthesize categoriesArray,getCantentDetails,getSections,getSectionsPages,searchresults;
@synthesize favIds;

static DataController *sharedDataController = nil;

+ (DataController*)sharedController {
    @synchronized(self) {
        if (sharedDataController == nil) {
			
            sharedDataController = [[self alloc] init]; // assignment not done here
        }
    }
    return sharedDataController;
}

+ (id)allocWithZone:(NSZone *)zone {
    @synchronized(self) {
        if (sharedDataController == nil) {
            sharedDataController = [super allocWithZone:zone];
            return sharedDataController;  // assignment and return on first allocation
        }
    }
    return nil; //on subsequent allocation attempts return nil
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (id)init {
	self = [super init];
	return self;
}

-(sqlite3 *) getDBConnection {
	
	//Search for standard documents using NSSearchPathForDirectoriesInDomains
	//First Param = Searching the documents directory
	//Second Param = Searching the Users directory and not the System
	//Expand any tildes and identify home directories.
	sqlite3 *dbConnection;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSString *path = [documentsDirectory stringByAppendingPathComponent:[[NSUserDefaults standardUserDefaults] objectForKey:@"DatabaseName"]];
	if (sqlite3_open([path UTF8String], &dbConnection) == SQLITE_OK)
	{
        
	}
    return dbConnection;
}

-(void)updateDatabase:(int)pageInstanceId htmlString:(NSString *)htmlString
{
    sqlite3 *database = [self getDBConnection];
	
    NSString *sqlString = [NSString stringWithFormat:@"Update page_html set Html = '%@' where PageInstanceId = '%d'",htmlString,pageInstanceId];
    const char *subSQL = [sqlString UTF8String];
    sqlite3_stmt *get_con_statement;
    
    if (sqlite3_prepare_v2(database, subSQL, -1, &get_con_statement, NULL) != SQLITE_OK)
    {
        NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
    }
    else
    {
        sqlite3_step(get_con_statement);
    }
    sqlite3_finalize(get_con_statement);
    sqlite3_close(database);
}

-(NSMutableArray *)getTotalTime
{
    sqlite3 *database = [self getDBConnection];
    
    PageInstance *apageinstance;
    getSectionsPages=[[NSMutableArray alloc]init];
    
    NSString * aTitle;
    sqlite3_stmt* statement;
    NSString *query;
    
    query=[NSString stringWithFormat:@"select length from recorded_book_chapter"];
    
    const char *sql =  [query UTF8String];
    if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) != SQLITE_OK)
    {
       // NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
    }
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        apageinstance=[[PageInstance alloc]init];
        aTitle = [NSString stringWithFormat:@"%s",sqlite3_column_text(statement, 0)];
        
        apageinstance.Title=aTitle;
        
        [getSectionsPages addObject:apageinstance];
    }
    sqlite3_finalize(statement);
	sqlite3_close(database);
  	return  getSectionsPages;
}

-(NSMutableArray *) getAllCardsFromDatabase
{
    sqlite3 *database = [self getDBConnection];
    sqlite3_stmt* statement;
    NSMutableArray *cardsArray = [[NSMutableArray alloc]init];
    
    NSString *query=[NSString stringWithFormat:@"select * from flash_cards order by TimeStamp DESC"];
    const char *sql =  [query UTF8String];
    if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) != SQLITE_OK)
    {
         NSLog(@"getAllCardsFromDatabase: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
    }
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        Card *card = [[Card alloc] init];
        card.timeStamp = sqlite3_column_double(statement, 0);
        card.pageInstanceId = sqlite3_column_int(statement, 1);
        const char *cardText = (const char *) sqlite3_column_text(statement, 2);
        card.cardText = [NSString stringWithUTF8String:cardText];
        card.mongoIdString = [NSString stringWithFormat:@"%s",sqlite3_column_text(statement, 3)];
        card.deletedInt = sqlite3_column_int(statement, 4);
        [cardsArray addObject:card];
    }
    sqlite3_finalize(statement);
	sqlite3_close(database);
  	return  cardsArray;
}

-(void)saveCardInDatabaseWithString:(NSString *)card pageInstanceIdInteger:(NSInteger)pageInstanceIdInteger;
{
	sqlite3 *database = [self getDBConnection];
	sqlite3_stmt *insert_statement;
    NSDate *date = [NSDate date];
    long long timeStamp = (long long)([date timeIntervalSince1970] * 1000.0f);
	NSString* query = [NSString stringWithFormat:@"INSERT INTO flash_cards (TimeStamp,PageId,Data,Deleted) VALUES (?,?,?,?)"];
	const char *sql = [query UTF8String];

	if (sqlite3_prepare_v2(database, sql, -1, &insert_statement, nil) != SQLITE_OK)
	{
//		NSLog(@"saveCardInDatabaseWithString: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
	}
    else
    {
		int code = sqlite3_bind_int64(insert_statement, 1, timeStamp);
		code = sqlite3_bind_int(insert_statement, 2, (long)pageInstanceIdInteger);
        NSLog(@"card text utf8====%s, ===macroman===%s",[card cStringUsingEncoding:NSUTF8StringEncoding], [card cStringUsingEncoding:NSMacOSRomanStringEncoding]);
		code = sqlite3_bind_text(insert_statement, 3, [card cStringUsingEncoding:NSUTF8StringEncoding], -1, SQLITE_TRANSIENT);
		code = sqlite3_bind_int(insert_statement, 4, 0);

        int  success= sqlite3_step(insert_statement);
        if(success == SQLITE_ERROR)
        {
            NSLog(@"====error is saving====");
        }
    }
	sqlite3_finalize(insert_statement);
    sqlite3_close(database);
}

// handle new flash cards sent to us by the server (because user added new cards on one or more of their other devices)
-(void)saveCardInDatabaseWithString:(NSString *)cardString pageInstanceIdInteger:(NSInteger)pageInstanceIdInteger timeStampLongLong:(long long)timeStampLongLong mongoIdString:(NSString *)mongoIdString;
{
    sqlite3 *database = [self getDBConnection];
	sqlite3_stmt *insert_statement;
	NSString* query = [NSString stringWithFormat:@"INSERT INTO flash_cards (TimeStamp,PageId,Data,MongoId,Deleted) VALUES (%llu,%d,'%@','%@',0)",timeStampLongLong,pageInstanceIdInteger,cardString,mongoIdString];
	const char *sql = [query UTF8String];
	if (sqlite3_prepare_v2(database, sql, -1, &insert_statement, NULL) != SQLITE_OK)
	{
        NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
	}
    else
    {
        int  success= sqlite3_step(insert_statement);
        if(success == SQLITE_ERROR)
        {
            NSLog(@"====error is saving====");
        }
    }
	sqlite3_finalize(insert_statement);
    sqlite3_close(database);
}

-(void) deleteCardFromDatabaseForTimeStamp:(long long)timeStamp
{
    sqlite3 *database = [self getDBConnection];
	sqlite3_stmt *insert_statement;
	
	NSString* query = [NSString stringWithFormat:@"delete from flash_cards where TimeStamp = %llu",timeStamp];
	const char *sql = [query UTF8String];
	if (sqlite3_prepare_v2(database, sql, -1, &insert_statement, NULL) != SQLITE_OK)
	{
        NSLog(@"failed===");
	}
	int  success= sqlite3_step(insert_statement);
	sqlite3_finalize(insert_statement);
	if(success == SQLITE_ERROR)
	{
        
	}
    sqlite3_close(database);
}


-(void)saveCustomerInfoInDatabaseWithCustomerJson:(CustomerJson *)customerJson;
{
	if (customerJson == nil)
		return;
	
	if (customerJson.nameString == nil || customerJson.nameString.length == 0 || customerJson.typeString == nil || customerJson.typeString.length == 0)
		return;
	
    sqlite3 *database = [self getDBConnection];
	sqlite3_stmt *insert_statement;
	NSString* query = [NSString stringWithFormat:@"INSERT INTO customer (Name,Type,MobiId,HaveAvatar) VALUES ('%@','%@','%@',%d)",
					   customerJson.nameString,
					   customerJson.typeString,
					   [NSNumber numberWithInt:customerJson.mobiIdInteger],
					   customerJson.haveAvatarInteger];
	const char *sql = [query UTF8String];
	if (sqlite3_prepare_v2(database, sql, -1, &insert_statement, NULL) != SQLITE_OK)
	{
        
	}
    else
    {
        int  success= sqlite3_step(insert_statement);
        if(success == SQLITE_ERROR)
        {
            NSLog(@"====error is saving====");
        }
    }
	sqlite3_finalize(insert_statement);
    sqlite3_close(database);
}

// deprecated.  use saveCustomerInfoInDatabaseWithCustomerJson: from now on.
- (void)saveCustomerInfoInDatabaseWithDictionary:(NSDictionary *)customerDictionary
{
	NSString *customerNameString = nil, *customerTypeString = nil;
	NSNumber *customerMobiIdNumber = nil;
	BOOL customerHaveAvatarNumber = NO;
	
	if (customerDictionary)
	{
		customerNameString = customerDictionary[@"name"];
		customerTypeString = customerDictionary[@"type"];
		customerMobiIdNumber = customerDictionary[@"mobiId"];
		customerHaveAvatarNumber = (customerDictionary[@"haveAvatar"] != nil);
	}

	if (!customerNameString || !customerTypeString || !customerMobiIdNumber || !customerHaveAvatarNumber)
		return;
	
    sqlite3 *database = [self getDBConnection];
	sqlite3_stmt *insert_statement;
	NSString* query = [NSString stringWithFormat:@"INSERT INTO customer (Name,Type,MobiId,HaveAvatar) VALUES ('%@','%@','%@',%d)",customerNameString,customerTypeString,customerMobiIdNumber,customerHaveAvatarNumber];
	const char *sql = [query UTF8String];
	if (sqlite3_prepare_v2(database, sql, -1, &insert_statement, NULL) != SQLITE_OK)
	{
        
	}
    else
    {
        int  success= sqlite3_step(insert_statement);
        if(success == SQLITE_ERROR)
        {
            NSLog(@"====error is saving====");
        }
    }
	sqlite3_finalize(insert_statement);
    sqlite3_close(database);
}

- (void)deleteExistingCustomerInfoIfNecessary
{
    sqlite3 *database = [self getDBConnection];
	sqlite3_stmt *insert_statement;
	
	NSString* query = [NSString stringWithFormat:@"delete from customer"];
	const char *sql = [query UTF8String];
	if (sqlite3_prepare_v2(database, sql, -1, &insert_statement, NULL) != SQLITE_OK)
	{
        
	}
	int  success= sqlite3_step(insert_statement);
	sqlite3_finalize(insert_statement);
	if(success == SQLITE_ERROR)
	{
        
	}
    sqlite3_close(database);
}

- (BOOL)customerInfoExistsInDatabase
{
	BOOL exists = NO;
	sqlite3 *database = [self getDBConnection];
    sqlite3_stmt* statement;
    
    NSString *query=[NSString stringWithFormat:@"select * from customer"];
    const char *sql =  [query UTF8String];
    if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) != SQLITE_OK)
    {
        // NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
    }

    if (sqlite3_step(statement) == SQLITE_ROW)
        exists = YES;

    sqlite3_finalize(statement);
	sqlite3_close(database);
	return exists;
}

-(NSDictionary *)customerInfoDictionary
{
	NSMutableDictionary *customerInfoDict = [[NSMutableDictionary alloc] initWithCapacity:0];
	sqlite3 *database = [self getDBConnection];
    sqlite3_stmt* statement;
    
    NSString *query=[NSString stringWithFormat:@"select * from customer"];
    const char *sql =  [query UTF8String];
    if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) != SQLITE_OK)
    {
        // NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
    }

    if (sqlite3_step(statement) == SQLITE_ROW)
    {
		if(sqlite3_column_text(statement,0)!=NULL)
            [customerInfoDict setObject:[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement,0)] forKey:@"haveAvatar"];
        if(sqlite3_column_text(statement,1)!=NULL)
            [customerInfoDict setObject:[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement,1)] forKey:@"name"];
        if(sqlite3_column_text(statement,2)!=NULL)
            [customerInfoDict setObject:[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement,2)] forKey:@"type"];
        if(sqlite3_column_text(statement,3)!=NULL)
            [customerInfoDict setObject:[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement,3)] forKey:@"mobiId"];
    }
    sqlite3_finalize(statement);
	sqlite3_close(database);
	return customerInfoDict;
}

-(void) updateIsActivateStateForAppId:(NSString *)appId
{
    sqlite3 *database = [self getDBConnection];
    sqlite3_stmt* statement;
    NSString *query=[NSString stringWithFormat:@"Update Pages Set isActivated = 1 where appId = '%@'",appId];
    const char *sql =  [query UTF8String];
    if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) != SQLITE_OK)
    {
        NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
    }
    else
    {
        if (sqlite3_step(statement)) {
        }
    }
    sqlite3_finalize(statement);
    sqlite3_close(database);
}

-(int)isRecoredbook{
    
    int key;
	sqlite3_stmt *statement;
	sqlite3 *database = [self getDBConnection];
	NSString* query = @"SELECT count(*) FROM sqlite_master WHERE type='table' AND name='recorded_book'";
    
	const char *sql = [query UTF8String];
    
	if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) != SQLITE_OK)
	{
		NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
	}
	while (sqlite3_step(statement) == SQLITE_ROW)
	{
        key = sqlite3_column_int(statement, 0);
	}
    sqlite3_finalize(statement);
    sqlite3_close(database);
	return key;
}

-(int) isRecordBookAvailable
{
    sqlite3 *database = [self getDBConnection];
    //PagesId, Name, OrderNum
    sqlite3_stmt* statement;
    NSString *query=@"SELECT count(*) FROM sqlite_master WHERE type='table' AND name='recorded_book'";
    const char *sql =  [query UTF8String];
    int isRecordAvailable = 0;
    if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK)
    {
        if (sqlite3_step(statement) == SQLITE_ROW)
        {
            isRecordAvailable = sqlite3_column_int(statement, 0)   ;
        }
    }
    else
    {
        
    }
    
    sqlite3_finalize(statement);
    sqlite3_close(database);
  	return  isRecordAvailable;
}

-(NSMutableDictionary *)getInfo
{
    sqlite3 *database = [self getDBConnection];
    //PagesId, Name, OrderNum
    sqlite3_stmt* statement;
    NSMutableDictionary *tempDict = [[NSMutableDictionary alloc] init];
    NSString *query=@"Select Name,Language,Author,PublisherName,ThothId,Created,Version from title";
    const char *sql =  [query UTF8String];
    if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) != SQLITE_OK)
    {
        NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
    }
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        if(sqlite3_column_text(statement,0)!=NULL)
        {
            [tempDict setObject:[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement,0)] forKey:@"Name"];
        }
        if(sqlite3_column_text(statement,1)!=NULL)
        {
            [tempDict setObject:[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement,1)] forKey:@"Language"];
        }
        if(sqlite3_column_text(statement,2)!=NULL)
        {
            [tempDict setObject:[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement,2)] forKey:@"Author"];
        }
        if(sqlite3_column_text(statement,3)!=NULL)
        {
            [tempDict setObject:[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement,3)] forKey:@"PublisherName"];
        }
        if(sqlite3_column_text(statement,4)!=NULL)
        {
            [tempDict setObject:[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement,4)] forKey:@"ThothId"];
        }
        if(sqlite3_column_text(statement,5)!=NULL)
        {
            [tempDict setObject:[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement,5)] forKey:@"Created"];
        }
        if(sqlite3_column_text(statement,6)!=NULL)
        {
            [tempDict setObject:[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement,6)] forKey:@"Version"];
        }
    }
    sqlite3_finalize(statement);
    sqlite3_close(database);
  	return  tempDict;
    
}

//get MainCategory List
-(NSMutableArray *)getMainCategoryList
{
    sqlite3 *database = [self getDBConnection];
    categoriesArray = [[NSMutableArray alloc]init];
    
    //PagesId, Name, OrderNum
    int aPagesId,aOrderNum,isActivated;
    NSString *aName,*aPrice,*appId;
    sqlite3_stmt* statement;
    NSString *query=@"Select PagesId, Name, OrderNum, Price, isActivated,appId from pages order by OrderNum ASC";
    const char *sql =  [query UTF8String];
    if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) != SQLITE_OK)
    {
        NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
    }
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        Pages *apages=[[Pages alloc]init];
        
        aPagesId= sqlite3_column_int(statement,0);
        if(sqlite3_column_text(statement,1)!=NULL)
        {
            aName = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement,1)];
        }
        aOrderNum= sqlite3_column_int(statement,2);
        if(sqlite3_column_text(statement,3)!=NULL)
        {
            aPrice = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement,3)];
        }
        isActivated = sqlite3_column_int(statement,4);
        if(sqlite3_column_text(statement,5)!=NULL)
        {
            appId = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement,5)];
        }
        
        apages.PagesId=aPagesId;
        apages.Name=aName;
        apages.OrderNum=aOrderNum;
        apages.isActivated = isActivated;
        apages.price = [aPrice floatValue];
        apages.appId = appId;
        [self.categoriesArray addObject:apages];
    }
    sqlite3_finalize(statement);
    sqlite3_close(database);
  	return  categoriesArray;
}

//getSections
-(NSMutableArray *)getSectionsList
{
    sqlite3 *database = [self getDBConnection];
    
    PageSections *asections;
    getSections=[[NSMutableArray alloc]init];
    
    int aTagsId;
    NSString *atag;
    sqlite3_stmt* statement;
    NSString *query=[NSString stringWithFormat:@"select TagsId, tag from tags ORDER BY orderNum ASC"];
    const char *sql =  [query UTF8String];
    if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) != SQLITE_OK)
    {
        NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
    }
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        asections=[[PageSections alloc]init];
        if(sqlite3_column_int(statement,0))
        {
            aTagsId= sqlite3_column_int(statement,0);
        }
        if(sqlite3_column_text(statement,1)!=NULL)
        {
            atag =  [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement,1)];
        }
        asections.TagsId=aTagsId;
        asections.tagName=atag;
        [getSections addObject:asections];
    }
    sqlite3_finalize(statement);
    sqlite3_close(database);
  	return  getSections;
}

-(NSMutableArray *)getChapterReadPercentageForPageInstanceId:(NSInteger)pageInstanceId;
{
    sqlite3 *database = [self getDBConnection];
    NSMutableArray *progressArray =[[NSMutableArray alloc]init];
    sqlite3_stmt* statement;
	NSString *query=[NSString stringWithFormat:@"select CurrentPercentage, MaxPercentage, LastUpdate from page_instance where PageInstanceId = %d", pageInstanceId];
	
    const char *sql =  [query UTF8String];
    if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) != SQLITE_OK)
    {
        NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
    }
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
		int curPercentageInt = sqlite3_column_int(statement,0);
		int maxPercentageInt = sqlite3_column_int(statement,1);
		long long lastUpdateLongLong = sqlite3_column_double(statement,2);
		[progressArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								  [NSNumber numberWithInt:curPercentageInt],
								  @"currentPercentage",
								  [NSNumber numberWithInt:maxPercentageInt],
								  @"maxPercentage",
								  [NSNumber numberWithLongLong:lastUpdateLongLong],
								  @"lastUpdate",
								  nil]];
    }
    sqlite3_finalize(statement);
    sqlite3_close(database);
  	return progressArray;
}

-(NSMutableArray *)getChapterReadPercentageForTagId:(NSInteger)tagIdInt forOrderNum:(NSInteger)orderNumInt;
{
    sqlite3 *database = [self getDBConnection];
    NSMutableArray *progressArray =[[NSMutableArray alloc]init];
    
    sqlite3_stmt* statement;
	NSString *query=[NSString stringWithFormat:@"select p.CurrentPercentage, p.MaxPercentage from page_instance p, page_tag t where t.TagsId='%i' and  t.PageInstanceId=p.PageInstanceId and p.OrderNum='%i' ORDER BY p.orderNum ASC",tagIdInt, orderNumInt];

    const char *sql =  [query UTF8String];
    if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) != SQLITE_OK)
    {
        NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
    }
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
		int curPercentageInt = sqlite3_column_int(statement,0);
		int maxPercentageInt = sqlite3_column_int(statement,1);
		[progressArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								  [NSNumber numberWithInt:curPercentageInt],
								  @"currentPercentage",
								  [NSNumber numberWithInt:maxPercentageInt],
								  @"maxPercentage",
								  nil]];
    }
    sqlite3_finalize(statement);
    sqlite3_close(database);
  	return progressArray;
}

-(void)populateChapterProgressArray:(NSMutableArray *)chapterProgressArray;
{
    sqlite3 *database = [self getDBConnection];
    sqlite3_stmt* statement;
	NSString *query=[NSString stringWithFormat:@"select CurrentPercentage, MaxPercentage, LastUpdate, PageInstanceId from page_instance"];
	
    const char *sql =  [query UTF8String];
    if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) != SQLITE_OK)
    {
        NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
    }
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
		int curPercentageInt = sqlite3_column_int(statement,0);
		int maxPercentageInt = sqlite3_column_int(statement,1);
		long long lastUpdateLongLong = sqlite3_column_double(statement,2);
		int pageIdInt = sqlite3_column_int(statement,3);
		[chapterProgressArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:
										 [NSNumber numberWithInt:curPercentageInt],
										  @"currentPercentage",
										  [NSNumber numberWithInt:maxPercentageInt],
										  @"maxPercentage",
										  [NSNumber numberWithLongLong:lastUpdateLongLong],
										  @"lastUpdate",
										  [NSNumber numberWithInt:pageIdInt],
										  @"pageInstanceId",
										  nil]];
    }
    sqlite3_finalize(statement);
    sqlite3_close(database);
}

-(int)getAverageMaxReadPercentage;
{
	int averageMaxReadPercentageInt = 0;
    sqlite3 *database = [self getDBConnection];
    sqlite3_stmt* statement;
	NSString *query=[NSString stringWithFormat:@"select AVG(MaxPercentage) from page_instance"];
    const char *sql =  [query UTF8String];
    
	if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) != SQLITE_OK)
    {
        NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
    }

    while (sqlite3_step(statement) == SQLITE_ROW)
    {
		averageMaxReadPercentageInt = sqlite3_column_int(statement,0);
    }
   
	sqlite3_finalize(statement);
    sqlite3_close(database);
  	return averageMaxReadPercentageInt;
}

-(void)saveChapterReadPercentage:(NSDictionary *)completionDict forPageInstanceId:(NSInteger)pageInstanceId;
{
    sqlite3 *database = [self getDBConnection];
	sqlite3_stmt *insert_statement;
    NSDate *date = [NSDate date];
    long long timeStamp = (long long)([date timeIntervalSince1970] * 1000.0f);

	int currentPercentage = [[completionDict valueForKey:@"currentPercentage"] intValue];
	int maxPercentage = [[completionDict valueForKey:@"maxPercentage"] intValue];
	
	NSString *query;

	if (maxPercentage == 100)
		query = [NSString stringWithFormat:@"UPDATE page_instance set CurrentPercentage = %d, MaxPercentage = %d, LastUpdate = %llu, DateRead = %llu where PageInstanceId = %d",
					   currentPercentage,maxPercentage,timeStamp,timeStamp,(int)pageInstanceId];
	else
		query = [NSString stringWithFormat:@"UPDATE page_instance set CurrentPercentage = %d, MaxPercentage = %d, LastUpdate = %llu where PageInstanceId = %d",
				 currentPercentage,maxPercentage,timeStamp,(int)pageInstanceId];

	const char *sql = [query UTF8String];
	if (sqlite3_prepare_v2(database, sql, -1, &insert_statement, NULL) != SQLITE_OK)
	{
        NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
	}
    else
    {
        int  success= sqlite3_step(insert_statement);
        if(success == SQLITE_ERROR)
        {
            NSLog(@"====error is saving====");
        }
    }
	sqlite3_finalize(insert_statement);
    sqlite3_close(database);
}

-(void)resetAllChapterReadPercentages;
{
    sqlite3 *database = [self getDBConnection];
	sqlite3_stmt *update_statement;
	NSString *query = [NSString stringWithFormat:@"UPDATE page_instance set CurrentPercentage = 0, MaxPercentage = 0, DateRead = NULL, LastUpdate = NULL"];
	
	const char *sql = [query UTF8String];
	if (sqlite3_prepare_v2(database, sql, -1, &update_statement, NULL) != SQLITE_OK)
	{
        NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
	}
    else
    {
        int  success= sqlite3_step(update_statement);
        if(success == SQLITE_ERROR)
        {
            NSLog(@"====error resetting chapter percentages====");
        }
    }
	sqlite3_finalize(update_statement);
    sqlite3_close(database);
}

- (void)saveQuestionResultForDictionary:(NSDictionary *)questionDict forQuizId:(int)quizIdInt;
{
	int questionIdInt = [[questionDict valueForKey:@"questionId"] intValue];
    NSDate *date = [NSDate date];
    long long timeStamp = (long long)([date timeIntervalSince1970] * 1000.0f);
	int correctInt = [[questionDict valueForKey:@"isCorrect"] isEqualToString:@"1"] ? 1 : 0;

	sqlite3 *database = [self getDBConnection];
    NSString *sqlString = [NSString stringWithFormat:@"Update question set correct = %d, answeredDate = %llu where quizId = %d and questionId = %d", correctInt, timeStamp, quizIdInt, questionIdInt];
    const char *subSQL = [sqlString UTF8String];
    sqlite3_stmt *get_con_statement;
    
    if (sqlite3_prepare_v2(database, subSQL, -1, &get_con_statement, NULL) != SQLITE_OK)
    {
        NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
    }
    else
    {
        sqlite3_step(get_con_statement);
    }
    sqlite3_finalize(get_con_statement);
    sqlite3_close(database);
}

- (void)saveQuestionResultFromServerForDictionary:(NSDictionary *)questionDict forQuizId:(int)quizIdInt forTimestamp:(long long)serverQuestionTimestamp
{
	int questionIdInt = [[questionDict valueForKey:@"questionId"] intValue];
	int correctInt = [[questionDict valueForKey:@"isCorrect"] isEqualToString:@"1"] ? 1 : 0;
	
	sqlite3 *database = [self getDBConnection];
    NSString *sqlString = [NSString stringWithFormat:@"Update question set correct = %d, answeredDate = %llu where quizId = %d and questionId = %d", correctInt, serverQuestionTimestamp, quizIdInt, questionIdInt];
    const char *subSQL = [sqlString UTF8String];
    sqlite3_stmt *get_con_statement;
    
    if (sqlite3_prepare_v2(database, subSQL, -1, &get_con_statement, NULL) != SQLITE_OK)
    {
        NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
    }
    else
    {
        sqlite3_step(get_con_statement);
    }
    sqlite3_finalize(get_con_statement);
    sqlite3_close(database);
}

// for handling quiz results sent to us by server.  only update results if server's answer timestamp is newer than sqlite's answer timestamp.
// xyzzy do we need to update the answer table too?  it has a result column.

- (void)saveQuestionResultToDatabaseIfNecessary:(NSDictionary *)questionDict forQuizId:(int)quizIdInt;
{
	NSNumber *questionId = questionDict[@"questionId"];
	sqlite3 *database = [self getDBConnection];
    sqlite3_stmt* statement;
    NSString *query=[NSString stringWithFormat:@"select answeredDate from question where quizId = %d and questionId = %d", quizIdInt, questionId.intValue];
    const char *sql = [query UTF8String];
	
	if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) != SQLITE_OK)
        NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
	
	long long localQuestionTimestamp = 0;
	
    if (sqlite3_step(statement) == SQLITE_ROW)
		localQuestionTimestamp = sqlite3_column_double(statement, 0);

    sqlite3_finalize(statement);
    sqlite3_close(database);
	
	NSNumber *serverTimestampNumber = questionDict[@"timestamp"];
	long long serverQuestionTimestamp = [serverTimestampNumber longLongValue];
	
	if (localQuestionTimestamp > 0 && serverQuestionTimestamp > localQuestionTimestamp)
	{
		int correctInt = [questionDict[@"isCorrect"] intValue];
		int questionIdInt = [questionDict[@"questionId"] intValue];
		sqlite3 *database = [self getDBConnection];
		NSString *sqlString = [NSString stringWithFormat:@"Update question set correct = %d, answeredDate = %llu where quizId = %d and questionId = %d", correctInt, serverQuestionTimestamp, quizIdInt, questionIdInt];
		const char *subSQL = [sqlString UTF8String];
		sqlite3_stmt *get_con_statement;
		
		if (sqlite3_prepare_v2(database, subSQL, -1, &get_con_statement, NULL) != SQLITE_OK)
		{
			NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
		}
		else
		{
			sqlite3_step(get_con_statement);
		}
		sqlite3_finalize(get_con_statement);
		sqlite3_close(database);
	}
}

- (int)getTotalQuestionCount;
{
    sqlite3 *database = [self getDBConnection];
    
    sqlite3_stmt* statement;
    NSString *query=[NSString stringWithFormat:@"select count(questionId) from question"];
    const char *sql =  [query UTF8String];
 
	if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) != SQLITE_OK)
        NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
	
    NSString *totalCountString = @"0";

    if (sqlite3_step(statement) == SQLITE_ROW)
        totalCountString = [NSString stringWithFormat:@"%s",sqlite3_column_text(statement, 0)];

    sqlite3_finalize(statement);
    sqlite3_close(database);
  	return  [totalCountString intValue];
}

- (int)getAnsweredQuestionCount;
{
    sqlite3 *database = [self getDBConnection];
    
    sqlite3_stmt* statement;
    NSString *query=[NSString stringWithFormat:@"select count(questionId) from question where answeredDate is not NULL"];
    const char *sql =  [query UTF8String];

    if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) != SQLITE_OK)
        NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
	
    NSString *answerCountString = @"0";
	
    if (sqlite3_step(statement) == SQLITE_ROW)
        answerCountString = [NSString stringWithFormat:@"%s",sqlite3_column_text(statement, 0)];
	
    sqlite3_finalize(statement);
    sqlite3_close(database);
  	return  [answerCountString intValue];
}

- (int)getCorrectlyAnsweredQuestionCount;
{
    sqlite3 *database = [self getDBConnection];
    
    sqlite3_stmt* statement;
    NSString *query=[NSString stringWithFormat:@"select count(questionId) from question where correct = 1"];
    const char *sql =  [query UTF8String];
	
    if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) != SQLITE_OK)
        NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
	
    NSString *correctAnswerCountString = @"0";
	
    if (sqlite3_step(statement) == SQLITE_ROW)
        correctAnswerCountString = [NSString stringWithFormat:@"%s",sqlite3_column_text(statement, 0)];
	
    sqlite3_finalize(statement);
    sqlite3_close(database);
  	return  [correctAnswerCountString intValue];
}

- (void)resetAllProgress;
{
	[self resetAllChapterReadPercentages];
	[self resetAllQuestionResults];
	[self resetAllQuizProgress];
}

- (void)resetAllQuestionResults;
{
	sqlite3 *database = [self getDBConnection];
    NSString *sqlString = [NSString stringWithFormat:@"Update question set correct = 0, answeredDate = NULL"];
    const char *subSQL = [sqlString UTF8String];
    sqlite3_stmt *update_statement;
    
    if (sqlite3_prepare_v2(database, subSQL, -1, &update_statement, NULL) != SQLITE_OK)
    {
		NSLog(@"====error resetting results====");
    }
    else
    {
        sqlite3_step(update_statement);
    }
    sqlite3_finalize(update_statement);
    sqlite3_close(database);
}

- (void)resetAllQuizProgress;
{
	sqlite3 *database = [self getDBConnection];
    NSString *sqlString = [NSString stringWithFormat:@"Update quiz set startedDate = NULL, completedDate = NULL, lastIndex = 0, lastIndexUpdate = 0, seconds = 0"];
    const char *subSQL = [sqlString UTF8String];
    sqlite3_stmt *update_statement;
    
    if (sqlite3_prepare_v2(database, subSQL, -1, &update_statement, NULL) != SQLITE_OK)
    {
		NSLog(@"====error resetting progress====");
    }
    else
    {
        sqlite3_step(update_statement);
    }
    sqlite3_finalize(update_statement);
    sqlite3_close(database);
}

-(NSString *)getInAppsCount
{
    sqlite3 *database = [self getDBConnection];
    
    sqlite3_stmt* statement;
    NSString *query=[NSString stringWithFormat:@"select Count(appId) from pages where appId IS NOT NULL"];
    const char *sql =  [query UTF8String];
    if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) != SQLITE_OK)
    {
        NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
    }
    NSString *aCount;
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        aCount = [NSString stringWithFormat:@"%s",sqlite3_column_text(statement, 0)];
    }
    sqlite3_finalize(statement);
    sqlite3_close(database);
  	return  aCount;
}

-(NSString *)getFavoritesCount
{
    sqlite3 *database = [self getDBConnection];
    
    sqlite3_stmt* statement;
    NSString *query=[NSString stringWithFormat:@"select count(*) from favorites"];
    const char *sql =  [query UTF8String];
    if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) != SQLITE_OK)
    {
        NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
    }
    NSString *aCount;
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        aCount = [NSString stringWithFormat:@"%s",sqlite3_column_text(statement, 0)];
    }
    sqlite3_finalize(statement);
    sqlite3_close(database);
  	return  aCount;
}

//get Pages List based on Sections
-(NSString *)getCountsOfTotalPages:(NSInteger)pageid tagsid:(NSInteger)tagid
{
    sqlite3 *database = [self getDBConnection];
    
    sqlite3_stmt* statement;
    NSString *query=[NSString stringWithFormat:@"select count(*) from page_instance p,page_tag t where p.PagesId='%i'  and t.TagsId='%i' and t.PageInstanceId=p.PageInstanceId",pageid,tagid];
    const char *sql =  [query UTF8String];
    if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) != SQLITE_OK)
    {
        // NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
    }
    NSString *aCount;
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        aCount = [NSString stringWithFormat:@"%s",sqlite3_column_text(statement, 0)];
    }
    sqlite3_finalize(statement);
    sqlite3_close(database);
  	return  aCount;
}

-(NSMutableArray *)getRecents:(int)noOfRecords
{
    [self getFavoritesIds];
    sqlite3 *database = [self getDBConnection];
    
    
    getSectionsPages=[[NSMutableArray alloc]init];
    
    
    sqlite3_stmt* statement;
    NSString *query;
    if (noOfRecords == 0) {
        query=[NSString stringWithFormat:@"select p.PageInstanceId,p.OrderNum,p.Title,p.Image,p.Intro,h.Html,p.Date,p.Extra,p.hasAudio from page_instance p,history f,page_html h where p.PageInstanceId=f.PageInstanceId and p.PageInstanceId=h.PageInstanceId ORDER BY f.UnixTime DESC"];
    }
    else
    {
        query=[NSString stringWithFormat:@"select p.PageInstanceId,p.OrderNum,p.Title,p.Image,p.Intro,h.Html,p.Date,p.Extra,p.hasAudio from page_instance p,history f,page_html h where p.PageInstanceId=f.PageInstanceId and p.PageInstanceId=h.PageInstanceId ORDER BY f.UnixTime DESC limit %d",noOfRecords];
    }
    const char *sql =  [query UTF8String];
    if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) != SQLITE_OK)
    {
        NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
    }
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        PageInstance *apageinstance = [[PageInstance alloc]init];
        int aPageInstanceId,aOrderNum,ahasAudio;
        NSString *aTitle,*aImage,*aIntro,*aHtml,*aDate,*aExtra;
        aPageInstanceId= sqlite3_column_int(statement,0);
        aOrderNum= sqlite3_column_int(statement,1);
        
        
        if(sqlite3_column_text(statement, 2)!=NULL)
        {
            aTitle =[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement,2)];
        }
        if(sqlite3_column_text(statement, 3)!=NULL)
        {
            aImage =[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement,3)];
        }
        if(sqlite3_column_text(statement, 4)!=NULL)
        {
            aIntro =[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement,4)];
        }
        if(sqlite3_column_text(statement, 5)!=NULL)
        {
            aHtml =[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement,5)];
        }
        if(sqlite3_column_text(statement, 6)!=NULL)
        {
            aDate =[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement,6)];
        }
        if(sqlite3_column_text(statement, 7)!=NULL)
        {
            aExtra =[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement,7)];
        }
        ahasAudio = sqlite3_column_int(statement,8);
        apageinstance.PageInstanceId=aPageInstanceId;
        apageinstance.OrderNum=aOrderNum;
        apageinstance.Title=aTitle;
        apageinstance.Image=aImage;
        apageinstance.Intro=aIntro;
        apageinstance.Html=aHtml;
        apageinstance.Date=aDate;
        apageinstance.extra = aExtra;
        apageinstance.hasAudio = ahasAudio;
        if ([favIds containsObject: [NSString stringWithFormat:@"%d",aPageInstanceId]]) {
            apageinstance.Bookmark = 1;
        }
        else
        {
            apageinstance.Bookmark = 0;
        }
        [getSectionsPages addObject:apageinstance];
    }
    sqlite3_finalize(statement);
    sqlite3_close(database);
  	return  getSectionsPages;
}

-(NSString *)getRecentCount
{
    sqlite3 *database = [self getDBConnection];
    
    sqlite3_stmt* statement;
    NSString *query=[NSString stringWithFormat:@"select count(*) from history"];
    const char *sql =  [query UTF8String];
    if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) != SQLITE_OK)
    {
        NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
    }
    NSString *aCount;
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        if(sqlite3_column_text(statement, 0)!=NULL)
        {
            aCount = [NSString stringWithFormat:@"%s",sqlite3_column_text(statement, 0)];
        }
    }
    sqlite3_finalize(statement);
    sqlite3_close(database);
  	return  aCount;
}

-(void)deleteallRecents:(NSString *)tableName
{
    sqlite3 *database = [self getDBConnection];
    
    sqlite3_stmt* statement;
    NSString *query=[NSString stringWithFormat:@"DELETE FROM %@",tableName];
    const char *sql =  [query UTF8String];
    if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) != SQLITE_OK)
    {
        NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
    }
    if(SQLITE_DONE != sqlite3_step(statement))
        
    {
        
    }
    
    sqlite3_finalize(statement);
    sqlite3_close(database);
  	
}

-(NSMutableArray *)getFavorites:(int)noOfRecords
{
    sqlite3 *database = [self getDBConnection];
    getSectionsPages=[[NSMutableArray alloc]init];
    sqlite3_stmt* statement;
    NSString *query;
    if (noOfRecords == 0) {
        query=[NSString stringWithFormat:@"select p.PageInstanceId,p.OrderNum,p.Title,p.Image,p.Intro,h.Html,p.Date,p.Extra,p.hasAudio from page_instance p,favorites f,page_html h where p.PageInstanceId=f.PageInstanceId and p.PageInstanceId=h.PageInstanceId ORDER BY f.UnixTime DESC"];
    }
    else
    {
        query=[NSString stringWithFormat:@"select p.PageInstanceId,p.OrderNum,p.Title,p.Image,p.Intro,h.Html,p.Date,p.Extra,p.hasAudio from page_instance p,favorites f,page_html h where p.PageInstanceId=f.PageInstanceId and p.PageInstanceId=h.PageInstanceId ORDER BY f.UnixTime DESC limit %d",noOfRecords];
    }
    const char *sql =  [query UTF8String];
    if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) != SQLITE_OK)
    {
        NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
    }
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        PageInstance *apageinstance =[[PageInstance alloc]init];
        int aPageInstanceId,aOrderNum,ahasAudio;
        NSString *aTitle,*aImage,*aIntro,*aHtml,*aDate,*aExtra;
        aPageInstanceId= sqlite3_column_int(statement,0);
        aOrderNum= sqlite3_column_int(statement,1);
        if(sqlite3_column_text(statement, 2)!=NULL)
        {
            aTitle =[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement,2)];
        }
        if(sqlite3_column_text(statement, 3)!=NULL)
        {
            aImage =[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement,3)];
        }
        if(sqlite3_column_text(statement, 4)!=NULL)
        {
            aIntro =[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement,4)];
        }
        if(sqlite3_column_text(statement, 5)!=NULL)
        {
            aHtml =[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement,5)];
        }
        if(sqlite3_column_text(statement, 6)!=NULL)
        {
            aDate =[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement,6)];
        }
        if(sqlite3_column_text(statement, 7)!=NULL)
        {
            aExtra =[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement,7)];
        }
        ahasAudio = sqlite3_column_int(statement,8);
        apageinstance.PageInstanceId=aPageInstanceId;
        apageinstance.OrderNum=aOrderNum;
        apageinstance.Title=aTitle;
        apageinstance.Image=aImage;
        apageinstance.Intro=aIntro;
        apageinstance.Html=aHtml;
        apageinstance.Date=aDate;
        apageinstance.Bookmark=1;
        apageinstance.extra = aExtra;
        apageinstance.hasAudio = ahasAudio;
        [getSectionsPages addObject:apageinstance];
    }
    sqlite3_finalize(statement);
	sqlite3_close(database);
  	return  getSectionsPages;
}

-(NSMutableArray *)getFavorites:(int)noOfRecords isExtraAvailable:(NSString *)value
{
    sqlite3 *database = [self getDBConnection];
    getSectionsPages=[[NSMutableArray alloc]init];
    sqlite3_stmt* statement;
    NSString *query;
    if (noOfRecords == 0) {
        query=[NSString stringWithFormat:@"select p.PageInstanceId,p.OrderNum,p.Title,p.Image,p.Intro,h.Html,p.Date,p.Extra,p.hasAudio from page_instance p,favorites f,page_html h where p.PageInstanceId=f.PageInstanceId and p.PageInstanceId=h.PageInstanceId ORDER BY f.UnixTime DESC"];
    }
    else
    {
        query=[NSString stringWithFormat:@"select p.PageInstanceId,p.OrderNum,p.Title,p.Image,p.Intro,h.Html,p.Date,p.Extra,p.hasAudio from page_instance p,favorites f,page_html h where p.PageInstanceId=f.PageInstanceId and p.PageInstanceId=h.PageInstanceId ORDER BY f.UnixTime DESC limit %d",noOfRecords];
    }
    const char *sql =  [query UTF8String];
    if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) != SQLITE_OK)
    {
        NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
    }
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        PageInstance *apageinstance =[[PageInstance alloc]init];
        int aPageInstanceId,aOrderNum,ahasAudio;
        NSString *aTitle,*aImage,*aIntro,*aHtml,*aDate,*aExtra;
        aPageInstanceId= sqlite3_column_int(statement,0);
        aOrderNum= sqlite3_column_int(statement,1);
        if(sqlite3_column_text(statement, 2)!=NULL)
        {
            aTitle =[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement,2)];
        }
        if(sqlite3_column_text(statement, 3)!=NULL)
        {
            aImage =[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement,3)];
        }
        if(sqlite3_column_text(statement, 4)!=NULL)
        {
            aIntro =[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement,4)];
        }
        if(sqlite3_column_text(statement, 5)!=NULL)
        {
            aHtml =[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement,5)];
        }
        if(sqlite3_column_text(statement, 6)!=NULL)
        {
            aDate =[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement,6)];
        }
        if(sqlite3_column_text(statement, 7)!=NULL)
        {
            aExtra =[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement,7)];
        }
        ahasAudio = sqlite3_column_int(statement,8);
        apageinstance.PageInstanceId=aPageInstanceId;
        apageinstance.OrderNum=aOrderNum;
        apageinstance.Title=aTitle;
        apageinstance.Image=aImage;
        apageinstance.Intro=aIntro;
        apageinstance.Html=aHtml;
        apageinstance.Date=aDate;
        apageinstance.Bookmark=1;
        apageinstance.extra = aExtra;
        apageinstance.hasAudio = ahasAudio;
        [getSectionsPages addObject:apageinstance];
    }
    sqlite3_finalize(statement);
	sqlite3_close(database);
  	return  getSectionsPages;
}

-(NSMutableArray *)getPagesListForTagid:(NSInteger)tagid
{
    [self getFavoritesIds];
    sqlite3 *database = [self getDBConnection];
    
    getSectionsPages=[[NSMutableArray alloc]init];
    sqlite3_stmt* statement;
    NSString *query;
    query=[NSString stringWithFormat:@"select p.PageInstanceId, p.OrderNum, p.Title,p.Image,p.Intro,p.Extra,p.hasAudio,p.PagesId from page_instance p,page_tag t,page_html h where t.TagsId='%i' and  t.PageInstanceId=p.PageInstanceId and p.PageInstanceId=h.PageInstanceId ORDER BY p.orderNum ASC",tagid];
   
    const char *sql =  [query UTF8String];
    if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) != SQLITE_OK)
    {
        NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
    }
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        int aPageInstanceId,aOrderNum,hasAudio,aPagesId;
        BOOL abookmark;
        NSString *aTitle,*aImage,*aIntro,*aExtra;
        PageInstance *apageinstance = [[PageInstance alloc]init];
        
        aPageInstanceId= sqlite3_column_int(statement,0);
        aOrderNum= sqlite3_column_int(statement,1);
        if(sqlite3_column_text(statement, 2)!=NULL)
        {
            aTitle = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement,2)];
        }
        if(sqlite3_column_text(statement, 3)!=NULL)
        {
            aImage = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement,3)];
        }
        if(sqlite3_column_text(statement, 4)!=NULL)
        {
            aIntro =[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement,4)];
        }
        if(sqlite3_column_text(statement, 5)!=NULL)
        {
            aExtra =[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement,5)];
        }
        hasAudio = sqlite3_column_int(statement, 6);
		aPagesId = sqlite3_column_int(statement, 7);
        abookmark= sqlite3_column_int(statement,5);
        apageinstance.PageInstanceId=aPageInstanceId;
        apageinstance.OrderNum=aOrderNum;
        apageinstance.Title=aTitle;
        apageinstance.Image=aImage;
        apageinstance.Intro=aIntro;
        apageinstance.extra = aExtra;
        apageinstance.PagesId = aPagesId;

        apageinstance.hasAudio = hasAudio;
        if ([favIds containsObject: [NSString stringWithFormat:@"%d",aPageInstanceId]]) {
            apageinstance.Bookmark = 1;
        }
        else
        {
            apageinstance.Bookmark = 0;
        }
        [getSectionsPages addObject:apageinstance];
    }
    sqlite3_finalize(statement);
    sqlite3_close(database);
  	return  getSectionsPages;
}

-(void)getFavoritesIds
{
    sqlite3 *database = [self getDBConnection];
    sqlite3_stmt* statement;
    NSString *query;
    favIds = nil;
    favIds = [[NSMutableArray alloc] init];
    query=[NSString stringWithFormat:@"select PageInstanceId from favorites"];
    const char *sql =  [query UTF8String];
    if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) != SQLITE_OK)
    {
        NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
    }
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        [favIds addObject:[NSString stringWithFormat:@"%d",sqlite3_column_int(statement, 0)]];
    }
    sqlite3_finalize(statement);
    sqlite3_close(database);
}

-(NSMutableArray *)getPageHtmlsForDetailedPage:(NSInteger)pageid tagsid:(NSInteger)tagid limit:(int)noOfRecords
{
    sqlite3 *database = [self getDBConnection];
    PageInstance *apageinstance;
    getSectionsPages=[[NSMutableArray alloc]init];
    [self getFavoritesIds];
    int aPageInstanceId;
    NSString *aHtml,*filename,*aTitle;
    NSUInteger hasAudio;
    sqlite3_stmt* statement;
    NSString *query;
    if (noOfRecords == 0) {
        query=[NSString stringWithFormat:@"select p.PageInstanceId,h.Html,p.Title,p.hasAudio from page_instance p,page_tag t,page_html h where p.PagesId='%i' and t.TagsId='%i' and  t.PageInstanceId=p.PageInstanceId and p.PageInstanceId=h.PageInstanceId ORDER BY p.orderNum ASC",pageid,tagid];
    }
    else
    {
        query=[NSString stringWithFormat:@"select p.PageInstanceId,h.Html,p.Title,p.hasAudio from page_instance p,page_tag t,page_html h where p.PagesId='%i'  and t.TagsId='%i' and  t.PageInstanceId=p.PageInstanceId and p.PageInstanceId=h.PageInstanceId ORDER BY p.orderNum ASC limit %d",pageid,tagid,noOfRecords];
    }
    const char *sql =  [query UTF8String];
    if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) != SQLITE_OK)
    {
        NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
    }
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        apageinstance=[[PageInstance alloc]init];
        
        aPageInstanceId= sqlite3_column_int(statement,0);
        if(sqlite3_column_text(statement,1)!=NULL)
        {
            aHtml = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement,1)];
        }
        if(sqlite3_column_text(statement,2)!=NULL)
        {
            aTitle =  [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement,2)];
        }
        if(sqlite3_column_text(statement,3)!=NULL)
        {
            filename= [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement,3)];
        }
        hasAudio = sqlite3_column_int(statement,3);
        apageinstance.PageInstanceId=aPageInstanceId;
       
        if ([favIds containsObject: [NSString stringWithFormat:@"%d",aPageInstanceId]]) {
            apageinstance.Bookmark = 1;
        }
        else
        {
            apageinstance.Bookmark = 0;
        }
        apageinstance.Html = aHtml;
        apageinstance.Title =  aTitle;
        apageinstance.fileName = filename;
        apageinstance.hasAudio = hasAudio;
        [getSectionsPages addObject:apageinstance];
    }
    sqlite3_finalize(statement);
    sqlite3_close(database);
  	return  getSectionsPages;
}

-(PageInstance *) getElementsForPageInstance:(NSInteger) pageInstanceId
{
    sqlite3 *database = [self getDBConnection];
	sqlite3_stmt* statement;
    NSString *sqlString = [NSString stringWithFormat:@"select p.Html,i.hasAudio from page_instance i, page_html p where  i.PageInstanceId=p.PageInstanceId and i.PageInstanceId = %d",pageInstanceId];
    const char *sql =  [sqlString UTF8String];
    PageInstance *apageinstance;
	if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) != SQLITE_OK)
	{
		
	}
    else
    {
        if (sqlite3_step(statement) == SQLITE_ROW)
        {
            int aHasAudio;
            NSString *ahtml;
            apageinstance=[[PageInstance alloc]init];
            
            if(sqlite3_column_text(statement,0)!=NULL)
            {
                ahtml=[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement,0)];
            }
            aHasAudio = sqlite3_column_int(statement,1);
            
            if ([favIds containsObject: [NSString stringWithFormat:@"%d",pageInstanceId]]) {
                apageinstance.Bookmark = 1;
            }
            else
            {
                apageinstance.Bookmark = 0;
            }
            apageinstance.Html=ahtml;
            apageinstance.hasAudio = aHasAudio;
            [searchresults addObject:apageinstance];
        }
    }
    sqlite3_finalize(statement);
    sqlite3_close(database);
    return apageinstance;
}

-(NSMutableArray *)getPageHtmls:(NSInteger)pageid tagsid:(NSInteger)tagid limit:(int)noOfRecords
{
    sqlite3 *database = [self getDBConnection];
    
    getSectionsPages=[[NSMutableArray alloc]init];
    [self getFavoritesIds];
    
    sqlite3_stmt* statement;
    NSString *query;
    int hasAudio = [self isRecordBookAvailable];
    if (noOfRecords == 0) {
        if (hasAudio ==1) {
            query=[NSString stringWithFormat:@"select p.PageInstanceId,h.Html,p.Title,p.Extra,c.fileName from page_instance p,page_tag t,page_html h,recorded_book_chapter c where p.PagesId='%i' and t.TagsId='%i' and  t.PageInstanceId=p.PageInstanceId and p.PageInstanceId=h.PageInstanceId and p.Extra=c.chapterId ORDER BY p.orderNum ASC",pageid,tagid];
        }
        else
        {
            query=[NSString stringWithFormat:@"select p.PageInstanceId,h.Html,p.Title,p.Extra from page_instance p,page_tag t,page_html h where p.PagesId='%i' and t.TagsId='%i' and  t.PageInstanceId=p.PageInstanceId and p.PageInstanceId=h.PageInstanceId ORDER BY p.orderNum ASC",pageid,tagid];
        }
    }
    else
    {
        if (hasAudio ==1) {
            query=[NSString stringWithFormat:@"select p.PageInstanceId,h.Html,p.Title,p.Extra,c.fileName from page_instance p,page_tag t,page_html h,recorded_book_chapter c where p.PagesId='%i'  and t.TagsId='%i' and  t.PageInstanceId=p.PageInstanceId and p.PageInstanceId=h.PageInstanceId and p.Extra=c.chapterId ORDER BY p.orderNum ASC limit %d",pageid,tagid,noOfRecords];
        }
        else
        {
            query=[NSString stringWithFormat:@"select p.PageInstanceId,h.Html,p.Title,p.Extra from page_instance p,page_tag t,page_html h where p.PagesId='%i'  and t.TagsId='%i' and  t.PageInstanceId=p.PageInstanceId and p.PageInstanceId=h.PageInstanceId ORDER BY p.orderNum ASC limit %d",pageid,tagid,noOfRecords];
        }
    }
    const char *sql =  [query UTF8String];
    if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) != SQLITE_OK)
    {
        NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
    }
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        PageInstance *apageinstance;
        int aPageInstanceId;
        NSString *aHtml,*filename,*aTitle,*aExtra;
        
        apageinstance=[[PageInstance alloc]init];
        
        aPageInstanceId= sqlite3_column_int(statement,0);
        if(sqlite3_column_text(statement,1)!=NULL)
        {
            aHtml = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement,1)];
        }
        if(sqlite3_column_text(statement,2)!=NULL)
        {
            aTitle = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement,2)];
        }
        if(sqlite3_column_text(statement,3)!=NULL)
        {
            aExtra= [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement,3)];
        }
        if(sqlite3_column_text(statement,4)!=NULL)
        {
            filename= [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement,4)];
        }
        apageinstance.PageInstanceId=aPageInstanceId;
        if ([favIds containsObject: [NSString stringWithFormat:@"%d",aPageInstanceId]]) {
            apageinstance.Bookmark = 1;
        }
        else
        {
            apageinstance.Bookmark = 0;
        }
        apageinstance.Html = aHtml;
        apageinstance.Title =  aTitle;
        apageinstance.extra = aExtra;
        apageinstance.fileName = filename;
        [getSectionsPages addObject:apageinstance];
    }
    sqlite3_finalize(statement);
    sqlite3_close(database);
  	return  getSectionsPages;
}

-(NSMutableArray *)activatedPagesIds
{
    sqlite3 *database = [self getDBConnection];
    NSMutableArray *activatedIds = [[NSMutableArray alloc] init];
    NSString *query = [NSString stringWithFormat:@"select PagesId from pages where isActivated = 1"];
    sqlite3_stmt *stmt = nil;
    if (sqlite3_prepare_v2(database, [query UTF8String], -1, &stmt, nil) == SQLITE_OK) {
        
        while (sqlite3_step(stmt) == SQLITE_ROW) {
            NSString *pageId = [NSString stringWithFormat:@"%d", sqlite3_column_int(stmt,0)];
            [activatedIds addObject:pageId];
        }
    }
    return activatedIds;
}

-(NSString *) isExtraForPageInstance:(NSInteger) pageInstanceId
{
    sqlite3 *database = [self getDBConnection];
    NSString *query = [NSString stringWithFormat:@"select Extra from page_instance where PageInstanceId = %d",pageInstanceId];
    sqlite3_stmt *stmt = nil;
    NSString *extra;
    if (sqlite3_prepare_v2(database, [query UTF8String], -1, &stmt, nil) == SQLITE_OK) {
        
        if(sqlite3_column_text(stmt,0)!=NULL)
        {
            extra = [NSString stringWithFormat:@"%s",sqlite3_column_text(stmt, 0)];
        }
    }
    return extra;
}

-(NSInteger) hasAudioForInstance:(NSInteger) pageInstanceId
{
    sqlite3 *database = [self getDBConnection];
    NSString *query = [NSString stringWithFormat:@"select hasAudio from page_instance where PageInstanceId = %d",pageInstanceId];
    sqlite3_stmt *stmt = nil;
    NSInteger hasAudio=0;
    if (sqlite3_prepare_v2(database, [query UTF8String], -1, &stmt, nil) == SQLITE_OK) {
        
        if(sqlite3_column_text(stmt,0)!=NULL)
        {
            hasAudio = sqlite3_column_int(stmt, 0);
        }
    }
    return hasAudio;
}

//get search results
-(NSMutableArray*)getAdvancedSearchList:(NSString*)searchText
{
    sqlite3 *database = [self getDBConnection];
    [self getFavoritesIds];
	[searchresults removeAllObjects];
    searchresults=[[NSMutableArray alloc]init];
	sqlite3_stmt* statement;
    searchText = [searchText stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString *sqlString;
    NSMutableArray *activatedIds = [self activatedPagesIds];
  //  BOOL isListView = [[NSUserDefaults standardUserDefaults] boolForKey:@"ListView"];
 //   if (isListView) {
        
        sqlString = [NSString stringWithFormat:@"SELECT * FROM (SELECT s.PageInstanceId,s.SearchData,i.Extra, 1 AS PRIO FROM search_table s,page_instance i WHERE s.SearchData = '%@' and i.PageInstanceId=s.PageInstanceId and i.PagesId in %@ UNION SELECT s.PageInstanceId,s.SearchData,i.Extra, 2 AS PRIO FROM search_table s,page_instance i WHERE s.SearchData LIKE 'OPEN%@CLOSE' AND s.SearchData <>'%@' and i.PageInstanceId=s.PageInstanceId and i.PagesId in %@) AS rowid ORDER BY PRIO",searchText,[activatedIds description], searchText, searchText,[activatedIds description]];
//    }
//    else
//    {
////        
//        sqlString = [NSString stringWithFormat:@"select s.PageInstanceId,s.Title,i.Extra ,p.Html,i.hasAudio from page_instance i, page_html p,search_table s,page_tag t where t.PageInstanceId=s.PageInstanceId and p.PageInstanceId=s.PageInstanceId and i.PageInstanceId=s.PageInstanceId  and i.PagesId in %@ and SearchData MATCH  'OPEN%@*CLOSE'",[activatedIds description],searchText];
//        
//        sqlString = [NSString stringWithFormat:@"select s.PageInstanceId,s.Title,i.Extra from search_table s, page_instance i where i.PageInstanceId=s.PageInstanceId   and SearchData MATCH  'OPEN%@*CLOSE' and s.Title LIKE 'OPEN%@CLOSE' ",searchText,searchText];
//    }
    sqlString = [sqlString stringByReplacingOccurrencesOfString:@"OPEN" withString:@"%"];
    sqlString = [sqlString stringByReplacingOccurrencesOfString:@"CLOSE" withString:@"%"];
    const char *sql =  [sqlString UTF8String];
	if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) != SQLITE_OK)
	{
		
	}
    else
    {
        while (sqlite3_step(statement) == SQLITE_ROW)
        {
            int aPageInstanceId,aHasAudio;
            NSString *aTitle,*ahtml,*filename,*aExtra;
            PageInstance *apageinstance=[[PageInstance alloc]init];
            aPageInstanceId= sqlite3_column_int(statement,0);
            if(sqlite3_column_text(statement,1)!=NULL)
            {
                aTitle = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement,1)];
            }
            if(sqlite3_column_text(statement,2)!=NULL)
            {
                aExtra =[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement,2)];
            }
//            if(sqlite3_column_text(statement,3)!=NULL)
//            {
//                ahtml=[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement,3)];
//            }
//            aHasAudio = sqlite3_column_int(statement,4);

            if ([favIds containsObject: [NSString stringWithFormat:@"%d",aPageInstanceId]]) {
                apageinstance.Bookmark = 1;
            }
            else
            {
                apageinstance.Bookmark = 0;
            }
            apageinstance.PageInstanceId=aPageInstanceId;
            apageinstance.Title=aTitle;
            apageinstance.Html=ahtml;
            apageinstance.extra = aExtra;
            apageinstance.fileName=filename;
            apageinstance.hasAudio = aHasAudio;
            [searchresults addObject:apageinstance];
        }
    }
    sqlite3_finalize(statement);
    sqlite3_close(database);

    return searchresults;
}
-(NSMutableArray *)getSearchResults:(NSMutableArray *)ids
{
    NSMutableArray *searchResults = [[NSMutableArray alloc] init];
    sqlite3_stmt *statement;
    int hasAudio = [self isRecordBookAvailable];
	sqlite3 *database = [self getDBConnection];
    NSString* query;
    if (hasAudio == 1) {
        query = [NSString stringWithFormat:@"select PageInstanceId, OrderNum, Title,Image,Intro,Extra,hasAudio from page_instance where PageInstanceId in (%@)",[ids description]];
    }
    else
    {
        query = [NSString stringWithFormat:@"select PageInstanceId, OrderNum, Title,Image,Intro,Extra,hasAudio from page_instance where PageInstanceId in (%@)",[ids description]];
    }
	const char *sql = [query UTF8String];
	if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) != SQLITE_OK)
	{
		NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
	}
	while (sqlite3_step(statement) == SQLITE_ROW)
	{
	}
    return searchResults;
}
//get tagId for serach table
-(NSDictionary *)tagID:(NSInteger)pageid
{
	NSDictionary *dictionary;
	sqlite3_stmt *statement;
	sqlite3 *database = [self getDBConnection];
	NSString* query = [NSString stringWithFormat:@"select p.TagsId, t.tag from  page_tag p, tags t where PageInstanceId='%d' and t.TagsId = p.TagsId",pageid];
    
	const char *sql = [query UTF8String];
    
	if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) != SQLITE_OK)
	{
		NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
	}
	while (sqlite3_step(statement) == SQLITE_ROW)
	{
        NSString *tagId = [NSString stringWithFormat:@"%d", sqlite3_column_int(statement, 0)];
        NSString *sectionName = [NSString stringWithFormat:@"%s", sqlite3_column_text(statement, 1)];
        dictionary = [NSDictionary dictionaryWithObjectsAndKeys:tagId,@"TagId",sectionName,@"Section Name", nil];
	}
    sqlite3_finalize(statement);
    sqlite3_close(database);
	return dictionary;
}

-(void)sethistory:(NSInteger)pageid
{
    sqlite3 *database = [self getDBConnection];
	sqlite3_stmt *insert_statement;
    double unixTime = 1000.0 * [[NSDate date] timeIntervalSince1970];
	NSString* query = [NSString stringWithFormat:@"INSERT INTO history VALUES (%d,%f)",pageid,unixTime];
	const char *sql = [query UTF8String];
	if (sqlite3_prepare_v2(database, sql, -1, &insert_statement, NULL) != SQLITE_OK)
	{
        
	}
    else
    {
        int  success= sqlite3_step(insert_statement);
        if(success == SQLITE_ERROR)
        {
            
        }
    }
	sqlite3_finalize(insert_statement);
    sqlite3_close(database);
}

-(void)bookMarkText:(NSInteger)pageid
{
    sqlite3 *database = [self getDBConnection];
	sqlite3_stmt *insert_statement;
    double unixTime = 1000.0 * [[NSDate date] timeIntervalSince1970];
	NSString* query = [NSString stringWithFormat:@"INSERT INTO favorites VALUES (%d,%f)",pageid,unixTime];
	const char *sql = [query UTF8String];
	if (sqlite3_prepare_v2(database, sql, -1, &insert_statement, NULL) != SQLITE_OK)
	{
        
	}
	int  success= sqlite3_step(insert_statement);
	sqlite3_finalize(insert_statement);
	if(success == SQLITE_ERROR)
	{
        
	}
    sqlite3_close(database);
}


-(void)removebookMarkText:(NSInteger)pageid
{
	sqlite3 *database = [self getDBConnection];
	sqlite3_stmt *insert_statement;
	
	NSString* query = [NSString stringWithFormat:@"delete from favorites where PageInstanceId = %d",pageid];
	const char *sql = [query UTF8String];
	if (sqlite3_prepare_v2(database, sql, -1, &insert_statement, NULL) != SQLITE_OK)
	{
        
	}
	int  success= sqlite3_step(insert_statement);
	sqlite3_finalize(insert_statement);
	if(success == SQLITE_ERROR)
	{
        
	}
    sqlite3_close(database);
}

-(NSString *)title
{
    sqlite3 *database = [self getDBConnection];
    
    sqlite3_stmt* statement;
    NSString *query=[NSString stringWithFormat:@"Select Name  from title "];
    const char *sql =  [query UTF8String];
    if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) != SQLITE_OK)
    {
        NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
    }
    NSString *aCount;
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        if(sqlite3_column_text(statement, 0)!=NULL)
        {
            aCount = [NSString stringWithFormat:@"%s",sqlite3_column_text(statement, 0)];
        }
    }
    sqlite3_finalize(statement);
    sqlite3_close(database);
  	return  aCount;
}

-(NSString *)getpagesCount
{
    sqlite3 *database = [self getDBConnection];
    
    sqlite3_stmt* statement;
    NSString *query=[NSString stringWithFormat:@"select count(*) from pages"];
    const char *sql =  [query UTF8String];
    if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) != SQLITE_OK)
    {
        NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
    }
    NSString *aCount;
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        if(sqlite3_column_text(statement, 0)!=NULL)
        {
            aCount = [NSString stringWithFormat:@"%s",sqlite3_column_text(statement, 0)];
        }
    }
    sqlite3_finalize(statement);
    sqlite3_close(database);
  	return  aCount;
}

-(NSString *) getFileNameForChapterId:(NSString *)chapterId
{
    NSString *fileName;
	sqlite3_stmt *statement;
	sqlite3 *database = [self getDBConnection];
	NSString* query = [NSString stringWithFormat: @"select fileName from recorded_book_chapter where chapterId = %@",chapterId];
	const char *sql = [query UTF8String];
	if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) != SQLITE_OK)
	{
		NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
	}
	while (sqlite3_step(statement) == SQLITE_ROW)
	{
        fileName = [NSString stringWithFormat:@"%s",sqlite3_column_text(statement, 0)];
	}
    sqlite3_finalize(statement);
    sqlite3_close(database);
	return fileName;

}

-(int)RecordBookID{
    
    int key;
	sqlite3_stmt *statement;
	sqlite3 *database = [self getDBConnection];
	NSString* query = @"select recordedBookId from recorded_book";
	const char *sql = [query UTF8String];
	if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) != SQLITE_OK)
	{
		NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
	}
	while (sqlite3_step(statement) == SQLITE_ROW)
	{
        key = sqlite3_column_int(statement, 0);
	}
    sqlite3_finalize(statement);
    sqlite3_close(database);
	return key;
}

- (NSString *)getQuizJsonForQuizId:(int)quizIdInt
{
    NSString *jsonString = nil;
	sqlite3_stmt *statement;
	sqlite3 *database = [self getDBConnection];
	NSString* query = [NSString stringWithFormat: @"select json from quiz where quizId = %d", quizIdInt];
	const char *sql = [query UTF8String];
	if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) != SQLITE_OK)
	{
		NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
	}
	while (sqlite3_step(statement) == SQLITE_ROW)
	{
        jsonString = [NSString stringWithFormat:@"%s",sqlite3_column_text(statement, 0)];
	}
    sqlite3_finalize(statement);
    sqlite3_close(database);
	return jsonString;
}

- (int)getCurrentQuizSecondsForQuizId:(int)quizIdInt;
{
	int currentSecondsInt = 0;
	NSString *jsonString = nil;
	sqlite3_stmt *statement;
	sqlite3 *database = [self getDBConnection];
	NSString* query = [NSString stringWithFormat: @"select seconds from quiz where quizId = %d", quizIdInt];
	const char *sql = [query UTF8String];
	if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) != SQLITE_OK)
	{
		NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
	}
	while (sqlite3_step(statement) == SQLITE_ROW)
	{
        jsonString = [NSString stringWithFormat:@"%s",sqlite3_column_text(statement, 0)];
		
		if (jsonString && jsonString.length > 0)
			currentSecondsInt = [jsonString intValue];
	}

    sqlite3_finalize(statement);
    sqlite3_close(database);
	
	return currentSecondsInt;
}

- (void)updateSecondsCount:(int)addedSecondsInt forQuizId:(int)quizIdInt;
{
	int currentQuizSecondsInt = [self getCurrentQuizSecondsForQuizId:quizIdInt];
	int totalSecondsInt = currentQuizSecondsInt + addedSecondsInt;
	
    sqlite3 *database = [self getDBConnection];
    sqlite3_stmt *statement;
    NSString *query = [NSString stringWithFormat:@"update quiz set seconds = %d where quizId = %d", totalSecondsInt, quizIdInt];
    const char *sql =  [query UTF8String];
    if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) != SQLITE_OK)
    {
        NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
    }
    else
    {
        sqlite3_step(statement);
    }
    sqlite3_finalize(statement);
    sqlite3_close(database);
}

- (int)getQuizCount;
{
    sqlite3 *database = [self getDBConnection];
    
    sqlite3_stmt* statement;
    NSString *query=[NSString stringWithFormat:@"select count(quizId) from quiz"];
    const char *sql =  [query UTF8String];
	
	if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) != SQLITE_OK)
        NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
	
    NSString *quizCountString = @"0";
	
    if (sqlite3_step(statement) == SQLITE_ROW)
        quizCountString = [NSString stringWithFormat:@"%s",sqlite3_column_text(statement, 0)];
	
    sqlite3_finalize(statement);
    sqlite3_close(database);
  	return  [quizCountString intValue];
}

- (void)populateArrayWithAllQuizInfo:(NSMutableArray *)quizInfoArray;
{
    sqlite3 *database = [self getDBConnection];
    sqlite3_stmt* statement;
	NSString *query=[NSString stringWithFormat:@"select quizId, name, seconds from quiz"];
	
    const char *sql =  [query UTF8String];
    if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) != SQLITE_OK)
    {
        NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
    }
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
		int quizIdInt = sqlite3_column_int(statement,0);
		NSString *quizNameString = [NSString stringWithFormat:@"%s",sqlite3_column_text(statement, 1)];
		int quizSecondsInt = sqlite3_column_int(statement, 2);
		[quizInfoArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								  [NSNumber numberWithInt:quizIdInt],
								  @"quizId",
								  quizNameString,
								  @"quizNameString",
								  [NSNumber numberWithInt:quizSecondsInt],
								  @"quizSecondsInt",
								  nil]];
    }
    sqlite3_finalize(statement);
    sqlite3_close(database);
}

- (NSDictionary *)getQuizDataDictionaryForQuizId:(int)quizIdInt;
{
	NSDictionary *quizInfoDict = nil;
    sqlite3 *database = [self getDBConnection];
    sqlite3_stmt* statement;
	NSString *query=[NSString stringWithFormat:@"select name, seconds from quiz where quizId = %d", quizIdInt];
	
    const char *sql =  [query UTF8String];
    if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) != SQLITE_OK)
    {
        NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
    }

    if (sqlite3_step(statement) == SQLITE_ROW)
    {
		NSString *quizNameString = [NSString stringWithFormat:@"%s",sqlite3_column_text(statement, 0)];
		int quizSecondsInt = sqlite3_column_int(statement, 1);
		quizInfoDict = [NSDictionary dictionaryWithObjectsAndKeys:
						[NSNumber numberWithInt:quizIdInt], @"quizId",
						quizNameString, @"quizNameString",
						[NSNumber numberWithInt:quizSecondsInt], @"quizSecondsInt",
						nil];
    }
    sqlite3_finalize(statement);
    sqlite3_close(database);
	return quizInfoDict;
}

- (int)getQuestionCountForQuizId:(int)quizIdInt;
{
    sqlite3 *database = [self getDBConnection];
    
    sqlite3_stmt* statement;
    NSString *query=[NSString stringWithFormat:@"select count(questionId) from question where quizId = '%d'", quizIdInt];
    const char *sql =  [query UTF8String];
	
	if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) != SQLITE_OK)
        NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
	
    NSString *quizQuestionCountString = @"0";
	
    if (sqlite3_step(statement) == SQLITE_ROW)
        quizQuestionCountString = [NSString stringWithFormat:@"%s",sqlite3_column_text(statement, 0)];
	
    sqlite3_finalize(statement);
    sqlite3_close(database);
  	return  [quizQuestionCountString intValue];
}

- (int)getAnsweredQuestionCountForQuizId:(int)quizIdInt;
{
    sqlite3 *database = [self getDBConnection];
    
    sqlite3_stmt* statement;
    NSString *query=[NSString stringWithFormat:@"select count(questionId) from question where answeredDate is not NULL and quizId = %d", quizIdInt];
    const char *sql =  [query UTF8String];
	
    if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) != SQLITE_OK)
        NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
	
    NSString *quizAnswerCountString = @"0";
	
    if (sqlite3_step(statement) == SQLITE_ROW)
        quizAnswerCountString = [NSString stringWithFormat:@"%s",sqlite3_column_text(statement, 0)];
	
    sqlite3_finalize(statement);
    sqlite3_close(database);
  	return  [quizAnswerCountString intValue];
}

- (int)getCorrectlyAnsweredQuestionCountForQuizId:(int)quizIdInt;
{
    sqlite3 *database = [self getDBConnection];
    
    sqlite3_stmt* statement;
    NSString *query=[NSString stringWithFormat:@"select count(questionId) from question where answeredDate is not NULL and quizId = %d and correct = 1", quizIdInt];
    const char *sql =  [query UTF8String];
	
    if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) != SQLITE_OK)
        NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
	
    NSString *quizCorrectAnswerCountString = @"0";
	
    if (sqlite3_step(statement) == SQLITE_ROW)
        quizCorrectAnswerCountString = [NSString stringWithFormat:@"%s",sqlite3_column_text(statement, 0)];
	
    sqlite3_finalize(statement);
    sqlite3_close(database);
  	return  [quizCorrectAnswerCountString intValue];
}

// create a dictionary with key = page instance id, value = array of quiz ids associated with each page instance id.
// this is so we can group all quizzes in a chapter and generate just one "correctness" number per page id (aka chapter) in timeline.
- (NSDictionary *)dictionaryOfQuizIdsByPageInstanceId;
{
    NSMutableDictionary *quizInfoDictionary =[[NSMutableDictionary alloc] initWithCapacity:0];
	sqlite3 *database = [self getDBConnection];
    sqlite3_stmt* statement;
    
    NSString *query=[NSString stringWithFormat:@"select PageInstanceId, QuizId from page_quiz order by PageInstanceId"];
    const char *sql =  [query UTF8String];
    if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) != SQLITE_OK)
    {
        // NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
    }
	
    while (sqlite3_step(statement) == SQLITE_ROW)
	{
		int pageIdInt = sqlite3_column_int(statement, 0);
		NSString *pageIdDictKey = [NSString stringWithFormat:@"%d", pageIdInt];
		
		int quizIdInt = sqlite3_column_int(statement, 1);
		NSNumber *quizIdNumber = [NSNumber numberWithInt:quizIdInt];
		
		NSMutableArray *arrayOfQuizIds = [quizInfoDictionary valueForKey:pageIdDictKey];
		
		if (arrayOfQuizIds == nil)
			arrayOfQuizIds = [[NSMutableArray alloc] initWithCapacity:0];
		
		[arrayOfQuizIds addObject:quizIdNumber];
		[quizInfoDictionary setObject:arrayOfQuizIds forKey:pageIdDictKey];
	}

    sqlite3_finalize(statement);
	sqlite3_close(database);
	return quizInfoDictionary;
}

// create a dictionary with key = quiz id, value = page instance id for each quiz.
// needed so we can associate a quiz with its page instance id.
- (NSDictionary *)dictionaryOfPageInstanceIdsByQuizIds;
{
    NSMutableDictionary *quizInfoDictionary =[[NSMutableDictionary alloc] initWithCapacity:0];
	sqlite3 *database = [self getDBConnection];
    sqlite3_stmt* statement;
    NSString *query=[NSString stringWithFormat:@"select QuizId, PageInstanceId from page_quiz order by QuizId"];
    const char *sql =  [query UTF8String];

    if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) != SQLITE_OK)
    {
        // NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
    }
	
    while (sqlite3_step(statement) == SQLITE_ROW)
	{
		int quizIdInt = sqlite3_column_int(statement, 0);
		int pageIdInt = sqlite3_column_int(statement, 1);
		NSString *quizIdKeyString = [NSString stringWithFormat:@"%d", quizIdInt];
		NSNumber *pageIdNumber = [NSNumber numberWithInt:pageIdInt];
		[quizInfoDictionary setObject:pageIdNumber forKey:quizIdKeyString];
	}
	
    sqlite3_finalize(statement);
	sqlite3_close(database);
	return quizInfoDictionary;
}

@end
