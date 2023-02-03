#include <jni.h>
#include <string>
#include <android/log.h>
#include <android/bitmap.h>
#include <stdio.h>
#include <netinet/in.h>
#define STB_IMAGE_IMPLEMENTATION
#include "./stb_image.h"
#undef STB_IMAGE_IMPLEMENTATION

#ifdef __cplusplus
extern "C" {
#endif

enum {
    PSD_SUCCESS = 0 //psd操作成功
    , PSD_ERR_FILE_OPEN_FAIL = 5000 //文件打开失败
    , PSD_ERR_CHANNEL //通道信息错误
    , PSD_ERR_HEIGHT //高度信息错误
    , PSD_ERR_WIDTH //宽度信息错误
    , PSD_ERR_PIXEL //图片像素获取失败
    , PSD_ERR_FILE_INFO //文件信息错误
};

#define DEBUG_SQ 0
#define LOG_TAG ("psd_see_log")

#define  LOGI(...)  __android_log_print(ANDROID_LOG_INFO,LOG_TAG,__VA_ARGS__)
#define  LOGE(...)  __android_log_print(ANDROID_LOG_ERROR,LOG_TAG,__VA_ARGS__)

jint readPsdFile(JNIEnv*, jclass, jobject, jstring);
int readRawImageData(void*, FILE*, int, int, int);
int readRLEImageData(void*, FILE*, int, int, int);

static JNINativeMethod sMethods[] =
        {
                /* name, signature, funcPtr */
                  { "parsePsdImage", "(Landroid/graphics/Bitmap;Ljava/lang/String;)I", (void*)readPsdFile }
                ,
        };

static const char* CLASS_PATH = "com/maimiao/psd_see/common/PSDReaderEx";

#ifdef __cplusplus
}
#endif

/**
 * 注册JNI函数
 */
jint JNI_OnLoad(JavaVM* vm, void* reserved)
{
    JNIEnv* pEnv = NULL;
    if(vm->GetEnv((void**)&pEnv, JNI_VERSION_1_4))
    {
        return JNI_ERR;
    }
    jclass MyClass = pEnv->FindClass(CLASS_PATH);
    if(NULL == MyClass)
    {
        return JNI_ERR;
    }

    if(pEnv->RegisterNatives(MyClass, sMethods, sizeof(sMethods)/sizeof(sMethods[0])) < 0)
    {
        return JNI_ERR;
    }

    return JNI_VERSION_1_4;
}

/**
 * 卸载JNI函数
 */
void JNI_OnUnload(JavaVM* vm, void* reserved)
{
    JNIEnv* pEnv = NULL;
    jclass MyClass = NULL;
    if(vm->GetEnv((void**)&pEnv, JNI_VERSION_1_4))
    {
        goto end;
    }
    MyClass = pEnv->FindClass(CLASS_PATH);
    if(NULL == MyClass)
    {
        goto end;
    }
    pEnv->UnregisterNatives(MyClass);

    end:
    ;
}

