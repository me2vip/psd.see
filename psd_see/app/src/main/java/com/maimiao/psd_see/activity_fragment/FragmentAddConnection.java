package com.maimiao.psd_see.activity_fragment;

import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.TextView;
import android.widget.Toast;

import com.google.android.gms.ads.AdRequest;
import com.google.android.gms.ads.AdView;
import com.maimiao.psd_see.IConstants;
import com.maimiao.psd_see.R;
import com.maimiao.psd_see.common.BaseFragment;
import com.maimiao.psd_see.kernel.KernelManager;


/**
 * Created by larry on 17/1/18.
 */

public class FragmentAddConnection extends BaseFragment implements View.OnClickListener {
    public static interface IConnectionAdd {
        void onServerAdd(String serverIp, String password);
    }

    private View mRootView;
    private IConnectionAdd mConnectionListener;

    public static Fragment create(IConnectionAdd connectionListener){
        FragmentAddConnection fragment = new FragmentAddConnection();
        fragment.mConnectionListener = connectionListener;
        return fragment;
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        mRootView = inflater.inflate(R.layout.fragment_add_connection, container, false);

        TextView textView = (TextView)(mRootView.findViewById(R.id.ID_TXT_TITLE));
        textView.setText(R.string.add_connection);

        Button btnRight = (Button)(mRootView.findViewById(R.id.ID_BTN_RIGHT));
        btnRight.setBackgroundResource(R.drawable.btn_help_selector);
        btnRight.setVisibility(View.VISIBLE);
        btnRight.setOnClickListener(this);
        ViewGroup.LayoutParams layoutParams = btnRight.getLayoutParams();
        layoutParams.height = getResources().getDimensionPixelSize(R.dimen.dp_40);
        layoutParams.width = getResources().getDimensionPixelSize(R.dimen.dp_40);

        mRootView.findViewById(R.id.ID_BTN_ADD).setOnClickListener(this);

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

        return mRootView;
    }

    @Override
    public void onDestroyView() {
        super.onDestroyView();

    }

    @Override
    public void onClick(View v) {
        if (R.id.ID_BTN_ADD == v.getId()) {
            TextView txtServer = (TextView)(mRootView.findViewById(R.id.ID_EDIT_SERVER));
            TextView txtPassword = (TextView) (mRootView.findViewById(R.id.ID_EDIT_PWD));

            String serverIp = txtServer.getText().toString();
            String password = txtPassword.getText().toString();

            if (KernelManager.isStringEmpty(serverIp)) {
                Toast.makeText(getActivity(), R.string.server_ip_null, Toast.LENGTH_SHORT).show();
                return;
            }

            if (KernelManager.isStringEmpty(password)) {
                Toast.makeText(getActivity(), R.string.password_null, Toast.LENGTH_SHORT).show();
                return;
            }

            mConnectionListener.onServerAdd(serverIp, password);
            getFragmentManager().popBackStack();
        } else if(R.id.ID_BTN_RIGHT == v.getId()) {
            getFragmentManager().beginTransaction().add(R.id.container
                    , FragmentHelp.create())
                    .addToBackStack(IConstants.FRAGMENT_MAIN_THREAD).commit();
        }
    }

}
