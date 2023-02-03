//
//  RFIWriter+ObjectExtension.h
//  RfiFormat
//
//  Created by Mgen on 14-7-7.
//  Copyright (c) 2014年 Mgen. All rights reserved.
//

#import "RFIWriter.h"

@interface RFIWriter (ObjectExtension)

- (void)writeInt32Object:(NSNumber*)val;
- (void)writeInt64Object:(NSNumber*)val;
- (void)writeInt16Object:(NSNumber*)val;
- (void)writeUInt32Object:(NSNumber*)val;
- (void)writeUInt64Object:(NSNumber*)val;
- (void)writeUInt16Object:(NSNumber*)val;
- (void)writeByteObject:(NSNumber*)val;
- (void)writeBoolObject:(NSNumber*)val;
- (void)writeFloatObject:(NSNumber*)val;
- (void)writeDoubleObject:(NSNumber*)val;
- (void)writeNull:(NSNumber*)val;

@end
