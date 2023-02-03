package com.maimiao.psd_see.common;

import android.util.Log;

import com.maimiao.psd_see.IConstants;

public class LogTrace
{
	public final static String LOG_NAME = IConstants.TAG; //日志的名称
	private static LogTrace sObject = null;

	private LogTrace()
	{
		try
		{
		}
		catch(Exception e)
		{
			e.printStackTrace();
		}
	}
	
	private String getStackTrace()
	{
		StackTraceElement[] stacktraces = Thread.currentThread().getStackTrace();

		if (null == stacktraces)
		{
			return "";
		}

		for (StackTraceElement item : stacktraces)
		{
			if (item.isNativeMethod())
			{
				continue;
			}
			if (item.getClassName().equals(Thread.class.getName()))
			{
				continue;
			}

			if (!item.getClassName().equals(getClass().getName()))
			{
				return new StringBuilder().append("[ ").append(Thread.currentThread().getName()).append(": ")
				        .append(item.getFileName()).append("-").append(item.getMethodName()).append("-")
				        .append(item.getLineNumber()).append(" ]: ").toString();
			}
		}
		return "";
	}
	
	private static synchronized LogTrace _GetLogTrace()
	{
		if(null == sObject)
		{
			sObject = new LogTrace();
		}
		
		return sObject;
	}
	
	public static synchronized void log(String logInfo)
	{
		//_GetLogTrace().mLogger.info(_GetLogTrace().getStackTrace() + logInfo);
		Log.i(LOG_NAME, _GetLogTrace().getStackTrace() + logInfo);
	}
	
	public static synchronized void print(String logInfo)
	{
		Log.i(LOG_NAME, _GetLogTrace().getStackTrace() + logInfo);
	}
}
