//
//  ViewController.h
//  PSD.See
//
//  Created by Larry on 16/9/5.
//  Copyright © 2016年 MaiMiao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SQViewController.h"

@interface ViewCtrlMain : SQViewController

/**
 打开外部文件
 */
-(void)openExternalFile:(NSString*)filePath;

/***
 保存文件s
 */
-(void)addFilePathInList:(NSString*)filePath;

@end

