//
//  FacebookLoginView.m
//  Fit
//
//  Created by Rich on 11/20/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//

#import "FacebookLoginView.h"
#import "WebServicesEngine.h"

@implementation FacebookLoginView

WebServicesEngine *facebookLoginViewWebServicesEngine = nil;					// singleton
UIWebView *facebookWebView;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    if (self)
	{
		// for testing only
		UILabel *helloWorldLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 250.0f, 320.0f, 100.0f)];
		helloWorldLabel.text = @"Facebook login view";
		helloWorldLabel.font = [UIFont systemFontOfSize:36.0f];
		helloWorldLabel.textColor = [UIColor whiteColor];
		helloWorldLabel.textAlignment = NSTextAlignmentCenter;
		helloWorldLabel.numberOfLines = 0;
		[self addSubview:helloWorldLabel];
		[self registerForNotifications];
		facebookWebView = [[UIWebView alloc] initWithFrame:self.frame];
		CGRect frame = facebookWebView.frame;
		frame.origin.x = 0.0f;
		facebookWebView.frame = frame;
		facebookWebView.delegate = self;
		[self doFacebookLogin];
    }

    return self;
}

- (void)doFacebookLogin
{
	facebookLoginViewWebServicesEngine = [WebServicesEngine webServicesEngine];
	[facebookLoginViewWebServicesEngine startFacebookLogin];
}

- (void)registerForNotifications
{
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleFacebookURL:)
												 name:@"facebookURLNotification"
											   object:nil];
}

- (void)unRegisterForNotifications
{
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:@"facebookURLNotification"
												  object:nil];
}

- (void)handleFacebookURL:(NSNotification *)notification
{
	NSURL *webViewURL = [NSURL URLWithString:(NSString *)notification.object];
	NSURLRequest *webViewURLRequest = [NSURLRequest requestWithURL:webViewURL];
	
	[facebookWebView loadRequest:webViewURLRequest];

	[facebookWebView setBackgroundColor:[UIColor whiteColor]];
	[facebookWebView setOpaque:NO];
	[self addSubview:facebookWebView];
	[self setNeedsDisplay];
}

#pragma mark - Webview delegate methods

- (BOOL) webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
	return YES;
}

- (void) webViewDidStartLoad:(UIWebView *)webView
{
}


- (void) webViewDidFinishLoad:(UIWebView *)webView
{
}


- (void) webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
}

#pragma mark - View lifecycle

- (void)dealloc
{
	[self unRegisterForNotifications];
}

@end
