package com.maimiao.psd_see.activity_fragment;

import android.content.pm.ActivityInfo;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
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
import com.maimiao.psd_see.kernel.DataModel;
import com.maimiao.psd_see.kernel.KernelManager;
import com.maimiao.psd_see.views.PSDDrawView;

/**
 * Created by larry on 17/1/16.
 */

public class FragmentPSDDrawView extends BaseFragment implements View.OnClickListener {
    private View mRootView;
    private DataModel.FileItemEx mFileItem;
    private Bitmap mBitmap;

    public static Fragment create(DataModel.FileItemEx fileItem){
        FragmentPSDDrawView fragment = new FragmentPSDDrawView();
        fragment.mFileItem = fileItem;

        return fragment;
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        mRootView = inflater.inflate(R.layout.fragment_psd_draw_view, container, false);

        try {
            getActivity().setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_SENSOR); //根据重力感应自动切换屏幕方向
            KernelManager.fullScreen(true, getActivity());
            showImage();

            mRootView.findViewById(R.id.ID_PRGRSS_LOADING).setVisibility(View.GONE);
            mRootView.findViewById(R.id.ID_LAYOUT_BOTTOM).setVisibility(View.GONE);
            mRootView.findViewById(R.id.ID_LAYOUT_TITLE).setVisibility(View.GONE);
            mRootView.findViewById(R.id.ID_BTN_LEFT).setVisibility(View.VISIBLE);

            mRootView.findViewById(R.id.ID_VIEW_DRAW).setOnClickListener(this);
            mRootView.findViewById(R.id.ID_BTN_FULLSCREEN).setOnClickListener(this);
            mRootView.findViewById(R.id.ID_BTN_RESTORE).setOnClickListener(this);

            TextView txtView = (TextView) (mRootView.findViewById(R.id.ID_TXT_TITLE));
            txtView.setText(KernelManager.getFileNameByPath(mFileItem.filePath));

            mFileItem.save();
        } catch (Exception e) {
            Toast.makeText(getActivity(), R.string.open_file_fail, Toast.LENGTH_SHORT).show();
            popbackDelay();
            e.printStackTrace();
        }

        return mRootView;
    }

    private void popbackDelay() {
        mRootView.postDelayed(new Runnable() {
            @Override
            public void run() {
                getFragmentManager().popBackStack();
            }
        }, 300);
    }

    public void showImage(){
        mRootView.postDelayed(new Runnable() {
            @Override
            public void run() {
                try {
                    final int SCREEN_W = mRootView.getWidth();
                    final int SCREEN_H = mRootView.getHeight();

                    if (IConstants.SIMPLE_PNG.equals(mFileItem.filePath)){
                        //内置文件
                        mBitmap = BitmapFactory.decodeStream(getActivity().getAssets().open("simple.png"));
                    }
                    else if (IConstants.SIMPLE_PSD.equals(mFileItem.filePath)){
                        mBitmap = BitmapFactory.decodeStream(getActivity().getAssets().open("simple_psd.jpg"));
                    }
                    else {
                        String imgFilePath = "";
                        if (mFileItem.filePath.toLowerCase().contains(".psd")){
                            //psd文件
                            imgFilePath = KernelManager.getSdcardDir()
                                    + IConstants.SAVE_PATH
                                    + KernelManager.getStringMD5(mFileItem.filePath);
                        } else {
                            imgFilePath = mFileItem.filePath;
                        }

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
                    }

                    if (null == mBitmap){
                        Toast.makeText(getActivity(), getString(R.string.file_error)
                                , Toast.LENGTH_SHORT).show();
                    } else {
                        PSDDrawView psdView = (PSDDrawView) (mRootView.findViewById(R.id.ID_VIEW_DRAW));
                        psdView.setBitmap(mBitmap);
                    }
                }
                catch (Exception e){
                    e.printStackTrace();
                }
            }
        }, 200);
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
