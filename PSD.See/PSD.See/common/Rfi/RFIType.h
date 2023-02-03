//
//  RFIType.h
//  RfiFormat
//
//  Created by Mgen on 14-7-7.
//  Copyright (c) 2014年 Mgen. All rights reserved.
//

typedef NS_ENUM(NSUInteger, RFIType) {
    RFITypeUnset = 0,
    RFITypeObject,
    RFITypeI8,
    RFITypeI16,
    RFITypeI32,
    RFITypeI64,
    RFITypeF32,
    RFITypeF64,
    RFITypeString,
    RFITypeDic,
};