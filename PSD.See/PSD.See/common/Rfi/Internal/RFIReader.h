//
//  RFIReader.h
//  RfiFormat
//
//  Created by Mgen on 14-7-1.
//  Copyright (c) 2014年 Mgen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RFIReader : NSObject

+ (instancetype)readerWithData:(NSData*)data;
- (instancetype)initWithData:(NSData*)data;

- (NSData*)readBytes:(uint32_t)len;
- (int32_t)readInt32;
- (int64_t)readInt64;
- (int16_t)readInt16;
- (uint32_t)readUInt32;
- (uint64_t)readUInt64;
- (uint16_t)readUInt16;
- (char)readByte;
- (BOOL)readBool;
- (NSString*)readString;
- (NSData*)readPrefixedBytes;
- (float)readFloat;
- (double)readDouble;
- (NSUInteger)readLength;
- (int)getPosition;
/**
 跳过一些字节数
 return: 实际跳过的字节数
 */
- (int)skipBytes:(int)skipCount;
@end
