//
//  JournalViewTableCell.h
//  Fit
//
//  Created by Rich on 2/6/14.
//  Copyright (c) 2014 mobifusion. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JournalCellPhotoScrollView.h"

@interface JournalViewTableCell : UITableViewCell

@property IBOutlet JournalCellPhotoScrollView *journalCellPhotoScrollView;	// exposed so the parent view controller can fade-in the cells in viewWillAppear:

@end
