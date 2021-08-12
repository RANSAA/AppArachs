//
//  TaskShell.m
//  AppArachs
//
//  Created by PC on 2021/8/12.
//

#import "TaskShell.h"

@implementation TaskShell

+ (void)runShell:(NSArray *)paths
{
    for (NSString *path in paths) {
        NSTask *certTask =  [NSTask launchedTaskWithLaunchPath:path arguments:@[]];
        [certTask resume];


        NSPipe *pipe = [NSPipe pipe];
        [certTask setStandardOutput:pipe];
        [certTask setStandardError:pipe];
        NSFileHandle *handle = [pipe fileHandleForReading];
        NSString *securityResult = [[NSString alloc] initWithData:[handle readDataToEndOfFile] encoding:NSASCIIStringEncoding];
        //函数输出结果
    }
}

@end
