//
//  SQManager.h
//  BiMaWen
//
//  Created by aec on 14-1-21.
//  Copyright (c) 2014年 SQ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "../Common/CWLSynthesizeSingleton.h"

@class ASIHTTPRequest;

/*! @brief 全局唯一实例管理对象
 */
@interface SQManager : NSObject

@property (nonatomic, assign)BOOL sqFirstStart; //是否首次启动
@property (nonatomic, readonly)NSString* sqMyIdentity; //设备的唯一标识
@property (nonatomic, readonly)NSString* sqAppVersion; //app版本
@property (nonatomic, readonly)NSString* sqDatabase; //数据库路径
@property (nonatomic, readonly)NSString* sqPsdImagePath; //psd文件图片路径

/*! @brief 初始化操作
 */
-(void)initManager;
 
/*! @brief 生成指定颜色半径的图片
 */
+(UIImage*)imageWithColor:(UIColor *)color andSize:(CGSize)size andRadius:(float)radius;

/** 生成字符串的32位MD5值
 */
+(NSString*)stringMD5:(NSString*)src;

+(void)setExtraCellLineHidden: (UITableView *)tableView;

//删除父视图下的所有子视图
+(void)removeAllSubViews:(UIView*)superView;

/**
 对手机号的有效性进行验证
 */
+(BOOL)validateMobile:(NSString*)mobile;

/**
 对邮箱的有效性进行验证
 */
+(BOOL)validateEmail:(NSString*)email;

/**
从队列中正序获取某个类的对象,取不到返回nil
 */
+(id)getObjectFrom:(NSArray*)array ofClass:(Class)objClass;

/**
 从队列中倒序获取某个对象,取不到返回nil
 */
+(id)getObjectReverseFrom:(NSArray*)array ofClass:(Class)objClass;

+(id)getPreviousObjectFrom:(NSArray*)array theObject:(id)me;

/**
 生成一个uuid
 */
+(NSString*)createUUID;

/**
 从队列中正序获取某个协议的类对象
 */
+(id)getObjectFrom:(NSArray*)array ofProtocol:(Protocol*)objClass;

/**
 从队列中倒序获取某个对象,取不到返回nil
 */
+(id)getObjectReverseFrom:(NSArray*)array ofProtocol:(Protocol*)objClass;

/**
 从队列中正序获取具有某个方法的对象,取不到返回nil
 */
+(id)getObjectFrom:(NSArray*)array responseSel:(SEL)selector;

/**
 从队列中倒序获取具有某个方法的对象,取不到返回nil
 */
+(id)getObjectReverseFrom:(NSArray*)array responseSel:(SEL)selector;

/**
 给某个view添加边框
 */
+(void)addBorderToView:(UIView*)view width:(float)width color:(UIColor*)color cornerRadius:(float)radius;

/**
 获取字符串的32位CRC值
 */
+(NSString*)getStringCRC32:(NSString*)src;

/**
 获取view在tableview中得位置
 */
+(NSInteger)getViewIndex:(UIView*)view inTableView:(UITableView*)tableView;

+(NSIndexPath*)getViewIndexPath:(UIView*)view inTableView:(UITableView*)tableView;

/**
 获取view的tableviewCell
 */
+(UITableViewCell*)tableViewCellWithView:(UIView*)view inTableView:(UITableView*)tableView;

/**
 对string 进行utf-8编码
 */
+(NSString*)stringWithUTF8:(NSString*)string;

/**
 给textInput的键盘添加close方法
 */
+(void)addKeyboardCloseButtonOnTextInput:(id)txtInput closeMethod:(SEL)closeMethod onTarget:(id)target andButtonTitle:(NSString*)title;

/**
 对图片进行缩放
 */
+(UIImage*)imageToSize:(UIImage*)image size:(CGSize)size;

/**
 获取文件大小的字符串格式
 */
+(NSString*)getFileSize:(long long)size;

/**
 在指定的矩形区域里绘制透明背景
 */
+(void)drawTransparentGridWithContext:(CGContextRef)cgContext inRect:(CGRect)rect;

/**
 获取本机的ip地址
 */
+(NSString *)getIPAddress;

/**
 获取wifi的名称
 */
+(NSString*)getCurrentWifiName;

+(UIImage *)createNonInterpolatedUIImageFormCIImage:(CIImage*)image withSize:(CGFloat) size;

/**
 判断当前设备是否为刘海屏
 */
+(BOOL)isIphoneX;

CWL_DECLARE_SINGLETON_FOR_CLASS(SQManager)
@end
