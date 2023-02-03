//
//  ViewController.m
//  PSD.See
//
//  Created by Larry on 16/9/5.
//  Copyright © 2016年 MaiMiao. All rights reserved.
//

#import "ViewCtrlSync.h"
#import "psdata.h"
#import "SQManager.h"
#import "datamodel.h"
#import <SystemConfiguration/CaptiveNetwork.h>
#import "../common/UIView+SQLayerAndKeyValue.h"
#import "../Datas/SQListItem.h"
#import "../common/ASIHTTPRequest/External/Reachability/Reachability.h"
#import "ViewCtrlAddServer.h"
#import "ViewCtrlPSDrawing.h"
#import "mbprogresshud+toast.h"
#import "SQConstant.h"

enum
{
    PS_SYNC_WIFI
    , PS_SYNC_SPLITE
    , PS_SYNC_LAST
};

@interface ViewCtrlSync ()<UITableViewDelegate, UITableViewDataSource, AddServerDelegate>

@property (retain, nonatomic) IBOutlet UITableView *psTableView;
@property (retain, nonatomic) IBOutlet UILabel *psTitle;
@property (retain, nonatomic) IBOutlet UIView *psViewTitle;

@property (nonatomic, retain) NSMutableArray* psListFiles;
@property (nonatomic, retain) Reachability* psReachability;
@property (nonatomic, assign) BOOL psWifiConnected; //wifi是否已连接
@property (nonatomic, copy) NSString* psWifiName; //wifi热点名称
@property (nonatomic, assign) NSTimeInterval psLastClickTime; //上次点击的时间
@property (nonatomic, assign) int psClickCount; //点击计数器
@property (retain, nonatomic) NSMutableArray* psLayoutConstraints; //布局属性列表

- (IBAction)onClickHelp:(id)sender;
- (IBAction)onClickBack:(id)sender;
- (IBAction)onClickAdd:(id)sender;

@end

@implementation ViewCtrlSync

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.psListFiles = [NSMutableArray array];
    self.psTitle.text = NSLocalizedString(@"synctitle", @"");
    self.psWifiConnected = FALSE;
    self.psLastClickTime = 0;
    self.psClickCount = 0;
    
    [self.psListFiles addObject:[SQListItem listItemWithType:PS_SYNC_WIFI]];
    [self.psListFiles addObject:[SQListItem listItemWithType:PS_SYNC_SPLITE]];
    [self.psListFiles addObjectsFromArray:[ServerInfo getServerList]];
    [self.psListFiles addObject:[SQListItem listItemWithType:PS_SYNC_LAST]];
    
#if SHOW_ADS
    // Replace this ad unit ID with your own ad unit ID.
    //self.psBannerView.adUnitID = @"ca-app-pub-3940256099942544/2934735716"; //测试id
    self.psBannerView.adUnitID = @"ca-app-pub-2925148926153054/6441483925";
    self.psBannerView.rootViewController = self;
    self.psBannerView.delegate = self;
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

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    
    [self setDeviceLayout];
}


-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setDeviceLayout]; //设置刘海屏布局
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
    
#if 0
    GADInterstitial* ads = [SQManager sharedSQManager].sqInterstitial;
    if (FALSE == ads.hasBeenUsed && ads.isReady)
    {
        //插页广告还没显示,显示插页广告
        [self performSegueWithIdentifier:@"sync2ads" sender:nil];
    }
#endif
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)reachabilityChanged:(NSNotification *)note
{
    Reachability* curReach = [note object];
    NetworkStatus status = [curReach currentReachabilityStatus];
    if (ReachableViaWiFi == status)
    {
        //wifi连接正常
        NSLog(@"%s - %d wifi connected", __func__, __LINE__);
        self.psWifiConnected = YES;
        [self getCurrentWifiName];
    }
    else
    {
        NSLog(@"%s - %d wifi not connected", __func__, __LINE__);
        self.psWifiConnected = NO;
        
        [self.psTableView reloadData];
    }
}

