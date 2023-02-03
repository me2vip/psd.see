//
//  ViewCtrlPSDrawing.m
//  PSD.See
//
//  Created by Larry on 16/10/20.
//  Copyright © 2016年 MaiMiao. All rights reserved.
//

#import "ViewCtrlPSDrawing.h"
#import "SQManager.h"
#import "asyncsocket.h"
#import "mbprogresshud+toast.h"
#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonKeyDerivation.h>
#import "RFIReader.h"
#import "DrawPSDDataView.h"
#import "PSCryptorAPI.h"
#import "ViewCtrlImageList.h"
#import "EVCircularProgressView.h"
#import "SQConstant.h"

enum
{
    COMM_STATUS_NO_ERROR = 0, //Communication 状态正常
    
    PROTOCOL_VERSION = 1, //协议版本
    MAX_FAIL_CONNECT = 3, //最大失败次数
    
    CONTENT_TYPE_ERROR_INFO = 1, //错误信息
    CONTENT_TYPE_JAVASCRIPT = 2, //JavaScript代码
    CONTENT_TYPE_IMAGE_DATA = 3, //图像数据
    CONTENT_TYPE_PROFILE = 4, //ICC profile
    CONTENT_TYPE_ARBITRARY = 5, //Arbitrary data to be saved as temporary file
    
    IMAGE_TYPE_JPEG = 1, //jpeg 格式图像
    IMAGE_TYPE_PIXMAP = 2, //原始的像素数据
    
    LENGTH_COMM_STATUS = 4, //Communication Status 的长度
    LENGTH_PROTOCOL_VERSION = 4, //协议版本长度
    LENGTH_TRANSACTION_ID = 4, //transaction id 长度
    LENGTH_CONTENT_TYPE = 4, //content type 长度
    
    LENGTH_KEY = 24, //key的长度
    SERVER_PORT = 49494, //服务器端口
    
};

/**
#define GET_IMAGE_EVENT (@"var idNS = stringIDToTypeID( 'sendDocumentThumbnailToNetworkClient' );\r var image_desc = new ActionDescriptor();\r image_desc.putInteger( stringIDToTypeID( 'width' ), 600 );\r image_desc.putInteger( stringIDToTypeID('height' ), 400 );\r image_desc.putInteger( stringIDToTypeID( 'format' ), 1 );\r executeAction( idNS, image_desc, DialogModes.NO );\r 'SUCCESS';")
**/

#define NETWORK_EVENT (@"var idNS = stringIDToTypeID( 'networkEventSubscribe' );\r var doc_desc = new ActionDescriptor();\r doc_desc.putClass( stringIDToTypeID( 'eventIDAttr' ), stringIDToTypeID( 'documentChanged' ) );\r executeAction( idNS, doc_desc, DialogModes.NO );\r var cur_doc_desc = new ActionDescriptor();\r cur_doc_desc.putClass( stringIDToTypeID( 'eventIDAttr' ), stringIDToTypeID( 'currentDocumentChanged' ) ); \r executeAction( idNS, cur_doc_desc, DialogModes.NO );\r 'NETWORK_SUCCESS';")

@interface ViewCtrlPSDrawing ()<UINavigationControllerDelegate, UIImagePickerControllerDelegate, PSDImageSelectedDelegate>
{
    PSCryptorRef _psCryptorRef;
}

@property (retain, nonatomic) IBOutlet UIButton *psButtonBack;
@property (retain, nonatomic) IBOutlet UIView *psBottomView;
@property (retain, nonatomic) IBOutlet UIButton *psButtonRefresh;
@property (retain, nonatomic) IBOutlet DrawPSDDataView *psDrawView;
@property (retain, nonatomic) IBOutlet EVCircularProgressView *psProgressView;

