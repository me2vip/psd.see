package com.maimiao.psd_see.kernel;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.graphics.Bitmap.Config;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Matrix;
import android.graphics.Paint;
import android.graphics.PorterDuff.Mode;
import android.graphics.PorterDuffXfermode;
import android.graphics.Rect;
import android.graphics.RectF;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;
import android.net.wifi.WifiInfo;
import android.net.wifi.WifiManager;
import android.os.Environment;
import android.os.Process;
import android.util.Log;
import android.view.WindowManager;

import com.google.zxing.BarcodeFormat;
import com.google.zxing.EncodeHintType;
import com.google.zxing.WriterException;
import com.google.zxing.common.BitMatrix;
import com.google.zxing.qrcode.QRCodeWriter;
import com.j256.ormlite.android.apptools.OpenHelperManager;
import com.maimiao.psd_see.IConstants;
import com.nostra13.universalimageloader.cache.disc.naming.Md5FileNameGenerator;
import com.nostra13.universalimageloader.cache.memory.impl.WeakMemoryCache;
import com.nostra13.universalimageloader.core.DisplayImageOptions;
import com.nostra13.universalimageloader.core.ImageLoader;
import com.nostra13.universalimageloader.core.ImageLoaderConfiguration;
import com.nostra13.universalimageloader.core.assist.ImageScaleType;
import com.nostra13.universalimageloader.core.assist.QueueProcessingType;
import com.nostra13.universalimageloader.core.display.SimpleBitmapDisplayer;

import java.io.File;
import java.io.FileInputStream;
import java.io.InputStream;
import java.security.MessageDigest;
import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Hashtable;
import java.util.Random;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.zip.CRC32;

import io.netty.channel.Channel;
import io.netty.channel.ChannelId;
import io.netty.channel.group.ChannelGroup;
import io.netty.channel.group.DefaultChannelGroup;
import io.netty.util.concurrent.GlobalEventExecutor;


public class KernelManager
{
	public static final ChannelGroup channelGroup = new DefaultChannelGroup(GlobalEventExecutor.INSTANCE);;

	private static KernelManager sKernelManager = null;
	private static String sSdCardPath = "";
	private DatabaseHelper mDatabaseHelper = null;
	private Context mContext = null;
	private String mVersionName; // 版本信息
	private String mPackName; // 包信息
	private int mVersionCode;
	private Random mRandom;
	private final String CONFIG_FILE = "config_file";
	private final String IS_FIRTST_START = "first_start";

	private KernelManager()
	{ mRandom = new Random(System.currentTimeMillis()); }

	public static KernelManager _GetObject()
	{
		if (null == sKernelManager)
		{
			sKernelManager = new KernelManager();
		}

		return sKernelManager;
	}

	public static int calculateInSampleSize(BitmapFactory.Options options,
											 int reqWidth, int reqHeight) {
		// Raw height and width of image
		final int height = options.outHeight;
		final int width = options.outWidth;
		int inSampleSize = 1;

		if (height > reqHeight || width > reqWidth) {

			// Calculate ratios of height and width to requested height and
			// width
			final int heightRatio = Math.round((float) height
					/ (float) reqHeight);
			final int widthRatio = Math.round((float) width / (float) reqWidth);

			// Choose the smallest ratio as inSampleSize value, this will
			// guarantee
			// a final image with both dimensions larger than or equal to the
			// requested height and width.
			inSampleSize = heightRatio < widthRatio ? widthRatio : heightRatio;
		}

		return inSampleSize;
	}

	/**
	 * 打印trace信息
	 * 
	 * @param e
	 */
	public static void showTrace(Exception e)
	{
		StackTraceElement[] trace = e.getStackTrace();
		for (int nIndex = 0; nIndex < trace.length; nIndex++)
		{
			Log.e("bmw_trace", "TRACE:" + trace[nIndex].toString());
		}
	}

	/**
	 * 获取2个数字之间的随机数
	 * @param min
	 * @param max
	 * @return
	 */
	public static int getRandom(int min, int max)
	{
		if(max <= min)
		{
			max = min + 1;
		}
		return min + _GetObject().mRandom.nextInt(max - min);
	}

	public static boolean isStringEmpty(String string)
	{
		if(null == string || 0 == string.length())
		{
			return true;
		}
		return false;
	}
	
	public static int string2Int(String szVale, int defaultValue)
	{
		int nRet = defaultValue;
		try
		{
			nRet = Integer.parseInt(szVale);
		}
		catch (Exception e)
		{
		}

		return nRet;
	}

