package com.maimiao.psd_see;


/**
 * 本模块主要定义程序中要使用的常量
 * @author 
 *
 */
public interface IConstants
{
	final boolean DEBUG = false;

	final String TAG = "psd_see_log";
    final int REQ_OPENABLE = 1000;

    final String SIMPLE_PSD = "assets://simple.psd"; //样例图片
    final String SIMPLE_PNG = "assets://simple.png";

    final String SAVE_PATH = "/psd.see/images/";
    final String FRAGMENT_MAIN_THREAD = "com.maimiao.psd_see.FRAGMENT_MAIN_THREAD"; //主线fragment

    final int ERROR_NETWORK = 100; //网络错误
    final int ERROR_SERVER = 101; //服务器异常
    final int ERROR_UNKNOWN = 1001; //未知错误
    final int ERROR_FILE_FORMAT = 1002; //文件格式错误
    final int ERROR_FILE_VERSOIN = 1003; //文件的版本信息错误
    final int ERROR_DEPTH = 1004; //文件的深度错误
    final int ERROR_NOT_RGB = 1005; //颜色模式不是RGB格式
    final int ERROR_COMPRESSION = 1006; //错误的压缩方式
    final int ERROR_MEM_OUT = 1007; //内存溢出
    final int ERROR_OPEN_FAIL = 1008; //文件打开失败
   
}