@property (nonatomic, readonly) NSString* psEventGetImage; //获取图片
@property (nonatomic, retain) NSMutableData* psRcvData; //收到的数据
@property (nonatomic, retain) AsyncSocket* psConnection;
@property (nonatomic, assign) BOOL psTitleHidden;
@property (nonatomic, assign) int32_t psTransactionId; //
@property (nonatomic, assign) long psReadTag;
@property (nonatomic, assign) long psWriteTag;
@property (nonatomic, assign) long psProcessedCount; //已经读取的字节数
@property (nonatomic, assign) long psTotalLength; //总长度
@property (nonatomic, assign) BOOL psImageSuccess; //图片获取成功
@property (nonatomic, assign) int psFailCount; //失败的次数
@property (retain, nonatomic) NSMutableArray* psLayoutConstraints; //布局属性列表

- (IBAction)onClickBack:(id)sender;
- (IBAction)onClickFullScreen:(id)sender;
- (IBAction)onClickRestoreView:(id)sender;
- (IBAction)onClickRefresh:(id)sender;
- (IBAction)onClickSave:(id)sender;
- (IBAction)onClickNew:(id)sender;

@end

@implementation ViewCtrlPSDrawing

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    float screenScale = [UIScreen mainScreen].scale;
    
    self.psImageSuccess = NO;
    self.psTitleHidden = NO;
    self.psButtonRefresh.hidden = YES;
    self.psRcvData = [NSMutableData data];
    self.psConnection = [[[AsyncSocket alloc] initWithDelegate:self] autorelease];
    
    float maxWidthHeight = (screenSize.width > screenSize.height) ? screenSize.width : screenSize.height;
    _psEventGetImage = [[NSString alloc] initWithFormat:@"var idNS = stringIDToTypeID( 'sendDocumentThumbnailToNetworkClient' );\r var image_desc = new ActionDescriptor();\r image_desc.putInteger( stringIDToTypeID( 'width' ), %d );\r image_desc.putInteger( stringIDToTypeID('height' ), %d );\r image_desc.putInteger( stringIDToTypeID( 'format' ), 1 );\r executeAction( idNS, image_desc, DialogModes.NO );\r 'GET_IMAGE_SUCCESS';", (int)(maxWidthHeight * screenScale), (int)(maxWidthHeight * screenScale)];
    
    _psCryptorRef = CreatePSCryptor([self.psServerInfo.psPassword UTF8String]);
    self.psTransactionId = 1;
    self.psReadTag = 1;
    self.psWriteTag = 1;
    
    [self.psProgressView setProgressColor:[UIColor colorWithRed:0x11/255.f green:0x8c/255.f blue:0xe3/255.f alpha:1] andBoxColor:[UIColor blueColor]];
    UITapGestureRecognizer* singleTap = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)] autorelease];
    [self.psDrawView addGestureRecognizer:singleTap];
    
    NSLog(@"%s - %d screenwidth:%f, screenheight:%f, screenScale:%f", __func__, __LINE__, screenSize.width, screenSize.height, screenScale);
    
#if SHOW_ADS
    //显示广告
    self.psBannerView.adUnitID = @"ca-app-pub-2925148926153054/6441483925";
    self.psBannerView.rootViewController = self;
    //self.psBannerView.delegate = self;
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
    
    [self performSelector:@selector(connectPhotoshopDelay) withObject:nil afterDelay:.3];
    self.psLayoutConstraints = [NSMutableArray array];
}

/**
 设置iphone x布局
 */
