//
//  SQManager.m
//  BiMaWen
//
//  Created by aec on 14-1-21.
//  Copyright (c) 2014年 sq. All rights reserved.
//

#import "SQManager.h"
#import "SQConstant.h"
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>
#import "../Common/UIView+SQAutoLayoutView.h"
#import "DataModel.h"
#import "FMDatabase.h"
#import <zlib.h>
#import <ifaddrs.h>
#import <arpa/inet.h>
#import <SystemConfiguration/CaptiveNetwork.h>

static void addRoundedRectToPath(CGContextRef context, CGRect rect, float ovalWidth,
                                 float ovalHeight)
{
    float fw, fh;
    
    if (0 == ovalWidth || 0 == ovalHeight)
    {
        CGContextAddRect(context, rect);
        return;
    }
    
    CGContextSaveGState(context);
    CGContextTranslateCTM(context, CGRectGetMinX(rect), CGRectGetMinY(rect));
    CGContextScaleCTM(context, ovalWidth, ovalHeight);
    fw = CGRectGetWidth(rect) / ovalWidth;
    fh = CGRectGetHeight(rect) / ovalHeight;
    
    CGContextMoveToPoint(context, fw, fh/2);  // Start at lower right corner
    CGContextAddArcToPoint(context, fw, fh, fw/2, fh, 1);  // Top right corner
    CGContextAddArcToPoint(context, 0, fh, 0, fh/2, 1); // Top left corner
    CGContextAddArcToPoint(context, 0, 0, fw/2, 0, 1); // Lower left corner
    CGContextAddArcToPoint(context, fw, 0, fw, fh/2, 1); // Back to lower right
    
    CGContextClosePath(context);
    CGContextRestoreGState(context);
}

@interface SQManager ()
{
}

@end

@implementation SQManager
CWL_SYNTHESIZE_SINGLETON_FOR_CLASS(SQManager)

