//
//  ALAssetsLibrary+CustomPhotoAlbum.h
//  Fit
//
//  Created by Rich on 2/15/14.
//  Copyright (c) 2014 mobifusion. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

typedef void(^SaveImageCompletion)(NSError* error);
typedef void (^ALAssetsLibraryAssetForURLResultBlock)(ALAsset *asset);
typedef void (^ALAssetsLibraryAccessFailureBlock)(NSError *error);

@interface ALAssetsLibrary(CustomPhotoAlbum)

-(void)saveImage:(UIImage*)image toAlbum:(NSString*)albumName withCompletionBlock:(SaveImageCompletion)completionBlock;
-(void)addAssetURL:(NSURL*)assetURL toAlbum:(NSString*)albumName withCompletionBlock:(SaveImageCompletion)completionBlock;

@end