-(void)setDeviceLayout{
    UIView* backButton = self.psButtonBack;
    UIView* drawView =  self.psDrawView;
    UIView* bottomView = self.psBottomView;
    UIView* refreshButton = self.psButtonRefresh;
    
    NSDictionary *views = @{@"backButton":backButton, @"drawView":drawView, @"bottomView":bottomView, @"refreshButton":refreshButton};
    NSArray* constraints = nil;
    //先删除上次的布局,为新的布局做准备
    [self.view removeConstraints:self.psLayoutConstraints];
    [self.psLayoutConstraints removeAllObjects];
    
    if (UIDeviceOrientationPortrait == self.interfaceOrientation || UIDeviceOrientationPortraitUpsideDown == self.interfaceOrientation) {
        //竖屏
        constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-20-[backButton]" options:0 metrics:nil views:views];
        [self.psLayoutConstraints addObjectsFromArray:constraints];
        
        constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-20-[refreshButton]" options:0 metrics:nil views:views];
        [self.psLayoutConstraints addObjectsFromArray:constraints];
        
    } else {
        //横屏
        constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-20-[backButton]" options:0 metrics:nil views:views];
        [self.psLayoutConstraints addObjectsFromArray:constraints];
        
        constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-20-[refreshButton]" options:0 metrics:nil views:views];
        [self.psLayoutConstraints addObjectsFromArray:constraints];
    }
   
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[refreshButton]-20-|" options:0 metrics:nil views:views];
       [self.psLayoutConstraints addObjectsFromArray:constraints];
    
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-20-[backButton]" options:0 metrics:nil views:views];
    [self.psLayoutConstraints addObjectsFromArray:constraints];
    
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[drawView]-0-|" options:0 metrics:nil views:views];
    [self.psLayoutConstraints addObjectsFromArray:constraints];
    
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[drawView]-0-|" options:0 metrics:nil views:views];
    [self.psLayoutConstraints addObjectsFromArray:constraints];
    
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[bottomView]-0-|" options:0 metrics:nil views:views];
    [self.psLayoutConstraints addObjectsFromArray:constraints];
    
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[bottomView]-0-|" options:0 metrics:nil views:views];
    [self.psLayoutConstraints addObjectsFromArray:constraints];
    
    [self.view addConstraints:self.psLayoutConstraints];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setDeviceLayout];
    
    [SQManager addBorderToView:self.psButtonBack width:0.5 color:[UIColor lightGrayColor] cornerRadius:self.psButtonBack.frame.size.width / 2];
    [SQManager addBorderToView:self.psButtonRefresh width:0.5 color:[UIColor lightGrayColor] cornerRadius:self.psButtonRefresh.frame.size.width / 2];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

/**
 连接服务器
 */
-(void)connectPhotoshopDelay
{
    if (_psCryptorRef)
    {
        [self connectToServer];
    }
    else
    {
        [MBProgressHUD Toast:NSLocalizedString(@"createKeyFail", @"createKeyFail") toView:self.view andTime:1];
        [self performSelector:@selector(popupDelay) withObject:nil afterDelay:2];
    }
}

-(void)popupDelay
{
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)prefersStatusBarHidden
{
    //NSLog(@"++++++++++++++++++++ %d", self.psTitleHidden);
    //return self.psTitleHidden;
    return TRUE;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

/**
 连接到服务器
 */
-(void)connectToServer
{
    if([self.psConnection isConnected])
    {
        return;
    }
    
    NSError* error = nil;
    if(FALSE == [self.psConnection connectToHost:self.psServerInfo.psServerIp onPort:SERVER_PORT withTimeout:20 error:&error])
    {
        self.psFailCount = MAX_FAIL_CONNECT + 1;
        [MBProgressHUD Toast:NSLocalizedString(@"connectServerFail", @"connectServerFail") toView:self.view andTime:1];
        NSLog(@"%s-%d error=%@", __func__, __LINE__, error);
    }
    else
    {
        [self.psButtonRefresh setHidden:YES];
        [self.psProgressView setHidden:NO];
        self.psProgressView.progress = 0;
    }
}

/**
 已成功连接到服务器
 */
- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
    NSLog(@"%s-%d host:%@ port:%d", __func__, __LINE__, host, port);
    
    self.psFailCount = MAX_FAIL_CONNECT + 1;
    [self.psRcvData resetBytesInRange:NSMakeRange(0, [self.psRcvData length])];
    [self.psRcvData setLength:0];
    [self.psServerInfo save];
    
    [sock readDataToLength:4*5 withTimeout:30 tag:self.psReadTag++]; //先获取消息的长度
    [self sendData:[NETWORK_EVENT dataUsingEncoding:NSUTF8StringEncoding] andContentType:CONTENT_TYPE_JAVASCRIPT];
    //[self sendData:[self.psEventGetImage dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void)onSocket:(AsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    NSLog(@"%s-%d tag:%ld", __func__, __LINE__, tag);
}

