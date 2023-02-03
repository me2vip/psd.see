//
//  MBProgressHUD+Toast.h
//  YuanChengUser
//
//  Created by Larry on 16/1/9.
//  Copyright (c) 2016年 YuanCheng. All rights reserved.
//

#import "MBProgressHUD.h"

@interface MBProgressHUD (Toast)

+(void)Toast:(NSString*)text toView:(UIView*)view andTime:(float)time;

@end
