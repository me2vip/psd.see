package com.maimiao.psd_see;


import android.app.Application;
import android.content.Context;
import android.support.multidex.MultiDex;
import android.util.Log;

import com.maimiao.psd_see.kernel.KernelManager;

public class MainApp extends Application
{	
	@Override
	protected void attachBaseContext(Context base) {
		super.attachBaseContext(base);
		final String packageName = base.getPackageName();
		MultiDex.install(this);
		Log.i(IConstants.TAG, "attachBaseContext.packgeName:" + packageName);
	}
	
	@Override
	public void onCreate()
	{
		super.onCreate();
		Log.i(IConstants.TAG, "==================START==================");
		KernelManager._GetObject().init(getApplicationContext());
		
		Log.i(IConstants.TAG, String.format("version_code:%d version_name:%s debug:%B"
				, KernelManager._GetObject().getMyVersionCode(), KernelManager._GetObject().getMyVersionName()
				, IConstants.DEBUG));
	}

}