/**
 收到服务器发来的数据
 */
- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
#if 0
    NSString* string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"%s-%d data.len:%lu, tag:%ld, string:%@", __func__, __LINE__, data.length, tag, string);
#endif
    NSLog(@"%s-%d data.len:%lu, tag:%ld", __func__, __LINE__, data.length, tag);
    //int msgLength = ntohl([reader readInt32]) + 4;
    [self.psRcvData appendData:data];
    
    RFIReader* reader = [RFIReader readerWithData:self.psRcvData];
    const int msgLen = ntohl([reader readInt32]) + 4;
    self.psTotalLength = msgLen;
    
    if(self.psRcvData.length < msgLen)
    {
        self.psProcessedCount = self.psRcvData.length;
        [sock readDataToLength:(msgLen - self.psRcvData.length) withTimeout:30 tag:self.psReadTag++];
    }
    else
    {
        //消息已经读取完毕
        [self parseData:self.psRcvData];
        
        [self.psRcvData resetBytesInRange:NSMakeRange(0, [self.psRcvData length])];
        [self.psRcvData setLength:0];
        
        [sock readDataToLength:4*5 withTimeout:-1 tag:self.psReadTag++];
    }
}

- (void)onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err
{
    NSLog(@"%s-%d error=%@", __func__, __LINE__, err);
}

- (void)onSocket:(AsyncSocket *)sock didReadPartialDataOfLength:(CFIndex)partialLength tag:(long)tag
{
    self.psProcessedCount += partialLength;
    if(self.psTotalLength <= 0)
    {
        self.psTotalLength = 1;
    }
    
    [self.psProgressView setProgress:(self.psProcessedCount*1.0 / self.psTotalLength) animated:NO];
    NSLog(@"%s-%d partialLength=%ld, psProcessedCount=%ld, psTotalLength=%ld", __func__, __LINE__, partialLength, self.psProcessedCount, self.psTotalLength);
}

/**
 * Called when a socket has written some data, but has not yet completed the entire write.
 * It may be used to for things such as updating progress bars.
 **/
- (void)onSocket:(AsyncSocket *)sock didWritePartialDataOfLength:(CFIndex)partialLength tag:(long)tag
{
    NSLog(@"%s-%d partialLength=%ld, psProcessedCount=%ld, psTotalLength=%ld", __func__, __LINE__, partialLength, self.psProcessedCount, self.psTotalLength);
    
    self.psProcessedCount += partialLength;
    if(self.psTotalLength <= 0)
    {
        self.psTotalLength = 1;
    }
    
    [self.psProgressView setProgress:(self.psProcessedCount*1.0 / self.psTotalLength) animated:NO];
}

- (void)onSocketDidDisconnect:(AsyncSocket *)sock
{
    NSLog(@"%s-%d, psFailCount:%d", __func__, __LINE__, self.psFailCount);
    
    self.psFailCount++;
    if (self.psFailCount < MAX_FAIL_CONNECT)
    {
        //重连服务器
        [self performSelector:@selector(connectToServer) withObject:nil afterDelay:5];
        return;
    }
    [self.psButtonRefresh setHidden:NO];
    [self.psProgressView setHidden:YES];
    
    [MBProgressHUD Toast:NSLocalizedString(@"connectServerFail", @"connectServerFail") toView:self.view andTime:1];
}

