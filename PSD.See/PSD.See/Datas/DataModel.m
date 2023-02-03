//
//  DataModel.m
//  YuanChengUser
//
//  Created by Larry on 16/1/3.
//  Copyright (c) 2016年 YuanCheng. All rights reserved.
//

#import "DataModel.h"
#import "psdata.h"
#import "../common/FMDB/FMDatabase.h"
#import "SQManager.h"
#import "SQConstant.h"
#import "RFIReader.h"

#define STB_IMAGE_IMPLEMENTATION
#include "../common/stb_image.h"
#undef STB_IMAGE_IMPLEMENTATION

@implementation FileItem

/**
 获取文件的相对路径
 */
+(NSString*)getRelativePathInDoc:(NSString*)filePath
{
    NSRange range = [filePath rangeOfString:@"/Documents/"];
    if (NSNotFound == range.location)
    {
        return filePath;
    }
    return [filePath substringFromIndex:(range.location + range.length)];
}

/**
 
 */
+(NSString*)getRelativePathInCaches:(NSString*)filePath
{
    NSRange range = [filePath rangeOfString:@"/Caches/"];
    if (NSNotFound == range.location)
    {
        return filePath;
    }
    return [filePath substringFromIndex:(range.location + range.length)];
}

-(void)dealloc
{
    [_psExtInfo release];
    [_psFilePath release];
    [_psPsdImage release];
    
    [super dealloc];
}

-(void)removeFromDatabase
{
    FMDatabase* database = [FMDatabase databaseWithPath:[SQManager sharedSQManager].sqDatabase];
    if([database open])
    {
        NSString* relativePath = [FileItem getRelativePathInDoc:self.psFilePath];
        [database executeUpdate:@"DELETE FROM file_info WHERE file_path=?" withArgumentsInArray:@[relativePath]];
    }
    [database close];
}

-(void)save
{
    FMDatabase* database = [FMDatabase databaseWithPath:[SQManager sharedSQManager].sqDatabase];
    if([database open])
    {
        NSString* relativePath = [FileItem getRelativePathInDoc:self.psFilePath];
        NSString* imageRelative = [FileItem getRelativePathInCaches:self.psPsdImage];
        
        FMResultSet* result = [database executeQuery:@"SELECT * FROM file_info WHERE file_path=?" withArgumentsInArray: @[relativePath]];
        BOOL itemHasIn = [result next];
        [result close];
        
        self.psOpenTime = [[NSDate date] timeIntervalSince1970];
        
        if(itemHasIn)
        {
            //记录已存在，更新记录
            [database executeUpdate:@"UPDATE file_info SET file_length=?, ext_info=?, psd_image=?, open_time=? WHERE file_path=?" withArgumentsInArray:@[@(self.psFileLength), self.psExtInfo, imageRelative, @(self.psOpenTime), relativePath]];
        }
        else
        {
            //记录不存在，插入记录
            [database executeUpdate:@"INSERT INTO file_info(file_length, ext_info, psd_image, open_time, file_path) VALUES(?,?,?,?,?)" withArgumentsInArray:@[@(self.psFileLength), self.psExtInfo, imageRelative, @(self.psOpenTime), relativePath]];
            
            result = [database executeQuery:@"SELECT item_id FROM file_info WHERE file_path=?" withArgumentsInArray:@[relativePath]];
            if ([result next]) {
                self.psIndex = [result intForColumn:@"item_id"];
            }
            [result close];
        }
    }
    [database close];
}

/**
 根据指定的文件路径创建一个item
 */
