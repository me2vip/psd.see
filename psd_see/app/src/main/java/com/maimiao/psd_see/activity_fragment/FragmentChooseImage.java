package com.maimiao.psd_see.activity_fragment;

import android.graphics.Bitmap;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.text.Spannable;
import android.text.SpannableString;
import android.text.style.ForegroundColorSpan;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.ImageView;
import android.widget.ListView;
import android.widget.TextView;

import com.google.android.gms.ads.AdRequest;
import com.google.android.gms.ads.AdView;
import com.maimiao.psd_see.IConstants;
import com.maimiao.psd_see.R;
import com.maimiao.psd_see.common.BaseFragment;
import com.maimiao.psd_see.common.ObjectAdapterList;
import com.maimiao.psd_see.common.PSDReaderEx;
import com.maimiao.psd_see.kernel.DataModel;
import com.maimiao.psd_see.kernel.KernelManager;
import com.maimiao.psd_see.listener.IAdapterObjectList;
import com.nostra13.universalimageloader.core.DisplayImageOptions;
import com.nostra13.universalimageloader.core.ImageLoader;
import com.nostra13.universalimageloader.core.assist.ImageScaleType;

import java.util.List;


/**
 * Created by larry on 17/1/18.
 */

public class FragmentChooseImage extends BaseFragment implements IAdapterObjectList
        , AdapterView.OnItemClickListener {
    public static interface IChoseImage {
        void onImageChose(DataModel.FileItemEx fileItem);
    }
    private View mRootView;
    private IChoseImage mChoseImage;
    private DisplayImageOptions mImageOptions;

    public static Fragment create(IChoseImage iChoseImage){
        FragmentChooseImage fragmentChooseImage = new FragmentChooseImage();
        fragmentChooseImage.mChoseImage = iChoseImage;

        return fragmentChooseImage;
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        mRootView = inflater.inflate(R.layout.fragment_choose_image, container, false);

        TextView textView = (TextView)(mRootView.findViewById(R.id.ID_TXT_TITLE));
        textView.setText(R.string.choose_image);

        ListView listView = (ListView)(mRootView.findViewById(R.id.ID_LIST_VIEW));
        ObjectAdapterList adapterList = new ObjectAdapterList(this, listView);
        listView.setAdapter(adapterList);
        listView.setOnItemClickListener(this);

        mImageOptions = new DisplayImageOptions.Builder()
                .showImageOnLoading(R.mipmap.default_image)
                .showImageForEmptyUri(R.mipmap.default_image)
                .showImageOnFail(R.mipmap.default_image).cacheInMemory(true)
                .bitmapConfig(Bitmap.Config.RGB_565)
                .imageScaleType(ImageScaleType.EXACTLY).build();

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

        List<?> list = (List<?>)(DataModel.FileItemEx.getFileList());
        adapterList.addList((List<Object>) list);

        return mRootView;
    }

    @Override
    public void onDestroyView() {
        super.onDestroyView();
    }

    @Override
    public View onItemChanged(int position, View convertView, ViewGroup parent, ObjectAdapterList adapter) {
        if (null == convertView) {
            convertView = LayoutInflater.from(getActivity()).inflate(
                    R.layout.item_file, null, false);
        }

        DataModel.FileItemEx item = (DataModel.FileItemEx)(adapter.getItem(position));
        ImageView imageView = (ImageView)(convertView.findViewById(R.id.ID_IMAGE));
        ImageView imgCheck = (ImageView)(convertView.findViewById(R.id.ID_CHECK_SEL));
        imgCheck.setVisibility(View.GONE);
        String imagePath = null;
        if (item.filePath.toLowerCase().endsWith(".psd")){
            imagePath = KernelManager.getSdcardDir() + IConstants.SAVE_PATH
                    + KernelManager.getStringMD5(item.filePath);
        } else {
            imagePath = item.filePath;
        }

        ImageLoader.getInstance().displayImage("file://" + imagePath, imageView, mImageOptions);

        TextView txtView = (TextView)(convertView.findViewById(R.id.ID_TXT_NAME));
        txtView.setText(KernelManager.getFileNameByPath(item.filePath));

        /**
         View viewItem = convertView.findViewById(R.id.ID_LAYOUT_ITEM);
         viewItem.setTag(item);
         viewItem.setOnClickListener(this);
         **/

        StringBuilder fileInfo = new StringBuilder();
        if (item.filePath.toLowerCase().endsWith(".psd")) {
            fileInfo.append(PSDReaderEx.getColorMode(item.psdColorMode)).append(' ');
        }
        fileInfo.append(item.width).append('*').append(item.height)
                .append(' ');
        final int endSpace = fileInfo.length();
        fileInfo.append(KernelManager.getFileSizeString(item.fileSize));

        SpannableString spanString = new SpannableString(fileInfo.toString());
        spanString.setSpan(new ForegroundColorSpan(getResources().getColor(R.color.font_red))
                , 0, endSpace
                , Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);

        txtView = (TextView)(convertView.findViewById(R.id.ID_TXT_INFO));
        txtView.setText(spanString);

        txtView = (TextView)(convertView.findViewById(R.id.ID_TXT_PATH));
        txtView.setText(item.filePath);

        return convertView;
    }

    @Override
    public int onAdapterItemViewType(int position, ObjectAdapterList adapter) {
        return 0;
    }

    @Override
    public long onAdapterItemId(int position, ObjectAdapterList adapter) {
        return 0;
    }

    @Override
    public void onItemClick(AdapterView<?> parent, View view, int position, long id) {
        DataModel.FileItemEx item = (DataModel.FileItemEx)(parent.getItemAtPosition(position));
        mChoseImage.onImageChose(item);

        getFragmentManager().popBackStack();
    }

}
