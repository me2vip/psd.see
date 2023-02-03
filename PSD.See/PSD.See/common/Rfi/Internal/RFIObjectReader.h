//
//  RFIObjectReader.h
//  RfiFormat
//
//  Created by Mgen on 14-7-8.
//  Copyright (c) 2014年 Mgen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RFIConstants.h"
#import "RFIDelegate.h"
#import "RFIReader.h"
#import "RFIReader+ObjectExtension.h"

@interface RFIObjectReader : NSObject
@property (nonatomic, retain) RFIReader *rfiReader;
- (id)readObject;
@end
