//
//  AppDelegate+Exit.m
//  AppArachs
//
//  Created by PC on 2022/5/27.
//

#import "AppDelegate+Exit.h"

@implementation AppDelegate (Exit)

static bool exitHolderOnce = YES;

/**
 添加左上角的Quit按钮与关闭按钮监听
 */
- (void)addQuitActions
{
    NSMenuItem *quitMenu = NSApplication.sharedApplication.mainMenu.itemArray.firstObject.submenu.itemArray.lastObject;
    [quitMenu setTarget:self];
    [quitMenu setAction:@selector(quitMeunExitAction)];
    NSLog(@"quitMenu:%@",quitMenu);

    //监听关闭按钮
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(terminateApp) name:NSWindowWillCloseNotification object:nil];

}

- (void)quitMeunExitAction
{
    NSLog(@"左上角右键quit按钮退出程序");
    [self terminateApp];
    exit(0);
//    [[NSApplication sharedApplication] terminate:nil];
}


//点击左上角 x 关闭程序
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    NSLog(@"点击 x 关闭程序。。。");
    [self terminateApp];
    return YES;
}

//dock右键退出
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    if (exitHolderOnce == NO){//防止点击左上角 x 关闭程序时会调用该退出方法
        exit(0);
    }

    NSLog(@"dock右键退出");
    [self terminateApp];
    return NSTerminateNow;
}


// 清理正在运行的任务
- (void)terminateApp {
    if (exitHolderOnce) {
        exitHolderOnce = NO;
        NSLog(@"清理正在运行的任务");

        // [[ShellTask shared] stopShell];
    }
}

@end