-(void)initManager
{
    //获取app版本
    _sqAppVersion = [[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"] retain];
#if 0
    _cbxButtonImgDisableCorner = [[[SQManager imageWithColor:SQ_COLOR_GRAY andSize:CGSizeMake(11, 11) andRadius:3] resizableImageWithCapInsets:UIEdgeInsetsMake(5, 5, 5, 5)] retain];
    _cbxButtonImgRedCorner = [[[SQManager imageWithColor:SQ_FONT_RED andSize:CGSizeMake(11, 11) andRadius:3] resizableImageWithCapInsets:UIEdgeInsetsMake(5, 5, 5, 5)] retain];
    _cbxButtonImgRedPressCorner = [[[SQManager imageWithColor:SQ_RED_2 andSize:CGSizeMake(11, 11) andRadius:3] resizableImageWithCapInsets:UIEdgeInsetsMake(5, 5, 5, 5)] retain];
#endif
    
    NSArray *library = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString* dbPath = [library objectAtIndex:0];
    _sqDatabase = [[dbPath stringByAppendingPathComponent:@"psd_see.db"] retain];
    
    NSString* cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    _sqPsdImagePath = [cachePath retain];
    
    NSLog(@"%s-%d dbpath:%@, _sqPsdImagePath:%@", __func__, __LINE__, _sqDatabase, _sqPsdImagePath);
    
    //创建设备的唯一标识
    NSUserDefaults* uuidData = [NSUserDefaults standardUserDefaults];
    _sqMyIdentity = [uuidData objectForKey:SQ_MY_UUID];
    if (nil == _sqMyIdentity)
    {
        _sqMyIdentity = [SQManager createUUID];
        [uuidData setObject:_sqMyIdentity forKey:SQ_MY_UUID];
    }
    [_sqMyIdentity retain];
    
    NSNumber* lastCommentTime = [uuidData objectForKey:SQ_LAST_COMMENT_TIME];
    if (nil == lastCommentTime)
    {
        //还没有设置评论时间,将当期时间 + 最小评论时间间隔 设为评论时间
        [uuidData setObject:@(time(NULL) + SQ_MIN_COMMENT_TIME) forKey:SQ_LAST_COMMENT_TIME];
    }
    
    NSLog(@"%s-%d my id:%@ version:%@ cmt:%ld", __func__, __LINE__, _sqMyIdentity, _sqAppVersion, (time(NULL) + SQ_MIN_COMMENT_TIME));
    
    [self createTables];
}

/**
 创建表
 */
-(void)createTables
{
    FMDatabase* database = [FMDatabase databaseWithPath:self.sqDatabase];
    if ([database open])
    {
        [ServerInfo createTableWithDatabase:database];
        [FileItem createTableWithDatabase:database];
    }
    
    [database close];
}

+(NSString*)createUUID
{
    CFUUIDRef puuid = CFUUIDCreate( nil );
    CFStringRef uuidString = CFUUIDCreateString( nil, puuid );
    NSString* uuid = (NSString *)CFBridgingRelease(CFStringCreateCopy( NULL, uuidString));
    CFRelease(puuid);
    CFRelease(uuidString);
    
    return uuid;
}

+(UIImage*)imageWithColor:(UIColor *)color andSize:(CGSize)size andRadius:(float)radius
{
    UIImage *img = nil;
    
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    UIGraphicsBeginImageContext(rect.size);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextBeginPath(context);
    addRoundedRectToPath(context, rect, radius, radius);
    CGContextClosePath(context);
    CGContextClip(context);
    
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillRect(context, rect);
    
    img = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return img;
}

+(NSString*)stringMD5:(NSString*)src
{
    const char* srcChars = [src UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5( srcChars, (unsigned int)strlen(srcChars), digest );
    NSMutableString *result = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
    {
        [result appendFormat:@"%02x", digest[i]];
    }
    
    return result;
}

+(void)removeAllSubViews:(UIView *)superView
{
    for(UIView* subView in superView.subviews)
    {
        [subView removeFromSuperview];
    }
}

+(void)setExtraCellLineHidden: (UITableView *)tableView
{
    UIView* spView = [UIView autolayoutView];
    [spView setBackgroundColor:[UIColor clearColor]];
    [tableView setTableFooterView:spView];
}

+(BOOL)validateMobile:(NSString*)mobile
{
    NSPredicate *phoneTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", @"^1(3|4|5|8|7)\\d{9}$"];
    
    return [phoneTest evaluateWithObject:mobile];
}

+(BOOL)validateEmail:(NSString*)email
{
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", @"^([a-zA-Z0-9_.-])+@([a-zA-Z0-9_-])+((\\.[a-zA-Z0-9_-]{2,3}){1,2})$"];
    
    return [emailTest evaluateWithObject:email];
}

+(id)getObjectFrom:(NSArray*)array ofClass:(Class)objClass
{
    for (id obj in array)
    {
        if ([obj isKindOfClass:objClass])
        {
            return obj;
        }
    }
    return nil;
}

+(id)getObjectFrom:(NSArray *)array ofProtocol:(Protocol *)objClass
{
    for (id obj in array)
    {
        if ([obj conformsToProtocol:objClass])
        {
            return obj;
        }
    }
    return nil;
}

+(id)getObjectFrom:(NSArray*)array responseSel:(SEL)selector
{
    for (id obj in array)
    {
        if ([obj respondsToSelector:selector])
        {
            return obj;
        }
    }
    return nil;
}

+(id)getObjectReverseFrom:(NSArray*)array responseSel:(SEL)selector
{
    NSEnumerator *enumerator = [array reverseObjectEnumerator];
    id obj = nil;
    while (obj = [enumerator nextObject])
    {
        if ([obj respondsToSelector:selector])
        {
            return obj;
        }
    }
    
    return nil;
}

+(id)getObjectReverseFrom:(NSArray *)array ofClass:(Class)objClass
{
    NSEnumerator *enumerator = [array reverseObjectEnumerator];
    id obj = nil;
    while (obj = [enumerator nextObject])
    {
        if ([obj isKindOfClass:objClass])
        {
            return obj;
        }
    }
    
    return nil;
}

+(id)getObjectReverseFrom:(NSArray *)array ofProtocol:(Protocol *)objClass
{
    NSEnumerator *enumerator = [array reverseObjectEnumerator];
    id obj = nil;
    while (obj = [enumerator nextObject])
    {
        if ([obj conformsToProtocol:objClass])
        {
            return obj;
        }
    }
    
    return nil;
}

+(id)getPreviousObjectFrom:(NSArray *)array theObject:(id)me
{
    NSInteger index = [array indexOfObject:me];
    if (NSNotFound == index || 0 == index)
    {
        return nil;
    }
    
    return array[index -1];
}

+(void)addBorderToView:(UIView*)view width:(float)width color:(UIColor*)color cornerRadius:(float)radius
{
    CALayer *layer = [view layer];
    layer.borderColor = [color CGColor];
    layer.borderWidth = width;
    layer.cornerRadius = radius;
    [layer setMasksToBounds:YES];
}

+(NSString*)getStringCRC32:(NSString*)src
{
    NSString* result = nil;
    @try
    {
        uLong crcValue = crc32(0L, NULL, 0L);
        NSData* data = [src dataUsingEncoding:NSUTF8StringEncoding];
        crcValue = crc32(crcValue, (const Bytef*)data.bytes, (unsigned int)(data.length));
        result = [NSString stringWithFormat:@"%lU", crcValue];
    }
    @catch (NSException *exception)
    {
        result = @"";
    }
    @finally
    {
        
    }
    return result;
}

+(NSIndexPath*)getViewIndexPath:(UIView*)view inTableView:(UITableView*)tableView
{
    UIView* cellView = view;
    while (cellView)
    {
        cellView = [cellView superview];
        if ([cellView isKindOfClass:[UITableViewCell class]])
        {
            break;
        }
    }
    
    NSIndexPath* indexPath = [tableView indexPathForCell:(UITableViewCell*)cellView];
    
    return indexPath;
}

+(NSInteger)getViewIndex:(UIView*)view inTableView:(UITableView*)tableView
{
    UIView* cellView = view;
    while (cellView)
    {
        cellView = [cellView superview];
        if ([cellView isKindOfClass:[UITableViewCell class]])
        {
            break;
        }
    }
    
    NSIndexPath* indexPath = [tableView indexPathForCell:(UITableViewCell*)cellView];
    if (indexPath)
    {
        return indexPath.row;
    }
    
    return -1;
}

+(UITableViewCell*)tableViewCellWithView:(UIView*)view inTableView:(UITableView*)tableView
{
    UIView* cellView = view;
    while (cellView)
    {
        cellView = [cellView superview];
        if ([cellView isKindOfClass:[UITableViewCell class]])
        {
            return (UITableViewCell*)cellView;
        }
    }
    return nil;
}

+(NSString*)stringWithUTF8:(NSString *)string
{
    NSString *result = (NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                           (CFStringRef)string,
                                                                           NULL,
                                                                           CFSTR("!*'();:@&=+$,/?%#[]"),
                                                                           kCFStringEncodingUTF8);
    [result autorelease];
    return result;
}

+(void)addKeyboardCloseButtonOnTextInput:(id)txtInput closeMethod:(SEL)closeMethod onTarget:(id)target andButtonTitle:(NSString*)title
{
    UIToolbar * closeKeyboard = [[UIToolbar alloc]initWithFrame:CGRectMake(0, 0, 320, 30)];
    [closeKeyboard setBarStyle:UIBarStyleDefault];
    UIBarButtonItem * btnSpace = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    UIBarButtonItem * doneButton = [[UIBarButtonItem alloc]initWithTitle:title style:UIBarButtonItemStyleDone target:target action:closeMethod];
    NSArray * buttonsArray = [NSArray arrayWithObjects:btnSpace,doneButton,nil];
    [closeKeyboard setItems:buttonsArray];
    if ([txtInput respondsToSelector:@selector(setInputAccessoryView:)])
    {
        [txtInput setInputAccessoryView:closeKeyboard];
    }
    [closeKeyboard release];
    [btnSpace release];
    [doneButton release];
}


+(UIImage*)imageToSize:(UIImage*)image size:(CGSize)size
{
    // 创建一个bitmap的context
    // 并把它设置成为当前正在使用的context
    UIGraphicsBeginImageContext(size);
    // 绘制改变大小的图片
    [image drawInRect:CGRectMake(0,0, size.width, size.height)];
    // 从当前context中创建一个改变大小后的图片
    UIImage* scaledImage =UIGraphicsGetImageFromCurrentImageContext();
    // 使当前的context出堆栈
    UIGraphicsEndImageContext();
    //返回新的改变大小后的图片
    return scaledImage;
}

+(NSString*)getFileSize:(long long)size
{
    NSString* fileSize;
    if(size >= 1024 * 1024)
    {
        fileSize = [NSString stringWithFormat:@"%0.2f MB", size / (1024 * 1024.0)];
    }
    else if(size > 1024)
    {
        fileSize = [NSString stringWithFormat:@"%lld KB", size / 1024];
    }
    else
    {
        fileSize = [NSString stringWithFormat:@"%lld B", size];
    }
    
    return fileSize;
}

/**
 在指定的矩形区域里绘制透明背景
 */
+(void)drawTransparentGridWithContext:(CGContextRef)cgContext inRect:(CGRect)rect
{
    const int GRID_W_H = 10; //格子的宽高
    const int GRID_ROW = (int)(rect.size.width / GRID_W_H / 2 + 1); //每行多少个格子
    const int ROWS = (int)(rect.size.height / GRID_W_H + 1); //有多少行
    float startX = 0;
    
    CGContextSaveGState(cgContext); //入栈
    
    //绘制背景
    CGContextSetRGBFillColor(cgContext, 1, 1, 1, 1);
    CGContextFillRect(cgContext, rect);
    
    //生成格子
    CGRect* gridRects = malloc(sizeof(CGRect) * GRID_ROW * ROWS);
    for(int i = 0; i < ROWS; i++)
    {
        if (0 == i%2)
        {
            startX = 0;
        }
        else
        {
            startX = GRID_W_H;
        }

        for (int j = 0; j < GRID_ROW; j++)
        {
            gridRects[i * GRID_ROW + j] = CGRectMake(startX + j * 2 * GRID_W_H, GRID_W_H * i, GRID_W_H, GRID_W_H);
        }
    }
    
    CGContextSetRGBFillColor(cgContext, 204/255.f, 204/255.f, 204/255.f, 1);
    CGContextFillRects(cgContext, gridRects, GRID_ROW * ROWS);
    
    free(gridRects);
    
    CGContextRestoreGState(cgContext); //出栈
}

+(NSString *)getIPAddress
{
    NSString *address = nil;
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    return address;
}

/**
 获取wifi的名称
 */
+(NSString*)getCurrentWifiName
{
    NSString* wifiName = nil;
    NSArray *ifs = (id)CNCopySupportedInterfaces();
    for (NSString *ifnam in ifs)
    {
        NSDictionary *info = (id)CNCopyCurrentNetworkInfo((CFStringRef)ifnam);
        NSLog(@"%s-%d dici：%@", __func__, __LINE__,[info  allKeys]);
        if (info[@"SSID"])
        {
            wifiName = info[@"SSID"];
            break;
        }
    }
    
    return wifiName;
}

/**
 * 根据CIImage生成指定大小的UIImage
 *
 * @param image CIImage
 * @param size 图片宽度
 */
+(UIImage *)createNonInterpolatedUIImageFormCIImage:(CIImage*)image withSize:(CGFloat) size
{
    UIImage* uiImage = nil;
    CGRect extent = CGRectIntegral(image.extent);
    CGFloat scale = MIN(size/CGRectGetWidth(extent), size/CGRectGetHeight(extent));
    // 1.创建bitmap;
    size_t width = CGRectGetWidth(extent) * scale;
    size_t height = CGRectGetHeight(extent) * scale;
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceGray();
    CGContextRef bitmapRef = CGBitmapContextCreate(nil, width, height, 8, 0, cs, (CGBitmapInfo)kCGImageAlphaNone);
    CIContext *context = [CIContext contextWithOptions:@{kCIContextUseSoftwareRenderer : @(YES)}]; //[CIContext contextWithOptions:nil];
    CGImageRef bitmapImage = [context createCGImage:image fromRect:extent];
    CGContextSetInterpolationQuality(bitmapRef, kCGInterpolationNone);
    CGContextScaleCTM(bitmapRef, scale, scale);
    CGContextDrawImage(bitmapRef, extent, bitmapImage);
    // 2.保存bitmap到图片
    CGImageRef scaledImage = CGBitmapContextCreateImage(bitmapRef);
    uiImage = [UIImage imageWithCGImage:scaledImage];
    CGContextRelease(bitmapRef);
    CGImageRelease(bitmapImage);
    CGImageRelease(scaledImage);
    CGColorSpaceRelease(cs);
    
    return uiImage;
}

/*!  判断当前机型是否为iphonex 以上机型
 */
+(BOOL)isIphoneX {
    BOOL isPhoneX = NO;
    if (@available(iOS 11.0, *)) {
        isPhoneX = [[UIApplication sharedApplication] delegate].window.safeAreaInsets.bottom > 0.0;
    }
    return isPhoneX;
}

@end
