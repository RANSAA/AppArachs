//
//  ViewController.m
//  AppArachs
//
//  Created by PC on 2021/8/12.
//

#import "ViewController.h"
#import "PermissionsKit.h"
#import "HelpViewController.h"


#define kMacOS [self.platformName containsString:@"mac"]
#define KiOS [self.platformName containsString:@"iphone"]

@interface ViewController()
@property (nonatomic,strong) IBOutlet NSPopUpButton *listItem;
@property (nonatomic,strong) IBOutlet NSTextView *textViewInfo;
@property (strong) IBOutlet NSButton *btnFullDisk;
@property (strong) IBOutlet NSButton *btnAllAppliions;
@property (strong) IBOutlet NSButton *btnSelected;


@property (nonatomic,copy) NSString *appName;
@property (nonatomic,copy) NSImage *appIcns;
@property (nonatomic,strong) NSDictionary *info;
@property (nonatomic,strong) NSString *platformName;
@property (nonatomic,copy) NSString *arch;
@property (nonatomic, strong) NSArray *whiteList;

@property (nonatomic, strong) NSMutableString *mString;
@property (nonatomic, strong) NSTextStorage *textStorage;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    [self.listItem removeAllItems];
    [self.listItem addItemsWithTitles:@[@"arm64",@"x86_64",@"i386"]];
    self.arch = self.listItem.selectedItem.title;
    NSLog(@"whiteList:%@",self.whiteList);

    self.mString = [[NSMutableString alloc] init];
    self.textStorage = self.textViewInfo.textStorage;

}

- (NSArray *)whiteList
{
    if (!_whiteList) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"whitelist" ofType:@"plist"];
        _whiteList = [[NSArray alloc] initWithContentsOfFile:path];
        _whiteList = _whiteList ? _whiteList : @[@"AppArachs",@"App廋身工具"];
    }
    return _whiteList;
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

- (IBAction)btnFullDiskAction:(NSButton *)sender {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.alertStyle = NSAlertStyleWarning;
    [alert setMessageText:@"获取完整的磁盘访问权限"];
    [alert setInformativeText:@"系统偏好设置 -> 安全与隐私 -> 完整的磁盘访问权限\n 添加：AppArachs (App廋身工具)"];
    [alert addButtonWithTitle:@"授权"];
    [alert addButtonWithTitle:@"取消"];


    [alert beginSheetModalForWindow:NSApplication.sharedApplication.keyWindow completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSAlertFirstButtonReturn) {//确定
            [MPPermissionsKit requestAuthorizationForPermissionType:MPPermissionTypeFullDiskAccess withCompletion:^(MPAuthorizationStatus status) {
                NSLog(@"status:%ld",status);
            }];
        }else if (returnCode == NSAlertSecondButtonReturn){//取消

        }else{

        }
    }];

}

- (IBAction)btnHelpAction:(NSButton *)sender {
    NSStoryboard *story = [NSStoryboard storyboardWithName:@"Main" bundle:nil];
    HelpViewController *vc = [story instantiateControllerWithIdentifier:@"HelpViewController"];
    [self presentViewControllerAsModalWindow:vc];
}



- (IBAction)selecteItemAction:(NSPopUpButton *)sender {
    self.arch = sender.selectedItem.title;
}


- (IBAction)selecteAppAction:(NSButton *)sender {
    NSLog(@"移出架构操作");
    [self appArachsBegan];
    [self openPanelCompletion:^(NSString *path) {
        [self checkAppWith:path single:YES];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self alert:0 completionHandler:^{
                dispatch_async(dispatch_get_global_queue(0, 0), ^{
                    NSArray *archs = [self archsWith:path];
                    [self runShell:archs];
                });
            }];
        });
    }];
}

- (IBAction)allApplicationsAcion:(NSButton *)sender {
    NSLog(@"移出ALL APP架构操作");
    [self appArachsBegan];
    [self alert:1 completionHandler:^{
        [self allApplicationsArchs];
    }];
}


/**
 type: 0： 移出单个APP  1：移出所有APP(白名单除外)
 */
- (void)alert:(NSInteger)type completionHandler:(void (^ _Nullable)(void))handler
{
    NSString *title = @"当前选中:/Applications中的所有APP";
    NSString *msg = [NSString stringWithFormat:@"⚠️：这是一个高危操作！\n⚠️：不会选中系统应用与白名单中的应用\n⚠️：这个操作会移出选中应用的%@架构",self.arch];
    if (type == 0) {
        title = [NSString stringWithFormat:@"当前选中：%@",self.appName];
        msg = [NSString stringWithFormat:@"\n⚠️：这个操作会移出选中应用的%@架构",self.arch];
    }

    NSAlert *alert = [[NSAlert alloc] init];
    alert.alertStyle = NSAlertStyleWarning;
    [alert setMessageText:title];
    [alert setInformativeText:msg];
    [alert addButtonWithTitle:[NSString stringWithFormat:@"移出%@架构",self.arch]];
    [alert addButtonWithTitle:@"取消"];
    if (type == 0 && self.appIcns) {
        alert.icon = self.appIcns;
    }

    [alert beginSheetModalForWindow:NSApplication.sharedApplication.keyWindow completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSAlertFirstButtonReturn) {//确定
            if (handler) {
                self.appIcns = nil;
                NSString *nodeStr = @"开始处理......\n";
                if (type == 1) {
                    nodeStr = @"开始处理......\n这是一个耗时操作请耐心等待......\n";
                }
                [self.textStorage replaceCharactersInRange:NSMakeRange(0, self.textStorage.string.length) withString:nodeStr];

                [self appArachsBegan];
                handler();
            }
        }else if (returnCode == NSAlertSecondButtonReturn){//取消
            [self.textStorage replaceCharactersInRange:NSMakeRange(0, self.textStorage.string.length) withString:@""];
            [self appArachsEnd];
        }else{

        }
    }];
}