+(id)getFileItemByPath:(NSString*)filePath
{
    FMDatabase* database = [FMDatabase databaseWithPath:[SQManager sharedSQManager].sqDatabase];
    FileItem* fileItem = nil;
    NSString* relativePath = [self getRelativePathInDoc:filePath];
    
    if ([database open])
    {
        FMResultSet* result = [database executeQuery:@"SELECT * FROM file_info WHERE file_path=?" withArgumentsInArray:@[relativePath]];
        if ([result next])
        {
            fileItem = [[[FileItem alloc] init] autorelease];
            
            fileItem.psIndex = [result intForColumn:@"item_id"];
            fileItem.psExtInfo = [result stringForColumn:@"ext_info"];
            fileItem.psFilePath = filePath;
            fileItem.psOpenTime = [result longForColumn:@"open_time"];
            fileItem.psPsdImage = [result stringForColumn:@"psd_image"];
            fileItem.psFileLength = [result longForColumn:@"file_length"];
            
            if (fileItem.psPsdImage.length > 0)
            {
                fileItem.psPsdImage = [[SQManager sharedSQManager].sqPsdImagePath stringByAppendingPathComponent:fileItem.psPsdImage];
            }
        }
        [result close];
        
        if (nil == fileItem)
        {
            //文件信息不存在，创建信息
            fileItem = [self createByPath:filePath];
            if (fileItem)
            {
                [database executeUpdate:@"INSERT INTO file_info(file_length, ext_info, psd_image, open_time, file_path) VALUES(?,?,?,?,?)" withArgumentsInArray:@[@(fileItem.psFileLength), fileItem.psExtInfo, [self getRelativePathInCaches:fileItem.psPsdImage], @(fileItem.psOpenTime), relativePath]];
                
                result = [database executeQuery:@"SELECT item_id FROM file_info WHERE file_path=?" withArgumentsInArray:@[relativePath]];
                if ([result next]) {
                    fileItem.psIndex = [result intForColumn:@"item_id"];
                }
                [result close];
            }

        }
    }
    [database close];
    
    return fileItem;
}

+(void)createTableWithDatabase:(FMDatabase *)dabase //创建数据库表
{
    [dabase executeUpdate:@"CREATE TABLE IF NOT EXISTS file_info(item_id INTEGER PRIMARY KEY AUTOINCREMENT, file_path VARCHAR(1024) NOT NULL, file_length INTEGER, ext_info VARCHAR(512) NOT NULL, psd_image VARCHAR(1024), open_time INTEGER)"];
}

+(id)getFileList //获取文件列表
{
    FMDatabase* database = [FMDatabase databaseWithPath:[SQManager sharedSQManager].sqDatabase];
    NSMutableArray* array = [NSMutableArray array];
    FileItem* fileItem = nil;
    NSString* docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    if ([database open])
    {
        FMResultSet* result = [database executeQuery:@"SELECT * FROM file_info ORDER BY open_time DESC"];
        while ([result next])
        {
            fileItem = [[[FileItem alloc] init] autorelease];
            [array addObject:fileItem];
            
            fileItem.psIndex = [result intForColumn:@"item_id"];
            fileItem.psExtInfo = [result stringForColumn:@"ext_info"];
            fileItem.psFilePath = [docPath stringByAppendingPathComponent:[result stringForColumn:@"file_path"]];
            fileItem.psOpenTime = [result longForColumn:@"open_time"];
            fileItem.psPsdImage = [result stringForColumn:@"psd_image"];
            fileItem.psFileLength = [result longForColumn:@"file_length"];
            
            if (fileItem.psPsdImage.length > 0)
            {
                fileItem.psPsdImage = [[SQManager sharedSQManager].sqPsdImagePath stringByAppendingPathComponent:fileItem.psPsdImage];
            }
        }
        
        [result close];
    }
    [database close];
    
    return array;
}

+(void)removeFromDatabaseByPath:(NSString*)filePath withDatabase:(FMDatabase*)db
{
    NSString* relativePath = [FileItem getRelativePathInDoc:filePath];
    [db executeUpdate:@"DELETE FROM file_info WHERE file_path=?" withArgumentsInArray:@[relativePath]];
}


+(void)putFileInList:(NSMutableArray*)fileList
{
    FMDatabase* database = [FMDatabase databaseWithPath:[SQManager sharedSQManager].sqDatabase];
    FileItem* fileItem = nil;
    NSString* docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSString* filePath = @"";
    NSString* psdImagePath = nil;
    
    if ([database open])
    {
        FMResultSet* result = [database executeQuery:@"SELECT * FROM file_info ORDER BY open_time DESC"];
        while ([result next])
        {
            filePath = [docPath stringByAppendingPathComponent:[result stringForColumn:@"file_path"]];
            psdImagePath = [result stringForColumn:@"psd_image"];
            if (psdImagePath.length > 0)
            {
                psdImagePath = [[SQManager sharedSQManager].sqPsdImagePath stringByAppendingPathComponent:psdImagePath];
            }
            
            if (NO == [fileManager fileExistsAtPath:filePath])
            {
                //文件不存在从数据库中删除
                [self removeFromDatabaseByPath:filePath withDatabase:database];
                continue;
            }
            
            if (psdImagePath.length > 0 && NO == [fileManager fileExistsAtPath:psdImagePath])
            {
                [self removeFromDatabaseByPath:filePath withDatabase:database];
                continue;
            }
            
            fileItem = [[[FileItem alloc] init] autorelease];
            [fileList addObject:fileItem];
            
            fileItem.psIndex = [result intForColumn:@"item_id"];
            fileItem.psExtInfo = [result stringForColumn:@"ext_info"];
            fileItem.psFilePath = filePath;
            fileItem.psOpenTime = [result longForColumn:@"open_time"];
            fileItem.psPsdImage = psdImagePath;
            fileItem.psFileLength = [result longForColumn:@"file_length"];
        }
        [result close];
    }
    [database close];
}


