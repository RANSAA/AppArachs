//
//  AppDelegate.m
//  AppArachs
//
//  Created by PC on 2021/8/12.
//

#import "AppDelegate.h"
#import "AppDelegate+Exit.h"


@interface AppDelegate ()


@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    [self addQuitActions];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


@end