	public static long string2Long(String szValue, long defaultValue)
	{
		long lRet = defaultValue;
		try
		{
			lRet = Long.parseLong(szValue);
		}
		catch (Exception e)
		{
		}
		return lRet;
	}

	public static boolean string2Bool(String value, boolean defaultValue)
	{
		boolean ret = defaultValue;
		try
		{
			ret = Boolean.parseBoolean(value);
		}
		catch (Exception e)
		{
		}
		return ret;
	}

	public static String getTimeString(long time)
	{
		SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
		Calendar calendar = Calendar.getInstance();
		calendar.setTimeInMillis(time);
		return dateFormat.format(calendar.getTime());
	}
	
	/**
	 * 生成二维码图片
	 * @param outBitmap
	 * @throws WriterException 
	 */
	public static void createQRCodeToImage(Bitmap outBitmap, String codeInfo) throws WriterException
	{
        // 需要引入core包
        QRCodeWriter writer = new QRCodeWriter();
        final int QR_WIDTH = outBitmap.getWidth();
        final int QR_HEIGHT = outBitmap.getHeight();

        // 把输入的文本转为二维码
        BitMatrix martix = writer.encode(codeInfo, BarcodeFormat.QR_CODE,
                QR_WIDTH, QR_HEIGHT);
        
        Log.i(IConstants.TAG, "createQRCodeToImage.width:" + martix.getWidth()
				+ " height:" + martix.getHeight());

        Hashtable<EncodeHintType, String> hints = new Hashtable<EncodeHintType, String>();
        hints.put(EncodeHintType.CHARACTER_SET, "utf-8");
        BitMatrix bitMatrix = new QRCodeWriter().encode(codeInfo,
                BarcodeFormat.QR_CODE, QR_WIDTH, QR_HEIGHT, hints);
        int[] pixels = new int[QR_WIDTH * QR_HEIGHT];
        for (int y = 0; y < QR_HEIGHT; y++) {
            for (int x = 0; x < QR_WIDTH; x++) {
                if (bitMatrix.get(x, y)) {
                    pixels[y * QR_WIDTH + x] = 0xff000000;
                } 
                else {
                    pixels[y * QR_WIDTH + x] = 0xffffffff;
                }
            }
        }

        /**
        Bitmap bitmap = Bitmap.createBitmap(QR_WIDTH, QR_HEIGHT,
                Bitmap.Config.ARGB_8888);
        **/

        outBitmap.setPixels(pixels, 0, QR_WIDTH, 0, 0, QR_WIDTH, QR_HEIGHT);
	}

	public static Channel getChannelById(ChannelId channelId) {
		Channel channel = null;
		try {
			channel = channelGroup.find(channelId);
		} catch (Exception e) {
			channel = null;
		}

		return channel;
	}

	/**
	 * 获取文件的CRC32位校验码
	 * @param szFilePath
	 * @return
	 */
	public static long getFileCRC32(String szFilePath)
	{
		long lCode = 0;
		FileInputStream fileStream = null;

		try
		{
			fileStream = new FileInputStream(szFilePath);
			byte[] buffer = new byte[1024];
			CRC32 crc32 = new CRC32();
			int nRead = 0;
			while ((nRead = fileStream.read(buffer)) > 0)
			{
				crc32.update(buffer, 0, nRead);
			}

			lCode = crc32.getValue();
			fileStream.close();
		}
		catch(Exception e)
		{
			lCode = 0;
		}

		return lCode;
	}

	/**
	 * 对bitmap进行缩放
	 * @param rawBitmap
	 * @param newWidth
     * @return
     */
	public static Bitmap scaleBitmap(Bitmap rawBitmap, int newWidth){
		if (newWidth >= rawBitmap.getWidth()){
			return Bitmap.createBitmap(rawBitmap);
		}

		Matrix matrix = new Matrix();
		float scale = newWidth * 1.0f / rawBitmap.getWidth();
		// float scaleHeight = ((float)newHeight) / height;
		matrix.postScale(scale, scale);
		// Bitmap result = Bitmap.createBitmap(target,0,0,width,height,
		// matrix,true);
		return Bitmap.createBitmap(rawBitmap, 0, 0, rawBitmap.getWidth(), rawBitmap.getHeight()
				, matrix, true);
	}