+(id)createByPath:(NSString*)filePath
{
    NSLog(@"%s-%d filePath:%@", __func__, __LINE__, filePath);
    
    NSError* error = nil;
    NSData* fileData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:&error];
    if (nil == fileData)
    {
        NSLog(@"%s-%d filePath:%@ error:%@", __func__, __LINE__, filePath, error);
        return nil;
    }
    
    int imageWidth = 0;
    int imageHeight = 0;
    UIImage* image = [UIImage imageWithData:fileData];
    
    imageWidth = image.size.width;
    imageHeight = image.size.height;
    
    PSHeader* psHeader = [PSHeader getHeaderFromData:fileData];
    
    if(image)
    {
        FileItem* file = [[[FileItem alloc] init] autorelease];
        if(FALSE == [psHeader isVaildPsFile])
        {
            //图片文件
            file.psExtInfo = [NSString stringWithFormat:@"%d*%d", imageWidth, imageHeight];
        }
        else
        {
            //psd文件
            file.psExtInfo = [NSString stringWithFormat:@"%@ %d*%d", [psHeader getColorMode], imageWidth, imageHeight];
        }
        
        file.psFilePath = filePath;
        file.psFileLength = fileData.length;
        file.psPsdImage = @"";
        
        NSLog(@"%s-%d image file", __func__, __LINE__);
        
        return file;
    }
    
    if(FALSE == [psHeader isVaildPsFile])
    {
        NSLog(@"%s-%d psd file invalid", __func__, __LINE__);
        return nil;
    }
    
    int w = 0, h = 0, comp = 0;
    unsigned char* pixBuff = stbi_load_from_memory(fileData.bytes, (int)(fileData.length), &w, &h, &comp, STBI_rgb_alpha);
    if (nil == pixBuff || 0 == w || 0 == h)
    {
        NSLog(@"%s-%d pixbuff null", __func__, __LINE__);
        
        return nil;
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, pixBuff, w*h*comp, NULL);
    
    // prep the ingredients
    const int BITS_PER_COMPONENT = 8;
    const int BITS_PER_PIXEL = 32;
    const int BITS_PER_ROW = 4 * w;
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    
    // make the cgimage
    CGImageRef imageRef = CGImageCreate(w, h, BITS_PER_COMPONENT, BITS_PER_PIXEL, BITS_PER_ROW
                                        , colorSpaceRef, bitmapInfo, provider, NULL, YES, renderingIntent);
    
    float scale = 1.0f;
    /**
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)])
    {
        scale = [[UIScreen mainScreen] scale];
    }
    **/
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(w/scale, h/scale), NO, scale);
    CGContextRef cgcontext = UIGraphicsGetCurrentContext();
    
    CGContextSetBlendMode(cgcontext, kCGBlendModeCopy);
    
    // Image needs to be flipped BACK for CG
    CGContextTranslateCTM(cgcontext, 0, h/scale);
    CGContextScaleCTM(cgcontext, 1, -1);
    CGContextDrawImage(cgcontext, CGRectMake(0.0, 0.0, w/scale, h/scale), imageRef);
    
    image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    // then make the uiimage from that
    //image = [UIImage imageWithCGImage:imageRef];
    
    //UIImageWriteToSavedPhotosAlbum(myImage, nil, nil, nil);
    
    //释放缓冲
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpaceRef);
    CGImageRelease(imageRef);
    stbi_image_free(pixBuff);
    
    if(nil == image)
    {
        NSLog(@"%s-%d image nil", __func__, __LINE__);
        return nil;
    }
    
    NSString* relativePath = [FileItem getRelativePathInDoc:filePath];
    NSString* saveImagePath = [SQManager sharedSQManager].sqPsdImagePath;
    NSString* psdImagePath = [saveImagePath stringByAppendingPathComponent:[SQManager getStringCRC32:relativePath]];
    NSData* psdImageData = UIImagePNGRepresentation(image);
    [psdImageData writeToFile:psdImagePath atomically:YES];
    
    NSLog(@"%s-%d mode:%@, w:%f, h:%f, psdImageData.len:%ld, psdImagePath:%@", __func__, __LINE__, [psHeader getColorMode], image.size.width, image.size.height, psdImageData.length, psdImagePath);
    
    FileItem* file = [[[FileItem alloc] init] autorelease];
    file.psExtInfo = [NSString stringWithFormat:@"%@ %d*%d", [psHeader getColorMode], (int)(image.size.width), (int)(image.size.height)];
    file.psFilePath = filePath;
    file.psFileLength = fileData.length;
    file.psOpenTime = [[NSDate date] timeIntervalSince1970];
    file.psPsdImage = psdImagePath;
    
    return file;

}

