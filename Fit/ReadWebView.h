//
//  ReadWebView.h
//  Fit
//
//  Created by Rich on 12/9/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WebServicesEngine.h"

@interface ReadWebView : UIWebView <UIWebViewDelegate>
{
}

@property (nonatomic,weak) NSObject <UIScrollViewDelegate> *ReadWebViewScrollDelegate;

@end
