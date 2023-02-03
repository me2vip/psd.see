//
//  ViewCtrlAbout.h
//  PSD.See
//
//  Created by Larry on 16/11/9.
//  Copyright © 2016年 MaiMiao. All rights reserved.
//

#import "SQViewController.h"
#import "DataModel.h"

@protocol PSFileAddedByScanDelegate <NSObject>

-(void)onFileScanSuccessWithPath:(NSString*)filePath;

@end

@interface ViewCtrlScan : SQViewController

@property (nonatomic, assign)id<PSFileAddedByScanDelegate> psDelegate;

@end
