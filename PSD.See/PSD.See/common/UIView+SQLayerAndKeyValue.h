//
//  UIView+SQLayer.h
//  BiMaWen
//
//  Created by SQ-SQ on 14-4-24.
//  Copyright (c) 2014年 sq. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (SQLayerAndKeyValue)

-(void)setTopLayerAtX:(float)xOffeset color:(UIColor *)color width:(float)width height:(float)height;

-(void)setBottomLayerAtX:(float)xOffeset color:(UIColor *)color width:(float)width height:(float)height;

-(void)setBottomLineX:(float)xOffeset color:(UIColor *)color height:(float)height;

-(void)setValueInMap:(NSMutableDictionary*)map withKey:(NSString*)key andValue:(id)value;

-(id)getValueInMap:(NSDictionary*)map withKey:(NSString*)key;

@end
