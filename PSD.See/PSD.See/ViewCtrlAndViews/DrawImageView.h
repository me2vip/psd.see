//
//  DrawImageView.h
//  PSD.See
//
//  Created by Larry on 16/9/29.
//  Copyright © 2016年 MaiMiao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "datamodel.h"

@interface DrawImageView : UIView

-(void)initWithFileItem:(FileItem*)fileItem;
-(void)updateImage:(UIImage*)image; //更新图片
-(void)fullScreen;
-(void)restoreView;
-(void)rotateWithAngle:(int)angle; //旋转图片

@end
