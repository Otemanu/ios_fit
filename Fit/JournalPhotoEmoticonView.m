//
//  JournalPhotoEmoticonView.m
//  Fit
//
//  Created by Rich on 2/13/14.
//  Copyright (c) 2014 mobifusion. All rights reserved.
//

#import "JournalPhotoEmoticonView.h"

@interface JournalPhotoEmoticonView ()

@property IBOutlet UILabel *titleLabel;
@property IBOutlet UILabel *messageLabel;
@property IBOutlet UIButton *happyButton;
@property IBOutlet UIButton *neutralButton;
@property IBOutlet UIButton *unappyButton;
@property IBOutlet UIButton *cancelButton;
@property IBOutlet UIButton *okButton;

@end

@implementation JournalPhotoEmoticonView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
	
    if (self)
	{
    }

    return self;
}

// the view is all set up in storyboard
//- (void)drawRect:(CGRect)rect
//{
//}

@end
