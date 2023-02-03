//
//  SQViewController.m
//  BiMaWen
//
//  Created by SQ-SQ on 14-6-3.
//  Copyright (c) 2014年 sq. All rights reserved.
//

#import "SQViewController.h"

@interface SQViewController ()

@end

@implementation SQViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the
    _sqUserData = [NSMutableDictionary dictionary];
    [_sqUserData retain];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    _sqAppeared = TRUE;
    //NSLog(@"%s-%d", __func__, __LINE__);
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    _sqAppeared = FALSE;
    //NSLog(@"%s-%d", __func__, __LINE__);
}

- (void)dealloc
{
    [_sqUserData release];
    
    NSLog(@"%@%s-%d", [self class], __func__, __LINE__);
    [super dealloc];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
