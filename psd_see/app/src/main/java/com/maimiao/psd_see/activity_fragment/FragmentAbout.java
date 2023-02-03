package com.maimiao.psd_see.activity_fragment;

import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import com.maimiao.psd_see.R;
import com.maimiao.psd_see.common.BaseFragment;
import com.maimiao.psd_see.kernel.KernelManager;

/**
 * Created by larry on 17/1/18.
 */

public class FragmentAbout extends BaseFragment {
    private View mRootView;

    public static Fragment create(){
        return new FragmentAbout();
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        mRootView = inflater.inflate(R.layout.fragment_about, container, false);

        TextView textView = (TextView)(mRootView.findViewById(R.id.ID_TXT_TITLE));
        textView.setText(R.string.about);

        textView = (TextView)(mRootView.findViewById(R.id.ID_TXT_INFO));
        textView.setText("PSD.See V" + KernelManager._GetObject().getMyVersionName());

        return mRootView;
    }
}
