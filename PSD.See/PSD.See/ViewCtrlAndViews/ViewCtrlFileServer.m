//
//  ViewCtrlAbout.m
//  PSD.See
//
//  Created by Larry on 16/11/9.
//  Copyright © 2016年 MaiMiao. All rights reserved.
//

#import "ViewCtrlFileServer.h"
#import "SQManager.h"
#import "../common/ASIHTTPRequest/External/Reachability/Reachability.h"
#import "cclhttpserver.h"
#import "CCLHTTPServerInterface.h"
#import "CCLHTTPServerResponse.h"
#import "SQConstant.h"

enum
{
    PS_HTTP_PORT = 5566, //http 端口
};

@interface ViewCtrlFileServer ()

@property (retain, nonatomic) IBOutlet UILabel *psLabelTitle;
@property (retain, nonatomic) IBOutlet UILabel *psLabelInfo;
@property (retain, nonatomic) IBOutlet UIImageView *psImageWifi;
@property (retain, nonatomic) IBOutlet UILabel *psLabelWifi;
@property (retain, nonatomic) IBOutlet UILabel *psLabelAddress;
@property (retain, nonatomic) IBOutlet UIImageView *psImageCode;
@property (retain, nonatomic) IBOutlet UIView *psViewTitle;

@property (nonatomic, retain) Reachability* psReachability;
@property (nonatomic, retain) CCLHTTPServer* psHttpServer;
@property (retain, nonatomic) NSMutableArray* psLayoutConstraints; //布局属性列表

- (IBAction)onClickBack:(id)sender;

@end

@implementation ViewCtrlFileServer

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.psLabelTitle.text = NSLocalizedString(@"transfer", @"transfer");
    self.psLabelInfo.text = @"";
    
#if SHOW_ADS
    // Replace this ad unit ID with your own ad unit ID.
    //self.psBannerView.adUnitID = @"ca-app-pub-3940256099942544/2934735716"; //测试id
    self.psBannerView.adUnitID = @"ca-app-pub-2925148926153054/8778318320";
    self.psBannerView.rootViewController = self;
    //self.psBannerView.adSize = kGADAdSizeSmartBannerLandscape;
    
    GADRequest *request = [GADRequest request];
    // Requests test ads on devices you specify. Your test device ID is printed to the console when
    // an ad request is made. GADBannerView automatically returns test ads when running on a
    // simulator.
    request.testDevices = @[
                            @"bd9a4a5a08499bf693087e78520a5b9a", @"94af4af21f1c3cf20c296729d25cbf58"  // Eric's iPod Touch
                            ];
    [self.psBannerView loadRequest:request];
#endif
    
    self.psLayoutConstraints = [NSMutableArray array];
}

/**
 设置iphone x布局
 */
-(void)setDeviceLayout{
    UIView* titleView = self.psViewTitle;
    NSDictionary *views = @{@"titleView":titleView};
    NSArray* constraints = nil;
    //先删除上次的布局,为新的布局做准备
    [self.view removeConstraints:self.psLayoutConstraints];
    [self.psLayoutConstraints removeAllObjects];
    
    if (UIDeviceOrientationPortrait == self.interfaceOrientation || UIDeviceOrientationPortraitUpsideDown == self.interfaceOrientation) {
        //竖屏
        if ([SQManager isIphoneX]) { //浏海屏
            constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[titleView(84)]" options:0 metrics:nil views:views];
        } else { //非浏海屏
            constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[titleView(64)]" options:0 metrics:nil views:views];
        }
    } else {
        //横屏
        if ([SQManager isIphoneX]) { //浏海屏
            constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[titleView(54)]" options:0 metrics:nil views:views];
        } else { //非浏海屏
            constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[titleView(44)]" options:0 metrics:nil views:views];
        }
    }
    [self.psLayoutConstraints addObjectsFromArray:constraints];
    
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[titleView]-0-|" options:0 metrics:nil views:views];
    [self.psLayoutConstraints addObjectsFromArray:constraints];
    
    [self.view addConstraints:self.psLayoutConstraints];
}

/**
 屏幕旋转
 */
-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    NSLog(@"%s-%d now orientation:%ld", __func__, __LINE__, self.interfaceOrientation);
    //屏幕已旋转, 设置相关控件的布局
    [self setDeviceLayout];
}


-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setDeviceLayout];
    //监听网络状态
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reachabilityChanged:)
                                                 name: kReachabilityChangedNotification
                                               object: nil];
    self.psReachability = [Reachability reachabilityWithHostName:@"www.apple.com"];
    [self.psReachability startNotifier];
}


