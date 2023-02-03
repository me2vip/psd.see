//
//  CBXDataParse.h
//  CbrexHouse
//
//  Created by Larry on 15/6/12.
//  Copyright (c) 2015年 Cbrex. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DataModel.h"

@class ASIHTTPRequest;

@interface DataParse : NSObject

/**
 检查是否有异常
 */
+(id)checkExceptionOnRequest:(ASIHTTPRequest*)request;
/**
 检查是否有新版本
 */
+(BOOL) parseHasNewVersion:(ASIHTTPRequest*)request;

@end