-(void)parseData:(NSData*)data
{
    RFIReader* reader = [RFIReader readerWithData:data];
    const int msgLen = ntohl([reader readInt32]); //消息的长度
    const int commStatus = ntohl([reader readInt32]); //状态码
    
    if(COMM_STATUS_NO_ERROR == commStatus)
    {
        //数据正确
        char* encryptBuff = (char*)(data.bytes) + 8; //跳过消息长度和状态码,消息长度和状态码不加密
        size_t encryptLength = msgLen - LENGTH_COMM_STATUS; //加密消息的长度
        PSCryptorStatus decryptResult = EncryptDecrypt (_psCryptorRef, false, encryptBuff, encryptLength, encryptBuff, encryptLength, &encryptLength);
        
        if (kCryptorSuccess == decryptResult)
        {
            //解密成功
            NSData* decryptData = [NSData dataWithBytes:encryptBuff length:encryptLength];
            [self parseSuccessData:decryptData];
        }
        else
        {
            [MBProgressHUD Toast:NSLocalizedString(@"passwordError", @"passwordError") toView:self.view andTime:1];
            [self performSelector:@selector(popupDelay) withObject:nil afterDelay:2];
        }
    }
    else
    {
        //数据不正确
        [self parseErrorMessage:reader andMsgLen:msgLen];
    }
}

-(void)parseSuccessData:(NSData*)data
{
    RFIReader* reader = [RFIReader readerWithData:data];
    
    ntohl([reader readInt32]); //protocol version
    ntohl([reader readInt32]); //transaction id
    const int contentType = ntohl([reader readInt32]); //content type
    char* contextData = (char*)(data.bytes) + 4*3; //数据存储的地方
    size_t dataLength = data.length - 12; //数据的长度
    
    if(CONTENT_TYPE_PROFILE == contentType)
    {
    }
    else if(CONTENT_TYPE_ARBITRARY == contentType)
    {
    }
    else if(CONTENT_TYPE_IMAGE_DATA == contentType)
    {
        //收到的图像数据
        [self parseImageData:contextData andLen:dataLength];
    }
    else if(CONTENT_TYPE_JAVASCRIPT == contentType)
    {
        //js脚本
        [self parseJavaScript:contextData andLen:dataLength];
    }
    else if(CONTENT_TYPE_ERROR_INFO == contentType)
    {
        //错误信息
        [self parseErrorInfo:contextData andLen:dataLength];
    }
}

-(void)parseErrorInfo:(char*)buff andLen:(size_t)length
{
    NSData* data = [NSData dataWithBytes:buff length:length];
    NSString* jsInfo = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    NSLog(@"%s - %d errorInfo:%@", __func__, __LINE__, jsInfo);
}

-(void)parseJavaScript:(char*)buff andLen:(size_t)length
{
    NSData* data = [NSData dataWithBytes:buff length:length];
    NSString* jsInfo = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    NSLog(@"%s - %d jsInfo:%@", __func__, __LINE__, jsInfo);
    
    if ([jsInfo containsString:@"documentChanged"] || [jsInfo containsString:@"currentDocumentChanged"] || [jsInfo containsString:@"NETWORK_SUCCESS"])
    {
        //获取图片数据
        self.psProcessedCount = 0;
        self.psButtonRefresh.hidden = YES;
        self.psProgressView.hidden = NO;
        self.psProgressView.progress = 0;
        
        [self sendData:[self.psEventGetImage dataUsingEncoding:NSUTF8StringEncoding] andContentType:CONTENT_TYPE_JAVASCRIPT];
    }
    else if([jsInfo containsString:@"GET_IMAGE_SUCCESS"])
    {
        //图像数据接收完成
        [self.psProgressView setHidden:YES];
        [self.psButtonRefresh setHidden:NO];
        self.psImageSuccess = YES;
    }
}

