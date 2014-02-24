//
//  Scalars.h
//  Fit
//
//  Created by Rich on 11/3/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//

#ifndef Fit_Scalars_h
#define Fit_Scalars_h

enum ScrollDirection
{
    kScrollDirectionNone	= 0,				// initial state: not scrolling yet
    kScrollDirectionRight	= 1,				// "right" as in user swiping finger to the right ...
    kScrollDirectionLeft	= 2,				// ... etc.
    kScrollDirectionUp		= 3,
    kScrollDirectionDown	= 4,
};

enum OutgoingWebServicesActions
{
	kCreateAnonymousUserAction	= 0,			// for web services to tell outgoing mobi analytics requests what action is required
	kSessionInfoRequestAction	= 1,
	kStartNewSessionAction		= 2,
	kRequestPageHistoryAction	= 3,
	kRequestNewMobiUserAction	= 4,
	kLoginExistingUserAction	= 5,
	kLoginFromFacebook			= 6,
	kLoginFromTwitter			= 7,
};

enum TimelineViewConstants
{
	kTimelineHeader0Height = 100,				// section 0 "header" is really cell 0 of section 0 (with big title image and title text)
	kTimelineHeader1Height = 220,				// section 1 "header" is really cell 0 of section 1 (with larger-than-normal chapter information)

	kTimelineFooter0Height = 80,				// section 0 "footer" is really cell n-1 of section 0 (with user avatar image and current chapter progess circle)
	kTimelineFooter1Height = 0,					// section 1 "footer" is just empty space
	
	kTimelineSection0Adjustment = -100,			// adjustable spacing between section 0 "book title" cell and first normal chapter cell
	kTimelineSection0AdjustmentZero = -225,		// adjustable spacing between section 0 title cell and user avatar if nothing has been read yet
	kTimelineAnimationAdjustment = -135,		// adjustment for autoscroll to current chapter and user avatar (with some reading already completed)
	kTimelineZeroReadAdjustment = -85,			// different adjustment for autoscroll to current chapter when nothing has been read yet

	kTimelineChapterCellHeight = 200,			// normal chapter cell height
	kTimelineUnreadChapterCellHeight = 92,		// unread chapter cell height
	kTimelineChapterCellWidth = 130,
	kTimelineChapterCellYGap = 10,				// adjustable spacing between normal chapter cells
	kTimelineUnreadChapterCellYGap = 9,

	kTimelineCurrentChapterCellHeight = 250,	// large current chapter cell height
	kTimelineCurrentChapterCellWidth = 180,		// large current chapter cell width
    kTimelineCurrentChapterCellHeightiPad = 282, // large current chapter cell height For iPad
    kTimelineCurrentChapterCellWidthiPad = 207,		// large current chapter cell width For iPad
    
	kTimelineCurrentChapterYOffset = 20,		// adjust this to change the distance between the circular current chapter progress indicator and  current chapter info
	kTimelineSection1YOffset = -20,				// adjust this to change the overlap of current chapter info and semi-translucent unread chapter that it partially covers
	kTimelineSection1YOffsetIPad = 10,
};

enum EmoticonValues
{
	kUnhappy = 0,
	kNeutral = 1,
	kHappy = 2,
};

#endif