	/**
	 * 获取文件流的CRC32值
	 * @param stream
	 * @return
     */
	public static long getStreamCRC32(InputStream stream)
	{
		long lCode = 0;

		try
		{
			byte[] buffer = new byte[1024];
			CRC32 crc32 = new CRC32();
			int nRead = 0;
			while ((nRead = stream.read(buffer)) > 0)
			{
				crc32.update(buffer, 0, nRead);
			}

			lCode = crc32.getValue();
			stream.close();
		}
		catch(Exception e)
		{
			lCode = 0;
		}

		return lCode;
	}

	public static String getStringMD5(String strings)
	{
		StringBuilder szMD5Buf = new StringBuilder();
		try
		{
			MessageDigest digester = MessageDigest.getInstance("MD5");
			digester.update(strings.getBytes());

			byte[] md5Value = digester.digest();
			for (byte b : md5Value)
			{
				if ((b & 0xff) < 0x10)
				{
					szMD5Buf.append("0");
				}
				szMD5Buf.append(Long.toString(b & 0xff, 16));
			}
		}
		catch (Exception e)
		{
		}

		//Log.i(IConstants.TAG, "getStringMD5.strings: " + strings + ", md5:" + szMD5Buf.toString());
		return szMD5Buf.toString();
	}
	
	public static String getStringSHA1(String str) 
	{
		if (str == null || str.length() == 0) 
		{
			return null;
		}
		
		char hexDigits[] = { '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f' };
		
		try 
		{
			MessageDigest mdTemp = MessageDigest.getInstance("SHA1");
			mdTemp.update(str.getBytes());
			
			byte[] md = mdTemp.digest();
			int j = md.length;
			char buf[] = new char[j * 2];
			int k = 0;
			for (int i = 0; i < j; i++)
			{
				byte byte0 = md[i];
				buf[k++] = hexDigits[byte0 >>> 4 & 0xf];
				buf[k++] = hexDigits[byte0 & 0xf];
			}
			return new String(buf);
		} catch (Exception e) 
		{
			return null;
		}
	}

	/**
	 * 根据原始图片生成圆形图片
	 * @param bitmap
	 * @return
	 */
    public static Bitmap getCircleBitmap(Bitmap bitmap)
    {
        int width = bitmap.getWidth();
        int height = bitmap.getHeight();
        Bitmap output = Bitmap.createBitmap(width, height, Config.ARGB_8888);
        Canvas canvas = new Canvas(output);

        final int color = 0xff424242;
        final Paint paint = new Paint();
        final Rect rect = new Rect(0, 0, bitmap.getWidth(), bitmap.getHeight());
        final RectF rectF = new RectF(rect);
        // 按照大小来计算圆角比例
        float round = width / 2;
        // 按照大小来计算圆角比例
        final float roundPy = height / 2;
        if (roundPy < round)
        {
            round = roundPy;
        }
        
        paint.setAntiAlias(true);
        canvas.drawARGB(0, 0, 0, 0);
        paint.setColor(color);
        canvas.drawRoundRect(rectF, round, round, paint);

        paint.setXfermode(new PorterDuffXfermode(Mode.SRC_IN));
        canvas.drawBitmap(bitmap, rect, rect, paint);
        bitmap.recycle();
        
        return output;
    }
    
	/**
	 * 获取明天的0点钟
	 * @return
	 */
	public static long getTomorrowZero()
	{
		Calendar calender = Calendar.getInstance();
		calender.add(Calendar.DAY_OF_MONTH, 1);
		calender.set(Calendar.HOUR_OF_DAY, 0);
		calender.set(Calendar.MINUTE, 0);
		calender.set(Calendar.SECOND, 0);
		
		return calender.getTimeInMillis();
	}

	/**
	 * 获取文件大小的字符串形式
	 * @param size
	 * @return
     */
	public static String getFileSizeString(long size){
		String fileSize = "";
		if(size >= 1024 * 1024)
		{
			fileSize = String.format("%1$.02f MB", size / (1024 * 1024.0)); //[NSString stringWithFormat:@"%0.2f MB", size / (1024 * 1024.0)];
		}
		else if(size > 1024)
		{
			fileSize = String.format("%1$d KB", size / 1024); //[NSString stringWithFormat:@"%lld KB", size / 1024];
		}
		else
		{
			fileSize = size + " B";//[NSString stringWithFormat:@"%lld B", size];
		}

		return fileSize;
	}
	
