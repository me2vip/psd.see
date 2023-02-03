//
//  PSData.m
//  PSD.See
//
//  Created by Larry on 16/9/5.
//  Copyright © 2016年 MaiMiao. All rights reserved.
//

#import "PSData.h"
#import "RFIReader.h"

@implementation PSHeader

- (void)dealloc
{
    [super dealloc];
}

+(void)getHeaderFromData:(NSData*)fileData intoHeader:(PSHeader*)header
{
    RFIReader* reader = [RFIReader readerWithData:fileData];
    //读取头部签名
    header.psSignature = ntohl([reader readInt32]);
    
    //读取版本信息
    header.psVersion = ntohs([reader readInt16]);
    
    //读取Reserved信息
    for (int index = 0; index < 6; index++)
    {
        [header setReservedByte:ntohs([reader readByte]) atIndex:index];
    }
    
    //读取通道信息
    header.psChannelNum = ntohs([reader readInt16]);
    
    //读取高度信息
    header.psHeight = ntohl([reader readInt32]);
    
    //读取宽度信息
    header.psWidth = ntohl([reader readInt32]);
    
    //读取通道的深度
    header.psChannelDepth = ntohs([reader readInt16]);
    
    //读取颜色模式
    header.psColorMode = ntohs([reader readInt16]);
    
    [header printHeaderInfo];

}

+(id)getHeaderFromData:(NSData *)fileData
{
    PSHeader* header = [[[PSHeader alloc] init] autorelease];
    RFIReader* reader = [RFIReader readerWithData:fileData];
    //读取头部签名
    header.psSignature = ntohl([reader readInt32]);
    
    //读取版本信息
    header.psVersion = ntohs([reader readInt16]);
    
    //读取Reserved信息
    for (int index = 0; index < 6; index++)
    {
        [header setReservedByte:ntohs([reader readByte]) atIndex:index];
    }
    
    //读取通道信息
    header.psChannelNum = ntohs([reader readInt16]);
    
    //读取高度信息
    header.psHeight = ntohl([reader readInt32]);
    
    //读取宽度信息
    header.psWidth = ntohl([reader readInt32]);
    
    //读取通道的深度
    header.psChannelDepth = ntohs([reader readInt16]);
    
    //读取颜色模式
    header.psColorMode = ntohs([reader readInt16]);
    
    [header printHeaderInfo];
    
    return header;
}

-(BOOL)isVaildPsFile
{
    BOOL result = TRUE;
    if (0x38425053 != self.psSignature)
    {
        result = FALSE;
    }
    else if(1 != self.psVersion)
    {
        result = FALSE;
    }
    
    for (int index = 0; index < 6; index++)
    {
        if (0 != _psReserved[index])
        {
            result = FALSE;
            break;
        }
    }
    
    return result;
}

-(void)setReservedByte:(UInt8)byte atIndex:(int)index
{
    _psReserved[index] = byte;
}

-(NSString*)getColorMode
{
    NSString* colorMode = @"RGB";
    if (PS_COLOR_MODE_BITMAP == self.psColorMode)
    {
        colorMode = @"Bitmap";
    }
    else if(PS_COLOR_MODE_GRAYSCALE == self.psColorMode)
    {
        colorMode = @"Grayscale";
    }
    else if(PS_COLOR_MODE_INDEXED == self.psColorMode)
    {
        colorMode = @"Indexed";
    }
    else if(PS_COLOR_MODE_RGB == self.psColorMode)
    {
        colorMode = @"RGB";
    }
    else if(PS_COLOR_MODE_CMYK == self.psColorMode)
    {
        colorMode = @"CMYK";
    }
    else if(PS_COLOR_MODE_MULTICHANNEL == self.psColorMode)
    {
        colorMode = @"Multichannel";
    }
    else if(PS_COLOR_MODE_DUOTONE == self.psColorMode)
    {
        colorMode = @"Duotone";
    }
    else if(PS_COLOR_MODE_LAB == self.psColorMode)
    {
        colorMode = @"Lab";
    }
    NSLog(@"%s-%d colorMode:%@", __func__, __LINE__, colorMode);
    
    return colorMode;
}

-(void)printHeaderInfo
{
    NSLog(@"%s-%d psSignature:0x%x, psVersion:%d, psChannelNum:%d, psHeight:%d, psWidth:%d, psChannelDepth:%d, psColorMode:%d", __func__, __LINE__, self.psSignature, self.psVersion, self.psChannelNum, self.psHeight, self.psWidth, self.psChannelDepth, self.psColorMode);
}

@end