//
//  CardView.m
//  Fit
//
//  Created by Mobi on 19/11/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//

#import "CardView.h"

@implementation CardView

#define Top_Padding 34
#define Side_Padding 34

#define TopPadding_iPad 150
#define SidePadding_iPad 138

@synthesize cardsScrollView;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
    }
    return self;
}

-(id)initWithCard:(Card *)card
{
    self = [super init];
    if (self) {
        self.card = card;
        [self addLabelsForCard];
    }
    return self;
}

-(void) addLabelsForCard
{
    UIColor *textColor = [UIColor whiteColor];
    NSArray *labelTexts = [self.card.cardText componentsSeparatedByString:@"$$$"];
    
    CGRect screenBound = [[UIScreen mainScreen] bounds];
    CGSize screenSize = screenBound.size;
    
    if (DEVICE_IS_IPAD)
        self.selectedTextLabel = [[UILabel alloc] initWithFrame:CGRectMake(SidePadding_iPad, TopPadding_iPad, screenSize.width - (2*SidePadding_iPad), screenSize.height - 300)];
    else
        self.selectedTextLabel = [[UILabel alloc] initWithFrame:CGRectMake(Side_Padding, Top_Padding, screenSize.width - (2*Side_Padding), screenSize.height - 300)];
    
    CGFloat fontSize = 30.0;
    self.selectedTextLabel.font = [UIFont fontWithName:@"Helvetica CE 35 Thin" size:30.0f];
    self.selectedTextLabel.font = [UIFont italicSystemFontOfSize:fontSize];
    self.selectedTextLabel.adjustsFontSizeToFitWidth = YES;
    
    while (fontSize > 15.0)
    {
        CGSize size = [[labelTexts objectAtIndex:0] sizeWithFont:[UIFont italicSystemFontOfSize:fontSize] constrainedToSize:CGSizeMake(self.selectedTextLabel.frame.size.width, 10000) lineBreakMode:NSLineBreakByWordWrapping];
        if (size.height <= self.selectedTextLabel.frame.size.height)
            break;
        fontSize -= 1.0;
    }
    self.selectedTextLabel.font = [UIFont fontWithName:@"Helvetica CE 35 Thin" size:fontSize];
    self.selectedTextLabel.numberOfLines = 20;
    self.selectedTextLabel.text = [NSString stringWithFormat:@"\xE2\x80\x9C%@\xE2\x80\x9D",[labelTexts objectAtIndex:0]];
    self.selectedTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.selectedTextLabel.textColor = textColor;
    NSDictionary *selTextAttributes = [NSDictionary dictionaryWithObject:self.selectedTextLabel.font forKey: NSFontAttributeName];
    CGSize selTextLabelSIze = [self.selectedTextLabel.text boundingRectWithSize:CGSizeMake(self.selectedTextLabel.frame.size.width, self.selectedTextLabel.frame.size.height) options:NSStringDrawingTruncatesLastVisibleLine|NSStringDrawingUsesLineFragmentOrigin attributes:selTextAttributes context:nil].size;
    if (selTextLabelSIze.height < screenSize.height - 300) {
        self.selectedTextLabel.frame = CGRectMake(self.selectedTextLabel.frame.origin.x, self.selectedTextLabel.frame.origin.y+5, self.selectedTextLabel.frame.size.width, selTextLabelSIze.height);
    }
    //self.selectedTextLabel.backgroundColor = [UIColor blackColor];
    
    self.shareButton = [UIButton buttonWithType:UIButtonTypeCustom];
    if (DEVICE_IS_IPAD)
    {
        self.shareButton.frame = CGRectMake(screenSize.width - SidePadding_iPad - 88, self.selectedTextLabel.frame.origin.y+self.selectedTextLabel.frame.size.height+2, 117, 32);
        [self.shareButton  setTitle:@"SHARE" forState:UIControlStateNormal];
    }
    else
    {
        self.shareButton.frame = CGRectMake(screenSize.width - Side_Padding - 59, self.selectedTextLabel.frame.origin.y+self.selectedTextLabel.frame.size.height+2, 59, 16);
        [self.shareButton setImage:[UIImage imageNamed:@"ShareImage"] forState:UIControlStateNormal];
    }
 
    [self addSubview:self.shareButton];
    
    UIView *lineView;
    if (DEVICE_IS_IPAD) {
        lineView = [[UIView alloc] initWithFrame:CGRectMake(SidePadding_iPad, self.shareButton.frame.origin.y + self.shareButton.frame.size.height+10, screenSize.width - (2 * SidePadding_iPad), 3)];
    }
    else
        lineView = [[UIView alloc] initWithFrame:CGRectMake(Side_Padding, self.shareButton.frame.origin.y + self.shareButton.frame.size.height+10, screenSize.width - (2 * Side_Padding), 3)];
    lineView.backgroundColor = [UIColor whiteColor];
    [self addSubview:lineView];
    
    if (DEVICE_IS_IPAD)
    {
        self.chapterLable = [[UILabel alloc] initWithFrame:CGRectMake(SidePadding_iPad, lineView.frame.origin.y + lineView.frame.size.height + 50, screenSize.width -(2 * SidePadding_iPad), 55)];
        self.chapterLable.font =  [UIFont boldSystemFontOfSize:24];
    }
    else
    {
        self.chapterLable = [[UILabel alloc] initWithFrame:CGRectMake(Side_Padding, lineView.frame.origin.y + lineView.frame.size.height + 20, screenSize.width -(2 * Side_Padding), 55)];
        self.chapterLable.font =  [UIFont boldSystemFontOfSize:20];
    }
    self.chapterLable.numberOfLines = 2;
    
#if 1
	if (labelTexts.count < 2)
		self.chapterLable.text = @"no text here";
	else
#endif
        self.chapterLable.text = [labelTexts objectAtIndex:1];
    self.chapterLable.lineBreakMode = NSLineBreakByWordWrapping;
    self.chapterLable.textColor = textColor;
    //  self.chapterLable.backgroundColor = [UIColor blackColor];
    NSDictionary *stringAttributes = [NSDictionary dictionaryWithObject:self.chapterLable.font forKey: NSFontAttributeName];
    
    CGSize chapterLabelSIze = [self.chapterLable.text boundingRectWithSize:CGSizeMake(self.chapterLable.frame.size.width, self.chapterLable.frame.size.height) options:NSStringDrawingTruncatesLastVisibleLine|NSStringDrawingUsesLineFragmentOrigin attributes:stringAttributes context:nil].size;
    if (chapterLabelSIze.height < 60) {
        self.chapterLable.frame = CGRectMake(self.chapterLable.frame.origin.x, self.chapterLable.frame.origin.y, self.chapterLable.frame.size.width, chapterLabelSIze.height);
    }
    
    
    if (DEVICE_IS_IPAD)
    {
        self.sectionNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(SidePadding_iPad, self.chapterLable.frame.origin.y+self.chapterLable.frame.size.height+28, screenSize.width - (2*SidePadding_iPad), 50)];
        self.sectionNameLabel.font = [UIFont boldSystemFontOfSize:24.0];
    }
    else
    {
        self.sectionNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(Side_Padding, self.chapterLable.frame.origin.y+self.chapterLable.frame.size.height+25, screenSize.width - (2*Side_Padding), 50)];
        self.sectionNameLabel.font = [UIFont boldSystemFontOfSize:24.0];
    }
    self.sectionNameLabel.numberOfLines = 2;
