//
//  JournalViewController.h
//  Fit
//
//  Created by Rich on 2/6/14.
//  Copyright (c) 2014 mobifusion. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "ALAssetsLibrary+CustomPhotoAlbum.h"
#import "JournalViewTableCell.h"
#import "JournalCellPhoto.h"
#import "JournalPhotoViewController.h"
#import "CustomerDataEngine.h"

typedef void (^ALAssetsLibraryAccessFailureBlock)(NSError *error);

@interface JournalViewController : UITableViewController <UIGestureRecognizerDelegate, UIImagePickerControllerDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
{
}

@end
