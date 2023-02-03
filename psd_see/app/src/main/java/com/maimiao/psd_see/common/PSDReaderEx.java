package com.maimiao.psd_see.common;

import android.graphics.Bitmap;

import com.maimiao.psd_see.IConstants;
import com.maimiao.psd_see.R;
import com.maimiao.psd_see.kernel.KernelException;
import com.maimiao.psd_see.kernel.KernelManager;

import java.io.BufferedInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;

public class PSDReaderEx {
    static {
        System.loadLibrary("nativeEntry");
    }
    public static final int COLOR_MODE_BITMAP = 0, COLOR_MODE_GRAYSCALE = 1
            , COLOR_MODE_INDEXED = 2, COLOR_MODE_RGB = 3, COLOR_MODE_CMYK = 4
            , COLOR_MODE_MULTICHANNEL = 7, COLOR_MODE_DUOTONE = 8, COLOR_MODE_LAB = 9;

    private short mNumOfChannel;
    private int mHeight;
    private int mWidth;
    private int mColorMode; //颜色模式
    private long mFileSize; //文件大小

    public static native int parsePsdImage(Bitmap bitmap, String filePath);

    public static String getColorMode(int colorModeInt) {
        String colorMode = "RGB";
        if (COLOR_MODE_BITMAP == colorModeInt) {
            colorMode = "Bitmap";
        } else if (COLOR_MODE_GRAYSCALE == colorModeInt) {
            colorMode = "Grayscale";
        } else if (COLOR_MODE_INDEXED == colorModeInt) {
            colorMode = "Indexed";
        } else if (COLOR_MODE_RGB == colorModeInt) {
            colorMode = "RGB";
        } else if (COLOR_MODE_CMYK == colorModeInt) {
            colorMode = "CMYK";
        } else if (COLOR_MODE_MULTICHANNEL == colorModeInt) {
            colorMode = "Multichannel";
        } else if (COLOR_MODE_DUOTONE == colorModeInt) {
            colorMode = "Duotone";
        } else if (COLOR_MODE_LAB == colorModeInt) {
            colorMode = "Lab";
        }

        return colorMode;
    }
    
    public PSDReaderEx() {}

    public Bitmap getImage(String filePath) throws IOException, KernelException {
        return getImage(new File(filePath));
    }

