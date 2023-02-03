//
//  RFIReader.m
//  RfiFormat
//
//  Created by Mgen on 14-7-1.
//  Copyright (c) 2014年 Mgen. All rights reserved.
//

#import "RFIReader.h"

@interface RFIReader ()
{
    char *_pointer;
}

@property (nonatomic, assign) uint32_t poz;
@property (nonatomic, retain) NSData *rfiData;

@end

@implementation RFIReader

+ (instancetype)readerWithData:(NSData *)data
{
    return [[[RFIReader alloc] initWithData:data] autorelease];
}

- (instancetype)initWithData:(NSData*)data
{
    self = [super init];
    if (!self || !data)
        return nil;
    
    self.rfiData = data;
    _pointer = (char*)(self.rfiData.bytes);
    return self;
}

- (NSData*)readBytes:(uint32_t)len
{
    if(!len) return nil;
    NSData *data = [self.rfiData subdataWithRange:NSMakeRange(_poz, len)];
    _poz += len;
    return data;
}

- (NSData*)readPrefixedBytes
{
    NSUInteger len = [self readLength];
    return [self readBytes:(uint32_t)len];
}

- (int32_t)readInt32
{
    char *ptr = _pointer + _poz;
    _poz += sizeof(int32_t);
    return *(int32_t*)ptr;
}

- (int64_t)readInt64
{
    char *ptr = _pointer + _poz;
    _poz += sizeof(int64_t);
    return *(int64_t*)ptr;
}

- (int16_t)readInt16
{
    char *ptr = _pointer + _poz;
    _poz += sizeof(int16_t);
    return *(int16_t*)ptr;
}

- (uint32_t)readUInt32
{
    char *ptr = _pointer + _poz;
    _poz += sizeof(uint32_t);
    return *(uint32_t*)ptr;
}

- (uint64_t)readUInt64
{
    char *ptr = _pointer + _poz;
    _poz += sizeof(uint64_t);
    return *(uint64_t*)ptr;
}

- (uint16_t)readUInt16
{
    char *ptr = _pointer + _poz;
    _poz += sizeof(uint16_t);
    return *(uint16_t*)ptr;
}

- (char)readByte
{
    char *ptr = _pointer + _poz;
    _poz += sizeof(char);
    return *(char*)ptr;
}

- (BOOL)readBool
{
    char *ptr = _pointer + _poz;
    _poz += sizeof(BOOL);
    return *(BOOL*)ptr;
}

- (float)readFloat
{
    char *ptr = _pointer + _poz;
    _poz += sizeof(float);
    return *(float*)ptr;
}

- (double)readDouble
{
    char *ptr = _pointer + _poz;
    _poz += sizeof(double);
    return *(double*)ptr;
}

- (NSString*)readString
{
    NSData *data = [self readPrefixedBytes];
    if(!data.length)
        return nil;
    return [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
}

- (NSUInteger)readLength
{
    int32_t num = 0;
    int32_t num2 = 0;
    while (num2 != 35)
    {
        char b = [self readByte];
        num |= (int32_t)(b & 127) << num2;
        num2 += 7;
        if ((b & 128) == 0)
        {
            return (uint32_t)num;
        }
    }
    [NSException raise:@"Corrupted length format" format:nil];
    return 0;
}

- (int)skipBytes:(int)skipCount
{
    int realSkip = skipCount;
    if (_poz + realSkip >= [_rfiData length])
    {
        realSkip = (int)([_rfiData length] - _poz);
        _poz += realSkip;
    }
    else
    {
        _poz += skipCount;
    }
    
    return realSkip;
}

- (int)getPosition
{
    return _poz;
}

- (void)dealloc
{
    [_rfiData release];
    
    [super dealloc];
}

@end
