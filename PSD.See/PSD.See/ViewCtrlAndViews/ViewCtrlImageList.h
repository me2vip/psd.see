//
//  ViewController.h
//  PSD.See
//
//  Created by Larry on 16/9/5.
//  Copyright © 2016年 MaiMiao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SQViewController.h"

@protocol PSDImageSelectedDelegate <NSObject>

-(void)imageSelected:(UIImage*)image;

@end

@interface ViewCtrlImageList : SQViewController

@property(nonatomic, assign)id<PSDImageSelectedDelegate> psImageSelectedDelegate;

@end

