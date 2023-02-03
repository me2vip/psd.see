//
//  RFIObjectReader.m
//  RfiFormat
//
//  Created by Mgen on 14-7-8.
//  Copyright (c) 2014年 Mgen. All rights reserved.
//

#import "RFIObjectReader.h"

@implementation RFIObjectReader
- (id)readObject
{
    char type = [self.rfiReader readByte];
    if (type & RFI_FLAG_ISARRAY) //int
    {
        NSUInteger len = [self.rfiReader readLength];
        if(len == 0)
            return [NSNull null];
        
        NSMutableArray *marr = [NSMutableArray arrayWithCapacity:len];
        for (int i = 0; i < len; i++)
        {
            [marr addObject:[self readObject]];
        }
        return marr;
    }
    
    //int
    if(type & RFI_FLAG_ISINT)
        return [self readInt:type];
    
    //non-int
    return [self readNonInt:type];
}

- (id)readDic
{
    NSUInteger len = [self.rfiReader readLength];
    if(len == 0)
        return [NSNull null];
    NSMutableDictionary *mdic = [NSMutableDictionary dictionaryWithCapacity:len];
    for (int i = 0; i < len; i++)
    {
        //read key
        NSString *key = [self.rfiReader readString];
        if(!key.length)
            [NSException raise:@"Empty key" format:nil];
        id value = [self readObject];
        [mdic setObject:value forKey:key];
    }
    return mdic;
}

- (id)readNonInt:(char)type
{
    id ret = nil;
    type = type & RFI_MASK_TYPEENUM;
    switch (type) {
        case RFI_TYPE_NULL: //null
            ret = [NSNull null];
            break;
            
        case RFI_TYPE_STRING: //string
            ret = [self.rfiReader readString];
            break;
            
        case RFI_TYPE_DIC: //dic
            ret = [self readDic];
            break;
            
        case RFI_TYPE_F32: //float
            ret = [self.rfiReader readFloatObject];
            break;
            
        case RFI_TYPE_F64: //double
            ret = [self.rfiReader readDoubleObject];
            break;
            
        case RFI_TYPE_BYTES:
            ret = [self.rfiReader readPrefixedBytes];
            break;
            
        default:
            [NSException raise:@"Unsupported non-int type" format:@"Type: %d", type];
            break;
    }
    return ret;
}

- (id)readInt:(char)type
{
    id ret = nil;
    type = type & RFI_MASK_TYPEENUM;
    switch (type) {
        case RFI_TYPE_I8: //byte
            ret = [self.rfiReader readByteObject];
            break;
            
        case RFI_TYPE_I16: //int16
            ret = [self.rfiReader readInt16Object];
            break;
            
        case RFI_TYPE_I32: //int32
            ret = [self.rfiReader readInt32Object];
            break;
            
        case RFI_TYPE_I64: //int64
            ret = [self.rfiReader readInt64Object];
            break;
            
        default:
            [NSException raise:@"Unsupported int type" format:@"Type: %d", type];
            break;
    }
    return ret;
}

- (void)dealloc
{
    [_rfiReader release];
    
    [super dealloc];
}

@end
