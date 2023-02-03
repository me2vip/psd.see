package com.maimiao.psd_see.listener;


import android.view.View;
import android.view.ViewGroup;

import com.maimiao.psd_see.common.ObjectAdapterList;

public interface IAdapterObjectList
{
	View onItemChanged(int position, View convertView, ViewGroup parent, ObjectAdapterList adapter);
	int onAdapterItemViewType (int position, ObjectAdapterList adapter);
	long onAdapterItemId(int position, ObjectAdapterList adapter);
}
