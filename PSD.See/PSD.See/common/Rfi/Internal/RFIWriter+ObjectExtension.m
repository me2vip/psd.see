//
//  RFIWriter+ObjectExtension.m
//  RfiFormat
//
//  Created by Mgen on 14-7-7.
//  Copyright (c) 2014年 Mgen. All rights reserved.
//

#import "RFIWriter+ObjectExtension.h"

@implementation RFIWriter (ObjectExtension)

- (void)writeInt32Object:(NSNumber*)val
{
    [self writeInt32:(int32_t)[val intValue]];
}

- (void)writeInt64Object:(NSNumber*)val
{
    [self writeInt64:(int64_t)[val longValue]];
}

- (void)writeInt16Object:(NSNumber*)val
{
    [self writeInt16:(int16_t)[val shortValue]];
}

- (void)writeUInt32Object:(NSNumber*)val
{
    [self writeUInt32:(uint32_t)[val unsignedIntValue]];
}

- (void)writeUInt64Object:(NSNumber*)val
{
    [self writeUInt64:(uint64_t)[val unsignedLongValue]];
}

- (void)writeUInt16Object:(NSNumber*)val
{
    [self writeUInt16:(uint16_t)[val unsignedShortValue]];
}

- (void)writeByteObject:(NSNumber*)val
{
    [self writeByte:[val charValue]];
}

- (void)writeBoolObject:(NSNumber*)val
{
    [self writeBool:[val boolValue]];
}

- (void)writeFloatObject:(NSNumber*)val
{
    [self writeFloat:[val floatValue]];
}

- (void)writeDoubleObject:(NSNumber*)val
{
    [self writeDouble:[val doubleValue]];
}

- (void)writeNull:(NSNumber*)val
{
    return;
}

@end
