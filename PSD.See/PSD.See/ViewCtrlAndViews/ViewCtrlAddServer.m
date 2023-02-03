//
//  ViewCtrlAddServer.m
//  PSD.See
//
//  Created by Larry on 16/10/16.
//  Copyright © 2016年 MaiMiao. All rights reserved.
//

#import "ViewCtrlAddServer.h"
#import "psdata.h"
#import "SQManager.h"
#import "datamodel.h"
#import "mbprogresshud+toast.h"
#import "SQConstant.h"


@interface ViewCtrlAddServer ()

@property (retain, nonatomic) IBOutlet UILabel *spLabelTitle;
@property (retain, nonatomic) IBOutlet UILabel *psLabelServerIp;
@property (retain, nonatomic) IBOutlet UITextField *psEditServerIp;
@property (retain, nonatomic) IBOutlet UILabel *psLabelPassword;
@property (retain, nonatomic) IBOutlet UITextField *psEditPassword;
@property (retain, nonatomic) IBOutlet UIButton *psButtonAdd;
@property (retain, nonatomic) IBOutlet UILabel *psLabelHelp;
@property (retain, nonatomic) IBOutlet UIView *psViewTitle;

@property (retain, nonatomic) NSMutableArray* psLayoutConstraints; //布局属性列表

- (IBAction)onClickBack:(id)sender;
- (IBAction)onClickHelp:(id)sender;
- (IBAction)onClickAdd:(id)sender;


@end

@implementation ViewCtrlAddServer

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self.spLabelTitle setText:NSLocalizedString(@"add connect", @"add connect")];
    [self.psButtonAdd setTitle:NSLocalizedString(@"add", @"add") forState:UIControlStateNormal];
    [self.psButtonAdd setTitle:NSLocalizedString(@"add", @"add") forState:UIControlStateHighlighted];
    [self.psLabelHelp setText:NSLocalizedString(@"new server help", @"new server help")];
    [self.psEditPassword setPlaceholder:NSLocalizedString(@"hint password", @"hint password")];
    [self.psEditServerIp setPlaceholder:NSLocalizedString(@"hint server ip", @"hint server ip")];
    [self.psLabelPassword setText:NSLocalizedString(@"passwrod", @"passwrod")];
    [self.psLabelServerIp setText:NSLocalizedString(@"server ip", @"server ip")];
    
    [self.psEditServerIp setText:@""];
    [self.psEditPassword setText:@""];
    self.psLayoutConstraints = [NSMutableArray array];
    
#if SHOW_ADS
    // Replace this ad unit ID with your own ad unit ID.
    //self.psBannerView.adUnitID = @"ca-app-pub-3940256099942544/2934735716"; //测试id
    self.psBannerView.adUnitID = @"ca-app-pub-2925148926153054/6441483925";
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
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/**
 设置iphone x布局
 */
-(void)setDeviceLayout{
    UIView* titleView = self.psViewTitle;
    NSDictionary *views = @{ @"titleView":titleView };
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
    /**
    NSLog(@"%f %f %f %f", self.psButtonAdd.frame.origin.x, self.psButtonAdd.frame.origin.y, self.psButtonAdd.frame.size.width, self.psButtonAdd.frame.size.height);
    **/
    [super viewWillAppear:animated];
    [self setDeviceLayout]; //设置刘海屏布局
    UIImage* imageNormal = [SQManager imageWithColor:[UIColor colorWithRed:0x11/255.f green:0x8c/255.f blue:0xe3/255.f alpha:1] andSize:self.psButtonAdd.frame.size andRadius:5.f];
    UIImage* imagePress = [SQManager imageWithColor:[UIColor colorWithRed:0x11/255.f green:0x3c/255.f blue:0x8a/255.f alpha:1] andSize:self.psButtonAdd.frame.size andRadius:5.f];
    
    [self.psButtonAdd setBackgroundImage:imageNormal forState:UIControlStateNormal];
    [self.psButtonAdd setBackgroundImage:imagePress forState:UIControlStateHighlighted];
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

- (IBAction)onClickBack:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)onClickHelp:(id)sender {
}

- (IBAction)onClickAdd:(id)sender
{
    NSString* serverIp = [self.psEditServerIp text];
    NSString* password = self.psEditPassword.text;
    
    if ([serverIp length] == 0)
    {
        [MBProgressHUD Toast:NSLocalizedString(@"serverIpNull", @"serverIpNull") toView:self.view andTime:1];
        return;
    }
    
    if([password length] == 0)
    {
        [MBProgressHUD Toast:NSLocalizedString(@"passwordNull", @"passwordNull") toView:self.view andTime:1];
        return;
    }
    
    [self.psAddServerDelegate serverAddByIp:serverIp andPassword:password];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)dealloc
{
    [_spLabelTitle release];
    [_psLabelServerIp release];
    [_psEditServerIp release];
    [_psLabelPassword release];
    [_psEditPassword release];
    [_psButtonAdd release];
    [_psLabelHelp release];
    [_psLayoutConstraints release];
    [_psViewTitle release];
    [super dealloc];
}
@end
