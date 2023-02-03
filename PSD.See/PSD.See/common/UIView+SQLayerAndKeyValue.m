//
//  UIView+SQLayer.m
//  BiMaWen
//
//  Created by SQ-SQ on 14-4-24.
//  Copyright (c) 2014年 sq. All rights reserved.
//

#import "UIView+SQLayerAndKeyValue.h"
#import "UIView+SQAutoLayoutView.h"

#define BOTTOM_LINE 0x3ffff0

@implementation UIView (SQLayer)

-(void)setTopLayerAtX:(float)xOffeset color:(UIColor *)color width:(float)width height:(float)height
{
    CALayer* newLayer = [self getLayerByName:@"TOP_LAYER_SQ"];
    if (newLayer)
    {
        newLayer.backgroundColor = color.CGColor;
        newLayer.frame = CGRectMake(xOffeset, 0, width, height);
        return;
    }
    
    newLayer = [CALayer layer];
    newLayer.name = @"TOP_LAYER_SQ";
    newLayer.contentsScale = [UIScreen mainScreen].scale;
    newLayer.backgroundColor = color.CGColor;
    newLayer.frame = CGRectMake(xOffeset, 0, width, height);
    [self.layer addSublayer:newLayer];
}

-(void)setBottomLayerAtX:(float)xOffeset color:(UIColor *)color width:(float)width height:(float)height
{
    CALayer* newLayer = [self getLayerByName:@"BOTTOM_LAYER_SQ"];
    if (newLayer)
    {
        newLayer.backgroundColor = color.CGColor;
        newLayer.frame = CGRectMake(xOffeset, self.frame.size.height - height, width, height);
        return;
    }
    
    newLayer = [CALayer layer];
    newLayer.contentsScale = [UIScreen mainScreen].scale;
    newLayer.backgroundColor = color.CGColor;
    newLayer.name = @"BOTTOM_LAYER_SQ";
    newLayer.frame = CGRectMake(xOffeset, self.frame.size.height - height, width, height);
    [self.layer addSublayer:newLayer];
}

-(CALayer*)getLayerByName:(NSString*)name
{
    for (CALayer* layer in self.layer.sublayers)
    {
        if ([layer.name length] > 0 && [name isEqualToString:layer.name])
        {
            return layer;
        }
    }
    
    return nil;
}

-(void)setBottomLineX:(float)xOffeset color:(UIColor *)color height:(float)height
{
    UIView* view = [self viewWithTag:BOTTOM_LINE];
    if (view)
    {
        return;
    }
    view = [UIView autolayoutView];
    [view setBackgroundColor:color];
    view.tag = BOTTOM_LINE;
    [self addSubview:view];
    
    NSDictionary* views = NSDictionaryOfVariableBindings(view);
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"|-%f-[view]-0-|", xOffeset] options:0 metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:[view(%f)]-0-|", height] options:0 metrics:nil views:views]];
}

-(void)setValueInMap:(NSMutableDictionary*)map withKey:(NSString*)key andValue:(id)value
{
    [map setValue:value forKey:key];
}

-(id)getValueInMap:(NSDictionary*)map withKey:(NSString*)key
{
    return [map valueForKey:key];
}

@end