    public Bitmap getImage(File file) throws IOException, KernelException {
        final long START_TIME = System.currentTimeMillis();
        LogTrace.log("ps file:" + file.getAbsolutePath());
        mFileSize = file.length();
        Bitmap bitmap = null;
        BufferedInputStream stream = null;
        int[] pixels = null;

        stream = new BufferedInputStream(new FileInputStream(file));
        PsdInputStream psdStream = new PsdInputStream(stream);

        try {
            //-------第一部分：文件头------------------
            String sig = psdStream.readString(4);
            if (!sig.equals("8BPS")) {
                throw new KernelException(IConstants.ERROR_FILE_FORMAT
                        , KernelManager._GetObject().getContext().getString(R.string.file_error));
            }

            int ver = psdStream.readShort();
            if (ver != 1) {
                throw new KernelException(IConstants.ERROR_FILE_VERSOIN
                        , KernelManager._GetObject().getContext().getString(R.string.file_error));
            }

            psdStream.skipBytes(6); // reserved
            mNumOfChannel = psdStream.readShort();
            mHeight = psdStream.readInt();
            mWidth = psdStream.readInt();
            //图像深度（每个通道的颜色位数）
            short depth = psdStream.readShort();
            if (8 != depth) {
                //深度必须是8位
                throw new KernelException(IConstants.ERROR_DEPTH,
                        new StringBuilder(KernelManager._GetObject().getContext().getString(R.string.error_depth_1))
                                .append(KernelManager._GetObject().getContext().getString(R.string.error_depth_2))
                                .append(depth).append(KernelManager._GetObject().getContext().getString(R.string.error_depth_3))
                                .toString());
            }

            //是rgb模式则type=3
            mColorMode = psdStream.readShort();
            if (COLOR_MODE_RGB != mColorMode) {
                throw new KernelException(IConstants.ERROR_NOT_RGB,
                        new StringBuilder(KernelManager._GetObject().getContext().getString(R.string.error_colormode_1))
                                .append(KernelManager._GetObject().getContext().getString(R.string.error_colormode_2))
                                .append(getColorMode()).toString());
            }

            //--------第二部分：色彩模式信息，跳过该段----
            int colorMapLength = psdStream.readInt();
            psdStream.skipBytes(colorMapLength);

            //--------第三部分：图像资源数据-------------
            int lenOfImageResourceBlock = psdStream.readInt();
            psdStream.skipBytes(lenOfImageResourceBlock);

            //--------第四部分：图层与蒙版信息-------------
            int lenOfLayerInfo = psdStream.readInt();
            psdStream.skipBytes(lenOfLayerInfo);
            LogTrace.log("width:" + mWidth + ", height:" + mHeight + ", file size:" + mFileSize);

            if (mWidth * mHeight <= 1024 * 1024) {
                LogTrace.log("open small psd doc");
                //小图处理
                pixels = new int[mWidth * mHeight]; //图像数据的缓存
                // Find out if the data is compressed.
                // Known values:
                //   0: no compression
                //   1: RLE compressed
                // channel 的顺序为RGBA
                int compression = psdStream.readShort();

                if (1 == compression) {
                    parseRleImage(psdStream, pixels);
                } else if (0 == compression) {
                    parseRawImage(psdStream, pixels);
                } else {
                    throw new KernelException(IConstants.ERROR_COMPRESSION
                            , KernelManager._GetObject().getContext().getString(R.string.error_compression));
                }

                bitmap = Bitmap.createBitmap(pixels, 0, mWidth, mWidth, mHeight, Bitmap.Config.ARGB_8888);
            } else {
                //大图处理
                LogTrace.log("open big psd doc");
                bitmap = Bitmap.createBitmap(mWidth, mHeight, Bitmap.Config.ARGB_8888);
                if (null == bitmap) {
                    throw new KernelException(IConstants.ERROR_MEM_OUT
                            , KernelManager._GetObject().getContext().getString(R.string.error_out_memory));
                }

                //调用底层的文件处理
                int result = parsePsdImage(bitmap, file.getAbsolutePath());
                if (0 != result) {
                    throw new KernelException(IConstants.ERROR_OPEN_FAIL, new StringBuilder(
                            KernelManager._GetObject().getContext().getString(R.string.open_file_fail)
                    ).append(":").append(result).toString());
                }
            }
        } catch (IOException e) {
            releaseBitmap(bitmap);
            bitmap = null;
            throw  e;
        } catch (KernelException e) {
            releaseBitmap(bitmap);
            bitmap = null;
            throw e;
        } catch (Exception e) {
            releaseBitmap(bitmap);
            bitmap = null;
            throw e;
        } finally {
            try {
                stream.close();
            } catch (Exception e) {
                e.printStackTrace();
            }
        }

        LogTrace.log("read time:" + (System.currentTimeMillis() - START_TIME));

        return bitmap;
    }