@end

@implementation ServerInfo

+(void)createTableWithDatabase:(FMDatabase *)database
{
    [database executeUpdate:@"CREATE TABLE IF NOT EXISTS server_info(server_ip VARCHAR(200) NOT NULL, password VARCHAR(200) NOT NULL, update_time VARCHAR(100))"];
}

+(id)getServerList
{
    FMDatabase* database = [FMDatabase databaseWithPath:[SQManager sharedSQManager].sqDatabase];
    NSMutableArray* array = [NSMutableArray array];
    ServerInfo* serverInfo = nil;
    
    if ([database open])
    {
        FMResultSet* result = [database executeQuery:@"SELECT * FROM server_info"];
        while ([result next])
        {
            serverInfo = [[[ServerInfo alloc] init] autorelease];
            [array addObject:serverInfo];
            
            serverInfo.psPassword = [result stringForColumn:@"password"];
            serverInfo.psLastTime = [result stringForColumn:@"update_time"];
            serverInfo.psServerIp = [result stringForColumn:@"server_ip"];
        }
        
        [result close];
    }
    [database close];
    
    return array;
}

+(id)serverWithIp:(NSString*)serverIp andPassword:(NSString*)password
{
    NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
    NSTimeZone *timeZone = [NSTimeZone localTimeZone];
    ServerInfo* servreInfo = [[[ServerInfo alloc] init] autorelease];
    [formatter setTimeZone:timeZone];
    [formatter setDateFormat : @"yyyy-MM-dd HH:mm:ss"];
    servreInfo.psServerIp = serverIp;
    servreInfo.psPassword = password;
    servreInfo.psLastTime = [formatter stringForObjectValue:[NSDate date]];
    
    return servreInfo;
}

-(void)save
{
    FMDatabase* database = [FMDatabase databaseWithPath:[SQManager sharedSQManager].sqDatabase];
    if([database open])
    {
        FMResultSet* result = [database executeQuery:@"SELECT * FROM server_info WHERE server_ip=? AND password=?" withArgumentsInArray: @[self.psServerIp, self.psPassword]];
        BOOL serverHasIn = [result next];
        [result close];
        
        NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
        NSTimeZone *timeZone = [NSTimeZone localTimeZone];
        [formatter setTimeZone:timeZone];
        [formatter setDateFormat : @"yyyy-MM-dd HH:mm:ss"];
        self.psLastTime = [formatter stringForObjectValue:[NSDate date]];
        
        if(serverHasIn)
        {
            //记录已存在，更新记录
            [database executeUpdate:@"UPDATE server_info SET update_time=? WHERE server_ip=? AND password=?" withArgumentsInArray:@[self.psLastTime, self.psServerIp, self.psPassword]];
        }
        else
        {
            //记录不存在，插入记录
            [database executeUpdate:@"INSERT INTO server_info(server_ip, password, update_time) VALUES(?,?,?)" withArgumentsInArray:@[self.psServerIp, self.psPassword, self.psLastTime]];
        }
    }
    [database close];
}

