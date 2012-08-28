//
//  Copyright (c) 2012 Foley Productions LLC. All rights reserved.
//

#import "AppDelegate.h"
#import "MainController.h"

@interface AppDelegate()

@property (nonatomic, retain) MainController *mainCtrl;

@end


@implementation AppDelegate

@synthesize window      = _window;
@synthesize mainCtrl    = _mainCtrl;

- (void)dealloc{
    [_mainCtrl release], _mainCtrl = nil;
    [_window release], _window = nil;
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions{
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    self.window.backgroundColor = [UIColor whiteColor];
    
    MainController *c = [[MainController alloc] init];
    self.mainCtrl = c;
    [c release];
    
    [self.window addSubview:self.mainCtrl.view];    
    [self.window makeKeyAndVisible];
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application{}

- (void)applicationDidEnterBackground:(UIApplication *)application{}

- (void)applicationWillEnterForeground:(UIApplication *)application{}

- (void)applicationDidBecomeActive:(UIApplication *)application{
#warning This is important in your app.
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookieAcceptPolicy:NSHTTPCookieAcceptPolicyAlways];
}

- (void)applicationWillTerminate:(UIApplication *)application{}

@end
