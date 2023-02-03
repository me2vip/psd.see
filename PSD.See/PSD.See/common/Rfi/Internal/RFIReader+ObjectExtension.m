//
//  RFIReader+ObjectExtension.m
//  RfiFormat
//
//  Created by Mgen on 14-7-3.
//  Copyright (c) 2014年 Mgen. All rights reserved.
//

#import "RFIReader+ObjectExtension.h"

@implementation RFIReader (ObjectExtension)

- (NSNumber*)readInt32Object
{
    NSNumber *num = @([self readInt32]);
    return num;
}

- (NSNumber*)readInt64Object
{
    NSNumber *num = @([self readInt64]);
    return num;
}

- (NSNumber*)readInt16Object
{
    NSNumber *num = @([self readInt16]);
    return num;
}

- (NSNumber*)readByteObject
{
    NSNumber *num = @([self readByte]);
    return num;
}

- (NSNumber*)readBoolObject
{
    NSNumber *num = @([self readBool]);
    return num;
}

- (NSNumber*)readFloatObject
{
    NSNumber *num = @([self readFloat]);
    return num;
}

- (NSNumber*)readDoubleObject
{
    NSNumber *num = @([self readDouble]);
    return num;
}

@end
