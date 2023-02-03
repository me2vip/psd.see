//
//  ViewController.m
//  PSD.See
//
//  Created by Larry on 16/9/5.
//  Copyright © 2016年 MaiMiao. All rights reserved.
//

#import "ViewCtrlLog.h"
#import "psdata.h"
#import "SQManager.h"
#import "datamodel.h"
#import "../common/UIView+SQLayerAndKeyValue.h"
#import "../Datas/SQListItem.h"
#import "cclhttpserver.h"
#import "CCLHTTPServerInterface.h"
#import "CCLHTTPServerResponse.h"
#import "SQConstant.h"

@interface ViewCtrlLog ()

@property (retain, nonatomic) IBOutlet UITextView *psTxtLog;

@property (nonatomic, retain) CCLHTTPServer* psHttpServer;

- (IBAction)onClickBack:(id)sender;

@end

@implementation ViewCtrlLog

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // Replace this ad unit ID with your own ad unit ID.
    //self.psBannerView.adUnitID = @"ca-app-pub-3940256099942544/2934735716"; //测试id
    NSString *tempDirectory = NSTemporaryDirectory();
    if (nil == tempDirectory)
    {
        return;
    }
    
    // 获取打印输出文件路径
    NSString *logFilePath = [tempDirectory stringByAppendingPathComponent:@"mylog.log"];
    NSError* error = nil;
    NSString* logInfo = [NSString stringWithContentsOfFile:logFilePath encoding:NSUTF8StringEncoding error:&error];
    
    if(nil == error)
    {
        self.psTxtLog.text = logInfo;
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
 
    [self.psHttpServer stop];
    self.psHttpServer = nil;
    
    self.psHttpServer = [[[CCLHTTPServer alloc] initWithInterface:nil port:7608 handler:^id<CCLHTTPServerResponse>(id<CCLHTTPServerRequest> request) {
        return [self parseHttpRequest:request];
    }] autorelease];
}

-(id<CCLHTTPServerResponse>)parseHttpRequest:(id<CCLHTTPServerRequest>)request
{
    NSDictionary *headers = @{
                              @"Content-Type": @"text/plain; charset=utf8",
                              };
    //NSLog(@"%s-%d method:%@, path:%@", __func__, __LINE__, request.method, request.path);
    NSData *body = [NSLocalizedString(@"error_file", @"error_file") dataUsingEncoding:NSUTF8StringEncoding];
    NSString *tempDirectory = NSTemporaryDirectory();
    
    NSString* urlPath = [NSString stringWithFormat:@"http://%@:7608/logs/getlog.jsp/testlog.log", [SQManager getIPAddress]];
    if (NO == [urlPath hasSuffix:request.path] || nil == tempDirectory)
    {
        //错误的请求
        return [[[CCLHTTPServerResponse alloc] initWithStatusCode:200 headers:headers body:body] autorelease];
    }
    
    // 获取打印输出文件路径
    NSString *logFilePath = [tempDirectory stringByAppendingPathComponent:@"mylog.log"];
    NSError* error = nil;
    body = [NSData dataWithContentsOfFile:logFilePath options:NSDataReadingMappedIfSafe error:&error];
    if(error || nil == body)
    {
        //NSLog(@"%s-%d error:%@", __func__, __LINE__, error);
        
        headers = @{
                    @"Content-Type": @"text/plain; charset=utf8",
                    };
        body = [NSLocalizedString(@"error_file", @"error_file") dataUsingEncoding:NSUTF8StringEncoding];
        
        return [[[CCLHTTPServerResponse alloc] initWithStatusCode:200 headers:headers body:body] autorelease];
    }
    
    headers = @{
                @"Accept-Ranges":@"bytes",
                //@"Content-Type":@"application/octet-stream",
                @"Content-Type":@"text/plain; charset=utf8",
                @"server":SQ_PSD_SEE_HEADER,
                @"Content-Length":@(body.length)
                };
    
    //正确的请求
    return [[[CCLHTTPServerResponse alloc] initWithStatusCode:200 headers:headers body:body] autorelease];
}


-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [self.psHttpServer stop];
    self.psHttpServer = nil;
}

- (BOOL)prefersStatusBarHidden
{
    return NO;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    [_psTxtLog release];
    
    [super dealloc];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

- (IBAction)onClickBack:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}
@end