-(void)removeFromDatabase
{
    FMDatabase* database = [FMDatabase databaseWithPath:[SQManager sharedSQManager].sqDatabase];
    if([database open])
    {
        [database executeUpdate:@"DELETE FROM server_info WHERE server_ip=? AND password=?" withArgumentsInArray:@[self.psServerIp, self.psPassword]];
    }
    [database close];
}

- (void)dealloc
{
    [_psLastTime release];
    [_psPassword release];
    [_psServerIp release];
    
    [super dealloc];
}

@end

@implementation PSChannel

+(id)createChannel
{
    return [[[PSChannel alloc] init] autorelease];
}

- (void)dealloc
{
    
    [super dealloc];
}

@end

@implementation PSLayer

- (void)dealloc
{
    [_psName release];
    [_psSubLayers release];
    [_psChannelList release];
    
    [super dealloc];
}

-(int)getFromReader:(RFIReader*)reader
{
    self.psTop = ntohl([reader readInt32]);
    self.psLeft = ntohl([reader readInt32]);
    self.psBottom = ntohl([reader readInt32]);
    self.psRight = ntohl([reader readInt32]);
    
    self.psWidth = self.psRight - self.psLeft;
    self.psHeight = self.psBottom - self.psTop;
    
    int16_t numberOfChannels = ntohs([reader readInt16]); //通道的数量
    self.psChannelList = [NSMutableArray array];
    
    for (int i = 0; i < numberOfChannels; i++) {
        PSChannel* channel = [PSChannel createChannel];
        channel.psChannelId = ntohs([reader readInt16]); //通道的id
        channel.psDataLength = ntohl([reader readInt32]); //通道的数据长度
        [self.psChannelList addObject:channel];
    }
    int blendSign = ntohl([reader readInt32]); //混合模式的签名, 8BIM
    if (0x3842494d != blendSign) {
        return PS_ERR_INVALIDE;
    }
    [reader skipBytes:4]; //不处理混合模式信息
    self.psOpacity = [reader readByte]; //不透明度
    [reader skipBytes:1]; //跳过裁剪信息
    int flags = [reader readByte];
    self.psVisible = ((flags >> 1) & 0x01) == 0;
    [reader skipBytes:1]; //跳过填充信息
    
    //读取额外的数据信息
    int extraSize = ntohl([reader readInt32]); //额外数据长度
    int extraPos = [reader getPosition];
    
    // LAYER MASK / ADJUSTMENT LAYER DATA
    // Size of the data: 36, 20, or 0. If zero, the following fields are not
    // present
    int size = ntohl([reader readInt32]);
    [reader skipBytes:size];
    
    // LAYER BLENDING RANGES DATA
    // Length of layer blending ranges data
    size = ntohl([reader readInt32]);
    [reader skipBytes:size];
    
    // Layer name: Pascal string, padded to a multiple of 4 bytes.
    size = [reader readByte] & 0xFF;
    size = ((size + 1 + 3) & ~0x03) - 1;
    
    NSData* nameBytes = [reader readBytes:size];
    int strSize = size;
    const char* nameBuffer = (char*)[nameBytes bytes];
    
    for (int i = 0; i < size; i++) {
        if (nameBuffer[i] == 0) {
            strSize = i;
            break;
        }
    }
    self.psName = [[[NSString alloc] initWithBytes:nameBuffer length:strSize encoding:NSISOLatin1StringEncoding] autorelease];
    int prevPos = [reader getPosition];
    int tag = 0;
    while ([reader getPosition] - extraPos < extraSize) {
        tag = ntohl([reader readInt32]); //混合模式的签名, 8BIM
        if (0x3842494d != blendSign) {
            return PS_ERR_INVALIDE;
        }
        tag = ntohl([reader readInt32]);
        
        size = ntohl([reader readInt32]);
        size = (size + 1) & ~0x01;
        prevPos = [reader getPosition];
        if (0x6c796964 == tag) { //lyid 图层id
            self.psLayerId = ntohl([reader readInt32]);
        } /* else if (tag.equals("shmd")) {
            metaInfo = new PsdLayerMetaInfo(stream);
        }*/ else if (0x6c736374 == tag) { //lsct
            int dividerType = ntohl([reader readInt32]); //图层的类型
            if (1 == dividerType || 2 == dividerType) {
                self.psLayerType = PS_LAYER_FOLDER; //分组图层
            }
            else if (3 == dividerType) {
                self.psLayerType = PS_LAYER_HIDDEN; //隐藏的图层不能显示,主要分隔分组
            }
            else
            {
                self.psLayerType = PS_LAYER_NORMAL; //普通图层
            }
        } /* else if (tag.equals("TySh")) {
            typeTool = new PsdTextLayerTypeTool(stream, size);
        } */ else if (0x6c756e69 == tag) { //luni
            int len = ntohl([reader readInt32]);
            nameBytes = [reader readBytes:len*2]; //unicode字符串一个字符占2个字节
            self.psName = [[[NSString alloc] initWithData:nameBytes encoding:NSUnicodeStringEncoding] autorelease];
        } else {
            //logger.warning("skipping tag:"  + tag);
            [reader skipBytes:size];
        }
        
        [reader skipBytes:prevPos + size - [reader getPosition]];
    }
    [reader skipBytes:extraSize - ([reader getPosition] - extraPos)];
    
    return PS_ERR_NO_ERROR;
}

