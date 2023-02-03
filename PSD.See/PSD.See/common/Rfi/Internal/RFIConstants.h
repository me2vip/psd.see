//
//  RFIConstants.h
//  RfiFormat
//
//  Created by Mgen on 14-7-8.
//  Copyright (c) 2014年 Mgen. All rights reserved.
//

#import <Foundation/Foundation.h>


//| [1] Array | [2] Int | [3] Sign | [4 - 8]: Type |
#define RFI_FLAG_ISARRAY 0x80
#define RFI_FLAG_ISINT 0x40
#define RFI_MASK_TYPEENUM 0x1F
#define RFI_TYPE_NULL 0
#define RFI_TYPE_STRING 1
#define RFI_TYPE_DIC 2
#define RFI_TYPE_F32 3
#define RFI_TYPE_F64 4
#define RFI_TYPE_BYTES 5
#define RFI_TYPE_I8 1
#define RFI_TYPE_I16 2
#define RFI_TYPE_I32 3
#define RFI_TYPE_I64 4

#define RFI_RAW_TYPE_NULL RFI_TYPE_NULL
#define RFI_RAW_TYPE_STRING RFI_TYPE_STRING
#define RFI_RAW_TYPE_DIC RFI_TYPE_DIC
#define RFI_RAW_TYPE_BYTES RFI_TYPE_BYTES
#define RFI_RAW_TYPE_F32 RFI_TYPE_F32
#define RFI_RAW_TYPE_F64 RFI_TYPE_F64
#define RFI_RAW_TYPE_I8  (RFI_TYPE_I8 | RFI_FLAG_ISINT)
#define RFI_RAW_TYPE_I16 (RFI_TYPE_I16 | RFI_FLAG_ISINT)
#define RFI_RAW_TYPE_I32 (RFI_TYPE_I32 | RFI_FLAG_ISINT)
#define RFI_RAW_TYPE_I64 (RFI_TYPE_I64 | RFI_FLAG_ISINT)
#define RFI_RAW_TYPE_ARRAY RFI_FLAG_ISARRAY
