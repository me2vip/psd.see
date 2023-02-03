//
//  DrawImageView.m
//  PSD.See
//
//  Created by Larry on 16/9/29.
//  Copyright © 2016年 MaiMiao. All rights reserved.
//

#import "DrawPSDDataView.h"
#import "sqmanager.h"
#import "mbprogresshud+toast.h"
#import "ViewCtrlMain.h"
#import <math.h>

enum
{
    OPT_TYPE_NONE = 0,
    OPT_TYPE_ZOOM = 1000,
    OPT_TYPE_PAN = 1001
};

@interface DrawPSDDataView ()

@property (nonatomic, retain)UIImage* psImage; //将要显示的图片
@property (nonatomic, assign)float psScale; //缩放系数
@property (nonatomic, assign)float psX; //平移X
@property (nonatomic, assign)float psY; //平移Y
@property (nonatomic, assign)int psType;
@property (nonatomic, assign)BOOL psFullScreen; //是否全屏

@end

@implementation DrawPSDDataView

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
    //获得处理的上下文
    CGContextRef context = UIGraphicsGetCurrentContext();
    [SQManager drawTransparentGridWithContext:context inRect:rect]; //绘制透明背景
    
    if (nil == self.psImage)
    {
        return;
    }
    
    CGRect drawRect = rect; //绘制区域
    float dstX = 0;
    float dstY = 0;
    float dstWidth = 0;
    float dstHeight = 0;
    
    CGContextSaveGState(context); //入栈
    
#if 0
    //在中心点进行缩放
    if(OPT_TYPE_ZOOM == self.psType)
    {
        CGContextTranslateCTM(context, (rect.size.width /2), (rect.size.height /2));
        CGContextScaleCTM(context, self.psScale, self.psScale);
        CGContextTranslateCTM(context, -(rect.size.width /2), -(rect.size.height /2));
    }
    else if(OPT_TYPE_PAN == self.psType)
    {
        //进行平移操作
        CGContextTranslateCTM(context, self.psX, self.psY);
    }
    
    CGContextDrawImage(context, rect, self.psImage.CGImage);
#endif
    
    CGContextTranslateCTM(context, self.psX * 0.1, self.psY * 0.1);
    
    CGContextTranslateCTM(context, (rect.size.width /2), (rect.size.height /2));
    CGContextScaleCTM(context, self.psScale, -self.psScale);
    CGContextTranslateCTM(context, -(rect.size.width /2), -(rect.size.height /2));
    
    //NSLog(@"-------%f,%f,%f,%f", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
    
    if (self.psFullScreen)
    {
        drawRect = rect;
    }
    else if (self.psImage.size.width <= rect.size.width && self.psImage.size.height <= rect.size.height)
    {
        drawRect = CGRectMake((rect.size.width - self.psImage.size.width)/2, (rect.size.height - self.psImage.size.height)/2, self.psImage.size.width, self.psImage.size.height);
    }
    else if( self.psImage.size.width > rect.size.width && self.psImage.size.height > rect.size.height)
    {
        if (rect.size.width > rect.size.height)
        {
            dstY = 0;
            //dstX = fabsf((rect.size.width - self.psImage.size.width)/2);
            dstHeight = rect.size.height;
            dstWidth = (dstHeight * self.psImage.size.width) /self.psImage.size.height;
            if(dstWidth > rect.size.width)
            {
                dstX = 0;
            }
            else
            {
                dstX = fabsf((rect.size.width - dstWidth)/2);
            }
            
            drawRect = CGRectMake(dstX, dstY, dstWidth, dstHeight);
        }
        else
        {
            dstX = 0;
            //dstY = fabsf((rect.size.height - self.psImage.size.height) / 2);
            dstWidth = rect.size.width;
            dstHeight = (rect.size.width * self.psImage.size.height) /self.psImage.size.width;
            if (dstHeight > rect.size.height)
            {
                dstY = 0;
            }
            else
            {
                dstY = fabsf((rect.size.height - dstHeight) / 2);
            }
            
            drawRect = CGRectMake(dstX, dstY, dstWidth, dstHeight);
        }
    }
    else if(self.psImage.size.height > rect.size.height)
    {
        dstY = 0;
        //dstX = fabsf((rect.size.width - self.psImage.size.width)/2);
        dstHeight = rect.size.height;
        dstWidth = (dstHeight * self.psImage.size.width) /self.psImage.size.height;
        dstX = fabsf((rect.size.width - dstWidth)/2);
        
        drawRect = CGRectMake(dstX, dstY, dstWidth, dstHeight);
    }
    else if(self.psImage.size.width > rect.size.width)
    {
        dstX = 0;
        //dstY = fabsf((rect.size.height - self.psImage.size.height) / 2);
        dstWidth = rect.size.width;
        dstHeight = (rect.size.width * self.psImage.size.height) /self.psImage.size.width;
        dstY = fabsf((rect.size.height - dstHeight) / 2);
        
        drawRect = CGRectMake(dstX, dstY, dstWidth, dstHeight);
    }
    else
    {
        drawRect = rect;
    }
    
    CGContextDrawImage(context, drawRect, self.psImage.CGImage);
    
    CGContextRestoreGState(context); //出栈
}