/**
 读取图层的图片信息
 */
-(int)readImageFromReader:(RFIReader*)reader withFileCode:(NSString*)fileCode
{
    NSData* imgData = nil;
    char* buffer = NULL;
    char* channelImg = NULL;
    if (self.psWidth * self.psHeight > 0) {
        imgData = [NSMutableData dataWithLength:self.psWidth * self.psHeight * 4]; //4=RGBA
        buffer = (char*)(imgData.bytes);
        //默认alpha为不透明
        channelImg = buffer + 3;
        for (int i = 0; i< self.psWidth * self.psHeight; i++) {
            *channelImg = 255;
            channelImg += 4;
        }
    }
    for (PSChannel* channel in self.psChannelList) {
        if (channel.psChannelId < -1 || channel.psChannelId > 2) {
            [reader skipBytes:channel.psDataLength]; // layer mask 不处理
            continue;
        }
        int16_t encoding = ntohs([reader readInt16]);
        if (encoding != 0 && encoding != 1) {
            return PS_ERR_COMPRESSION; //压缩模式错误
        }
        if (1 == encoding) {
            //RLE 压缩模式
            [reader skipBytes:2 * self.psHeight]; //不处理行长信息,每个行长2个字节
        }
        if (NULL == buffer) {
            //没有channel 数据
        }
        else if (0 == channel.psChannelId) {
            //red channel
            channelImg = buffer;
            [self readImageFromReader:reader intoBuff:channelImg isEncoding:encoding withChannelId:channel.psChannelId];
        }
        else if (1 == channel.psChannelId) {
            //green channel
            channelImg = buffer + 1;
            [self readImageFromReader:reader intoBuff:channelImg isEncoding:encoding withChannelId:channel.psChannelId];
        }
        else if (2 == channel.psChannelId) {
            //blue channel
            channelImg = buffer + 2;
            [self readImageFromReader:reader intoBuff:channelImg isEncoding:encoding withChannelId:channel.psChannelId];
        }
        else if (-1 == channel.psChannelId) {
            //alpha channel
            channelImg = buffer + 3;
            [self readImageFromReader:reader intoBuff:channelImg isEncoding:encoding withChannelId:channel.psChannelId];
        }
        else {}
    }
    
    //生成图片
    if (buffer) {
        [self saveImage:buffer withFileCode:fileCode];
    }
    return PS_ERR_NO_ERROR;
}

