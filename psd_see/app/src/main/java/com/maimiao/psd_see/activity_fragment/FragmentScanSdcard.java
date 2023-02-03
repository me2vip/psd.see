package com.maimiao.psd_see.activity_fragment;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.os.AsyncTask;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AbsListView;
import android.widget.AdapterView;
import android.widget.GridView;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;

import com.google.android.gms.ads.AdRequest;
import com.google.android.gms.ads.AdView;
import com.maimiao.psd_see.IConstants;
import com.maimiao.psd_see.R;
import com.maimiao.psd_see.common.BaseFragment;
import com.maimiao.psd_see.common.LogTrace;
import com.maimiao.psd_see.common.ObjectAdapterList;
import com.maimiao.psd_see.kernel.DataModel;
import com.maimiao.psd_see.kernel.KernelManager;
import com.maimiao.psd_see.listener.IAdapterObjectList;
import com.nostra13.universalimageloader.core.DisplayImageOptions;
import com.nostra13.universalimageloader.core.ImageLoader;
import com.nostra13.universalimageloader.core.assist.ImageScaleType;

import java.io.File;
import java.util.LinkedList;
import java.util.List;

/**
 * Created by larry on 17/1/18.
 */

public class FragmentScanSdcard extends BaseFragment implements View.OnClickListener
        , IAdapterObjectList, AdapterView.OnItemClickListener, AbsListView.OnScrollListener {
    private final int ITEM_FILE = 0; //文件节点
    private final int ITEM_LAST = 1; //最后的空白节点

    private View mRootView;
    private DisplayImageOptions mImageOptions;
    private volatile boolean mWillExit; //是否退出
    private IFileSelected mFileSelectedListen;
    private int mPageIndex = 0;
    private int mTotalPage = 1; //总页数
    private boolean mRefreshing; //是否正在刷新
    private boolean mScrollTop = false; //是否滑动到顶部
    private boolean mScrollBottom = false; //是否滑动到底部

    public  static interface IFileSelected{
        public void onSelectedFile(DataModel.FileItemEx fileItem);
    }

    public static Fragment create(IFileSelected fileSelected){
        FragmentScanSdcard fragmentScanSdcard = new FragmentScanSdcard();
        fragmentScanSdcard.mFileSelectedListen = fileSelected;

        return fragmentScanSdcard;
    }

    @Override
    public void onClick(View v) {
        if (R.id.ID_BTN_REFRESH == v.getId()){
            //刷新
            scanSDCard();
        }
    }

    @Override
    public View onItemChanged(int position, View convertView, ViewGroup parent, ObjectAdapterList adapter) {
        try {
            Object objItem = adapter.getItem(position);
            if (objItem instanceof DataModel.SDCardFileItemEx)
            {
                if (null == convertView) {
                    convertView = LayoutInflater.from(getActivity()).inflate(
                            R.layout.item_sdcard_file, null, false);
                }
                setFileItem(convertView, (DataModel.SDCardFileItemEx)objItem);
            }
            else if (objItem instanceof DataModel.ListItem)
            {
                if (null == convertView) {
                    convertView = LayoutInflater.from(getActivity()).inflate(
                            R.layout.item_last_blank, null, false);
                }
                View contentView = convertView.findViewById(R.id.ID_CONTENT_VIEW);
                ViewGroup.LayoutParams layout = contentView.getLayoutParams();
                //Log.i(IConstants.TAG, "******w:" + layout.width + ", h:" + layout.height);

                if (0 != position % 2)
                {
                    layout.height = getResources().getDimensionPixelSize(R.dimen.height_grid_last);
                }
                else
                {
                    layout.height = getResources().getDimensionPixelSize(R.dimen.blank_normal_height);
                }
                contentView.setLayoutParams(layout);
            }
        }
        catch (Exception e)
        {
            //LogTrace.log("exp:" + KernelManager.getFileNameByPath(fileItem.filePath));
            e.printStackTrace();
        }
        return convertView;
    }

    @Override
    public int onAdapterItemViewType(int position, ObjectAdapterList adapter) {
        Object objItem = (Object)(adapter.getItem(position));
        if (objItem instanceof DataModel.ListItem)
        {
            return ITEM_LAST;
        }
        return ITEM_FILE;
    }

    @Override
    public long onAdapterItemId(int position, ObjectAdapterList adapter) {
        return 0;
    }

    @Override
    public void onItemClick(AdapterView<?> parent, View view, int position, long id) {
        ObjectAdapterList adapterList = (ObjectAdapterList)(parent.getAdapter());
        Object objItem = adapterList.getItem(position);
        if (objItem instanceof DataModel.ListItem)
        {
            return;
        }
        DataModel.SDCardFileItemEx sdFileItem = (DataModel.SDCardFileItemEx)(objItem);
        String lowFilePath = sdFileItem.filePath.toLowerCase();
        LogTrace.log("filePath:" + sdFileItem.filePath);
        File file = new File(sdFileItem.filePath);

        if (false == file.exists()) {
            //文件不存在
            DataModel.SDCardFileItemEx.delete(sdFileItem);
            adapterList.removeItem(position);
            adapterList.notifyDataSetChanged();

            Toast.makeText(getActivity(), R.string.file_error, Toast.LENGTH_SHORT).show();
            return;
        }

        DataModel.FileItemEx fileItem = new DataModel.FileItemEx();
        fileItem.fileSize = file.length();
        fileItem.filePath = sdFileItem.filePath;
        fileItem.height = sdFileItem.height;
        fileItem.width = sdFileItem.width;
        fileItem.psdColorMode = -1;

        mFileSelectedListen.onSelectedFile(fileItem);
        //显示该文件
        getFragmentManager().beginTransaction().add(R.id.container
                , FragmentPSDDrawView.create(fileItem))
                .addToBackStack(IConstants.FRAGMENT_MAIN_THREAD).commit();
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        mRootView = inflater.inflate(R.layout.fragment_scan_sdcard, container, false);
        mRootView.findViewById(R.id.ID_BTN_REFRESH).setOnClickListener(this);

        mImageOptions = new DisplayImageOptions.Builder()
                .showImageOnLoading(R.mipmap.default_image)
                .showImageForEmptyUri(R.mipmap.default_image)
                .showImageOnFail(R.mipmap.default_image).cacheInMemory(true)
                .bitmapConfig(Bitmap.Config.RGB_565)
                .imageScaleType(ImageScaleType.EXACTLY).build();
        mWillExit = false;
        mRefreshing = false;
        mScrollTop = false;

        GridView gridView = (GridView)(mRootView.findViewById(R.id.ID_GRID_VIEW));
        ObjectAdapterList adapterList = new ObjectAdapterList(this, gridView);
        gridView.setAdapter(adapterList);
        gridView.setOnItemClickListener(this);
        gridView.setOnScrollListener(this);

        //处理广告
        // Gets the ad view defined in layout/ad_fragment.xml with ad unit ID set in
        // values/strings.xml.
        AdView adView = (AdView) (mRootView.findViewById(R.id.ID_AD_VIEW));
        // Create an ad request. Check your logcat output for the hashed device ID to
        // get test ads on a physical device. e.g.
        // "Use AdRequest.Builder.addTestDevice("ABCDEF012345") to get test ads on this device."
        AdRequest adRequest = new AdRequest.Builder()
                .addTestDevice("42491D5B367196505D015CC00EEE0263")
                .addTestDevice("2D7EE1868002F161C8E9696732AE8379")
                .addTestDevice("9AA4A76DA7F07F520E249F107053CF29")
                .build();
        // Start loading the ad in the background.
        adView.loadAd(adRequest);

        List<?> fileList = DataModel.SDCardFileItemEx.getFileList(mPageIndex);
        if (null == fileList || 0 == fileList.size()) {
            //扫描sdcard
            scanSDCard();
        }
        else {
            //直接显示列表
            adapterList.addList((List<Object>) fileList);
            adapterList.addItem(new DataModel.ListItem(ITEM_LAST, 0));
            if (0 == adapterList.getCount() % 2)
            {
                adapterList.addItem(new DataModel.ListItem(ITEM_LAST, 0));
            }
            final int ALL_COUNT = (int)(DataModel.SDCardFileItemEx.getFileCount());
            mTotalPage = (int)(ALL_COUNT / DataModel.SDCardFileItemEx.PAGE_SIZE);
            mTotalPage += (0 == ALL_COUNT % DataModel.SDCardFileItemEx.PAGE_SIZE ? 0 : 1);

            mRootView.findViewById(R.id.ID_BTN_REFRESH).setVisibility(View.VISIBLE);
            mRootView.findViewById(R.id.ID_PRGRSS_LOADING).setVisibility(View.GONE);
            TextView textView = (TextView)(mRootView.findViewById(R.id.ID_TXT_PAGE));
            textView.setText("1/" + mTotalPage);
        }

        return mRootView;
    }

    /**
     * 处理文件
     */
    private DataModel.SDCardFileItemEx dealFile(String filePath){
        DataModel.SDCardFileItemEx fileItem = null;
        try{
            String lowPath = filePath.toLowerCase();
            /**
            if (lowPath.endsWith(".psd")){
                //处理psd文件
                fileItem = dealPsdFile(filePath);
                fileItem.fileType = "PSD";
            }
            else **/
            if (lowPath.endsWith(".png") || lowPath.endsWith(".jpg")
                    || lowPath.endsWith(".jpeg") || lowPath.endsWith(".gif")
                    || lowPath.endsWith(".bmp")){
                //其他格式的文件，检查是否为图片
                BitmapFactory.Options opts = new BitmapFactory.Options();
                opts.inJustDecodeBounds = true;
                BitmapFactory.decodeFile(filePath, opts);
                if (opts.outWidth > 0 && opts.outHeight > 0) {
                    File file = new File(filePath);
                    fileItem = new DataModel.SDCardFileItemEx();
                    fileItem.filePath = filePath;
                    fileItem.fileType = opts.outMimeType.toUpperCase();
                    fileItem.fileSize = file.length();
                    fileItem.height = opts.outHeight;
                    fileItem.width = opts.outWidth;
                    /**
                    fileItem.fileInfo = new StringBuilder()
                            .append(opts.outWidth).append('*').append(opts.outHeight)
                            .append('-')
                            .append(KernelManager.getFileSizeString(file.length()))
                            .toString();
                    **/
                }
            }
        }
        catch (Exception e){
            fileItem = null;
            e.printStackTrace();
        }
        return fileItem;
    }

    private void setFileItem(View convertView, DataModel.SDCardFileItemEx fileItem)
    {
        ImageView imageView = (ImageView) (convertView.findViewById(R.id.ID_IMAGE));
        ImageLoader.getInstance().displayImage("file://" + fileItem.filePath, imageView, mImageOptions);

        TextView txtView = (TextView) (convertView.findViewById(R.id.ID_TXT_NAME));
        txtView.setText(KernelManager.getFileNameByPath(fileItem.filePath));

        txtView = (TextView) (convertView.findViewById(R.id.ID_TXT_TYPE));
        txtView.setText(fileItem.fileType);
    }

    @Override
    public void onDestroyView() {
        mWillExit = true;
        super.onDestroyView();
    }

    /**
     * 开始扫描sd卡
     */
    private void scanSDCard()
    {
        mRootView.findViewById(R.id.ID_BTN_REFRESH).setVisibility(View.GONE);
        mRootView.findViewById(R.id.ID_PRGRSS_LOADING).setVisibility(View.VISIBLE);
        mRefreshing = true;
        TextView textView = (TextView)(mRootView.findViewById(R.id.ID_TXT_PAGE));
        textView.setText("1/1");

        //先清除显示列表
        GridView gridView = (GridView)(mRootView.findViewById(R.id.ID_GRID_VIEW));
        ObjectAdapterList adapterList = (ObjectAdapterList)(gridView.getAdapter());
        adapterList.removeAll();
        adapterList.notifyDataSetChanged();

        DataModel.SDCardFileItemEx.removeAll(); //删除所有数据

        new AsyncTask<Void, Object, Void>() {
            @Override
            protected Void doInBackground(Void ... param) {
                try {
                    File sdcard = new File(KernelManager.getSdcardDir());
                    if (false == sdcard.exists()) {
                        //sd卡不存在
                        return null;
                    }
                    int itemIndex = 1;
                    String myPath = IConstants.SAVE_PATH.substring(1, IConstants.SAVE_PATH.length() -1);
                    myPath = myPath.toLowerCase();
                    LinkedList<File> listDir = new LinkedList<File>();
                    listDir.add(sdcard);

                    File tempFile = null;
                    File[] files = null;
                    while (false == listDir.isEmpty() && false == mWillExit){
                        tempFile = listDir.removeFirst();
                        if (tempFile.getAbsolutePath().toLowerCase().contains(myPath)){
                            continue; //受保护目录不能访问
                        }
                        files = tempFile.listFiles();
                        if (null == files){
                            continue;
                        }

                        //publishProgress(tempFile.getAbsolutePath());

                        for (File item : files){
                            if (mWillExit){
                                return null; //界面已退出无需再次扫描
                            }

                            if (item.isDirectory()){
                                listDir.add(item); //是一个目录
                            }
                            else{
                                //处理文件
                                DataModel.SDCardFileItemEx fileItem =
                                        dealFile(item.getAbsolutePath());
                                if (null != fileItem){
                                    fileItem.itemIndex = itemIndex++;
                                    fileItem.save();
                                    if (fileItem.itemIndex <= DataModel.SDCardFileItemEx.PAGE_SIZE) {
                                        //刷新时只显示第一页数据
                                        //Log.i(IConstants.TAG, "****" + fileItem.itemIndex);
                                        publishProgress(fileItem);
                                    }
                                    else if (0 == fileItem.itemIndex
                                            % DataModel.SDCardFileItemEx.PAGE_SIZE)
                                    {
                                        publishProgress(fileItem.itemIndex);
                                    }
                                }
                            }
                        }
                    }
                }
                catch (Exception e){
                    e.printStackTrace();
                }
                return null;
            }

            @Override
            protected void onProgressUpdate(Object ... values) {
                if (values[0] instanceof DataModel.SDCardFileItemEx) {
                    GridView gridView = (GridView) (mRootView.findViewById(R.id.ID_GRID_VIEW));
                    ObjectAdapterList adapterList = (ObjectAdapterList) (gridView.getAdapter());
                    adapterList.addItem(values[0]);
                    adapterList.notifyDataSetChanged();
                }else if (values[0] instanceof Integer){
                    TextView textView = (TextView)(mRootView.findViewById(R.id.ID_TXT_PAGE));
                    final int findCount = (int)(values[0]);
                    textView.setText("1/" + (findCount / DataModel.SDCardFileItemEx.PAGE_SIZE));
                }
            }

            @Override
            protected void onPostExecute(Void aVoid) {
                //所有数据已处理完成
                mRootView.findViewById(R.id.ID_BTN_REFRESH).setVisibility(View.VISIBLE);
                mRootView.findViewById(R.id.ID_PRGRSS_LOADING).setVisibility(View.GONE);
                mRefreshing = false;

                final int ALL_COUNT = (int)(DataModel.SDCardFileItemEx.getFileCount());
                mTotalPage = (int)(ALL_COUNT / DataModel.SDCardFileItemEx.PAGE_SIZE);
                mTotalPage += (0 == ALL_COUNT % DataModel.SDCardFileItemEx.PAGE_SIZE ? 0 : 1);

                TextView textView = (TextView)(mRootView.findViewById(R.id.ID_TXT_PAGE));
                textView.setText("1/" + mTotalPage);
            }
        }.execute();
    }

    /**
     * 翻页
     */
    private void gotoPage(AbsListView view)
    {
        ObjectAdapterList adapterList = (ObjectAdapterList)(view.getAdapter());
        adapterList.removeAll();
        mScrollBottom = false;
        mScrollTop = false;

        TextView txtView = (TextView)(mRootView.findViewById(R.id.ID_TXT_PAGE));
        List<?> fileList = DataModel.SDCardFileItemEx.getFileList(mPageIndex);
        adapterList.addList((List<Object>) fileList);
        adapterList.addItem(new DataModel.ListItem(ITEM_LAST, 0));
        if (0 == adapterList.getCount() % 2)
        {
            adapterList.addItem(new DataModel.ListItem(ITEM_LAST, 0));
        }
        adapterList.notifyDataSetChanged();

        mRootView.postDelayed(new Runnable() {
            @Override
            public void run() {
                GridView gridView = (GridView)(mRootView.findViewById(R.id.ID_GRID_VIEW));
                gridView.setSelection(gridView.getCount() / 2);
            }
        }, 200);
        //Log.i(IConstants.TAG, "****count:" + adapterList.getCount());

        txtView.setText((mPageIndex + 1) + "/" + mTotalPage);
    }

    @Override
    public void onScrollStateChanged(AbsListView view, int scrollState)
    {
        if (AbsListView.OnScrollListener.SCROLL_STATE_IDLE == scrollState && false == mRefreshing)
        {
            //Log.i(IConstants.TAG, "****:" + view.getLastVisiblePosition() + ",:" + view.getCount());
            if (0 == view.getFirstVisiblePosition())
            {
                //滑动到顶部
                if (mPageIndex <= 0)
                {
                    return;
                }
                if (false == mScrollTop)
                {
                    mScrollTop = true;
                    Toast.makeText(getActivity(), R.string.scroll_page, Toast.LENGTH_SHORT).show();
                    mRootView.postDelayed(new Runnable() {
                        @Override
                        public void run() {
                            mScrollTop = false;
                        }
                    }, 800);
                }
                else
                {
                    mPageIndex--;
                    gotoPage(view);
                }
            }
            else if (view.getLastVisiblePosition() == (view.getCount() -1))
            {
                //滑动到底部
                if (mPageIndex >= mTotalPage -1)
                {
                    return;
                }

                if (false == mScrollBottom)
                {
                    mScrollBottom = true;
                    Toast.makeText(getActivity(), R.string.scroll_page, Toast.LENGTH_SHORT).show();
                    mRootView.postDelayed(new Runnable() {
                        @Override
                        public void run() {
                            mScrollBottom = false;
                        }
                    }, 800);
                }
                else
                {
                    mPageIndex++;
                    gotoPage(view);
                }
            }
        }
    }

    @Override
    public void onScroll(AbsListView view, int firstVisibleItem, int visibleItemCount, int totalItemCount)
    {
    }
}
