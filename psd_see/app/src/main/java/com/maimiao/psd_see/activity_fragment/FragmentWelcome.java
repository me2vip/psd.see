package com.maimiao.psd_see.activity_fragment;


import android.os.Bundle;
import android.os.CountDownTimer;
import android.support.v4.app.Fragment;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import com.google.android.gms.ads.AdRequest;
import com.google.android.gms.ads.AdView;
import com.maimiao.psd_see.R;
import com.maimiao.psd_see.kernel.KernelManager;

public class FragmentWelcome extends Fragment
{
	private View mRootView;
	private String mOutsideFile; //外部文件
	private CountDownTimer mTimer;

	public static FragmentWelcome create(String outsideFile)
	{
		FragmentWelcome fragment = new FragmentWelcome();
		fragment.mOutsideFile = outsideFile;
		return fragment;
	}

	@Override
	public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState)
	{
		mRootView = inflater.inflate(R.layout.fragment_welcome, container, false);
		try {
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

			final int second = KernelManager.getRandom(3, 6);
			mTimer = new CountDownTimer(second * 1000, 1000) {
				@Override
				public void onTick(long millisUntilFinished) {
					TextView txtTimer = (TextView)(mRootView.findViewById(R.id.ID_TXT_TIME));
					txtTimer.setText("" + millisUntilFinished / 1000);
				}

				@Override
				public void onFinish() {
					try {
						if (KernelManager.isStringEmpty(mOutsideFile)) {
							//退出全屏
							KernelManager.fullScreen(false, getActivity());
							//跳转到主界面
							getFragmentManager().beginTransaction()
									.replace(R.id.container, FragmentHome.create()).commitAllowingStateLoss();
						} else {
							getFragmentManager().beginTransaction()
									.replace(R.id.container, FragmentOutsideFileView.create(mOutsideFile))
									.commitAllowingStateLoss();
						}
					} catch (Exception e) {
						e.printStackTrace();
					}
				}
			};
			mTimer.start();

		} catch (Exception e) {
			e.printStackTrace();
		}

		return mRootView;
	}

	@Override
	public void onDestroyView() {
		super.onDestroyView();
		if (null != mTimer) {
			mTimer.cancel();
		}
		mTimer = null;
    }
}