-(void)saveImage:(char*)imgBuff withFileCode:(NSString*)fileCode
{
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, imgBuff, self.psWidth * self.psHeight * 4, NULL);
    
    // prep the ingredients
    const int BITS_PER_COMPONENT = 8;
    const int BITS_PER_PIXEL = 32;
    const int BITS_PER_ROW = 4 * self.psWidth;
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    
    // make the cgimage
    CGImageRef imageRef = CGImageCreate(self.psWidth, self.psHeight, BITS_PER_COMPONENT, BITS_PER_PIXEL, BITS_PER_ROW
                                        , colorSpaceRef, bitmapInfo, provider, NULL, YES, renderingIntent);
    
    float scale = 1.0f;
    /**
     if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)])
     {
     scale = [[UIScreen mainScreen] scale];
     }
     **/
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(self.psWidth/scale, self.psHeight/scale), NO, scale);
    CGContextRef cgcontext = UIGraphicsGetCurrentContext();
    
    CGContextSetBlendMode(cgcontext, kCGBlendModeCopy);
    
    // Image needs to be flipped BACK for CG
    CGContextTranslateCTM(cgcontext, 0, self.psHeight/scale);
    CGContextScaleCTM(cgcontext, 1, -1);
    CGContextDrawImage(cgcontext, CGRectMake(0.0, 0.0, self.psWidth/scale, self.psHeight/scale), imageRef);
    
    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    // 写入文件
    NSString* saveImagePath = [SQManager sharedSQManager].sqPsdImagePath;
    NSString* layerFileName = [NSString stringWithFormat:@"%@_%d", fileCode, self.psLayerId];
    NSString* layerImagePath = [saveImagePath stringByAppendingPathComponent:layerFileName];
    NSData* layerImageData = UIImagePNGRepresentation(image);
    [layerImageData writeToFile:layerImagePath atomically:YES];
    NSLog(@"%s - %d layerId:%d, layerName:%@, layerImagePath:%@", __func__, __LINE__, self.psLayerId, self.psName, layerImagePath);
    
    //UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil); //先写入相册测试
    
    //释放缓冲
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpaceRef);
    CGImageRelease(imageRef);
    
}

-(int)readImageFromReader:(RFIReader*)reader intoBuff:(char*)buffer isEncoding:(int)encoding withChannelId:(int)channelId
{
    const int PIXEL_COUNT = self.psWidth * self.psHeight;
    int index = 0;
    int rleLen = 0;
    char val = 0;
    float opacity = 0;
    
    if (0 == encoding) {
        //没有压缩,原始数据
        for (index = 0; index < PIXEL_COUNT; index++, buffer += 4) {
            *buffer = [reader readByte];
            if (-1 != self.psOpacity && -1 == channelId) { //alpha 通道需要再次处理
                opacity = (self.psOpacity & 0xff)/256.f;
                *buffer = (char)((*buffer & 0xff)*opacity);
            }
        }
    }
    else
    {
        //RLE压缩模式
        while (index < PIXEL_COUNT) {
            rleLen = [reader readByte];
            if (rleLen < 0) {
                // Next -len+1 bytes in the dest are replicated from next source byte.
                // (Interpret len as a negative 8-bit int.)
                rleLen = 1 - rleLen;
                index += rleLen;
                val = [reader readByte];
                while (rleLen) {
                    *buffer = val;
                    if (-1 != self.psOpacity && -1 == channelId) {
                        opacity = (self.psOpacity & 0xff)/256.f;
                        *buffer = (char)((*buffer & 0xff)*opacity);
                    }
                    buffer += 4;
                    rleLen--;
                }

            } else {
                // Copy next len+1 bytes literally.
                rleLen++;
                index += rleLen;
                while (rleLen) {
                    *buffer = [reader readByte];
                    if (-1 != self.psOpacity && -1 == channelId) {
                        opacity = (self.psOpacity & 0xff)/256.f;
                        *buffer = (char)((*buffer & 0xff)*opacity);
                    }
                    buffer += 4;
                    rleLen--;
                }
            }
            
        }
    }
    return PS_ERR_NO_ERROR;
}

-(NSString*)getLayerInfo
{
    return [NSString stringWithFormat:@"layer:%@, top:%d, right:%d, bottom:%d, left:%d, width:%d, height:%d, visible:%d, opacity:0x%x, layertype:%d, layerId:%d, channelnum:%ld", self.psName, self.psTop, self.psRight, self.psBottom, self.psLeft, self.psWidth, self.psHeight, self.psVisible, self.psOpacity, self.psLayerType, self.psLayerId, self.psChannelList.count];
}

/**
 是否需要生成图片
 */
-(BOOL)needBuildImageWithCode:(NSString*)fileCode
{
    if (self.psWidth * self.psHeight <= 0) {
        return NO;
    }
    
    //检查图层的图片是否存在
    NSString* saveImagePath = [SQManager sharedSQManager].sqPsdImagePath;
    NSString* layerFileName = [NSString stringWithFormat:@"%@_%d", fileCode, self.psLayerId];
    NSString* layerImagePath = [saveImagePath stringByAppendingPathComponent:layerFileName];
    NSFileManager* fileManager = [NSFileManager defaultManager];
    
    if ([fileManager fileExistsAtPath:layerImagePath]) {
        return NO; //文件已存在，无需重复生成
    }
    
    NSLog(@"%s-%d filePath:%@", __func__, __LINE__, layerImagePath);
    return YES;
}

