//
//  ViewCtrlConnectHelp.m
//  PSD.See
//
//  Created by Larry on 16/11/12.
//  Copyright © 2016年 MaiMiao. All rights reserved.
//

#import "ViewCtrlConnectHelp.h"
#import "KDViewPager.h"
#import "ViewCtrlConnectHelpPage1.h"
#import "ViewCtrlConnectHelpPage2.h"
#import "ViewCtrlConnectHelpPage3.h"
#import "ViewCtrlConnectHelpPage4.h"
#import "ViewCtrlConnectHelpPage5.h"
#import "ViewCtrlConnectHelpPage6.h"
#import "ViewCtrlConnectHelpPage7.h"
#import "ViewCtrlConnectHelpPage8.h"
#import "SQManager.h"
#import "SQConstant.h"

enum
{
    PS_PAGE_SIZE = 8,
};

@interface ViewCtrlConnectHelp ()<KDViewPagerDatasource, KDViewPagerDelegate>

@property (retain, nonatomic) IBOutlet UIButton *psButtonBack;
@property (retain, nonatomic) IBOutlet UIView *psContentView;
@property (retain, nonatomic) IBOutlet UILabel *psLabelPage;

@property (nonatomic, retain) KDViewPager* psViewPage;

- (IBAction)onClickBack:(id)sender;

@end

@implementation ViewCtrlConnectHelp

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    self.psViewPage = [[[KDViewPager alloc] initWithController:self inView:self.psContentView] autorelease];
    self.psViewPage.delegate = self;
    self.psViewPage.datasource = self;
    self.psLabelPage.text = [NSString stringWithFormat:@"1/%d", PS_PAGE_SIZE];
    
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

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [SQManager addBorderToView:self.psButtonBack width:0.5 color:[UIColor lightGrayColor] cornerRadius:self.psButtonBack.frame.size.width / 2];
    [SQManager addBorderToView:self.psLabelPage width:0.5 color:[UIColor lightGrayColor] cornerRadius:self.psLabelPage.frame.size.width / 2];
}

-(UIViewController *)kdViewPager:(KDViewPager *)viewPager controllerAtIndex:(NSUInteger)index cachedController:(UIViewController *)cachedController
{
    UIStoryboard * storyBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    if (0 == index && nil == cachedController)
    {
        cachedController = [storyBoard instantiateViewControllerWithIdentifier:@"HELP_PAGE_1"];
    }
    else if(1 == index && nil == cachedController)
    {
        cachedController = [[[ViewCtrlConnectHelpPage2 alloc] init] autorelease];
        cachedController = [storyBoard instantiateViewControllerWithIdentifier:@"HELP_PAGE_2"];
    }
    else if(2 == index && nil == cachedController)
    {
        cachedController = [[[ViewCtrlConnectHelpPage3 alloc] init] autorelease];
        cachedController = [storyBoard instantiateViewControllerWithIdentifier:@"HELP_PAGE_3"];
    }
    else if(3 == index && nil == cachedController)
    {
        cachedController = [[[ViewCtrlConnectHelpPage3 alloc] init] autorelease];
        cachedController = [storyBoard instantiateViewControllerWithIdentifier:@"HELP_PAGE_4"];
    }
    else if(4 == index && nil == cachedController)
    {
        cachedController = [[[ViewCtrlConnectHelpPage3 alloc] init] autorelease];
        cachedController = [storyBoard instantiateViewControllerWithIdentifier:@"HELP_PAGE_5"];
    }
    else if(5 == index && nil == cachedController)
    {
        cachedController = [[[ViewCtrlConnectHelpPage3 alloc] init] autorelease];
        cachedController = [storyBoard instantiateViewControllerWithIdentifier:@"HELP_PAGE_6"];
    }
    else if(6 == index && nil == cachedController)
    {
        cachedController = [[[ViewCtrlConnectHelpPage3 alloc] init] autorelease];
        cachedController = [storyBoard instantiateViewControllerWithIdentifier:@"HELP_PAGE_7"];
    }
    else if(7 == index && nil == cachedController)
    {
        cachedController = [[[ViewCtrlConnectHelpPage3 alloc] init] autorelease];
        cachedController = [storyBoard instantiateViewControllerWithIdentifier:@"HELP_PAGE_8"];
    }

    return cachedController;
}

-(NSUInteger)numberOfPages:(KDViewPager *)viewPager
{
    return PS_PAGE_SIZE;
}

-(void)kdViewpager:(KDViewPager *)viewPager didSelectPage:(NSUInteger)index direction:(UIPageViewControllerNavigationDirection)direction selectedViewController:(UIViewController *)viewController
{
    //NSLog(@"%s-%d index:%ld, viewController:%@", __func__, __LINE__, index, viewController);
    self.psLabelPage.text = [NSString stringWithFormat:@"%u/%d", (index+1), PS_PAGE_SIZE];
}

-(void)kdViewpager:(KDViewPager *)viewPager willSelectPage:(NSUInteger)index direction:(UIPageViewControllerNavigationDirection)direction selectedViewController:(UIViewController *)viewController
{
    //NSLog(@"%s-%d index:%ld, viewController:%@", __func__, __LINE__, index, viewController);
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
    [_psButtonBack release];
    [_psContentView release];
    [_psViewPage release];
    
    [_psLabelPage release];
    [super dealloc];
}

- (IBAction)onClickBack:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}
@end