- (void)openPanelCompletion:(void (^ _Nullable)(NSString * path))handler
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    openPanel.allowsOtherFileTypes = false;
    openPanel.treatsFilePackagesAsDirectories = false;
    openPanel.canChooseFiles = true;
    openPanel.canChooseDirectories = false;
    openPanel.canCreateDirectories = false;
    openPanel.prompt = @"选择";
    [openPanel beginSheetModalForWindow:NSApplication.sharedApplication.keyWindow completionHandler:^(NSModalResponse result) {
        if (result == NSModalResponseOK) {
            if (handler) {
                [self appArachsBegan];
                handler(openPanel.URL.path);
            }
        }else if (result == NSModalResponseCancel){
            [self appArachsEnd];
        }
    }];
}


#pragma mark shell
- (void)runShell:(NSArray *)paths
{
    dispatch_async(dispatch_get_global_queue(0,0), ^{

        NSString *file = [[NSBundle mainBundle] pathForResource:@"lipo" ofType:@"plist"];
        NSDictionary *info = [[NSDictionary alloc] initWithContentsOfFile:file];
        NSString *lipo = info[@"lipoPath"];
        if (!lipo) {
            lipo = @"/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/lipo";
        }

        // 1.创建队列
        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
        // 2.设置最大并发操作数
        queue.maxConcurrentOperationCount = 1; // 串行队列
        // queue.maxConcurrentOperationCount = 2; // 并发队列
        // queue.maxConcurrentOperationCount = 8; // 并发队列
        for (NSString *path in paths){
            [queue addOperationWithBlock:^{
                NSTask *certTask = [[NSTask alloc]init];
                [certTask setLaunchPath:lipo];
                [certTask setArguments:@[
                    @"-remove",
                    self.arch,
                    path,
                    @"-output",
                    path
                ]];
                NSPipe *pipe = [NSPipe pipe];
                [certTask setStandardOutput:pipe];
                [certTask setStandardError:pipe];
                NSFileHandle *handle = [pipe fileHandleForReading];
                [certTask launch];

                //函数输出结果
                NSString *shellResult = [[NSString alloc] initWithData:[handle readDataToEndOfFile] encoding:NSUTF8StringEncoding];
                [self.mString appendString:shellResult];
                // 回到主线程
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    [self.textStorage appendAttributedString:[[NSAttributedString alloc]initWithString:shellResult]];
                    [self.textViewInfo scrollRangeToVisible: NSMakeRange(self.textStorage.string.length, 0)];
                }];
            }];
        }

        [queue waitUntilAllOperationsAreFinished];
//        [queue cancelAllOperations];

        dispatch_async(dispatch_get_main_queue(), ^{
            [self.textStorage appendAttributedString:[[NSAttributedString alloc]initWithString:@"\n✅处理完成!!!"]];
            [self.textViewInfo scrollRangeToVisible: NSMakeRange(self.textStorage.string.length, 0)];
        });


        //执行完成后，恢复按钮状态
        [self appArachsEnd];

    });
}

