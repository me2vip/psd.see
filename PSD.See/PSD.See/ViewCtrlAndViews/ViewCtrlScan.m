//
//  ViewCtrlAbout.m
//  PSD.See
//
//  Created by Larry on 16/11/9.
//  Copyright © 2016年 MaiMiao. All rights reserved.
//

#import "ViewCtrlScan.h"
#import "SQManager.h"
#import <AVFoundation/AVFoundation.h>
#import "MBProgressHUD.h"
#import "MBProgressHUD+Toast.h"
#import "ASIHTTPRequest.h"
#import "SQConstant.h"
#import "../common/ASIHTTPRequest/External/Reachability/Reachability.h"

@interface ViewCtrlScan ()<AVCaptureMetadataOutputObjectsDelegate>

@property (retain, nonatomic) IBOutlet UILabel *psLabelTitle;
@property (retain, nonatomic) IBOutlet UILabel *psLabelInfo;
@property (retain, nonatomic) IBOutlet UIImageView *psImageScan;
@property (retain, nonatomic) IBOutlet UIImageView *psImageLine;
@property (retain, nonatomic) IBOutlet UIView *psViewScan;
@property (retain, nonatomic) IBOutlet UIImageView *psImageWifi;
@property (retain, nonatomic) IBOutlet UILabel *psLabelWifi;
@property (retain, nonatomic) IBOutlet UIView *psViewTitle;

@property (retain, nonatomic) AVCaptureSession * psSession;
@property (retain, nonatomic) NSTimer* psAnimationTime;
@property (assign, nonatomic) BOOL psUpOrdown;
@property (retain, nonatomic) AVCaptureVideoPreviewLayer* psPreview;
@property (nonatomic, retain) ASIHTTPRequest* psRequest;
@property (nonatomic, retain) NSFileHandle* psFileHandle;
@property (copy, nonatomic) NSString* psFilePath;
@property (nonatomic, retain) Reachability* psReachability;
@property (retain, nonatomic) NSMutableArray* psLayoutConstraints; //布局属性列表

- (IBAction)onClickBack:(id)sender;

@end

@implementation ViewCtrlScan

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.psLabelTitle.text = NSLocalizedString(@"scan_qr_code", @"scan_qr_code");
    self.psLabelInfo.text = NSLocalizedString(@"scan_info", @"scan_info");
    self.psUpOrdown = NO;
    self.psImageLine.hidden = YES;
    
    [self initCamera];
    
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

- (void)initCamera
{
    // Device
    AVCaptureDevice* device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    // Input
    AVCaptureDeviceInput* input = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    
    // Output
    AVCaptureMetadataOutput* output = [[[AVCaptureMetadataOutput alloc]init] autorelease];
    [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    
    // Session
    self.psSession = [[[AVCaptureSession alloc]init] autorelease];
    [self.psSession setSessionPreset:AVCaptureSessionPresetHigh];
    if ([self.psSession canAddInput:input])
    {
        [self.psSession addInput:input];
    }
    
    if ([self.psSession canAddOutput:output])
    {
        [self.psSession addOutput:output];
    }
    
    // 条码类型 AVMetadataObjectTypeQRCode
    output.metadataObjectTypes = @[AVMetadataObjectTypeQRCode];
    
    self.psPreview = [AVCaptureVideoPreviewLayer layerWithSession:self.psSession];
    self.psPreview.videoGravity = AVLayerVideoGravityResizeAspectFill;
    //preview.connection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
    [self.psViewScan.layer insertSublayer:self.psPreview atIndex:0];

}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setDeviceLayout]; //处理刘海屏布局
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
    
    CGRect rectLine = CGRectMake(self.psImageLine.frame.origin.x, self.psImageLine.frame.origin.y, self.psImageLine.frame.size.width, self.psImageLine.frame.size.height);
    rectLine.origin.y = 0;
    self.psImageLine.frame = rectLine;
    
    self.psAnimationTime = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(scanAnimation) userInfo:nil repeats:YES];
    self.psImageLine.hidden = NO;
    
    self.psPreview.frame = self.psImageScan.frame;
    self.psPreview.connection.videoOrientation = self.interfaceOrientation;
    // Start
    [self.psSession startRunning];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [self.psAnimationTime invalidate];
    [self.psSession stopRunning];
    
    if (self.psFileHandle)
    {
        [self.psFileHandle closeFile];
        self.psFileHandle = nil;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    self.psPreview.connection.videoOrientation = toInterfaceOrientation;
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
    }
    else
    {
        NSLog(@"%s - %d wifi not connected", __func__, __LINE__);
        self.psImageWifi.image = [UIImage imageNamed:@"wiff_disable.png"];
        self.psLabelWifi.text = NSLocalizedString(@"wifinotconnect", nil);
    }
}


-(void)scanAnimation

