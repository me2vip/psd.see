//
//  RFIObjectWriter.m
//  RfiFormat
//
//  Created by Mgen on 14-7-8.
//  Copyright (c) 2014年 Mgen. All rights reserved.
//

#import "RFIObjectWriter.h"

@implementation RFIObjectWriter

- (void)writeObject:(id)val
{
    if(val == nil || [val isKindOfClass:[NSNull class]])
    {
        [self writeNull];
        return;
    }

    if ([val isKindOfClass:[NSArray class]])
    {
        NSArray *array = val;
        if (!array.count)
        {
            [self writeNull];
            return;
        }
        
        [self.rfiWriter writeByte:RFI_RAW_TYPE_ARRAY];
        [self.rfiWriter writeLength:array.count];
        for(id item in array)
        {
            [self writeObject:item];
        }
    } //if (isArray)
    else if([val isKindOfClass:[NSData class]])
    {
        NSData *nsData = val;
        if (!nsData.length)
        {
            [self writeNull];
            return;
        }
        [self.rfiWriter writeByte:RFI_RAW_TYPE_BYTES];
        [self.rfiWriter writeLength:nsData.length];
        [self.rfiWriter writeBytes:nsData];
    }
    else if([val isKindOfClass:[NSDictionary class]])
    {
        [self writeDic:val];
    }
    else if([val isKindOfClass:[NSString class]])
    {
        NSString *str = val;
        if (!str.length)
        {
            [self writeNull];
            return;
        }
        [self.rfiWriter writeByte:RFI_RAW_TYPE_STRING];
        [self.rfiWriter writeString:str];
    }
    else if([val isKindOfClass:[NSNumber class]])
    {
        NSNumber *number = val;
        char type = [self getRfiTypeFromNumberType:number];
        [self.rfiWriter writeByte:type];
        [self writeNumber:type val:number];
    }
    else
    {
        [NSException raise:@"UnsupportedType" format:@"%@", [[val class] description]];
    }
}


- (char)getRfiTypeFromNumberType:(NSNumber*)num
{
    CFNumberType type = CFNumberGetType((CFNumberRef)num);
    switch (type)
    {
        case kCFNumberSInt8Type:
        case kCFNumberCharType:
            return RFI_RAW_TYPE_I8;
            
        case kCFNumberSInt16Type:
        case kCFNumberShortType:
            return RFI_RAW_TYPE_I16;
            
        case kCFNumberSInt32Type:
        case kCFNumberIntType:
            return RFI_RAW_TYPE_I32;
            
        case kCFNumberSInt64Type:
        case kCFNumberLongType:
            return RFI_RAW_TYPE_I64;
            
        case kCFNumberFloat32Type:
        case kCFNumberFloatType:
            return RFI_RAW_TYPE_F32;
            
        case kCFNumberFloat64Type:
        case kCFNumberDoubleType:
            return RFI_RAW_TYPE_F64;
            
        default:
            [NSException raise:@"Unsupported int type" format:@"%lu", type];
            break;
    }
    return 0;
}

- (void)writeDic:(NSDictionary*)dic
{
    NSUInteger len = dic.count;
    if(len == 0)
    {
        [self writeNull];
        return;
    }
    
    [self.rfiWriter writeByte:RFI_RAW_TYPE_DIC];
    [self.rfiWriter writeLength:len];
    for (id keyObj in dic)
    {
        if(![keyObj isKindOfClass:[NSString class]])
            [NSException raise:@"Invalid key type" format:@"%@", [keyObj class]];
        NSString *key = (NSString*)keyObj;
        if(!key.length)
            [NSException raise:@"Empty key" format:nil];
        
        [self.rfiWriter writeString:key];
        id value = [dic objectForKey:key];
        [self writeObject:value];
    }
}

- (void)writeNull
{
    [self.rfiWriter writeByte:RFI_RAW_TYPE_NULL];
}

- (void)writeNumber:(char)type val:(NSNumber*)val
{
    switch (type)
    {
        case RFI_RAW_TYPE_I8: //byte
            [self.rfiWriter writeByteObject:val];
            break;
            
        case RFI_RAW_TYPE_I16: //int16
            [self.rfiWriter writeInt16Object:val];
            break;
            
        case RFI_RAW_TYPE_I32: //int32
            [self.rfiWriter writeInt32Object:val];
            break;
            
        case RFI_RAW_TYPE_I64: //int64
            [self.rfiWriter writeInt64Object:val];
            break;
            
        case RFI_RAW_TYPE_F32:
            [self.rfiWriter writeFloatObject:val];
            break;
            
        case RFI_RAW_TYPE_F64:
            [self.rfiWriter writeDoubleObject:val];
            break;
            
        default:
            [NSException raise:@"Unsupported number type" format:@"%d", type];
            break;
    }
}

- (void)dealloc
{
    [_rfiWriter release];
    
    [super dealloc];
}

@end
