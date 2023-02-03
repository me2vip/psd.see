package com.maimiao.psd_see.kernel;


import android.content.Context;
import android.database.sqlite.SQLiteDatabase;

import com.j256.ormlite.android.apptools.OrmLiteSqliteOpenHelper;
import com.j256.ormlite.support.ConnectionSource;
import com.j256.ormlite.table.TableUtils;
import com.maimiao.psd_see.common.LogTrace;

public class DatabaseHelper extends OrmLiteSqliteOpenHelper
{
	// name of the database file for your application -- change to something
	// appropriate for your app
	private static final String DATABASE_NAME = "psd_see.db";
	// any time you make changes to your database objects, you may have to
	// increase the database version
	private static final int DATABASE_VERSION = 4;

	public DatabaseHelper(Context context)
	{
		super(context, DATABASE_NAME, null, DATABASE_VERSION);
		LogTrace.log("db_version:" + DATABASE_VERSION);
	}

	@Override
	public void onCreate(SQLiteDatabase arg0, ConnectionSource connectionSource)
	{
		// TODO Auto-generated method stub
		LogTrace.log("create tables...");

		try{
			TableUtils.createTableIfNotExists(connectionSource, DataModel.FileItemEx.class);
			TableUtils.createTableIfNotExists(connectionSource, DataModel.SDCardFileItemEx.class);
			TableUtils.createTableIfNotExists(connectionSource, DataModel.ServerInfo.class);
		}
		catch (Exception e){
			LogTrace.log(e.getMessage());
			e.printStackTrace();
		}
	}

	@Override
	public void onUpgrade(SQLiteDatabase db, ConnectionSource connectionSource
			, int oldVersion, int newVersion)
	{
		// TODO Auto-generated method stub
		LogTrace.log("upgrade tables...");
		onCreate(db, connectionSource);
	}


	/**
	 * Close the database connections and clear any cached DAOs.
	 */
	@Override
	public void close()
	{
		super.close();
	}
}