	/**
	 * 获取今天的0点钟
	 * @return
	 */
	public static long getTodayZero()
	{
		Calendar calender = Calendar.getInstance();
		calender.set(Calendar.HOUR_OF_DAY, 0);
		calender.set(Calendar.MINUTE, 0);
		calender.set(Calendar.SECOND, 0);
		
		return calender.getTimeInMillis();
	}
	
	public void init(Context context)
	{
		try
		{
			mContext = context;
			PackageManager packMng = context.getPackageManager();
			PackageInfo packInfo = packMng.getPackageInfo(
			        context.getPackageName(), 0);
			mPackName = packInfo.packageName;
			mVersionCode = packInfo.versionCode;
			mVersionName = packInfo.versionName;

			Log.i(IConstants.TAG, "BMOB_CHANNEL:" + getAppMetaDataValue("BMOB_CHANNEL", "null")
				+ ", UMENG_CHANNEL:" + getAppMetaDataValue("UMENG_CHANNEL", "null"));

			//创建存储目录
			String savePath = getSdcardDir() + IConstants.SAVE_PATH;
			File filePath = new File(savePath);
			filePath.mkdirs();

			// imageLoader初始设置
			DisplayImageOptions options = new DisplayImageOptions.Builder()
					.imageScaleType(ImageScaleType.EXACTLY)
					.bitmapConfig(Bitmap.Config.RGB_565)
					.displayer(new SimpleBitmapDisplayer()).build();
			ImageLoaderConfiguration config = new ImageLoaderConfiguration.Builder(
			        context).threadPriority(Thread.NORM_PRIORITY - 2)
			        .memoryCache(new WeakMemoryCache())
			        .diskCacheFileNameGenerator(new Md5FileNameGenerator())
			        .tasksProcessingOrder(QueueProcessingType.LIFO)
			        .diskCacheFileCount(200)
					.diskCacheExtraOptions(200, 200, null) //设置缓存的每个文件的最大宽高,默认是屏幕宽高
					.defaultDisplayImageOptions(options)
			        // .writeDebugLogs() // Remove for release app
			        .build();
			// Initialize ImageLoader with configuration.
			ImageLoader.getInstance().init(config);
		}
		catch (Exception e)
		{
			e.printStackTrace();
		}
	}

	public Context getContext()
	{
		return mContext;
	}
	
	/**
	 * 发送短信
	 * @param message
	 */
	public void sendSMSMessage(String message, Activity activity)
	{
		try
		{
			Intent sendIntent = new Intent(Intent.ACTION_VIEW);
		    sendIntent.putExtra("sms_body", message);
		    sendIntent.setType("vnd.android-dir/mms-sms");
		    activity.startActivity(sendIntent);
		}
		catch(Exception e)
		{
			e.printStackTrace();
		}
	}
	
	/**
	 * 判断网络是否打开
	 * 
	 * @return
	 */
	public boolean isNetworkOpen()
	{
		ConnectivityManager connManager = (ConnectivityManager) mContext
		        .getSystemService(Context.CONNECTIVITY_SERVICE);
		NetworkInfo.State state = connManager.getNetworkInfo(
		        ConnectivityManager.TYPE_WIFI).getState();
		if (NetworkInfo.State.CONNECTED == state)
		{
			return true;
		}

		state = connManager.getNetworkInfo(ConnectivityManager.TYPE_MOBILE)
		        .getState();
		if (NetworkInfo.State.CONNECTED == state)
		{
			return true;
		}

		return false;
	}

	
	/**
	 * 根据字符串的id获取字符串值
	 * @param resourceId
	 * @return
	 */
	public static String getStringByResourceId(String resourceId)
	{
		String result = "";
		final int string_id = _GetObject().getContext().getResources().getIdentifier(
		        resourceId, "string", _GetObject().getMyPackName());
		if (0 != string_id)
		{
			result = _GetObject().getContext().getString(string_id);
		}
		
		return result;
	}
	
	/**
	 * 获取sd卡目录的名称
	 * @return
	 */
	public static String getSdcardDir() 
	{
        if (isStringEmpty(sSdCardPath) && Environment.getExternalStorageState().equalsIgnoreCase(
                Environment.MEDIA_MOUNTED)) 
        {  
            sSdCardPath = Environment.getExternalStorageDirectory().toString();
        }  
        return sSdCardPath;
    }     
	
