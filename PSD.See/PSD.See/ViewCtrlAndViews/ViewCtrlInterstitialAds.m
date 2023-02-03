//
//  ViewCtrlInterstitialAds.m
//  PSD.See
//
//  Created by Larry on 16/12/2.
//  Copyright © 2016年 MaiMiao. All rights reserved.
//

#import "ViewCtrlInterstitialAds.h"
#import "SQManager.h"
#import "SQConstant.h"
@import GoogleMobileAds;

@interface ViewCtrlInterstitialAds ()<GADNativeExpressAdViewDelegate>

@property (retain, nonatomic) IBOutlet GADNativeExpressAdView *psAdsView;

@end

@implementation ViewCtrlInterstitialAds

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
#if SHOW_ADS
    self.psAdsView.adUnitID = @"ca-app-pub-2925148926153054/7594338325";
    //self.psAdsView.rootViewController = self;
    self.psAdsView.delegate = self;
    GADRequest *request = [GADRequest request];
    request.testDevices = @[
                            @"bd9a4a5a08499bf693087e78520a5b9a", @"94af4af21f1c3cf20c296729d25cbf58"  // Eric's iPod Touch
                            ];
    [self.psAdsView loadRequest:request];
#endif
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    [_psAdsView release];
    [super dealloc];
}

/// Tells the delegate that the native express ad view successfully received an ad. The delegate may
/// want to add the native express ad view to the view hierarchy if it hasn't been added yet.
- (void)nativeExpressAdViewDidReceiveAd:(GADNativeExpressAdView *)nativeExpressAdView
{
    
}

/// Tells the delegate that an ad request failed. The failure is normally due to network
/// connectivity or ad availablility (i.e., no fill).
- (void)nativeExpressAdView:(GADNativeExpressAdView *)nativeExpressAdView
didFailToReceiveAdWithError:(GADRequestError *)error
{
    
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
