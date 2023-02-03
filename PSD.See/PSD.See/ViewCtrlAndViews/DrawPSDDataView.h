//
//  DrawImageView.h
//  PSD.See
//
//  Created by Larry on 16/9/29.
//  Copyright © 2016年 MaiMiao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "datamodel.h"

@interface DrawPSDDataView : UIView

-(void)refreshImage:(UIImage*)image;
-(void)fullScreen;
-(void)restoreView;
-(void)save;

@end