-(void)refreshImage:(UIImage*)image
{
    self.psImage = image;
    
    self.psScale = 1;
    self.psX = 0;
    self.psY = 0;
    self.psType = OPT_TYPE_NONE;
    self.psFullScreen = FALSE;
    
    UIPinchGestureRecognizer *pinchGesture = [[[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(zoomDrawing:)] autorelease];
    [self addGestureRecognizer:pinchGesture];
    
    UIPanGestureRecognizer *panGesture = [[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panDrawing:)] autorelease];
    [panGesture setMaximumNumberOfTouches:1];
    [panGesture setMinimumNumberOfTouches:1];
    [self addGestureRecognizer:panGesture];
    
    [self setNeedsDisplay];
    //[self setBackgroundColor:[UIColor blackColor]];
}

-(void)fullScreen
{
    self.psX = 0;
    self.psY = 0;
    self.psScale = 1.0f;
    self.psFullScreen = TRUE;
    
    [self setNeedsDisplay];
}

-(void)restoreView
{
    self.psX = 0;
    self.psY = 0;
    self.psScale = 1.0f;
    self.psFullScreen = FALSE;
    
    [self setNeedsDisplay];
}

/**
 缩放操作
 */
-(void)zoomDrawing:(UIPinchGestureRecognizer *)pinchGestureRecognizer
{
    if (UIGestureRecognizerStateBegan == pinchGestureRecognizer.state)
    {
        self.psType = OPT_TYPE_ZOOM;
    }
    else if (UIGestureRecognizerStateChanged == pinchGestureRecognizer.state)
    {
        if (self.psScale > 1)
        {
            self.psScale += ((pinchGestureRecognizer.scale - 1.0) * 0.5);
        }
        else
        {
            self.psScale += ((pinchGestureRecognizer.scale - 1.0) * 0.05);
        }
        [self setNeedsDisplay];
    }
    else if(UIGestureRecognizerStateEnded == pinchGestureRecognizer.state)
    {
        self.psType = OPT_TYPE_NONE;
    }
}

/**
 平移操作
 */
-(void)panDrawing:(UIPanGestureRecognizer *)panGestureRecognizer
{
    if (UIGestureRecognizerStateBegan == panGestureRecognizer.state)
    {
        self.psType = OPT_TYPE_PAN;
    }
    else if (UIGestureRecognizerStateChanged == panGestureRecognizer.state)
    {
        CGPoint translation = [panGestureRecognizer translationInView:self];
        self.psX += translation.x;
        self.psY += translation.y;
        
        [self setNeedsDisplay];
    }
    else if(UIGestureRecognizerStateEnded == panGestureRecognizer.state)
    {
        self.psType = OPT_TYPE_NONE;
    }
}

-(void)save
{
    if (nil == self.psImage)
    {
        return;
    }
    
    NSData* imageData = UIImageJPEGRepresentation(self.psImage, 1);
    if(nil == imageData)
    {
        return;
    }
    
    NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
    //设定时间格式,这里可以设置成自己需要的格式
    [dateFormatter setDateFormat:@"yyyyMMdd_HHmmss"];
    //用[NSDate date]可以获取系统当前时间
    NSString *currentDateStr = [dateFormatter stringFromDate:[NSDate date]];
    
    NSArray *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* docPath = [path objectAtIndex:0];
    
    NSString* fileName = [NSString stringWithFormat:@"%@.jpg", currentDateStr];
    NSString* jpegPath = [docPath stringByAppendingPathComponent:fileName];
    
    [imageData writeToFile:jpegPath atomically:YES];
    
    //添加到首页的文件列表中
    UINavigationController* rootViewCtrl = (UINavigationController*)(self.window.rootViewController);
    ViewCtrlMain* ctrlMain = [SQManager getObjectFrom:rootViewCtrl.viewControllers ofClass:[ViewCtrlMain class]];
    [ctrlMain addFilePathInList:jpegPath];
    
    //保存到相册
    UIImageWriteToSavedPhotosAlbum(self.psImage, self, @selector(imageSavedToPhotosAlbum:didFinishSavingWithError:contextInfo:), nil);
}

// 实现imageSavedToPhotosAlbum:didFinishSavingWithError:contextInfo:
- (void)imageSavedToPhotosAlbum:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    NSLog(@"%s-%d error:%@", __func__, __LINE__, error);
    if (error)
    {
        //保存到相册失败
        UIAlertView* alertView = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"error_save_title", @"error_save_title") message:NSLocalizedString(@"error_save_info", @"error_save_info") delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", @"ok") otherButtonTitles:nil] autorelease];
        [alertView show];
    }
    else
    {
        //保存到相册成功
        [MBProgressHUD Toast:NSLocalizedString(@"save_ok", @"save_ok") toView:self.superview andTime:1];
    }
}

- (void)dealloc
{
    [_psImage release];
    
    [super dealloc];
}

@end
