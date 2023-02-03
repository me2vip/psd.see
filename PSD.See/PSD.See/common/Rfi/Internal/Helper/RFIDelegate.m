//
//  RFIDelegate.m
//  RfiFormat
//
//  Created by Mgen on 14-7-3.
//  Copyright (c) 2014年 Mgen. All rights reserved.
//

#import "RFIDelegate.h"

@implementation RFIDelegate

- (id)invokeFunc
{
    return [self.rfiObj performSelector:_sel];
}

- (id)invokeFunc:(id)pa1
{
    return [self.rfiObj performSelector:_sel withObject:pa1];
}

- (void)invokeAction
{
    [self.rfiObj performSelector:_sel];
}

- (void)invokeAction:(id)pa1
{
    [self.rfiObj performSelector:_sel withObject:pa1];
}

-(void)dealloc
{
    [_rfiObj release];
    _sel = nil;
    
    [super dealloc];
}

@end
