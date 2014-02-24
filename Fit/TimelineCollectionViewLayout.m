//
//  TimelineCollectionViewLayout.m
//  Fit
//
//  Created by Rich on 11/26/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//

#import "TimelineCollectionViewLayout.h"

@implementation TimelineCollectionViewLayout

float section0Height, section1Height;
float totalContentHeight;
float collectionViewWidth;
int section0CellCount, section1CellCount;
int section0Adjustment = 0;

CGSize totalContentSize;

NSMutableArray *section0AttributesArray = nil;
NSMutableArray *section1AttributesArray = nil;

#pragma mark - Initialization

// note: flow-based layout control isn't quite adequate for the timeline view's "staggered column" look.  flow layout tries very hard to distribute cells across "rows."
// staggering columns by adjusting the y origin of the left or right cells up or down (in the view controller) will cause cells to "pop" in and out of view before they
// are scrolled up or down off screen.  this is because the flow-based layout control still thinks the bottom / top edges of adjacent cells, in a "row," are even.
// instead, a custom layout controller allows us to specify the exact position of all cells.  thus, because we tell the controller each cell's y origin and height,
// it knows exactly when to re-use cells as they scroll offscreen.

- (void)prepareLayout
{
	[self calculateSizes];
	[self initializeArrays];
}

- (void)calculateSizes
{
	section0CellCount = (int)[self.collectionView numberOfItemsInSection:0];			// cell count includes "header" and "footer" cells (index 0 and n-1 for n cells in section 0 and 1)
	section1CellCount = (int)[self.collectionView numberOfItemsInSection:1];
	section0Adjustment = (section0CellCount == 2 ? kTimelineSection0AdjustmentZero : kTimelineSection0Adjustment);
	section0Height = kTimelineHeader0Height + section0Adjustment + kTimelineFooter0Height + section0CellCount * (((float)kTimelineChapterCellHeight / 2.0f) + kTimelineChapterCellYGap);
	section1Height = kTimelineHeader1Height + kTimelineFooter1Height + section1CellCount * (((float)kTimelineUnreadChapterCellHeight / 2.0f) + kTimelineUnreadChapterCellYGap);
	totalContentHeight = section0Height + section1Height;
	collectionViewWidth = self.collectionView.frame.size.width;
	totalContentSize = CGSizeMake(self.collectionView.frame.size.width, totalContentHeight);
}

- (void)initializeArrays
{
	section0AttributesArray = [[NSMutableArray alloc] initWithCapacity:0];
	section1AttributesArray = [[NSMutableArray alloc] initWithCapacity:0];
	
	for (int itemIndex = 0; itemIndex < section0CellCount; itemIndex++)
		[section0AttributesArray addObject:[self makeAttributesObjectForSection:0 forIndex:itemIndex]];
	
	for (int itemIndex = 0; itemIndex < section1CellCount; itemIndex++)
		[section1AttributesArray addObject:[self makeAttributesObjectForSection:1 forIndex:itemIndex]];
}

- (UICollectionViewLayoutAttributes *)makeAttributesObjectForSection:(int)sectionIndex forIndex:(int)itemIndex
{
	NSIndexPath *indexPath = [NSIndexPath indexPathForItem:itemIndex inSection:sectionIndex];
	UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
	
	if (sectionIndex == 0)
	{
		if (itemIndex == 0)
			[self setAttributesForBookTitle:attributes];
		else if (itemIndex == (section0CellCount - 1))
			[self setAttributesForCurrentChapterProgress:attributes];
		else
			[self setAttributesForChapterCell:attributes forSection:sectionIndex forIndex:itemIndex];
	}
	else
	{
		if (itemIndex == 0)
			[self setAttributesForCurrentChapterInfo:attributes];
		else
			[self setAttributesForChapterCell:attributes forSection:sectionIndex forIndex:itemIndex];
	}

	return attributes;
}

- (void)setAttributesForBookTitle:(UICollectionViewLayoutAttributes *)attributes
{
	attributes.frame = CGRectMake(0.0f, 0.0f, collectionViewWidth, kTimelineHeader0Height);
	attributes.size = CGSizeMake(collectionViewWidth, kTimelineHeader0Height);
}

- (void)setAttributesForChapterCell:(UICollectionViewLayoutAttributes *)attributes forSection:(int)sectionIndex forIndex:(int)itemIndex
{
	float yOffset = 0.0f;
	float cellHeight = (sectionIndex == 0 ? kTimelineChapterCellHeight : kTimelineUnreadChapterCellHeight);
	float section1Offset = kTimelineSection1YOffset;
	
	if (DEVICE_IS_IPAD)
		section1Offset = kTimelineSection1YOffsetIPad;
	
	if (sectionIndex == 0)
		yOffset = kTimelineHeader0Height + section0Adjustment + ((cellHeight / 2.0f) + kTimelineChapterCellYGap) * (float)itemIndex;
	else
		yOffset = section0Height + kTimelineHeader1Height + section1Offset + ((cellHeight / 2.0f) + kTimelineUnreadChapterCellYGap) * (float)itemIndex;

	attributes.frame = CGRectMake(0.0f, yOffset, kTimelineChapterCellWidth, cellHeight);
	attributes.size = CGSizeMake(kTimelineChapterCellWidth, cellHeight);
}

- (void)setAttributesForCurrentChapterProgress:(UICollectionViewLayoutAttributes *)attributes
{
	float yOffset = section0Height - kTimelineFooter0Height;
	attributes.frame = CGRectMake(0.0f, yOffset, kTimelineChapterCellWidth, kTimelineFooter0Height);
	attributes.size = CGSizeMake(kTimelineChapterCellWidth, kTimelineFooter0Height);
}

- (void)setAttributesForCurrentChapterInfo:(UICollectionViewLayoutAttributes *)attributes
{
	float yOffset = section0Height + kTimelineCurrentChapterYOffset;
    if (DEVICE_IS_IPAD)
    {
        float xOffset = (attributes.indexPath.section == 1) ? ((self.collectionView.frame.size.width - kTimelineCurrentChapterCellWidthiPad) / 2.0f) : 0.0f;
        attributes.frame = CGRectMake(xOffset, yOffset, kTimelineCurrentChapterCellWidthiPad, kTimelineCurrentChapterCellHeightiPad);
        attributes.size = CGSizeMake(kTimelineCurrentChapterCellWidthiPad, kTimelineCurrentChapterCellHeightiPad);
    }
    else
    {
        float xOffset = (attributes.indexPath.section == 1) ? ((self.collectionView.frame.size.width - kTimelineCurrentChapterCellWidth) / 2.0f) : 0.0f;
        attributes.frame = CGRectMake(xOffset, yOffset, kTimelineCurrentChapterCellWidth, kTimelineCurrentChapterCellHeight);
        attributes.size = CGSizeMake(kTimelineCurrentChapterCellWidth, kTimelineCurrentChapterCellHeight);
    }
	attributes.zIndex = 200;
}

#pragma mark - Data source

- (CGSize)collectionViewContentSize
{
	return totalContentSize;
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
	NSMutableArray *attribs = [[NSMutableArray alloc] initWithArray:section0AttributesArray];
	[attribs addObjectsFromArray:section1AttributesArray];
	return attribs;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
	// note: if we return YES, prepareLayout will be called every time the collection view's scrollview moves 1 pixel, which is hideously inefficient.
	return NO;
}

@end