jint readPsdFile(JNIEnv* env, jclass jClass, jobject jBitmap, jstring jFilePath)
{
    int result = 0;
    short channelCount = 0; //通道数量
    int width = 0;
    int height = 0;
    void* pixelBuffer = NULL; //像素的地址
    int skipLength = 0;
    short compression = 0; //是否压缩
    const char* filePath =  env->GetStringUTFChars(jFilePath, NULL);
    int comp = 0;

    FILE* psdFile = fopen(filePath, "rb");
    if (NULL == psdFile) {
        result = PSD_ERR_FILE_OPEN_FAIL;
        goto end;
    }

    AndroidBitmap_lockPixels(env, jBitmap, &pixelBuffer);
    if (NULL == pixelBuffer) {
        //像素获取失败
        result = PSD_ERR_PIXEL;
        goto end;
    }

    //STBIDEF stbi_uc *stbi_load_psd_from_file  (FILE *f, stbi_uc* pixelBuffer, int *x, int *y, int *comp, int req_comp)
    result = stbi_load_psd_from_file(psdFile, (unsigned char*)pixelBuffer, &width
            , &height, &comp, STBI_rgb_alpha);
    LOGI("%s-%d width:%d, height:%d, comp:%d, result:%d", __func__, __LINE__,
    width, height, comp, result);

    goto end;

    fseek(psdFile, 4, SEEK_SET); //跳过文件签名, 8BPS
    fseek(psdFile, 2, SEEK_CUR); //跳过版本信息
    fseek(psdFile, 6, SEEK_CUR); //跳过保留字段
    if (fread(&channelCount, 2, 1, psdFile) <= 0) { //获取通道信息
        result = PSD_ERR_CHANNEL;
        goto end;
    }

    channelCount = ntohs(channelCount);
    if (channelCount < 0 || channelCount > 16) {
        result = PSD_ERR_CHANNEL;
        goto end;
    }

    if (fread(&height, 4, 1, psdFile) <= 0) { //高度信息
        result = PSD_ERR_HEIGHT;
        goto end;
    }

    height = ntohl(height);
    if (fread(&width, 4, 1, psdFile) <= 0) { //宽度信息
        result = PSD_ERR_WIDTH;
        goto end;
    }

    width = ntohl(width);
    if (height <= 0) {
        result = PSD_ERR_HEIGHT;
        goto end;
    }

    if (width <= 0) {
        result = PSD_ERR_WIDTH;
        goto end;
    }
    fseek(psdFile, 2, SEEK_CUR); //跳过深度信息
    fseek(psdFile, 2, SEEK_CUR); //跳过颜色模式
    LOGI("%s-%d: widht:%d, height:%d, channelCount:%d, psd file:%s"
    , __func__, __LINE__, width, height, channelCount, filePath);

    //跳过颜色模式信息段
    if (fread(&skipLength, 4, 1, psdFile) <= 0) {
        result = PSD_ERR_FILE_INFO;
        goto end;
    }
    skipLength = ntohl(skipLength);
    if (skipLength < 0) {
        result = PSD_ERR_FILE_INFO;
        goto end;
    }

#if DEBUG_SQ
    LOGI("%s-%d: color mode len:%d, fpos:%d", __func__, __LINE__, skipLength, ftell(psdFile));
#endif

    fseek(psdFile, skipLength, SEEK_CUR);

    //跳过图像资源段
    if (fread(&skipLength, 4, 1, psdFile) <= 0) {
        result = PSD_ERR_FILE_INFO;
        goto end;
    }
    skipLength = ntohl(skipLength);
    if (skipLength < 0) {
        result = PSD_ERR_FILE_INFO;
        goto end;
    }
#if DEBUG_SQ
    LOGI("%s-%d: image block len:%d, fpos:%d", __func__, __LINE__, skipLength, ftell(psdFile));
#endif
    fseek(psdFile, skipLength, SEEK_CUR);

    //跳过图层与蒙版信息
    if (fread(&skipLength, 4, 1, psdFile) <= 0) {
        result = PSD_ERR_FILE_INFO;
        goto end;
    }
    skipLength = ntohl(skipLength);
    if (skipLength < 0) {
        result = PSD_ERR_FILE_INFO;
        goto end;
    }
    fseek(psdFile, skipLength, SEEK_CUR);

#if DEBUG_SQ
    LOGI("%s-%d: layer block len:%d, fpos:%d", __func__, __LINE__, skipLength, ftell(psdFile));
#endif

    //处理图像数据
    if (fread(&compression, 2, 1, psdFile) <= 0) {
        result = PSD_ERR_FILE_INFO;
        goto end;
    }
    compression = ntohs(compression);

    AndroidBitmap_lockPixels(env, jBitmap, &pixelBuffer);
    if (NULL == pixelBuffer) {
        //像素获取失败
        result = PSD_ERR_PIXEL;
        goto end;
    }

    if (0 == compression) {
        //原始数据
        result = readRawImageData(pixelBuffer, psdFile, channelCount, width, height);
        if (result) {
            goto end;
        }
    } else if (1 == compression) {
        //RLE压缩数据
        result = readRLEImageData(pixelBuffer, psdFile, channelCount, width, height);
        if (result) {
            goto end;
        }
    } else {
        //不支持的数据格式
        result = PSD_ERR_PIXEL;
        goto end;
    }

    end:
    if (pixelBuffer) {
        AndroidBitmap_unlockPixels(env, jBitmap);
        pixelBuffer = NULL;
    }

    if (psdFile) {
        fclose(psdFile);
        psdFile = NULL;
    }
    env->ReleaseStringUTFChars(jFilePath, filePath);

    return result;
}

