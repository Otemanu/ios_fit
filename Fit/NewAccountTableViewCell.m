//
//  NewAccountTableViewCell.m
//  Fit
//
//  Created by Rich on 11/15/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//

#import "NewAccountTableViewCell.h"

@implementation NewAccountTableViewCell

@synthesize accountTableViewCellTextField;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
