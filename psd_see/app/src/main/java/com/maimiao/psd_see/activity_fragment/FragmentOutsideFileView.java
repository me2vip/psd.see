package com.maimiao.psd_see.activity_fragment;

import android.content.pm.ActivityInfo;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.os.AsyncTask;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;
import android.widget.Toast;

import com.maimiao.psd_see.IConstants;
import com.maimiao.psd_see.R;
import com.maimiao.psd_see.common.BaseFragment;
import com.maimiao.psd_see.common.LogTrace;
import com.maimiao.psd_see.common.PSDReaderEx;
import com.maimiao.psd_see.kernel.DataModel;
import com.maimiao.psd_see.kernel.KernelException;
import com.maimiao.psd_see.kernel.KernelManager;
import com.maimiao.psd_see.views.PSDDrawView;

import java.io.File;
import java.io.FileOutputStream;

/**
 * Created by larry on 17/1/16.
 */

public class FragmentOutsideFileView extends BaseFragment implements View.OnClickListener {
    private View mRootView;
    private Bitmap mBitmap;
    private String mFilePath;

    public static Fragment create(String filePath){
        FragmentOutsideFileView fragment = new FragmentOutsideFileView();
        fragment.mFilePath = filePath;

        return fragment;
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        mRootView = inflater.inflate(R.layout.fragment_psd_draw_view, container, false);

        try {
            dealLeftButton(); //处理返回按钮是否显示
            KernelManager.fullScreen(true, getActivity());

            getActivity().setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_SENSOR); //根据重力感应自动切换屏幕方向

            mRootView.findViewById(R.id.ID_LAYOUT_BOTTOM).setVisibility(View.GONE);
            mRootView.findViewById(R.id.ID_VIEW_DRAW).setOnClickListener(this);
            mRootView.findViewById(R.id.ID_BTN_FULLSCREEN).setOnClickListener(this);
            mRootView.findViewById(R.id.ID_BTN_RESTORE).setOnClickListener(this);

            TextView txtView = (TextView) (mRootView.findViewById(R.id.ID_TXT_TITLE));
            txtView.setText(KernelManager.getFileNameByPath(mFilePath));

            if (mFilePath.contains(IConstants.SAVE_PATH)) {
                //内置目录不能访问
                Toast.makeText(getActivity(), R.string.private_dir, Toast.LENGTH_LONG).show();
            } else {
                showImage();
            }
        } catch (Exception e) {
            e.printStackTrace();
            Toast.makeText(getActivity(), R.string.open_file_fail, Toast.LENGTH_LONG).show();
        }
        return mRootView;
    }

    private void dealLeftButton(){
        mRootView.postDelayed(new Runnable() {
            @Override
            public void run() {
                if (getFragmentManager().getBackStackEntryCount() > 0){
                    mRootView.findViewById(R.id.ID_BTN_LEFT).setVisibility(View.VISIBLE);
                }
                else{
                    mRootView.findViewById(R.id.ID_BTN_LEFT).setVisibility(View.GONE);
                }
            }
        }, 100);
    }

    /**
     * 处理图片文件
     */
    private void dealImageFile(){
        final int SCREEN_W = mRootView.getWidth();
        final int SCREEN_H = mRootView.getHeight();

        BitmapFactory.Options options = new BitmapFactory.Options();
        options.inJustDecodeBounds = true;

        BitmapFactory.decodeFile(mFilePath, options); //获取图片的宽度和高度
        options.inJustDecodeBounds = false;
        if (options.outWidth > SCREEN_W) {
            options.inSampleSize = options.outWidth / SCREEN_W;
        }

        if (options.outHeight / SCREEN_H > options.inSampleSize){
            options.inSampleSize = options.outHeight / SCREEN_H;
        }
        LogTrace.log("width:" + options.outWidth + ", height:" + options.outHeight
            + ", inSampleSize:" + options.inSampleSize + ", outMimeType:" + options.outMimeType);

        final int IMAGE_WIDTH = options.outWidth;
        final int IMAGE_HEIGHT = options.outHeight;

        mBitmap = BitmapFactory.decodeFile(mFilePath, options);

        if (null == mBitmap){
            Toast.makeText(getActivity(), getString(R.string.file_error)
                    , Toast.LENGTH_SHORT).show();
        } else {
            if (false == DataModel.FileItemEx.isFileIn(mFilePath)) {
                File file = new File(mFilePath);
                DataModel.FileItemEx fileItem = new DataModel.FileItemEx();
                fileItem.filePath = mFilePath;
                /**
                fileItem.fileInfo = new StringBuilder()
                        .append(IMAGE_WIDTH).append('*').append(IMAGE_HEIGHT)
                        .append('-')
                        .append(KernelManager.getFileSizeString(file.length()))
                        .toString();
                **/
                fileItem.psdColorMode = -1;
                fileItem.height = IMAGE_HEIGHT;
                fileItem.width = IMAGE_WIDTH;
                fileItem.fileSize = file.length();
                fileItem.save();
            }

            PSDDrawView psdView = (PSDDrawView) (mRootView.findViewById(R.id.ID_VIEW_DRAW));
            psdView.setBitmap(mBitmap);
        }
    }

    /**
     * 显示psd文件
     * @param fileItem
     */
    private void showPsdFile(DataModel.FileItemEx fileItem){
        final int SCREEN_W = mRootView.getWidth();
        final int SCREEN_H = mRootView.getHeight();

        String imgFilePath = KernelManager.getSdcardDir()
                + IConstants.SAVE_PATH + KernelManager.getStringMD5(fileItem.filePath);

        BitmapFactory.Options options = new BitmapFactory.Options();
        options.inJustDecodeBounds = true;

        BitmapFactory.decodeFile(imgFilePath, options); //获取图片的宽度和高度
        options.inJustDecodeBounds = false;
        if (options.outWidth > SCREEN_W) {
            options.inSampleSize = options.outWidth / SCREEN_W;
        }

        if (options.outHeight / SCREEN_H > options.inSampleSize){
            options.inSampleSize = options.outHeight / SCREEN_H;
        }

        mBitmap = BitmapFactory.decodeFile(imgFilePath, options);

        if (null == mBitmap){
            Toast.makeText(getActivity(), getString(R.string.file_error)
                    , Toast.LENGTH_SHORT).show();
        }
        else {
            PSDDrawView psdView = (PSDDrawView) (mRootView.findViewById(R.id.ID_VIEW_DRAW));
            psdView.setBitmap(mBitmap);
        }
    }

    /**
     * 处理psd文件
     */
    private void dealPsdFile(){
        DataModel.FileItemEx fileItem = DataModel.FileItemEx.getFileByPath(mFilePath);
        if (null != fileItem){
            //文件在数据库中已存在
            showPsdFile(fileItem);
            mRootView.findViewById(R.id.ID_PRGRSS_LOADING).setVisibility(View.GONE);
            return;
        }

        new AsyncTask<String, Void, Object>(){
            @Override
            protected Object doInBackground(String... params) {
                Object resObj = null;
                try{
                    DataModel.FileItemEx fileItem = new DataModel.FileItemEx();
                    fileItem.filePath = params[0];
                    String imgFilePath = KernelManager.getSdcardDir()
                            + IConstants.SAVE_PATH + KernelManager.getStringMD5(fileItem.filePath);

                    dealPsdFile(fileItem);
                    fileItem.save();
                }
                catch (KernelException e) {
                    resObj = e;
                }
                catch (Exception e){
                    resObj = e;
                    e.printStackTrace();
                }
                return resObj;
            }

            @Override
            protected void onPostExecute(Object objResult) {
                if (objResult instanceof DataModel.FileItemEx){
                    showPsdFile((DataModel.FileItemEx)objResult);
                }
                else if (objResult instanceof KernelException) {
                    KernelException exception = (KernelException)objResult;
                    Toast.makeText(getActivity(), exception.getMessage()
                            , Toast.LENGTH_SHORT).show();
                }
                else{
                    Toast.makeText(getActivity(), R.string.file_error, Toast.LENGTH_SHORT).show();
                }

                mRootView.findViewById(R.id.ID_PRGRSS_LOADING).setVisibility(View.GONE);
            }
        }.execute(mFilePath);
    }

    /**
     * 处理psd文件
     * @param fileItem
     */
    private void dealPsdFile(DataModel.FileItemEx fileItem) throws Exception {
        String psdPath = fileItem.filePath;
        boolean needCreateImage = false;

        String imgFilePath = KernelManager.getSdcardDir()
                + IConstants.SAVE_PATH + KernelManager.getStringMD5(psdPath);

        File file = new File(imgFilePath);
        if (false == file.exists() || fileItem.width <= 0 || fileItem.height <= 0
                || fileItem.fileSize <= 0) {
            //对应的图片文件不存在，需要生成
            needCreateImage = true;
        }

        if (needCreateImage){
            PSDReaderEx psdReader = new PSDReaderEx(); // new PSDReaderEx(psdPath);
            Bitmap bitmap = psdReader.getImage(psdPath);
            FileOutputStream writeStream = new FileOutputStream(imgFilePath, false);
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, writeStream);
            writeStream.flush();
            writeStream.close();
            bitmap.recycle();
            bitmap = null;

            fileItem.fileSize = psdReader.getFileSize();
            fileItem.height = psdReader.getHeight();
            fileItem.width = psdReader.getWidth();
            fileItem.psdColorMode = psdReader.getColorMode();

            psdReader = null;
        }
    }

    private void showImage(){
        mRootView.findViewById(R.id.ID_PRGRSS_LOADING).setVisibility(View.VISIBLE);

        mRootView.postDelayed(new Runnable() {
            @Override
            public void run() {
                try {
                    if (mFilePath.toLowerCase().endsWith(".psd")){
                        //psd文件
                        dealPsdFile();
                    }
                    else {
                        //图片文件
                        dealImageFile();
                        mRootView.findViewById(R.id.ID_PRGRSS_LOADING).setVisibility(View.GONE);
                    }
                }
                catch (Exception e){
                    e.printStackTrace();
                }
            }
        }, 500);
    }

    @Override
    public void onDestroyView()
    {
        super.onDestroyView();

        PSDDrawView psdView = (PSDDrawView)(mRootView.findViewById(R.id.ID_VIEW_DRAW));
        psdView.destroy();
        if (null != mBitmap && false == mBitmap.isRecycled()){
            mBitmap.recycle();
        }

        mBitmap = null;
        KernelManager.fullScreen(false, getActivity());
        getActivity().setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_PORTRAIT);
    }

    @Override
    public void onClick(View v) {
        if (R.id.ID_VIEW_DRAW == v.getId()){
            //显示或隐藏标题栏和底部工具栏
            final int visiable = mRootView.findViewById(R.id.ID_LAYOUT_TITLE).getVisibility();
            if (View.VISIBLE == visiable){
                mRootView.findViewById(R.id.ID_LAYOUT_TITLE).setVisibility(View.GONE);
                mRootView.findViewById(R.id.ID_LAYOUT_BOTTOM).setVisibility(View.GONE);
            }
            else{
                mRootView.findViewById(R.id.ID_LAYOUT_TITLE).setVisibility(View.VISIBLE);
                mRootView.findViewById(R.id.ID_LAYOUT_BOTTOM).setVisibility(View.VISIBLE);
            }
        }
        else if (R.id.ID_BTN_FULLSCREEN == v.getId()){
            mRootView.findViewById(R.id.ID_LAYOUT_TITLE).setVisibility(View.GONE);
            mRootView.findViewById(R.id.ID_LAYOUT_BOTTOM).setVisibility(View.GONE);
            PSDDrawView psdView = (PSDDrawView)(mRootView.findViewById(R.id.ID_VIEW_DRAW));
            psdView.fullScreen(true);
        }
        else if (R.id.ID_BTN_RESTORE == v.getId()){
            mRootView.findViewById(R.id.ID_LAYOUT_TITLE).setVisibility(View.GONE);
            mRootView.findViewById(R.id.ID_LAYOUT_BOTTOM).setVisibility(View.GONE);
            PSDDrawView psdView = (PSDDrawView)(mRootView.findViewById(R.id.ID_VIEW_DRAW));
            psdView.fullScreen(false);
        }
    }
}
