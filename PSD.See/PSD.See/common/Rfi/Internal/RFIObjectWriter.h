//
//  RFIObjectWriter.h
//  RfiFormat
//
//  Created by Mgen on 14-7-8.
//  Copyright (c) 2014年 Mgen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RFIConstants.h"
#import "RFIDelegate.h"
#import "RFIWriter.h"
#import "RFIWriter+ObjectExtension.h"

@interface RFIObjectWriter : NSObject
@property (nonatomic, retain) RFIWriter *rfiWriter;
- (void)writeObject:(id)val;
@end
