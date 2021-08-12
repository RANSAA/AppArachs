//
//  HelpViewController.m
//  AppArachs
//
//  Created by PC on 2021/8/12.
//

#import "HelpViewController.h"

@interface HelpViewController ()
@property (strong) IBOutlet NSTextView *textViewInfo;

@end

@implementation HelpViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"AppArachs说明";
    self.view.frame = CGRectMake(0, 0, 900, 480);

    // Do view setup here.
    NSString *text = @"\n                                                                         "
    "本工具主要用来移除APP不需要的架构，以达到节省磁盘空间的目的。\n\n\n\n\n"
    "       完整的磁盘访问权限：需要给本应用添加完整的磁盘访问权限，只需要单击授权按钮一次即可;\n\n"
    "       选择需要移出的架构：可以选择arm64，x86_64，i385三种架构，由具体的CPU架构决定，如：x86_64平台可以选择arm64\n\n"
    "       架构移出说明：本应用总会让程序保证有一种架构，如App是x86_64并且只有这一种架构时，选择需要移出的依然是x86_64时这个操作将会无效，\n\n"
    "       选择APP：选中某一个APP移出不需要的架构\n\n"
    "       选中所有应用程序：这个操作会移出/Applications中的所有APP（白名单除外）中的不需要的架构\n\n"
    "       whitelist.plist：白名单文件，如果不想要瘦身某个APP，只需要将它的名字添加到这个白名单即可。该文件在AppArachs.app的Resources资源中\n\n"
    "       lipo.plist：lipo工具路径配置，如果没有Xcode就需要安装lipo工具，命令：xcode-select --install  "
    ;
    self.textViewInfo.string = text;
}

@end
