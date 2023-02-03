//
//  PSData.h
//  PSD.See
//
//  Created by Larry on 16/9/5.
//  Copyright © 2016年 MaiMiao. All rights reserved.
//

#ifndef PSData_h
#define PSData_h

#import <Foundation/Foundation.h>

enum
{
    //颜色模式的定义
    PS_COLOR_MODE_BITMAP = 0
    , PS_COLOR_MODE_GRAYSCALE = 1
    , PS_COLOR_MODE_INDEXED = 2
    , PS_COLOR_MODE_RGB = 3
    , PS_COLOR_MODE_CMYK = 4
    , PS_COLOR_MODE_MULTICHANNEL = 7
    , PS_COLOR_MODE_DUOTONE = 8
    , PS_COLOR_MODE_LAB = 9
};

//ps文件的头信息
@interface PSHeader : NSObject
{
    UInt8 _psReserved[6]; //保留信息, 必须为0; 6位
}

@property (nonatomic, assign)SInt32 psSignature; //文件签名,必须为 '8BPS'=0x38425053  4位
@property (nonatomic, assign)UInt16 psVersion; //版本信息,必须为1或2; 2位
//@property (nonatomic, assign)UInt8 psReserved[6]; //保留信息, 必须为0; 6位
@property (nonatomic, assign)UInt16 psChannelNum; //通道的数量1-56, 2位
@property (nonatomic, assign)SInt32 psHeight; //高度 1-30000, 4位
@property (nonatomic, assign)SInt32 psWidth; //宽度 1-30000, 4位
@property (nonatomic, assign)SInt16 psChannelDepth; //通道的深度, 1,8,16,32; 2位
@property (nonatomic, assign)SInt16 psColorMode; //颜色模式, 2位

+(id)getHeaderFromData:(NSData*)fileData;

+(void)getHeaderFromData:(NSData*)fileData intoHeader:(PSHeader*)header;

/**
 检查ps文件是否合法
 */
-(BOOL)isVaildPsFile;

/**
 获取颜色模式
 */
-(NSString*)getColorMode;

//打印头部信息
-(void)printHeaderInfo;

@end

#endif /* PSData_h */

