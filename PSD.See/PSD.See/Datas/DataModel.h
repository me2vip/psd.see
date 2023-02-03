//
//  DataModel.h
//  YuanChengUser
//
//  Created by Larry on 16/1/3.
//  Copyright (c) 2016年 YuanCheng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "FMDatabase.h"
#import "PSData.h"

@interface FileItem:NSObject

@property (nonatomic, copy)NSString* psFilePath; //文件路径
@property (nonatomic, assign)long psFileLength; //文件的大小
@property (nonatomic, copy)NSString* psExtInfo; //额外的信息
@property (nonatomic, copy)NSString* psPsdImage; //psd文件的图片地址
@property (nonatomic, assign)long psOpenTime; //上次打开时间
@property (nonatomic, assign)int psIndex; //文件的索引

-(void)removeFromDatabase;

-(void)save;

/**
 根据指定的文件路径创建一个item
 */
+(id)getFileItemByPath:(NSString*)filePath;

+(void)createTableWithDatabase:(FMDatabase *)dabase; //创建数据库表

+(id)getFileList; //获取文件列表

+(void)putFileInList:(NSMutableArray*)fileList; //将文件信息放入指定的列表中

+(NSString*)getRelativePathInDoc:(NSString*)filePath; //获取doc文件的的相对路径

+(NSString*)getRelativePathInCaches:(NSString*)filePath; //获取caches目录的相对路径
@end

/**
 服务器信息
 **/
@interface ServerInfo : NSObject

@property (nonatomic, retain)NSString* psServerIp; //服务器地址
@property (nonatomic, retain)NSString* psPassword; //密码
@property (nonatomic, retain)NSString* psLastTime; //上次连接的时间

-(void)removeFromDatabase;

-(void)save;

+(void)createTableWithDatabase:(FMDatabase *)dabase; //创建数据库表
/**
 获取服务器列表
 */
+(id)getServerList;
+(id)serverWithIp:(NSString*)serverIp andPassword:(NSString*)password;

@end

@interface PSChannel : NSObject

@property (nonatomic, assign) SInt16 psChannelId; //通道id
@property (nonatomic, assign) int psDataLength; //数据长度

+(id)createChannel;

@end

//psd文件的图层信息
@interface PSLayer : NSObject

@property (nonatomic, assign) BOOL psVisible; //是否可见
@property (nonatomic, assign) int psOpacity; //不透明度
@property (nonatomic, copy) NSString* psName; //图层的名称
@property (nonatomic, assign) int psLayerType; //图层的类型;PS_LAYER_NORMAL, PS_LAYER_FOLDER, PS_LAYER_HIDDEN
@property (nonatomic, retain) NSMutableArray* psSubLayers; //子图层, 当psLayerType=PS_LAYER_FOLDER时有效
@property (nonatomic, assign) int psTop;
@property (nonatomic, assign) int psLeft;
@property (nonatomic, assign) int psRight;
@property (nonatomic, assign) int psBottom;
@property (nonatomic, assign) int psWidth;
@property (nonatomic, assign) int psHeight;
@property (nonatomic, retain) NSMutableArray* psChannelList; //通道列表
@property (nonatomic, assign) int psLayerId; //图层的id
@property (nonatomic, assign) id psParentLayer; //父图层

+(id)createLayer;

/**
 从ps文件中读取图层信息
 return: 0读取成功, 其他错误信息
 */
+(int)readLayersInList:(NSMutableArray*)listArray withData:(NSData*)psData withFileCode:(NSString*)fileCode outHeader:(PSHeader*)header;

-(NSString*)getLayerInfo;

@end