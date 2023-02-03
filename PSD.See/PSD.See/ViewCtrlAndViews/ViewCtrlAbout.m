//
//  ViewCtrlAbout.m
//  PSD.See
//
//  Created by Larry on 16/11/9.
//  Copyright © 2016年 MaiMiao. All rights reserved.
//

#import "ViewCtrlAbout.h"
#import "SQManager.h"

@interface ViewCtrlAbout ()

@property (retain, nonatomic) IBOutlet UILabel *psLabelTitle;
@property (retain, nonatomic) IBOutlet UILabel *psLabelInfo;
@property (retain, nonatomic) IBOutlet UIView *psViewTitle;

@property (retain, nonatomic) NSMutableArray* psLayoutConstraints; //布局属性列表

- (IBAction)onClickBack:(id)sender;

@end

@implementation ViewCtrlAbout

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.psLabelTitle.text = NSLocalizedString(@"about", @"about");
    self.psLabelInfo.text = [NSString stringWithFormat:@"PSD.See V%@\r\n%@:https://github.com/LoveGreenLeave/psd.see", [SQManager sharedSQManager].sqAppVersion, NSLocalizedString(@"Source code link", @"")];
    
    self.psLayoutConstraints = [NSMutableArray array];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setDeviceLayout];
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
        } else {
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

- (void)dealloc
{
    [_psLabelTitle release];
    [_psLabelInfo release];
    [_psLayoutConstraints release];
    [_psViewTitle release];
    [super dealloc];
}
- (IBAction)onClickBack:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}
@end
