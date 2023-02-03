//
//  SQListItem.h
//  CbrexHouse
//
//  Created by Larry on 15/6/3.
//  Copyright (c) 2015年 Cbrex. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SQListItem : NSObject

@property (nonatomic, retain)id sqContent;
@property (nonatomic, assign)int sqType;
@property (nonatomic, retain)NSIndexPath* sqIndex;

+(id)listItem;
+(id)listItemWithType:(int)type;

@end
