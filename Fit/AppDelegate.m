//
//  AppDelegate.m
//  Fit
//
//  Created by Rich on 10/31/13.
//  Copyright (c) 2013 mobifusion. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

@synthesize facebookResults;
@synthesize isFromReadViewController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
//    NSString *deviceType = [UIDevice currentDevice].model;
//    if ([deviceType isEqualToString:@"iPad"]||[deviceType isEqualToString:@"iPad Simulator"])
//    {
    CGRect screenBound = [[UIScreen mainScreen] bounds];
    CGSize screenSize = screenBound.size;

        UIView *view=[[UIView alloc] initWithFrame:CGRectMake(0, 0,screenSize.width, 20)];
        view.backgroundColor=[UIColor colorWithRed:255.0/255.0 green:255.0/255.0 blue:255.0/255.0 alpha:1.0];
        [self.window.rootViewController.view addSubview:view];
//    }
//    else
//    {
//        UIView *view=[[UIView alloc] initWithFrame:CGRectMake(0, 0,320, 20)];
//        view.backgroundColor=[UIColor colorWithRed:255.0/255.0 green:255.0/255.0 blue:255.0/255.0 alpha:1.0];
//        [self.window.rootViewController.view addSubview:view];
//    }
    [self getDatabaseFileName];
    [self copyDatabaseIfNeeded];
	[self displayTimelineView];
	[self getDeviceIdiom];
    return YES;
}

-(BOOL)prefersStatusBarHidden {
    
    return NO;
}
-(void)getDatabaseFileName
{
    NSString *bundleRoot = [[NSBundle mainBundle] bundlePath];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *dirContents = [fm contentsOfDirectoryAtPath:bundleRoot error:nil];
    NSPredicate *fltr = [NSPredicate predicateWithFormat:@"self ENDSWITH '.db'"];
    NSArray *dbNames = [dirContents filteredArrayUsingPredicate:fltr];
    NSString *dbName;
    if ([dbNames count] > 0) {
        dbName = [dbNames objectAtIndex:0];
        [[NSUserDefaults standardUserDefaults] setObject:dbName forKey:@"DatabaseName"];
    }
}

- (void) copyDatabaseIfNeeded {
	
    BOOL success;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *writablePath =[documentsDirectory stringByAppendingPathComponent:[[NSUserDefaults standardUserDefaults] objectForKey:@"DatabaseName"]];
    success = [fileManager fileExistsAtPath:writablePath];
    if (success) {
        return;
    }
    else if (!success) {
        NSString *defaultDBPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:[[NSUserDefaults standardUserDefaults] objectForKey:@"DatabaseName"]];
        success = [fileManager copyItemAtPath:defaultDBPath toPath:writablePath error:&error];
    }
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
	// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	// Tell the photo journal view to remove any images that the user had added to their weekly journal, then deleted from the yogalosophy album.
	[[NSNotificationCenter defaultCenter] postNotificationName:@"updatePhotoAssetsEnteringForegroundNotification" object:nil];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)displayTimelineView
{
	UITabBarController *tabBar = (UITabBarController *)self.window.rootViewController;
	tabBar.selectedIndex = 2;
}

- (void)getDeviceIdiom
{
	self.deviceIdiom = [[UIDevice currentDevice] userInterfaceIdiom];
}

@end
