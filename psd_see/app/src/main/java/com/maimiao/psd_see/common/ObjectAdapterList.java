package com.maimiao.psd_see.common;

import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.BaseAdapter;

import com.maimiao.psd_see.listener.IAdapterObjectList;

import java.util.ArrayList;
import java.util.List;

public class ObjectAdapterList extends BaseAdapter
{
	private List<Object> mDatas = null;
	private IAdapterObjectList mAdapterListener = null;
	public final AdapterView<?> adapterView;

	public ObjectAdapterList(IAdapterObjectList hAdapterListener, AdapterView<?> adapterView)
	{
		// TODO Auto-generated constructor stub
		mDatas = new ArrayList<Object>();
		mAdapterListener = hAdapterListener;
		this.adapterView = adapterView;
	}

	@Override
	public View getView(int position, View convertView, ViewGroup parent)
	{
		// TODO Auto-generated method stub
		return mAdapterListener.onItemChanged(position, convertView, parent, this);
	}
	
	@Override
	public int getItemViewType(int position)
	{
		return mAdapterListener.onAdapterItemViewType(position, this);
	}

	@Override
	public int getCount()
	{
		// TODO Auto-generated method stub
		return mDatas.size();
	}

	@Override
	public Object getItem(int position)
	{
		// TODO Auto-generated method stub
		return mDatas.get(position);
	}

	@Override
	public int getViewTypeCount()
	{
		return 500;
	}

	/**
	 * 添加一个节点
	 * 
	 * @param item
	 */
	public void addItem(Object item)
	{
		mDatas.add(item);
		// notifyDataSetChanged();
	}

	public void setDataList(List<Object> dataList)
	{
		mDatas = dataList;
	}

	public void addItem(int nIndex, Object item)
	{
		mDatas.add(nIndex, item);
	}
	
	public void addList(List<Object> list)
	{
		mDatas.addAll(list);
	}

	/**
	 * 清空整个列表
	 */
	public void removeAll()
	{
		mDatas.clear();
	}

	/**
	 * 删除某个节点
	 * 
	 * @param nIndex
	 */
	public void removeItem(int nIndex)
	{
		mDatas.remove(nIndex);
	}

	public void removeItem(Object item)
	{
		mDatas.remove(item);
	}

	public final List<Object> getDataList()
	{
		return mDatas;
	}

	@Override
    public long getItemId(int arg0)
    {
	    // TODO Auto-generated method stub
	    return 0;
    }
}
