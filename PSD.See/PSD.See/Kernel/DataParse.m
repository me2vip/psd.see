//
//  CBXDataParse.m
//  CbrexHouse
//
//  Created by Larry on 15/6/12.
//  Copyright (c) 2015年 Cbrex. All rights reserved.
//

#import "DataParse.h"
#import "ASIHTTPRequest.h"
#import "SQConstant.h"
#import "JSONKit.h"
#import "SQManager.h"

#define JSON_LOG_OUT 1

#if JSON_LOG_OUT

#define JsonLog NSLog

#else

#define JsonLog

#endif

@implementation DataParse

+(id)checkExceptionOnRequest:(ASIHTTPRequest*)request
{
    const int STATU_CODE = [request responseStatusCode];
    NSDictionary* jsonData = nil;
    NSLog(@"%s-%d http statu:%d", __FUNCTION__, __LINE__, STATU_CODE);
    
    if (200 != STATU_CODE && 206 != STATU_CODE)
    {
        @throw [NSException exceptionWithName:@"1000" reason:NSLocalizedString(@"server_error", @"server_error") userInfo:nil];
    }
    
    jsonData = [[request responseData] objectFromJSONDataNullCase];
    JsonLog(@"%s-%d json:%@", __func__, __LINE__, jsonData);
    if (nil == jsonData)
    {
        @throw [NSException exceptionWithName:@"1001" reason:NSLocalizedString(@"server_error", @"server_error") userInfo:nil];
    }
    
    int error = [[jsonData objectForKey:@"error"] intValue];
    if (error)
    {
        @throw [NSException exceptionWithName:[NSString stringWithFormat:@"%d", error] reason:[jsonData objectForKey:@"errorInfo"] userInfo:nil];
    }
    
    return jsonData;
}

/**
 * 解析是否有新版本
 * @param json
 * @throws KernelException
 * @throws JSONException
 */
+(BOOL) parseHasNewVersion:(ASIHTTPRequest*)request
{
    BOOL result = NO;
    @autoreleasepool
    {
        const int STATU_CODE = [request responseStatusCode];
        NSDictionary* jsonData = nil;
        NSLog(@"%s-%d http statu:%d", __FUNCTION__, __LINE__, STATU_CODE);
        
        if (200 != STATU_CODE && 206 != STATU_CODE)
        {
            @throw [NSException exceptionWithName:@"1000" reason:NSLocalizedString(@"server_error", @"server_error") userInfo:nil];
        }
        
        jsonData = [[request responseData] objectFromJSONDataNullCase];
        JsonLog(@"%s-%d json:%@", __func__, __LINE__, jsonData);
        if (nil == jsonData)
        {
            @throw [NSException exceptionWithName:@"1001" reason:NSLocalizedString(@"server_error", @"server_error") userInfo:nil];
        }
        
        NSArray *infoArray = [jsonData objectForKey:@"results"];
        NSDictionary *releaseInfo = [infoArray objectAtIndex:0];
        NSString *latestVersion = [releaseInfo objectForKey:@"version"];
        
        if ([latestVersion isEqualToString:[SQManager sharedSQManager].sqAppVersion])
        {
            //最新版本无需更新
            result = NO;
        }
        else
        {
            result = YES;
        }
    }
    
    return result;
}

@end
