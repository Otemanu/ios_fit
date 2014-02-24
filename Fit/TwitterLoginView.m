//
//  TwitterLoginView.m
//  Fit
//
//  Created by Rich on 11/20/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//

#import "TwitterLoginView.h"
#import "WebServicesEngine.h"

@implementation TwitterLoginView

WebServicesEngine *twitterLoginViewWebServicesEngine = nil;					// singleton
UIWebView *twitterWebView;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
	
    if (self)
	{
		// for testing only
		UILabel *helloWorldLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 250.0f, 320.0f, 100.0f)];
		helloWorldLabel.text = @"Twitter login view";
		helloWorldLabel.font = [UIFont systemFontOfSize:36.0f];
		helloWorldLabel.textColor = [UIColor whiteColor];
		helloWorldLabel.textAlignment = NSTextAlignmentCenter;
		helloWorldLabel.numberOfLines = 0;
		[self addSubview:helloWorldLabel];
 		[self registerForNotifications];
		twitterWebView = [[UIWebView alloc] initWithFrame:self.frame];
		CGRect frame = twitterWebView.frame;
		frame.origin.x = 0.0f;
		twitterWebView.frame = frame;
		twitterWebView.delegate = self;
		[self doTwitterLogin];
   }
	
    return self;
}

- (void)doTwitterLogin
{
	twitterLoginViewWebServicesEngine = [WebServicesEngine webServicesEngine];
	[twitterLoginViewWebServicesEngine startTwitterLogin];
}

- (void)registerForNotifications
{
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleTwitterURL:)
												 name:@"twitterURLNotification"
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleTwitterURL:)
												 name:@"twitterLoginDoneNotification"
											   object:nil];
}

- (void)unRegisterForNotifications
{
 	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:@"twitterURLNotification"
												  object:nil];
 	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:@"twitterLoginDoneNotification"
												  object:nil];
}

- (void)handleTwitterURL:(NSNotification *)notification
{
	NSURL *webViewURL = [NSURL URLWithString:(NSString *)notification.object];
	NSURLRequest *webViewURLRequest = [NSURLRequest requestWithURL:webViewURL];
	
	[twitterWebView loadRequest:webViewURLRequest];
	
	[twitterWebView setBackgroundColor:[UIColor whiteColor]];
	[twitterWebView setOpaque:NO];
	[self addSubview:twitterWebView];
	[self setNeedsDisplay];
}

- (void)dealloc
{
	[self unRegisterForNotifications];
}

@end
