//
//  ViewCtrlConnectHelpPage1.m
//  PSD.See
//
//  Created by Larry on 16/11/12.
//  Copyright © 2016年 MaiMiao. All rights reserved.
//

#import "ViewCtrlConnectHelpPage1.h"

@interface ViewCtrlConnectHelpPage1 ()
@property (retain, nonatomic) IBOutlet UILabel *psLabel1;
@property (retain, nonatomic) IBOutlet UILabel *psLabel2;

@end

@implementation ViewCtrlConnectHelpPage1

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.psLabel1.text = NSLocalizedString(@"psversion", @"psversion");
    self.psLabel2.text = NSLocalizedString(@"helpWifi", @"helpWifi");
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)dealloc {
    [_psLabel1 release];
    [_psLabel2 release];
    
    [super dealloc];
}
@end