	/**
	 * 获取本机mac地址
	 * @return
	 */
	public static String getLocalMacAddress() 
	{  
		String mac = "null_mac";
		try
		{
	        WifiManager wifi = (WifiManager)sKernelManager.mContext.getSystemService(Context.WIFI_SERVICE);  
	        WifiInfo info = wifi.getConnectionInfo(); 
	        mac = info.getMacAddress();
		}
		catch(Exception e)
		{}
        return mac;  
    }

	/**
	 * 获取application的metadata值
	 * 
	 * @param key
	 * @return
	 */
	public static String getAppMetaDataValue(String key, String defaultValue)
	{
		String result = defaultValue;
		try
		{
			ApplicationInfo appInfo = sKernelManager.mContext
			        .getPackageManager().getApplicationInfo(
			                sKernelManager.mPackName,
			                PackageManager.GET_META_DATA);
			result = appInfo.metaData.getString(key);
		}
		catch (Exception e)
		{
		}

		return result;
	}

	/**
	 * 获取application的metadata值
	 * 
	 * @param key
	 * @return
	 */
	public static boolean getAppMetaDataValue(String key, boolean defaultValue)
	{
		boolean result = defaultValue;
		try
		{
			ApplicationInfo appInfo = sKernelManager.mContext
			        .getPackageManager().getApplicationInfo(
			                sKernelManager.mPackName,
			                PackageManager.GET_META_DATA);
			result = appInfo.metaData.getBoolean(key);
		}
		catch (Exception e)
		{
		}

		return result;
	}

	/**
	 * 检查字符串是否为邮箱
	 * 
	 * @param strings
	 * @return
	 */
	public static boolean isEmail(String strings)
	{
		Pattern pattern = Pattern
		        .compile("^([a-zA-Z0-9_.-])+@([a-zA-Z0-9_-])+((\\.[a-zA-Z0-9_-]{2,3}){1,2})$");
		Matcher matcher = pattern.matcher(strings);
		return matcher.matches();
	}

	/**
	 * 检查手机号是否合法
	 * 
	 * @param strings
	 * @return
	 */
	public static boolean isPhoneNum(String strings)
	{
		Pattern pattern = Pattern.compile("^1(3|4|5|8)\\d{9}$");
		Matcher matcher = pattern.matcher(strings);
		return matcher.matches();
	}

	/**
	 * 设置当前activity是否全屏
	 * @param isFullScreen
	 */
	public static void fullScreen(boolean isFullScreen, Activity activity)
	{
		WindowManager.LayoutParams params = activity.getWindow().getAttributes();
		if(isFullScreen)
		{
			params.flags |= WindowManager.LayoutParams.FLAG_FULLSCREEN;
		}
		else
		{
			params.flags &= (~WindowManager.LayoutParams.FLAG_FULLSCREEN);
		}
		activity.getWindow().setAttributes(params);
		activity.getWindow().clearFlags(WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS);
	}

	public static String getFileNameByPath(String filePath)
	{
		if (isStringEmpty(filePath))
		{
			return "";
		}

		int index = filePath.lastIndexOf('/');
		if (index >= filePath.length() -1 || index <= 0)
		{
			return "";
		}
		return filePath.substring(index + 1);
	}

	/**
	 * 退出程序
	 */
	public void exitApp()
	{
		try
		{
			// 关闭网络及业务处理器
			if (null != mDatabaseHelper)
			{
				OpenHelperManager.releaseHelper();
				mDatabaseHelper = null;
			}
			channelGroup.close();
		}
		catch (Exception e)
		{
		}
		
		// 退出后台线程
		Process.killProcess(Process.myPid());
	}
	
	// 多线程安全
	public final DatabaseHelper getDatabaseHelper()
	{
		if (null == mDatabaseHelper)
		{
			mDatabaseHelper = OpenHelperManager.getHelper(mContext,
			        DatabaseHelper.class);
		}

		return mDatabaseHelper;
	}

	public String getMyPackName()
	{
		return mPackName;
	}

	public String getMyVersionName()
	{
		return mVersionName;
	}

	public int getMyVersionCode()
	{
		return mVersionCode;
	}

	/**
	 * 是否首次启动
	 * @return
	 */
	public boolean isFirstStart()
	{
		boolean result = true;
		SharedPreferences preference = KernelManager._GetObject().getContext()
				.getSharedPreferences(CONFIG_FILE, Context.MODE_PRIVATE);
		result = preference.getBoolean(IS_FIRTST_START, true);
		if(result)
		{
			preference.edit().putBoolean(IS_FIRTST_START, false).commit();
		}
		
		return result;
	}

}