{
    CGRect rectLine = self.psImageLine.frame;
    CGRect rectParent = self.psViewScan.frame;
    
    if (NO == self.psUpOrdown)
    {
        rectLine.origin.y = rectLine.origin.y + 2;
        self.psImageLine.frame = rectLine;
        
        if (rectLine.origin.y + 10 > rectParent.size.height)
        {
            self.psUpOrdown = YES;
        }
    }
    else
    {
        rectLine.origin.y = rectLine.origin.y - 2;
        self.psImageLine.frame = rectLine;
        
        if (rectLine.origin.y < 10)
        {
            self.psUpOrdown = NO;
        }
    }
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

#pragma mark AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    NSString *scanResult = nil;
    
    if ([metadataObjects count] >0)
    {
        AVMetadataMachineReadableCodeObject * metadataObject = [metadataObjects objectAtIndex:0];
        scanResult = metadataObject.stringValue;
        NSLog(@"%s-%d scanResult:%@", __func__, __LINE__, scanResult);
        
        [self.psSession stopRunning];
        [self startRequestWithUrl:scanResult];
    }
}

-(void)scanDealy
{
    [self.psSession startRunning];
}

/**
 开始请求
 */
-(void)startRequestWithUrl:(NSString*)url
{
    MBProgressHUD* viewProgress = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    viewProgress.labelText = NSLocalizedString(@"loading", @"loading");
    viewProgress.dimBackground = YES;
    
    NSString* urlEncode = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    self.psRequest = [ASIHTTPRequest requestWithURL:urlEncode onTarget:self andFinishSelector:@selector(resultOnRequest:) andFailSelector:@selector(httpErrorOnRequest:)];
    self.psRequest.timeOutSeconds = 30;
    [self.psRequest startAsynchronous];
}

-(void)request:(ASIHTTPRequest*)request didReceiveResponseHeaders:(NSDictionary*)headers
{
    id value = headers[@"server"];
    if (FALSE == [SQ_PSD_SEE_HEADER isEqualToString:value])
    {
        return;
    }

    NSString* fileFullName = [request.url lastPathComponent];
    NSString* fileName = [fileFullName stringByDeletingPathExtension];
    NSString* extName = [fileFullName pathExtension];
    NSArray *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* docPath = [path objectAtIndex:0];
    
    NSString* filePath = [docPath stringByAppendingPathComponent:fileFullName];
    NSFileManager* defaultFileManager = [NSFileManager defaultManager];
    NSString* tempPath = nil;
    int index = 1;
    while ([defaultFileManager fileExistsAtPath:filePath])
    {
        tempPath = [NSString stringWithFormat:@"%@_%d", fileName, index];
        index++;
        tempPath = [tempPath stringByAppendingPathExtension:extName];
        filePath = [docPath stringByAppendingPathComponent:tempPath];
    }
    
    self.psFilePath = filePath;
    [defaultFileManager createFileAtPath:filePath contents:nil attributes:nil];
    self.psFileHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];
    [self.psFileHandle seekToFileOffset:0];
}

- (void)request:(ASIHTTPRequest *)request didReceiveData:(NSData *)data
{
    //NSLog(@"%s-%d datalen:%lu", __func__, __LINE__, data.length);
    if (self.psFileHandle)
    {
        [self.psFileHandle writeData:data];
    }
}

-(void)resultOnRequest:(ASIHTTPRequest*)request
{
    //文件下载完成
    NSLog(@"%s-%d filePath:%@", __func__, __LINE__, self.psFilePath);
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    if (self.psFileHandle)
    {
        [self.psFileHandle closeFile];
        self.psFileHandle = nil;
        if (self.psDelegate)
        {
            [self.psDelegate onFileScanSuccessWithPath:self.psFilePath];
        }
        
        [self.navigationController popViewControllerAnimated:YES];
    }
    else
    {
        [MBProgressHUD Toast:NSLocalizedString(@"file_invalid", @"file_invalid") toView:self.view andTime:1];
        [self performSelector:@selector(scanDealy) withObject:nil afterDelay:5];
    }
}

-(void)httpErrorOnRequest:(ASIHTTPRequest*) request
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [MBProgressHUD Toast:NSLocalizedString(@"http_error", @"http_error") toView:self.view andTime:1];
    
    [self performSelector:@selector(scanDealy) withObject:nil afterDelay:5];
    if (self.psFileHandle)
    {
        [self.psFileHandle closeFile];
        self.psFileHandle = nil;
    }
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
    [_psAnimationTime release];
    [_psImageScan release];
    [_psImageLine release];
    [_psViewScan release];
    [_psSession release];
    [_psPreview release];
    [_psRequest release];
    [_psFileHandle release];
    [_psFilePath release];
    [_psReachability release];
    [_psImageWifi release];
    [_psLabelWifi release];
    [_psViewTitle release];
    [_psLayoutConstraints release];
    [super dealloc];
}


- (IBAction)onClickBack:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}
@end
