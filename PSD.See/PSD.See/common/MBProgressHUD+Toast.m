//
//  MBProgressHUD+Toast.m
//  YuanChengUser
//
//  Created by Larry on 16/1/9.
//  Copyright (c) 2016年 YuanCheng. All rights reserved.
//

#import "MBProgressHUD+Toast.h"

@implementation MBProgressHUD (Toast)

+(void)Toast:(NSString*)text toView:(UIView*)view andTime:(float)time
{
    if(nil == view)
    {
        view = [[UIApplication sharedApplication].windows lastObject];
    }
    
    if(time < 0.05)
    {
        time = 1;
    }
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
    hud.labelText = text;
    hud.mode = MBProgressHUDModeText;
    // 隐藏时候从父控件中移除
    hud.removeFromSuperViewOnHide = YES;
    [hud hide:YES afterDelay:time];
}

@end
