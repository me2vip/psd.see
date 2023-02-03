//
//  RFIReader+ObjectExtension.h
//  RfiFormat
//
//  Created by Mgen on 14-7-3.
//  Copyright (c) 2014年 Mgen. All rights reserved.
//

#import "RFIReader.h"

@interface RFIReader (ObjectExtension)

- (NSNumber*)readInt32Object;
- (NSNumber*)readInt64Object;
- (NSNumber*)readInt16Object;
- (NSNumber*)readByteObject;
- (NSNumber*)readBoolObject;
- (NSNumber*)readFloatObject;
- (NSNumber*)readDoubleObject;

@end