#if 1
	if (labelTexts.count < 3)
		self.sectionNameLabel.text = @"no text here either";
	else
#endif
        self.sectionNameLabel.text = [NSString stringWithFormat:@"\xE2\x80\x9C%@\xE2\x80\x9D", [labelTexts objectAtIndex:2]];
    
    self.sectionNameLabel.textColor = textColor;
    
    NSDictionary *sectionAttributes = [NSDictionary dictionaryWithObject:self.sectionNameLabel.font forKey: NSFontAttributeName];
    CGSize sectionLabelSIze = [self.sectionNameLabel.text boundingRectWithSize:CGSizeMake(self.sectionNameLabel.frame.size.width, self.sectionNameLabel.frame.size.height) options:NSStringDrawingTruncatesLastVisibleLine|NSStringDrawingUsesLineFragmentOrigin attributes:sectionAttributes context:nil].size;
    if (sectionLabelSIze.height < 50) {
        self.sectionNameLabel.frame = CGRectMake(self.sectionNameLabel.frame.origin.x, self.sectionNameLabel.frame.origin.y, self.sectionNameLabel.frame.size.width, sectionLabelSIze.height);
    }
    [self addSubview:self.selectedTextLabel];
    [self addSubview:self.chapterLable];
    [self addSubview:self.sectionNameLabel];
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
