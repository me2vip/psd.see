//
//  RFIFormat.m
//  RfiFormat
//
//  Created by Mgen on 14-7-10.
//  Copyright (c) 2014年 Mgen. All rights reserved.
//

#import "RFIFormat.h"
#import "RFIWriter.h"
#import "RFIReader.h"
#import "RFIObjectReader.h"
#import "RFIObjectWriter.h"

@implementation RFIFormat

+ (id)rawToObject:(NSData *)raw
{
    if(!raw.length)
        return nil;
    RFIReader *reader = [RFIReader readerWithData:raw];
    RFIObjectReader *objReader = [[[RFIObjectReader alloc] init] autorelease];
    objReader.rfiReader = reader;
    return [objReader readObject];
}

+ (NSData *)objectToRaw:(id)obj
{
    if(!obj)
        return nil;
    NSMutableData *mdata = [NSMutableData data];
    RFIWriter *writer = [RFIWriter writerWithData:mdata];
    RFIObjectWriter *objWriter = [[[RFIObjectWriter alloc] init] autorelease];
    objWriter.rfiWriter = writer;
    [objWriter writeObject:obj];
    return mdata;
}

@end
