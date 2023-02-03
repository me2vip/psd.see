//
//  SQListItem.m
//  CbrexHouse
//
//  Created by Larry on 15/6/3.
//  Copyright (c) 2015年 Cbrex. All rights reserved.
//

#import "SQListItem.h"

@implementation SQListItem

+(id)listItem
{
    return [[[SQListItem alloc] init] autorelease];
}

+(id)listItemWithType:(int)type
{
    SQListItem* item = [[[SQListItem alloc] init] autorelease];
    item.sqType = type;
    
    return item;
}

- (void)dealloc
{
    [_sqContent release];
    [_sqIndex release];
    
    [super dealloc];
}

@end