-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [self.psHttpServer stop];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.psHttpServer = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)prefersStatusBarHidden
{
    return NO;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)dealloc
{
    [_psLabelTitle release];
    [_psLabelInfo release];
    [_psFileInfo release];
    [_psImageWifi release];
    [_psLabelWifi release];
    [_psLabelAddress release];
    [_psImageCode release];
    [_psReachability release];
    //[_psHttpServer release];
    [_psLayoutConstraints release];
    [_psViewTitle release];
    [super dealloc];
}

- (void)reachabilityChanged:(NSNotification *)note
{
    Reachability* curReach = [note object];
    NetworkStatus status = [curReach currentReachabilityStatus];
    if (ReachableViaWiFi == status)
    {
        //wifi连接正常
        NSLog(@"%s - %d wifi connected", __func__, __LINE__);
        self.psImageWifi.image = [UIImage imageNamed:@"wiff_enabel.png"];
        self.psLabelWifi.text = [SQManager getCurrentWifiName];
        self.psLabelAddress.text = [SQManager getIPAddress];
        
        [self startServer];
    }
    else
    {
        NSLog(@"%s - %d wifi not connected", __func__, __LINE__);
        self.psImageWifi.image = [UIImage imageNamed:@"wiff_disable.png"];
        self.psLabelWifi.text = NSLocalizedString(@"wifinotconnect", nil);
        self.psLabelAddress.text = NSLocalizedString(@"no_ip", nil);
        self.psLabelInfo.text = @"";
        [self.psHttpServer stop];
        self.psHttpServer = nil;
    }
}

-(id<CCLHTTPServerResponse>)parseHttpRequest:(id<CCLHTTPServerRequest>)request
{
    NSDictionary *headers = @{
                              @"Content-Type": @"text/plain; charset=utf8",
                              };
    NSLog(@"%s-%d method:%@, path:%@", __func__, __LINE__, request.method, request.path);
    NSData *body = [NSLocalizedString(@"error_file", @"error_file") dataUsingEncoding:NSUTF8StringEncoding];
    
    NSString* urlLastName = [self.psFileInfo.psFilePath lastPathComponent];
    urlLastName = [urlLastName stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString* urlPath = [NSString stringWithFormat:@"http://%@:%d/doc/getimage.jsp/%@", [SQManager getIPAddress], PS_HTTP_PORT, urlLastName];
    if (NO == [urlPath hasSuffix:request.path])
    {
        //错误的请求
        return [[[CCLHTTPServerResponse alloc] initWithStatusCode:200 headers:headers body:body] autorelease];
    }
    
    NSError* error = nil;
    body = [NSData dataWithContentsOfFile:self.psFileInfo.psFilePath options:NSDataReadingMappedIfSafe error:&error];
    if(error || nil == body)
    {
        NSLog(@"%s-%d error:%@", __func__, __LINE__, error);
        
        headers = @{
                    @"Content-Type": @"text/plain; charset=utf8",
                    };
        body = [NSLocalizedString(@"error_file", @"error_file") dataUsingEncoding:NSUTF8StringEncoding];
        
        return [[[CCLHTTPServerResponse alloc] initWithStatusCode:200 headers:headers body:body] autorelease];
    }
    
    headers = @{
                @"Accept-Ranges":@"bytes",
                //@"Content-Type":@"application/octet-stream",
                @"Content-Type":@"image/*",
                @"server":SQ_PSD_SEE_HEADER,
                @"Content-Length":@(body.length)
                };
    
    //正确的请求
    return [[[CCLHTTPServerResponse alloc] initWithStatusCode:200 headers:headers body:body] autorelease];
}

/**
 开始http服务器
 */
-(void)startServer
{
    [self.psHttpServer stop];
    self.psHttpServer = nil;
    
    self.psHttpServer = [[[CCLHTTPServer alloc] initWithInterface:nil port:PS_HTTP_PORT handler:^id<CCLHTTPServerResponse>(id<CCLHTTPServerRequest> request) {
        return [self parseHttpRequest:request];
    }] autorelease];
    
    NSString* urlPath = [NSString stringWithFormat:@"http://%@:%d/doc/getimage.jsp/%@", [SQManager getIPAddress], PS_HTTP_PORT, [self.psFileInfo.psFilePath lastPathComponent]];
    NSLog(@"%s-%d psUrlPath:%@", __func__, __LINE__, urlPath);
    CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    [filter setDefaults];
    NSData *data = [urlPath dataUsingEncoding:NSUTF8StringEncoding];
    [filter setValue:data forKeyPath:@"inputMessage"];
    // 4.获取输出的二维码
    CIImage *outputImage = [filter outputImage];
    self.psImageCode.image = [SQManager createNonInterpolatedUIImageFormCIImage:outputImage withSize:150];
    
    self.psLabelInfo.text = [NSString stringWithFormat:@"%@\"%@\"%@", NSLocalizedString(@"qr_info_1", @"qr_info_1"), urlPath, NSLocalizedString(@"qr_info_2", @"qr_info_2")];
}


- (IBAction)onClickBack:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}
@end
