//
//  RFIFormat.h
//  RfiFormat
//
//  Created by Mgen on 14-7-10.
//  Copyright (c) 2014年 Mgen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RFIType.h"

@interface RFIFormat : NSObject
+ (NSData*)objectToRaw:(id)obj;
+ (id)rawToObject:(NSData*)raw;

@end
