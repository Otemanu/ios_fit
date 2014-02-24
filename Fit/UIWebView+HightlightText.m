//
//  UIWebView+HightlightText.m
//  Fit
//
//  Created by Mobi on 15/11/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//

#import "UIWebView+HightlightText.h"

@implementation UIWebView (HightlightText)

- (NSString *)selectedText {
    return [self stringByEvaluatingJavaScriptFromString:@"window.getSelection().toString()"];
}

-(NSString *) hightlightSelectedText
{
    NSString *startSearch   = [NSString stringWithFormat:@"getSelectionCharOffsetsWithin()"];
	[self stringByEvaluatingJavaScriptFromString:startSearch];
    NSString *stringByEvaluate=[self
                                stringByEvaluatingJavaScriptFromString:@"document.documentElement.outerHTML"];
    stringByEvaluate = [stringByEvaluate stringByReplacingOccurrencesOfString:@"'" withString:@""];
    return stringByEvaluate;
}
@end
