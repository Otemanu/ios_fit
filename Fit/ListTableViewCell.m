//
//  ListTableViewCell.m
//
//  Created by Narayana on 12/11/13.
//
//

#import "ListTableViewCell.h"

@implementation ListTableViewCell
@synthesize introLabel,titleLabel;
@synthesize sectionNo,tagValue,selectedPage,tileCategory;
@synthesize pageInstance,isExtraAvailable,hasAudio;
@synthesize aImageView,backgroundImageView;

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