-(void)parseImageData:(char*)buff andLen:(size_t)length
{
    unsigned char image_type = *((unsigned char *)buff);
    if(IMAGE_TYPE_JPEG != image_type)
    {
        [MBProgressHUD Toast:NSLocalizedString(@"imageTypeError", @"imageTypeError") toView:self.view andTime:1];
        [self performSelector:@selector(popupDelay) withObject:nil afterDelay:2];
        return;
    }
   
    NSData* imageData = [NSData dataWithBytes:buff+1 length:length -1];
    UIImage* image = [UIImage imageWithData:imageData];
    
    //显示图像数据
    [self.psDrawView refreshImage:image];
}

-(void)parseErrorMessage:(RFIReader*)reader andMsgLen:(int)msgLength
{
    const int protocolVersion = ntohl([reader readInt32]);
    [reader readInt32]; //transaction id
    const int contentType = ntohl([reader readInt32]);
    NSData* errorData = [reader readBytes:msgLength - 4 * 5];
    NSString* errorMssage = [[[NSString alloc] initWithData:errorData encoding:NSUTF8StringEncoding] autorelease];
    
    NSLog(@"%s-%d protocolVersion:%d, contentType:%d, errorMssage:%@", __func__, __LINE__, protocolVersion, contentType, errorMssage);
    
    [MBProgressHUD Toast:NSLocalizedString(@"passwordError", @"passwordError") toView:self.view andTime:1];
    [self performSelector:@selector(popupDelay) withObject:nil afterDelay:2];
}

/**
 发送数据
 */