-(void)serverAddByIp:(NSString *)serverIp andPassword:(NSString *)password
{
    ServerInfo* serverItem = [self serverHasInWithIP:serverIp andPassword:password];
    if (nil == serverItem)
    {
        serverItem = [ServerInfo serverWithIp:serverIp andPassword:password];
        [self.psListFiles insertObject:serverItem atIndex:2];
    }
    
    [serverItem save];
    [self willAddServer:serverItem];
}

-(void)willAddServer:(ServerInfo*)serverInfo
{
    if (FALSE == self.sqAppeared)
    {
        [self performSelector:@selector(willAddServer:) withObject:serverInfo afterDelay:0.3];
        return;
    }
    
    [self.psTableView reloadData];
    
    //进入连接界面
    if(self.psWifiConnected)
    {
        [self performSegueWithIdentifier:@"sync2drawing" sender:serverInfo];
    }
    else
    {
        [MBProgressHUD Toast:NSLocalizedString(@"wifinotconnect", @"wifinotconnect") toView:self.view andTime:1];
    }

}

/**
 服务器是否已存在
 */
-(ServerInfo*)serverHasInWithIP:(NSString*)serverIp andPassword:(NSString*)password
{
    for (id item in self.psListFiles)
    {
        if([item isKindOfClass:[ServerInfo class]])
        {
            ServerInfo* serverItem = item;
            if ([serverIp isEqualToString:serverItem.psServerIp] && [password isEqualToString:serverItem.psPassword])
            {
                return serverItem;
            }
        }
    }
    
    return nil;
}

-(void)getCurrentWifiName
{
    NSArray *ifs = (id)CNCopySupportedInterfaces();
    for (NSString *ifnam in ifs)
    {
        NSDictionary *info = (id)CNCopyCurrentNetworkInfo((CFStringRef)ifnam);
        NSLog(@"dici：%@",[info  allKeys]);
        if (info[@"SSID"])
        {
            self.psWifiName = info[@"SSID"];
            break;
        }
    }
    
    [self.psTableView reloadData];
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
    [_psListFiles release];
    [_psTableView release];
    [_psTitle release];
    [_psReachability release];
    [_psWifiName release];
    [_psLayoutConstraints release];
    [_psViewTitle release];
    [super dealloc];
}

-(void)setWifiCell:(UITableViewCell*)cellView
{
    UILabel* label = (UILabel*)[cellView viewWithTag:101];
    UIImageView* imageView = (UIImageView*)[cellView viewWithTag:100];
    if(self.psWifiConnected)
    {
        label.text = self.psWifiName;
        imageView.image = [UIImage imageNamed:@"wiff_enabel.png"];
    }
    else
    {
        label.text = NSLocalizedString(@"wifinotconnect", nil);
        imageView.image = [UIImage imageNamed:@"wiff_disable.png"];
    }
}

