//
//  UIView+SQAutoLayoutView.m
//  BiMaWen
//
//  Created by aec on 14-1-20.
//  Copyright (c) 2014年 sq. All rights reserved.
//

#import "UIView+SQAutoLayoutView.h"

@implementation UIView (SQAutoLayoutView)

+(id)autolayoutView
{
    UIView* view = [[self new] autorelease];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    //NSLog(@"%s-%d count=%d", __FUNCTION__, __LINE__, [view retainCount]);
    
    return view;
}

@end