    private void releaseBitmap(Bitmap bitmap) {
        try {
            bitmap.recycle();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    /**
    public Bitmap getImage(int width){
        Bitmap newImage = null;
        Bitmap rawImage = Bitmap.createBitmap(mPixels, 0, mWidth, mWidth
                , mHeight, Bitmap.Config.ARGB_8888); //原始图片
        if (width >= mWidth)
        {
            //超过原始尺寸,返回原图
            return rawImage;
        }

        Matrix matrix = new Matrix();
        float scale = width * 1.0f / mWidth;
        // float scaleHeight = ((float)newHeight) / height;
        matrix.postScale(scale, scale);
        // Bitmap result = Bitmap.createBitmap(target,0,0,width,height,
        // matrix,true);
        newImage = Bitmap.createBitmap(rawImage, 0, 0, mWidth, mHeight, matrix,
                true);
        //释放原始图片
        rawImage.recycle();
        rawImage = null;

        return newImage;
    }
    **/

    public long getFileSize() {
        return mFileSize;
    }

    public int getWidth() {
        return mWidth;
    }

    public int getHeight() {
        return mHeight;
    }

    public int getColorMode() {
        return mColorMode;
    }

    /**
     * 读取RLE模式的数据
     * @param psdStream
     * @throws IOException
     */
    private void parseRleImage(PsdInputStream psdStream, int[] pixels) throws IOException {
        final int PIXEL_COUNT = mWidth * mHeight;
        int index = 0;
        int channel = 0;
        int pixelValue;
        int rleLen = 0;
        int pixelIndex = 0;

        psdStream.skipBytes(mHeight * mNumOfChannel * 2); //跳过每行的压缩字节数
        for (channel = 0; channel < 4; channel++) {
            if (channel >= mNumOfChannel) {
                pixelValue = (3 == channel ? 255 : 0);
                if (3 == channel) {
                    pixelValue <<= 24; //alpha值
                } else if (0 == channel) {
                    //red 值
                    pixelValue <<= 16;
                } else if (1 == channel) {
                    //green 值
                    pixelValue <<= 8;
                }
                for (index = 0; index < PIXEL_COUNT; index++) {
                    pixels[index] |= pixelValue;
                }
            } else {
                index = 0;
                pixelIndex = 0;
                while (index < PIXEL_COUNT) {
                    rleLen = psdStream.readByte();
                    if (rleLen < 0) {
                        // Next -len+1 bytes in the dest are replicated from next source byte.
                        // (Interpret len as a negative 8-bit int.)
                        rleLen = 1 - rleLen;
                        index += rleLen;
                        pixelValue = psdStream.readUnsignedByte();
                        if (3 == channel) {
                            pixelValue <<= 24; //alpha值
                        } else if (0 == channel) {
                            //red 值
                            pixelValue <<= 16;
                        } else if (1 == channel) {
                            //green 值
                            pixelValue <<= 8;
                        }
                        while (rleLen > 0) {
                            pixels[pixelIndex++] |= pixelValue;
                            rleLen--;
                        }
                    } else {
                        // Copy next len+1 bytes literally.
                        rleLen++;
                        index += rleLen;
                        while (rleLen > 0) {
                            pixelValue = psdStream.readUnsignedByte();
                            if (3 == channel) {
                                pixelValue <<= 24; //alpha值
                            } else if (0 == channel) {
                                //red 值
                                pixelValue <<= 16;
                            } else if (1 == channel) {
                                //green 值
                                pixelValue <<= 8;
                            }
                            pixels[pixelIndex++] |= pixelValue;
                            rleLen--;
                        }
                    }
                }
            }
        }
    }

    /**
     * 读取原始图片数据
     * @param psdStream
     */
    private void parseRawImage(PsdInputStream psdStream, int[] pixels) throws IOException {
        final int PIXEL_COUNT = mWidth * mHeight;
        int index = 0;
        int channel = 0;
        int pixelValue;

        for (channel = 0; channel < 4; channel++) {
            if (channel >= mNumOfChannel) {
                pixelValue = (3 == channel ? 255 : 0);
                if (3 == channel) {
                    pixelValue <<= 24; //alpha值
                } else if (0 == channel) {
                    //red 值
                    pixelValue <<= 16;
                } else if (1 == channel) {
                    //green 值
                    pixelValue <<= 8;
                }
                for (index = 0; index < PIXEL_COUNT; index++) {
                    pixels[index] |= pixelValue;
                }
            } else {
                for (index = 0; index < PIXEL_COUNT; index++) {
                    pixelValue = psdStream.readUnsignedByte();
                    if (3 == channel) {
                        pixelValue <<= 24; //alpha值
                    } else if (0 == channel) {
                        //red 值
                        pixelValue <<= 16;
                    } else if (1 == channel) {
                        //green 值
                        pixelValue <<= 8;
                    }
                    pixels[index] |= pixelValue;
                }
            }
        }
    }

    /**
     * 读取文件头信息
     * @param
     * @throws KernelException
     * @throws IOException
     */
    private void readFileHeader(File file) throws KernelException, IOException {
        BufferedInputStream stream = new BufferedInputStream(new FileInputStream(file));
        PsdInputStream psdStream = new PsdInputStream(stream);
        //-------第一部分：文件头------------------
        String sig = psdStream.readString(4);
        if (!sig.equals("8BPS")) {
            stream.close();
            throw new KernelException(IConstants.ERROR_FILE_FORMAT
                    , KernelManager._GetObject().getContext().getString(R.string.file_error));
        }

        int ver = psdStream.readShort();
        if (ver != 1) {
            stream.close();
            throw new KernelException(IConstants.ERROR_FILE_VERSOIN
                    , KernelManager._GetObject().getContext().getString(R.string.file_error));
        }

        psdStream.skipBytes(6); // reserved
        mNumOfChannel = psdStream.readShort();
        mHeight = psdStream.readInt();
        mWidth = psdStream.readInt();
        //图像深度（每个通道的颜色位数）
        short depth = psdStream.readShort();
        if (8 != depth) {
            //深度必须是8位
            stream.close();
            throw new KernelException(IConstants.ERROR_DEPTH,
                    new StringBuilder(KernelManager._GetObject().getContext().getString(R.string.error_depth_1))
                            .append(KernelManager._GetObject().getContext().getString(R.string.error_depth_2))
                            .append(depth).append(KernelManager._GetObject().getContext().getString(R.string.error_depth_3))
                            .toString());
        }

        //是rgb模式则type=3
        mColorMode = psdStream.readShort();
        if (COLOR_MODE_RGB != mColorMode) {
            stream.close();
            throw new KernelException(IConstants.ERROR_NOT_RGB,
                    new StringBuilder(KernelManager._GetObject().getContext().getString(R.string.error_colormode_1))
                            .append(KernelManager._GetObject().getContext().getString(R.string.error_colormode_2))
                            .append(getColorMode()).toString());
        }

        stream.close();
    }
}