/**
 * 读取原始的图片数据
 * @param pixelBuffer
 * @param psdFile
 * @param channelCount
 * @param width
 * @param height
 */
int readRawImageData(void* pixelBuffer, FILE* psdFile, int channelCount, int width, int height) {
    const int PIXEL_COUNT = width * height;
    int index = 0;
    int channel = 0;
    unsigned char* pixelAddress = NULL;

    for (channel = 0; channel < 4; channel++) {
        pixelAddress = (unsigned char *) pixelBuffer + channel;

        if (channel >= channelCount) {
            for (index = 0; index < PIXEL_COUNT; index++, pixelAddress += 4) {
                *pixelAddress = (3 == channel ? 255 : 0);
            }
        } else {
            for (index = 0; index < PIXEL_COUNT; index++, pixelAddress += 4) {
                if (fread(pixelAddress, 1, 1, psdFile) <= 0) {
                    return PSD_ERR_FILE_INFO;
                }
            }
        }
    }
    return 0;
}

/**
 * 读取RLE压缩图像数据
 * @param pixelBuffer
 * @param psdFile
 * @param channelCount
 * @param width
 * @param height
 */
int readRLEImageData(void* pixelBuffer, FILE* psdFile, int channelCount, int width, int height) {
    const int PIXEL_COUNT = width * height;
    int index = 0;
    int channel = 0;
    unsigned char* pixelAddress = NULL;
    signed char rleLen = 0;
    unsigned char tempByte = 0;

    fseek(psdFile, height * channelCount * 2, SEEK_CUR); //跳过每行的压缩字节数

    for (channel = 0; channel < 4; channel++) {
        pixelAddress = (unsigned char *) pixelBuffer + channel;

        if (channel >= channelCount) {
            for (index = 0; index < PIXEL_COUNT; index++, pixelAddress += 4) {
                *pixelAddress = (3 == channel ? 255 : 0);
            }
        } else {
            index = 0;
            while (index < PIXEL_COUNT) {
                if (fread(&rleLen, 1, 1, psdFile) <= 0) {
                    return PSD_ERR_FILE_INFO;
                }

                if (rleLen < 0) {
                    // Next -len+1 bytes in the dest are replicated from next source byte.
                    // (Interpret len as a negative 8-bit int.)
                    rleLen = 1 - rleLen;
                    index += rleLen;

                    if (fread(&tempByte, 1, 1, psdFile) <= 0) {
                        return PSD_ERR_FILE_INFO;
                    }

                    while (rleLen > 0) {
                        *pixelAddress = tempByte;
                        rleLen --;
                        pixelAddress += 4;
                    }
                } else {
                    // Copy next len+1 bytes literally.
                    rleLen++;
                    index += rleLen;
                    while (rleLen > 0) {
                        if (fread(pixelAddress, 1, 1, psdFile) <= 0) {
                            return PSD_ERR_FILE_INFO;
                        }

                        pixelAddress += 4;
                        rleLen--;
                    }
                }
            }
        }
    }

    return 0;
}