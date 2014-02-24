//
//  JournalViewTableCell.m
//  Fit
//
//  Created by Rich on 2/6/14.
//  Copyright (c) 2014 mobifusion. All rights reserved.
//

#import "JournalViewTableCell.h"

@implementation JournalViewTableCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

    if (self)
	{
        // cell is set up in storyboard
    }
	
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
