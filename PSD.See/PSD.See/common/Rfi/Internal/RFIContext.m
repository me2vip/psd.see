//
//  RFIContext.m
//  RfiFormat
//
//  Created by Mgen on 14-7-3.
//  Copyright (c) 2014年 Mgen. All rights reserved.
//

#import "RFIContext.h"

@implementation RFIContext

- (void)dealloc
{
    [_rfiReader release];
    [_rfiWriter release];
    
    [super dealloc];
}

@end
