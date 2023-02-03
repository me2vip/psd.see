//
//  ViewCtrlConnectHelpPage4.m
//  PSD.See
//
//  Created by Larry on 16/11/12.
//  Copyright © 2016年 MaiMiao. All rights reserved.
//

#import "ViewCtrlConnectHelpPage4.h"

@interface ViewCtrlConnectHelpPage4 ()
@property (retain, nonatomic) IBOutlet UILabel *psLabel1;

@end

@implementation ViewCtrlConnectHelpPage4

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.psLabel1.text = NSLocalizedString(@"openConnect", @"openConnect");
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
    
    [super dealloc];
}
@end
