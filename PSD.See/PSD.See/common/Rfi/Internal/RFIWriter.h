//
//  RFIWriter.h
//  RfiFormat
//
//  Created by Mgen on 14-7-1.
//  Copyright (c) 2014年 Mgen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RFIWriter : NSObject

+ (instancetype)writerWithData:(NSMutableData*)data;
- (instancetype)initWithData:(NSMutableData*)data;

- (void)writeBytes:(NSData*)bytes;
- (void)writeBytes:(const char*)rawBytes length:(uint32_t)length;
- (void)writePrefixedBytes:(NSData*)data;
- (void)writeInt32:(int32_t)value;
- (void)writeInt64:(int64_t)value;
- (void)writeInt16:(int16_t)value;
- (void)writeUInt32:(uint32_t)value;
- (void)writeUInt64:(uint64_t)value;
- (void)writeUInt16:(uint16_t)value;
- (void)writeByte:(char)byte;
- (void)writeBool:(BOOL)value;
- (void)writeString:(NSString*)str;
- (void)writeFloat:(float)value;
- (void)writeDouble:(double)value;
- (void)writeLength:(NSUInteger)len;
@end
