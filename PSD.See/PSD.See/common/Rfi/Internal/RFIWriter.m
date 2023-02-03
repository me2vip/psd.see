//
//  RFIWriter.m
//  RfiFormat
//
//  Created by Mgen on 14-7-1.
//  Copyright (c) 2014年 Mgen. All rights reserved.
//

#import "RFIWriter.h"

@interface RFIWriter ()

@property (nonatomic, assign) uint32_t poz;
@property (nonatomic, retain) NSMutableData *rfiData;

@end

@implementation RFIWriter

+ (instancetype)writerWithData:(NSMutableData *)data
{
    return [[[RFIWriter alloc] initWithData:data] autorelease];
}

- (instancetype)initWithData:(NSMutableData *)data
{
    self = [super init];
    if (!self || !data)
        return nil;
    
    self.rfiData = data;
    return self;
}

- (void)writeBytes:(NSData*)bytes
{
    if(bytes.length) [self.rfiData appendData:bytes];
}

- (void)writeBytes:(const char*)rawBytes length:(uint32_t)length
{
    if(length) [self.rfiData appendBytes:rawBytes length:length];
}

- (void)writePrefixedBytes:(NSData *)data
{
    [self writeLength:data.length];
    [self writeBytes:data];
}

- (void)writeInt32:(int32_t)value
{
    [self writeBytes:(const char *)&value length:sizeof(int32_t)];
}

- (void)writeInt64:(int64_t)value
{
    [self writeBytes:(const char *)&value length:sizeof(int64_t)];
}

- (void)writeInt16:(int16_t)value
{
    [self writeBytes:(const char *)&value length:sizeof(int16_t)];
}

- (void)writeUInt32:(uint32_t)value
{
    [self writeBytes:(const char *)&value length:sizeof(uint32_t)];
}

- (void)writeUInt64:(uint64_t)value
{
    [self writeBytes:(const char *)&value length:sizeof(uint64_t)];
}

- (void)writeUInt16:(uint16_t)value
{
    [self writeBytes:(const char *)&value length:sizeof(uint16_t)];
}

- (void)writeByte:(char)byte
{
    [self writeBytes:(const char *)&byte length:sizeof(char)];
}

- (void)writeBool:(BOOL)value
{
    [self writeByte:value ? 1 : 0];
}

- (void)writeString:(NSString*)str
{
    if(!str.length)
        [self writeLength:0];
    else
        [self writePrefixedBytes:[str dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void)writeFloat:(float)value
{
    [self writeBytes:(const char *)&value length:sizeof(float)];
}

- (void)writeDouble:(double)value
{
    [self writeBytes:(const char *)&value length:sizeof(double)];
}

- (void)writeLength:(NSUInteger)len
{
    uint32_t num;
    for (num = (uint32_t)len; num >= (uint32_t)128; num >>= 7)
    {
        [self writeByte:(char)(num | (uint32_t)128)];
    }
    [self writeByte:(char)num];
}

-(void)dealloc
{
    [_rfiData release];
    
    [super dealloc];
}

@end
