//
//  CustomerDataEngine.m
//  Fit
//
//  Created by Richard Motofuji on 12/3/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//

#import "CustomerDataEngine.h"

@implementation CustomerDataEngine

CustomerDataEngine *customerDataEngine = nil;

// zzzzz change these from Bright to Fit or something
NSString *documentsDirectoryPath = nil;				// e.g. /var/mobile/Applications/3B424D8C-0C45-404E-A1EC-F9600DB81F45/Documents/Bright/695
NSString *customerAvatarFilePath = nil;				// e.g. /var/mobile/Applications/3B424D8C-0C45-404E-A1EC-F9600DB81F45/Documents/Bright/695/customerAvatar.png
NSString *quizDataDictionaryFilePath = nil;			// e.g. /var/mobile/Applications/3B424D8C-0C45-404E-A1EC-F9600DB81F45/Documents/Bright/695/quizDataDictionary

NSString *journalPhotoThumbnailFilePath = nil;		// e.g. /var/mobile/Applications/3B424D8C-0C45-404E-A1EC-F9600DB81F45/Documents/Bright/695/journalPhotoThumbnails

#pragma mark - Customer avatar

- (void)saveAvatarImageToLocalFilesystem
{
	if (self.customerAvatarImage == nil)
	{
		[self removeAvatarImageFromLocalFilesystem];
	}
	else
	{
		NSData *pngImageData = UIImagePNGRepresentation(self.customerAvatarImage);
		[pngImageData writeToFile:customerAvatarFilePath atomically:YES];
	}
}

- (void)removeAvatarImageFromLocalFilesystem
{
	NSError *error = nil;
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:customerAvatarFilePath])
		[[NSFileManager defaultManager] removeItemAtPath:customerAvatarFilePath error:&error];
}

- (UIImage *)readAvatarImageFromLocalFilesystem
{
	NSData *pngImageData = [NSData dataWithContentsOfFile:customerAvatarFilePath];
	self.customerAvatarImage = [UIImage imageWithData:pngImageData];		// note: file is empty and image is nil if user logged in with a mobi account
	
	if (self.customerAvatarImage == nil)
		self.customerAvatarImage = [UIImage imageNamed:@"default-avatar"];

	return self.customerAvatarImage;
}

#pragma mark - Customer name

- (NSString *)getCustomerName
{
	NSDictionary *customerInfoDict = [[DataController sharedController] customerInfoDictionary];
	
	if (customerInfoDict)
	{
		NSString *name = [customerInfoDict valueForKey:@"name"];
		
		if (name)
			self.customerName = name;
	}
	
	return self.customerName;
}

#pragma mark - Customer quiz data

// note: the actual customer quiz data dictionary is accessed by the QuizDataController object.  it is only read from file or written to file here.

- (NSDictionary *)readQuizDataDictionaryFromLocalFilesystem;
{
	NSDictionary *quizDataDictionary = [NSMutableDictionary dictionaryWithContentsOfFile:quizDataDictionaryFilePath];
	
	if (quizDataDictionary == nil)
		quizDataDictionary = [[NSMutableDictionary alloc] initWithCapacity:0];
	
	return quizDataDictionary;
}

- (BOOL)writeQuizDataDictionaryToLocalFilesystem:(NSDictionary *)quizDataDictionary;
{
	BOOL writtenOK = NO;
	
	if (quizDataDictionary)
		writtenOK = [quizDataDictionary writeToFile:quizDataDictionaryFilePath atomically:YES];
	
	return writtenOK;
}

- (NSMutableArray *)readJournalPhotoDataFromLocalFilesystem;
{
	// note: we return nil if there is no file yet
	NSMutableArray *journalPhotoThumbnailArray = [NSMutableArray arrayWithContentsOfFile:journalPhotoThumbnailFilePath];
	return journalPhotoThumbnailArray;
}

- (BOOL)writeJournalPhotoDataToLocalFilesystem:(NSArray *)journalThumbnails;
{
	BOOL writtenOK = NO;
	NSError *error = nil;
	
	// note: we can pass in 'nil' to erase the file
	if (journalThumbnails)
		writtenOK = [journalThumbnails writeToFile:journalPhotoThumbnailFilePath atomically:YES];
	else
		writtenOK = [[NSFileManager defaultManager] removeItemAtPath:journalPhotoThumbnailFilePath error:&error];

	return writtenOK;
}

#pragma mark - Initialization

+ (id)customerDataEngine
{
    static dispatch_once_t onceToken;
	
    dispatch_once(&onceToken, ^{
        customerDataEngine = [[self alloc] init];
    });
	
    return customerDataEngine;
}

- (id)init
{
	[self initDocumentsDirectoryPath];
	[self initCustomerAvatarFilePath];
	[self readAvatarImageFromLocalFilesystem];
	[self initQuizDataDictionaryFilePath];
	[self initJournalPhotoThumbnailFilePath];
	return self;
}

- (void) initDocumentsDirectoryPath
{
	documentsDirectoryPath = nil;
	
	NSArray *pathArray = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	
	if (pathArray && pathArray.count > 0)
	{
		NSString *pathString = [pathArray objectAtIndex:0];
		
		// zzzzz should we change the directory name to a "real" app name?  or should we put all Bright-based apps' info here?
		// we could, instead, create a directory named thothID

		if (pathArray && pathArray.count > 0)
		{
			NSDictionary *publicationInfo = [[DataController sharedController] getInfo];
			
			if (publicationInfo && publicationInfo.count > 0)
			{
				NSString *thothIdString = [publicationInfo valueForKey:@"ThothId"];
				
				if (thothIdString)
					documentsDirectoryPath = [[pathString stringByAppendingPathComponent:@"Bright"] stringByAppendingPathComponent:thothIdString];
				
				[self createDirectoryAtPathIfNecessary:documentsDirectoryPath];
			}
		}
	}
}

- (BOOL) createDirectoryAtPathIfNecessary:(NSString *)newDirectoryPath
{
	BOOL directoryOK = YES;
	NSError *error = nil;
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:newDirectoryPath] == NO)
	{
		if ([[NSFileManager defaultManager] createDirectoryAtPath:newDirectoryPath
									  withIntermediateDirectories:YES
													   attributes:nil
															error:&error] == NO)
		{
			directoryOK = NO;	// note: this should absolutely never happen, but if it does, how can we handle the error?
		}
	}
	
	return directoryOK;
}

- (void)initCustomerAvatarFilePath
{
	customerAvatarFilePath = [documentsDirectoryPath stringByAppendingPathComponent:@"customerAvatar.png"];
}

- (void)initQuizDataDictionaryFilePath
{
	quizDataDictionaryFilePath = [documentsDirectoryPath stringByAppendingPathComponent:@"quizDataDictionary"];
}

- (void)initJournalPhotoThumbnailFilePath
{
	journalPhotoThumbnailFilePath = [documentsDirectoryPath stringByAppendingPathComponent:@"journalPhotoThumbnails"];
}

@end