+(id)createLayer
{
    return [[[PSLayer alloc] init] autorelease];
}

/**
 设置图层的分组
 */
+ (void)setLayersGroupsInList:(NSMutableArray *)listArray withTempLayers:(NSArray*)tempLayerList
{
    PSLayer* parentLayer = nil;
    for (int index = (int)(tempLayerList.count -1); index >= 0; index--) {
        PSLayer* layer = [tempLayerList objectAtIndex:index];
        if (PS_LAYER_NORMAL == layer.psLayerType) {
            layer.psParentLayer = parentLayer;
            if (parentLayer) {
                if (nil == parentLayer.psSubLayers) {
                    parentLayer.psSubLayers = [NSMutableArray array];
                }
                [parentLayer.psSubLayers addObject:layer];
            } else {
                [listArray addObject:layer];
            }
        } else if (PS_LAYER_FOLDER == layer.psLayerType) {
            layer.psParentLayer = parentLayer;
            if (parentLayer) {
                if (nil == parentLayer.psSubLayers) {
                    parentLayer.psSubLayers = [NSMutableArray array];
                }
                [parentLayer.psSubLayers addObject:layer];
            } else {
                [listArray addObject:layer];
            }

            parentLayer = layer;
        } else if (PS_LAYER_HIDDEN == layer.psLayerType) {
            if (parentLayer) {
                parentLayer = parentLayer.psParentLayer;
            }
        }
    }
}

+(int)readLayersInList:(NSMutableArray *)listArray withData:(NSData *)psData withFileCode:(NSString*)fileCode outHeader:(PSHeader*)header
{
    BOOL needReadImage = NO; //是否需要读取图片
    [PSHeader getHeaderFromData:psData intoHeader:header];
    if (FALSE == [header isVaildPsFile])
    {
        return PS_ERR_INVALIDE; //文件格式无效
    }
    if (PS_COLOR_MODE_RGB != header.psColorMode)
    {
        return PS_ERR_NOT_RGB; //只能处理RGB模式
    }
    if (8 != header.psChannelDepth) {
        return PS_ERR_DEPTH_NOT_8; //只能处理深度为8位的文档
    }
    
    NSMutableArray* tempLayers = [NSMutableArray array];
    RFIReader* reader = [RFIReader readerWithData:psData];
    //跳过头部信息,头部信息已经解析完成
    [reader skipBytes:26]; //头部长度26个byte
    
    int colorMapLength = ntohl([reader readInt32]); //color mode data 段长度
    [reader skipBytes:colorMapLength]; //跳过color mode data
    
    //跳过image resource section
    int imageResourceSectionLength = ntohl([reader readInt32]);
    if (imageResourceSectionLength > 0)
    {
        [reader skipBytes:imageResourceSectionLength];
    }
    
    int layerSectionLength = ntohl([reader readInt32]); //layer section 的长度
    if (layerSectionLength > 0)
    {
        int layerInfoSize = ntohl([reader readInt32]); //layer info 段的长度
        if ((layerInfoSize & 0x01) != 0) {
            layerInfoSize++;
        }
        if (layerInfoSize > 0) {
            int16_t layersCount = ntohs([reader readInt16]); //图层的数量
            if (layersCount < 0) {
                layersCount = -layersCount;
            }
            
            for (int i = 0; i < layersCount; i++) {
                PSLayer* layer = [PSLayer createLayer];
                int error = [layer getFromReader:reader];
                NSLog(@"%s-%d error = %d, layer:%@", __func__, __LINE__, error, [layer getLayerInfo]);
                if (PS_ERR_NO_ERROR == error) {
                    [tempLayers addObject:layer];
                    if (NO == needReadImage) {
                        needReadImage = [layer needBuildImageWithCode:fileCode];
                    }
                }
            }
            
            //读取layer的图片
            if (needReadImage) {
                for (PSLayer* layer in tempLayers) {
                    @autoreleasepool {
                    [layer readImageFromReader:reader withFileCode:fileCode];
                    }
                }
            }
            
            //设置图层分组
            [self setLayersGroupsInList:listArray withTempLayers:tempLayers];
        }
    }
    
    return PS_ERR_NO_ERROR;
}

@end