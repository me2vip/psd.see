//
//  DrawImageView.m
//  PSD.See
//
//  Created by Larry on 16/9/29.
//  Copyright © 2016年 MaiMiao. All rights reserved.
//

#import "DrawImageView.h"
#import "sqmanager.h"
#import <math.h>

enum
{
    OPT_TYPE_NONE = 0,
    OPT_TYPE_ZOOM = 1000,
    OPT_TYPE_PAN = 1001
};

@interface DrawImageView ()

@property (nonatomic, retain)FileItem* psFile; //将要显示的图片
@property (nonatomic, assign)float psScale; //缩放系数
@property (nonatomic, assign)float psX; //平移X
@property (nonatomic, assign)float psY; //平移Y
@property (nonatomic, assign)float psAngle; //旋转的角度
@property (nonatomic, assign)int psType;
@property (nonatomic, assign)BOOL psFullScreen; //是否全屏
@property (nonatomic, retain)UIImage* psShowImage; //

@end

@implementation DrawImageView

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
    if (nil == self.psShowImage)
    {
        return;
    }
    
    CGRect drawRect = rect; //绘制区域
    float dstX = 0;
    float dstY = 0;
    float dstWidth = 0;
    float dstHeight = 0;
    
    //获得处理的上下文
    CGContextRef context = UIGraphicsGetCurrentContext();
    [SQManager drawTransparentGridWithContext:context inRect:rect]; //绘制透明背景
    
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
    
    CGContextDrawImage(context, rect, self.psShowImage.CGImage);
#endif
    
    CGContextTranslateCTM(context, self.psX * 0.1, self.psY * 0.1);
    
    CGContextTranslateCTM(context, (rect.size.width /2), (rect.size.height /2));
    CGContextScaleCTM(context, self.psScale, -self.psScale);
    CGContextRotateCTM(context, self.psAngle);
    CGContextTranslateCTM(context, -(rect.size.width /2), -(rect.size.height /2));
    
    //NSLog(@"-------%f,%f,%f,%f", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
    
    if (self.psFullScreen)
    {
        drawRect = rect;
    }
    else if (self.psShowImage.size.width <= rect.size.width && self.psShowImage.size.height <= rect.size.height)
    {
        drawRect = CGRectMake((rect.size.width - self.psShowImage.size.width)/2, (rect.size.height - self.psShowImage.size.height)/2, self.psShowImage.size.width, self.psShowImage.size.height);
    }
    else if( self.psShowImage.size.width > rect.size.width && self.psShowImage.size.height > rect.size.height)
    {
        if (rect.size.width > rect.size.height)
        {
            dstY = 0;
            //dstX = fabsf((rect.size.width - self.psShowImage.size.width)/2);
            dstHeight = rect.size.height;
            dstWidth = (dstHeight * self.psShowImage.size.width) /self.psShowImage.size.height;
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
            //dstY = fabsf((rect.size.height - self.psShowImage.size.height) / 2);
            dstWidth = rect.size.width;
            dstHeight = (rect.size.width * self.psShowImage.size.height) /self.psShowImage.size.width;
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
    else if(self.psShowImage.size.height > rect.size.height)
    {
        dstY = 0;
        //dstX = fabsf((rect.size.width - self.psShowImage.size.width)/2);
        dstHeight = rect.size.height;
        dstWidth = (dstHeight * self.psShowImage.size.width) /self.psShowImage.size.height;
        dstX = fabsf((rect.size.width - dstWidth)/2);
        
        drawRect = CGRectMake(dstX, dstY, dstWidth, dstHeight);
    }
    else if(self.psShowImage.size.width > rect.size.width)
    {
        dstX = 0;
        //dstY = fabsf((rect.size.height - self.psShowImage.size.height) / 2);
        dstWidth = rect.size.width;
        dstHeight = (rect.size.width * self.psShowImage.size.height) /self.psShowImage.size.width;
        dstY = fabsf((rect.size.height - dstHeight) / 2);
        
        drawRect = CGRectMake(dstX, dstY, dstWidth, dstHeight);
    }
    else
    {
        drawRect = rect;
    }
    
    CGContextDrawImage(context, drawRect, self.psShowImage.CGImage);
    
    CGContextRestoreGState(context); //出栈
}

-(void)initWithFileItem:(FileItem*)fileItem
{
    self.psFile = fileItem;
    
    self.psScale = 1;
    self.psX = 0;
    self.psY = 0;
    self.psType = OPT_TYPE_NONE;
    self.psFullScreen = FALSE;
    if (self.psFile.psPsdImage.length > 0)
    {
        self.psShowImage = [UIImage imageWithContentsOfFile:self.psFile.psPsdImage];
    }
    else
    {
        self.psShowImage = [UIImage imageWithContentsOfFile:self.psFile.psFilePath];
    }
    
    UIPinchGestureRecognizer *pinchGesture = [[[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(zoomDrawing:)] autorelease];
    [self addGestureRecognizer:pinchGesture];
    
    UIPanGestureRecognizer *panGesture = [[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panDrawing:)] autorelease];
    [panGesture setMaximumNumberOfTouches:1];
    [panGesture setMinimumNumberOfTouches:1];
    [self addGestureRecognizer:panGesture];
    
    //[self setBackgroundColor:[UIColor blackColor]];
}

-(void)updateImage:(UIImage*)image
{
    self.psShowImage = image;
    [self setNeedsDisplay];
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

-(void)rotateWithAngle:(int)angle
{
    self.psAngle += angle * M_PI / 180.f;
    
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

- (void)dealloc
{
    [_psFile release];
    [_psShowImage release];
    
    [super dealloc];
}

@end
