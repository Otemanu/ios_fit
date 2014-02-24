//
//  JournalPhotoViewController.h
//  Fit
//
//  Created by Rich on 2/13/14.
//  Copyright (c) 2014 mobifusion. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ALAssetsLibrary+CustomPhotoAlbum.h"
#import "JournalPhotoEmoticonView.h"
#import "Scalars.h"

@interface JournalPhotoViewController : UIViewController

@property (strong, nonatomic) NSURL *journalPhotoAssetURL;
@property (strong, atomic) ALAssetsLibrary *assetsLibrary;
@property int emotionalStateIndex;

@end
