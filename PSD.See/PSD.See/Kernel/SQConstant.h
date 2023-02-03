//
//  SQConstant.h
//  BiMaWen
//
//  Created by aec on 14-1-22.
//  Copyright (c) 2014年 sq. All rights reserved.
//

#import <Foundation/Foundation.h>

#define SQ_DEBUG 0
#define SHOW_ADS 0 //是否显示广告

#define SQ_MY_UUID (@"sq_my_identity") //用户设备的唯一标识
#define SQ_VIEW_ID (@"sq_view_id") //用户自定义view id
#define SQ_LAST_COMMENT_TIME (@"sq_last_comment_time") //上次评论的时间
#define SQ_LAYERIAMGE_PREIX (@"layerimg_") //图层文件的前缀
#define SQ_IGNORE_VERSION (@"ignore_version") //忽略的升级版本号

#define SQ_MIN_COMMENT_TIME (60 * 60 * 24 * 5) //评论的最小间隔时间
#define SQ_MAX_COMMENT_TIME (60 * 60 * 24 * 30 * 3) //评论的最大间隔时间

#define SQ_PSD_SEE_HEADER (@"psd.see")

#define SQ_VIEW_BLUE ([UIColor colorWithRed:75/255.f green:193/255.f blue:238/255.f alpha:1.f])
#define SQ_COLOR_BLUE_PRESS ([UIColor colorWithRed:55/255.f green:160/255.f blue:232/255.f alpha:1.f])
#define SQ_LINE_GRAY ([UIColor colorWithRed:210/255.f green:210/255.f blue:210/255.f alpha:1.f])
#define SQ_COLOR_GRAY ([UIColor colorWithRed:102/255.f green:102/255.f blue:102/255.f alpha:1.f])
#define SQ_FONT_BLACK ([UIColor colorWithRed:51/255.f green:51/255.f blue:51/255.f alpha:1.f])
#define SQ_FONT_YELLOW ([UIColor colorWithRed:246/255.f green:181/255.f blue:62/255.f alpha:1.f])
#define SQ_KEYBOARD_Y (286)
#define SQ_SMALL_IMG_WIDTH (100)


enum
{
    SQ_FONT_SIZE_NORMAL = 16 //正常字体
    , SQ_FONT_SIZE_BIG = 18 //大字体
    , SQ_FONT_SIZE_BIGER = 20
    , SQ_FONT_SIZE_BIGEST = 28
    
    //小字体
    , SQ_FONT_SIZE_SMALL = 12
    , SQ_FONT_SIZE_SMALLER = 10
    , SQ_FONT_SIZE_SMALLEST = 7
    
    , SQ_NAV_BAR_HEIGH = 60 //导航条的高度
    
    , PS_LAYER_NORMAL = 0 //普通的图层
    , PS_LAYER_FOLDER //分组图层
    , PS_LAYER_HIDDEN //隐藏图层,该图层不会显示用于分隔分组
    
    , PS_ERR_NO_ERROR = 0 //没有错误
    , PS_ERR_INVALIDE //无效的文件格式
    , PS_ERR_NOT_RGB //非RGB格式的ps文件
    , PS_ERR_HIDDEN_LAYER //隐藏的图层, 不能显示
    , PS_ERR_COMPRESSION //错误的压缩模式
    , PS_ERR_DEPTH_NOT_8 //深度不是8位
    , PS_ERR_OPEN_FILE //文件打开失败
    
};