-(void)sendData:(NSData*)contentData andContentType:(int)contentType
{
    NSMutableData* outputStream = [NSMutableData data];
    //NSData* dataToSend = [GET_IMAGE_EVENT dataUsingEncoding:NSUTF8StringEncoding];
    const int remainingToWrite = (int)[contentData length];
    
    /* -------------------------------------------------------
     we're writing things in this order:
     Unencrypted:
     1. total message length (not including the length itself)
     2. communication stat
     Encrypted:
     3. Protocol version
     4. Transaction ID
     5. Message type
     6. The message itself
     ------------------------------------------------------- */
    
    const int plainTextLength = LENGTH_PROTOCOL_VERSION + LENGTH_TRANSACTION_ID + LENGTH_CONTENT_TYPE + remainingToWrite;
    size_t encryptedLength = CryptorGetEncryptedLength(plainTextLength);
    
    // ---- UNENCRYPTED PART ------
    // write length of message as 32 bit signed int, includes all bytes after the length
    int swabbed_temp = htonl( encryptedLength + LENGTH_COMM_STATUS );
    [outputStream appendBytes:(const uint8_t*)&swabbed_temp length:4];
    
    /*
     stream status has the following status:  (check Apple's Developer Reference for more info)
     NSStreamStatusNotOpen = 0,
     NSStreamStatusOpening = 1,
     NSStreamStatusOpen = 2,
     NSStreamStatusReading = 3,
     NSStreamStatusWriting = 4,
     NSStreamStatusAtEnd = 5,
     NSStreamStatusClosed = 6,
     NSStreamStatusError = 7
     */
    
    // the communication status is NOT encrypted
    // write communication status value as 32 bit unsigned int
    swabbed_temp = htonl( 0 );
    [outputStream appendBytes:(const uint8_t*)&swabbed_temp length:4];
    
    // ------------------------------------------------
    // Encrypted section, until the end of the message
    char *tempBuffer = (char *) malloc (encryptedLength);
    
    // protocol version, 32 bit unsigned integer
    swabbed_temp = htonl( 1 );
    memcpy (tempBuffer+0, (const void *) &swabbed_temp, 4);
    
    // transaction id, 32 bit unsigned integer
    swabbed_temp = htonl( self.psTransactionId++ );
    memcpy (tempBuffer+4,(const void *) &swabbed_temp, 4);
    
    // content type, 32 bit unsigned integer
    swabbed_temp = htonl( contentType );		// javascript = 2
    memcpy (tempBuffer+8, (const void *) &swabbed_temp, 4);
    
    // the data to transmit
    unsigned char * marker = (unsigned char *)[contentData bytes];
    memcpy (tempBuffer+12, marker, remainingToWrite);
    
    // now encrypt the message packet
    EncryptDecrypt (_psCryptorRef, true, tempBuffer, plainTextLength, tempBuffer, encryptedLength, &encryptedLength);
    [outputStream appendBytes:tempBuffer length:encryptedLength];
    
    [self.psConnection writeData:outputStream withTimeout:10 tag:self.psWriteTag++];
    
    free(tempBuffer);
    
#if 0
    
    NSData* sendData = [GET_IMAGE_EVENT dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableData* networkData = [NSMutableData data];
    const int dataLength = (int)(sendData.length);
    size_t encryptedLength = LENGTH_PROTOCOL_VERSION + LENGTH_TRANSACTION_ID + LENGTH_CONTENT_TYPE + dataLength;
    encryptedLength = (int)CryptorGetEncryptedLength(encryptedLength);
    
    RFIWriter* writer = [RFIWriter writerWithData:networkData];
    [writer writeInt32:htonl(encryptedLength + LENGTH_COMM_STATUS)]; //数据长度
    [writer writeInt32:htonl(0)]; //communication status
    
    NSMutableData* encryptData = [NSMutableData dataWithCapacity:encryptedLength];
    RFIWriter* encryptWriter = [RFIWriter writerWithData:encryptData];
    [encryptWriter writeInt32:htonl(PROTOCOL_VERSION)];
    [encryptWriter writeInt32:htonl(self.psTransactionId++)];
    [encryptWriter writeInt32:htonl(CONTENT_TYPE_JAVASCRIPT)];
    [encryptWriter writeBytes:sendData];
    
    char* tempBuffer = (char*)(encryptData.bytes);
    EncryptDecrypt (_psCryptorRef, true, tempBuffer, LENGTH_PROTOCOL_VERSION + LENGTH_TRANSACTION_ID + LENGTH_CONTENT_TYPE + dataLength, tempBuffer, encryptedLength, &encryptedLength);
    [writer writeBytes:tempBuffer length:encryptedLength];
    
    [sock writeData:networkData withTimeout:20 tag:self.psWriteTag++];
    
#endif
}

-(void)handleSingleTap:(UITapGestureRecognizer *)sender
{
    self.psTitleHidden = !(self.psTitleHidden);
    
    [self.psButtonBack setHidden:self.psTitleHidden];
    [self.psBottomView setHidden:self.psTitleHidden];
    if (YES == self.psProgressView.hidden)
    {
        [self.psButtonRefresh setHidden:self.psTitleHidden];
    }
    [self prefersStatusBarHidden];
    [self setNeedsStatusBarAppearanceUpdate];
    [[UIApplication sharedApplication] setStatusBarHidden:self.psTitleHidden withAnimation:UIStatusBarAnimationSlide];
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    [self setDeviceLayout];
    [self.psDrawView setNeedsDisplay];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.destinationViewController isKindOfClass:[ViewCtrlImageList class]]) {
        ViewCtrlImageList* viewCtrl = segue.destinationViewController;
        viewCtrl.psImageSelectedDelegate = self;
    }
}