#pragma mark 检查APP信息
- (void)checkAppWith:(NSString *)path single:(BOOL)single
{
    self.info = [[NSDictionary alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/Contents/Info.plist",path]];
    self.platformName = [self.info[@"DTSDKName"] lowercaseString];

    if (single) {//选中单个APP
        NSString *imgPath = [NSString stringWithFormat:@"%@/Contents/Resources/%@",path,self.info[@"CFBundleIconFile"]];
        if (![imgPath.pathExtension isEqualToString:@"icns"]) {
            imgPath = [NSString stringWithFormat:@"%@.icns",imgPath];
        }
        self.appIcns = [[NSImage alloc] initWithContentsOfFile:imgPath];
        self.appName = path.lastPathComponent;
    }
}


/**
 需要移出指定架构的文件路径
 */
- (NSArray *)archsWith:(NSString *)path
{
    if (![path.pathExtension isEqualToString:@"app"]) {
        return @[path];
    }
    //解析APP
    NSFileManager *fm = NSFileManager.defaultManager;
    NSMutableArray *ary = @[].mutableCopy;
    if (kMacOS) {
        //MacOS
        [ary addObject:[NSString stringWithFormat:@"%@/Contents/MacOS/%@",path,self.info[@"CFBundleExecutable"]]];
        //Frameworks
        NSString *frameworks = [NSString stringWithFormat:@"%@/Contents/Frameworks/",path];
        NSDirectoryEnumerator *dirEnum = [fm enumeratorAtPath:frameworks];
//        NSLog(@"frameworks:%@",frameworks);
        NSString *sub;
        while ((sub = [dirEnum nextObject]) != nil)
        {
            if ([sub containsString:@"app/Contents/MacOS/"]) {
                [ary addObject:[NSString stringWithFormat:@"%@%@",frameworks,sub]];
            }else if ([sub containsString:@"framework/"]){
                if ([sub containsString:@"Versions/A"] && ![sub containsString:@"_CodeSignature"] && ![sub containsString:@"Resources"] && ![sub containsString:@"Headers/"] && ![sub containsString:@"PrivateHeaders/"]) {
                    [ary addObject:[NSString stringWithFormat:@"%@%@",frameworks,sub]];
                }else if ([sub containsString:@".dylib"]){
                    [ary addObject:[NSString stringWithFormat:@"%@%@",frameworks,sub]];
                }
            }
        }
        //Library
        NSString *library = [NSString stringWithFormat:@"%@/Contents/Library/",path];
        dirEnum = [fm enumeratorAtPath:library];
        while ((sub = [dirEnum nextObject]) != nil)
        {
            if ([sub containsString:@"Contents/MacOS/"]) {
                [ary addObject:[NSString stringWithFormat:@"%@%@",library,sub]];
            }
        }
        //PlugIns
        NSString *plugIns = [NSString stringWithFormat:@"%@/Contents/PlugIns/",path];
        dirEnum = [fm enumeratorAtPath:plugIns];
        while ((sub = [dirEnum nextObject]) != nil)
        {
            if ([sub containsString:@"app/Contents/"]) {
                if ([sub containsString:@"Contents/MacOS/"]) {
                    [ary addObject:[NSString stringWithFormat:@"%@%@",plugIns,sub]];
                }else if ([sub containsString:@"Library/"]){
                    if ([sub containsString:@"Contents/MacOS"]) {
                        [ary addObject:[NSString stringWithFormat:@"%@%@",plugIns,sub]];
                    }
                }else if([sub containsString:@"Frameworks/"]){
                    if ([sub containsString:@"Versions/A"] && ![sub containsString:@"_CodeSignature"] && ![sub containsString:@"Resources"]) {
                        [ary addObject:[NSString stringWithFormat:@"%@%@",plugIns,sub]];
                    }else if ([sub containsString:@".dylib"]){
                        [ary addObject:[NSString stringWithFormat:@"%@%@",plugIns,sub]];
                    }
                }
            }

        }

    }else if (KiOS){

    }

    BOOL isDir = NO;
    NSMutableArray *result = @[].mutableCopy;
    for (NSString *str in ary) {
        if ([fm fileExistsAtPath:str isDirectory:&isDir]) {
            if (!isDir) {
                [result addObject:str];
            }
        }
    }
    self.info = nil;
    return result;
}

- (void)allApplicationsArchs
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSString *applications = @"/Applications";
        NSFileManager *fm = NSFileManager.defaultManager;
        NSSet *set = [[NSSet alloc] initWithArray:self.whiteList];
        NSArray *fileAry =  [fm contentsOfDirectoryAtPath:applications error:nil];
        NSMutableArray *resultAry = @[].mutableCopy;

        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
        // 2.设置最大并发操作数
        queue.maxConcurrentOperationCount = 1; // 串行队列

        for (NSString *item in fileAry) {
            [queue addOperationWithBlock:^{
                if ([item.pathExtension isEqualToString:@"app"]) {
                    NSString *name = item.stringByDeletingPathExtension;
                    if (![set containsObject:name]) {
                        NSString *itemPath = [NSString stringWithFormat:@"%@/%@",applications,item];
                        [self checkAppWith:itemPath single:NO];
                        NSArray *ary = [self archsWith:itemPath];
                        if (ary.count > 0) {
                            [resultAry addObjectsFromArray:ary];
                            NSString *nodeStr = [NSString stringWithFormat:@"%@",ary];
                            // 回到主线程
                            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                [self.textStorage appendAttributedString:[[NSAttributedString alloc]initWithString:nodeStr]];
                                [self.textViewInfo scrollRangeToVisible: NSMakeRange(self.textStorage.string.length, 0)];
                            }];
                        }
                    }
                }
            }];
        }

        [queue waitUntilAllOperationsAreFinished];

        [self runShell:resultAry];

    });

}


- (void)appArachsBegan
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.listItem.enabled = NO;
        self.btnFullDisk.enabled = NO;
        self.btnAllAppliions.enabled = NO;
        self.btnSelected.enabled = NO;
    });
}

- (void)appArachsEnd
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.listItem.enabled = YES;
        self.btnFullDisk.enabled = YES;
        self.btnAllAppliions.enabled = YES;
        self.btnSelected.enabled = YES;
    });
}

@end
