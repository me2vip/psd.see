//
//  AppDelegate.m
//  PSD.See
//
//  Created by Larry on 16/9/5.
//  Copyright © 2016年 MaiMiao. All rights reserved.
//

#import "AppDelegate.h"
#import "SQManager.h"
#import "SQConstant.h"
#import "viewctrlMain.h"
#import "UMMobClick/MobClick.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

/* 将NSlog打印信息保存到cache目录下的文件中 */
- (void)redirectLogFile
{
    if (SQ_DEBUG)
    {
        return;
    }
    
    // 获取沙盒路径
    NSString *tempDirectory = NSTemporaryDirectory();
    if (nil == tempDirectory)
    {
        return;
    }
    
    // 获取打印输出文件路径
    NSString *logFilePath = [tempDirectory stringByAppendingPathComponent:@"mylog.log"];
    
    // 先删除已经存在的文件
    NSFileManager *defaultManager = [NSFileManager defaultManager];
    [defaultManager removeItemAtPath:logFilePath error:nil];
    
    // 将NSLog的输出重定向到文件，因为C语言的printf打印是往stdout打印的，这里也把它重定向到文件
    freopen([logFilePath cStringUsingEncoding:NSASCIIStringEncoding],"a+", stdout);
    freopen([logFilePath cStringUsingEncoding:NSASCIIStringEncoding],"a+", stderr);
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    [self redirectLogFile];
    
    [[SQManager sharedSQManager] initManager];
    
    //友盟初始化
    UMConfigInstance.appKey = @"5964155a04e20574d70011b4";
    UMConfigInstance.channelId = @"app_store";
    [MobClick setLogEnabled:NO];
    [MobClick setAppVersion:[SQManager sharedSQManager].sqAppVersion];
    [MobClick startWithConfigure:UMConfigInstance];
    
#if 0
    //firebase 初始化
    [FIRApp configure];
    // Initialize Google Mobile Ads SDK
    //[GADMobileAds configureWithApplicationID:@"ca-app-pub-3940256099942544~1458002511"]; //测试id
    [GADMobileAds configureWithApplicationID:@"ca-app-pub-2925148926153054~1394652326"];
#endif
    
    UINavigationController* rootViewCtrl = (UINavigationController*)(self.window.rootViewController);
    [rootViewCtrl setNavigationBarHidden:YES];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    NSLog(@"%s-%d file path:%@", __FUNCTION__, __LINE__, [url path]);
    if (NO == [url isFileURL])
    {
        return NO;
    }
    
    NSString* filePath = [url path];
    
    UINavigationController* rootViewCtrl = (UINavigationController*)(self.window.rootViewController);
    [rootViewCtrl popToViewController:[SQManager getObjectFrom:rootViewCtrl.viewControllers ofClass:[ViewCtrlMain class]] animated:NO];
    ViewCtrlMain* ctrlMain = [SQManager getObjectFrom:rootViewCtrl.viewControllers ofClass:[ViewCtrlMain class]];
    [ctrlMain openExternalFile:filePath];
    
    return YES;
}

@end