-(void)imageSelected:(UIImage*)image
{
    if (NO == self.sqAppeared) {
        [self performSelector:@selector(imageSelected:) withObject:image afterDelay:0.2];
        return;
    }
    
    if(FALSE == self.psImageSuccess)
    {
        //not_connect_ps
        [MBProgressHUD Toast:NSLocalizedString(@"not_connect_ps", @"not_connect_ps") toView:self.view andTime:1];
        return;
    }

    self.psProcessedCount = 0;
    self.psButtonRefresh.hidden = YES;
    self.psProgressView.hidden = NO;
    self.psProgressView.progress = 0;
    
    NSData *imageData = UIImageJPEGRepresentation(image, 1.0);
    // need one byte before the image data for format type
    NSMutableData *image_message = [NSMutableData data];
    
    unsigned char format = IMAGE_TYPE_JPEG; // JPEG = 1
    [image_message appendBytes:(const void *)&format length:1];
    [image_message appendData:imageData];
    
    self.psTotalLength = image_message.length;
    [self sendData:image_message andContentType:CONTENT_TYPE_IMAGE_DATA];  // type 3 = JPEG
}

/*
 用户选择了相册中的某张照片
 */
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    self.psProcessedCount = 0;
    self.psButtonRefresh.hidden = YES;
    self.psProgressView.hidden = NO;
    self.psProgressView.progress = 0;
    
    NSData *imageData = UIImageJPEGRepresentation(image, 1.0);
    // need one byte before the image data for format type
    NSMutableData *image_message = [NSMutableData data];
    
    unsigned char format = IMAGE_TYPE_JPEG; // JPEG = 1
    [image_message appendBytes:(const void *)&format length:1];
    [image_message appendData:imageData];
    
    self.psTotalLength = image_message.length;
    [self sendData:image_message andContentType:CONTENT_TYPE_IMAGE_DATA];  // type 3 = JPEG
}

/*
 用户取消选择照片
 */
-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)dealloc
{
    [_psServerInfo release];
    [_psBottomView release];
    [_psButtonBack release];
    [_psConnection release];
    [_psRcvData release];
    [_psButtonRefresh release];
    [_psDrawView release];
    [_psEventGetImage release];
    
    if(_psCryptorRef)
    {
        DestroyPSCryptor(_psCryptorRef);
    }
    _psCryptorRef = NULL;
    [_psLayoutConstraints release];
    [_psProgressView release];
    [super dealloc];
}

- (IBAction)onClickBack:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
    
    [self.psConnection setDelegate:nil];
    [self.psConnection disconnect];
}

- (IBAction)onClickFullScreen:(id)sender
{
    [self.psDrawView fullScreen];
    
    [self handleSingleTap:nil];
}

- (IBAction)onClickRestoreView:(id)sender
{
    [self.psDrawView restoreView];
    
    [self handleSingleTap:nil];
}

- (IBAction)onClickRefresh:(id)sender
{
    if (self.psConnection.isConnected)
    {
        //服务器已连接
        self.psProcessedCount = 0;
        self.psButtonRefresh.hidden = YES;
        self.psProgressView.hidden = NO;
        self.psProgressView.progress = 0;
        
        [self sendData:[self.psEventGetImage dataUsingEncoding:NSUTF8StringEncoding] andContentType:CONTENT_TYPE_JAVASCRIPT];
    }
    else
    {
        self.psFailCount = 0;
        [self connectToServer];
    }
}

- (IBAction)onClickSave:(id)sender
{
    if(FALSE == self.psImageSuccess)
    {
        //not_connect_ps
        [MBProgressHUD Toast:NSLocalizedString(@"not_connect_ps", @"not_connect_ps") toView:self.view andTime:1];
        return;
    }
    
    [self.psDrawView save];
}

- (IBAction)onClickNew:(id)sender
{
    if(FALSE == self.psImageSuccess)
    {
        //not_connect_ps
        [MBProgressHUD Toast:NSLocalizedString(@"not_connect_ps", @"not_connect_ps") toView:self.view andTime:1];
        return;
    }
    
    UIImagePickerController* pickerImage = [[[UIImagePickerController alloc] init] autorelease];
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
    {
        pickerImage.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        //pickerImage.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
        pickerImage.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:pickerImage.sourceType];
        
    }
    pickerImage.delegate = self;
    pickerImage.allowsEditing = NO;
    [self presentViewController:pickerImage animated:YES completion:nil];
}

@end
