//
//  RFIContext.h
//  RfiFormat
//
//  Created by Mgen on 14-7-3.
//  Copyright (c) 2014年 Mgen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RFIReader.h"
#import "RFIWriter.h"
#import "RFIReader+ObjectExtension.h"

@interface RFIContext : NSObject
@property (nonatomic, retain) RFIReader *rfiReader;
@property (nonatomic, retain) RFIWriter *rfiWriter;

@end