-(void)setServerCell:(UITableViewCell*)cellView andServerInfo:(ServerInfo*)serverInfo
{
    UILabel* label = (UILabel*)[cellView viewWithTag:101];
    label.text = [NSString stringWithFormat:@"%@ (%@)", serverInfo.psServerIp, serverInfo.psPassword];
    
    label = (UILabel*)[cellView viewWithTag:102];
    label.text = serverInfo.psLastTime;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell* cellItem = nil;
    id dataItem = [self.psListFiles objectAtIndex:indexPath.row];
    if ([dataItem isKindOfClass:[SQListItem class]])
    {
        SQListItem* listItem = dataItem;
        if (PS_SYNC_SPLITE == listItem.sqType)
        {
            cellItem = [tableView dequeueReusableCellWithIdentifier:@"CELL_SPLITE"];
        }
        else if(PS_SYNC_WIFI == listItem.sqType)
        {
            cellItem = [tableView dequeueReusableCellWithIdentifier:@"CELL_WIFI"];
            [self setWifiCell:cellItem];
        }
        else
        {
            cellItem = [tableView dequeueReusableCellWithIdentifier:@"CELL_LAST"];
            [cellItem.contentView setTopLayerAtX:0 color:[UIColor lightGrayColor] width:4096 height:0.5];
        }
    }
    else if([dataItem isKindOfClass:[ServerInfo class]])
    {
        cellItem = [tableView dequeueReusableCellWithIdentifier:@"CELL_CONNECT"];
        [self setServerCell:cellItem andServerInfo:dataItem];
        
        if (indexPath.row > 2)
        {
            [cellItem.contentView setTopLayerAtX:15 color:[UIColor lightGrayColor] width:4096 height:0.5];
        }
        else
        {
            [cellItem.contentView setTopLayerAtX:0 color:[UIColor lightGrayColor] width:4096 height:0.5];
        }
    }
    
    cellItem.selectionStyle = UITableViewCellSelectionStyleNone;
    return cellItem;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.psListFiles count];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id tabItem = [self.psListFiles objectAtIndex:indexPath.row];
    if([tabItem isKindOfClass:[ServerInfo class]])
    {
        if(self.psWifiConnected)
        {
            [self performSegueWithIdentifier:@"sync2drawing" sender:tabItem];
        }
        else
        {
            [MBProgressHUD Toast:NSLocalizedString(@"wifinotconnect", @"wifinotconnect") toView:self.view andTime:1];
        }
    }
    else if([tabItem isKindOfClass:[SQListItem class]])
    {
        SQListItem* listItem = tabItem;
        if(PS_SYNC_WIFI == listItem.sqType)
        {
            //连续点击20下后调出日志信息
            NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
            if (now - self.psLastClickTime > 2)
            {
                self.psClickCount = 0;
            }
            else
            {
                self.psClickCount++;
            }
            self.psLastClickTime = now;
            
            if (self.psClickCount >= 20)
            {
                //跳转到日志界面
                [self performSegueWithIdentifier:@"sync2log" sender:nil];
            }
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    float height = 60;
    
    id dataItem = [self.psListFiles objectAtIndex:indexPath.row];
    if ([dataItem isKindOfClass:[SQListItem class]])
    {
        SQListItem* listItem = dataItem;
        if (PS_SYNC_SPLITE == listItem.sqType)
        {
            height = 10;
        }
        else if(PS_SYNC_WIFI == listItem.sqType)
        {
            height = 44;
        }
        else
        {
            height = 51;
        }
    }
    
    return height;
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return TRUE;
}

-(UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id tabItem = self.psListFiles[indexPath.row];
    if([tabItem isKindOfClass:[ServerInfo class]])
    {
        return UITableViewCellEditingStyleDelete;
    }
    
    return UITableViewCellEditingStyleNone;
}

-(NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NSLocalizedString(@"deleting", @"deleting");
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    id tabItem = self.psListFiles[indexPath.row];
    if([tabItem isKindOfClass:[ServerInfo class]])
    {
        ServerInfo* serverItem = tabItem;
        [serverItem removeFromDatabase];
        
        [self.psListFiles removeObject:serverItem];
        [self.psTableView reloadData];
    }
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.destinationViewController isKindOfClass:[ViewCtrlAddServer class]])
    {
        ViewCtrlAddServer* viewCtrl = segue.destinationViewController;
        viewCtrl.psAddServerDelegate = self;
    }
    else if([segue.destinationViewController isKindOfClass:[ViewCtrlPSDrawing class]])
    {
        ViewCtrlPSDrawing* viewCtrl = segue.destinationViewController;
        viewCtrl.psServerInfo = sender;
    }
}

- (IBAction)onClickHelp:(id)sender {
    
}

- (IBAction)onClickBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)onClickAdd:(id)sender {
}
@end
