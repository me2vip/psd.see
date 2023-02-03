package com.maimiao.psd_see.activity_fragment;

import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.support.v4.app.FragmentActivity;
import android.widget.Toast;

import com.google.android.gms.ads.MobileAds;
import com.maimiao.psd_see.IConstants;
import com.maimiao.psd_see.R;
import com.maimiao.psd_see.common.LogTrace;
import com.maimiao.psd_see.kernel.KernelManager;
import com.umeng.analytics.MobclickAgent;

public class ActivityMain extends FragmentActivity /**implements SensorEventListener**/ {

    // Used to load the 'native-lib' library on application startup.

    private boolean mNextBackExit = false; //再按一次back键退出
    private long mLastAutoChangeTime; //上一次屏幕更改时间

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        //Bmob.initialize(this, "c2661e61f932582b1d25246512926eb5");
        //BmobUpdateAgent.initAppVersion(); 该方法只能用一次

        // Initialize the Mobile Ads SDK.
        MobileAds.initialize(this, "ca-app-pub-2925148926153054~2216307921");

        String filePath = null;
        try {
            Intent intent = getIntent();
            Uri uri = (Uri) intent.getData();
            filePath = uri.getPath();
        }
        catch (Exception e){
            filePath = null;
        }

        LogTrace.log("filePath:" + filePath);

        getSupportFragmentManager().beginTransaction().add(R.id.container,
                FragmentWelcome.create(filePath)).commitAllowingStateLoss();
    }

    @Override
    protected void onNewIntent(Intent intent){
        super.onNewIntent(intent);
        String filePath = "";
        try {
            Uri uri = (Uri) (intent.getData());
            filePath = uri.getPath();
        }
        catch (Exception e){
            filePath = "";
            e.printStackTrace();
        }
        LogTrace.log("path:" + filePath);
        if (false == KernelManager.isStringEmpty(filePath)) {
            getSupportFragmentManager().beginTransaction().add(R.id.container
                    , FragmentOutsideFileView.create(filePath))
                    .addToBackStack(IConstants.FRAGMENT_MAIN_THREAD).commitAllowingStateLoss();
        }
    }

    @Override
    protected void onResume() {
        super.onResume();
        MobclickAgent.onResume(this);
    }

    @Override
    protected void onPause() {
        super.onPause();
        MobclickAgent.onPause(this);
    }

    @Override
    public void onBackPressed()
    {
        // TODO Auto-generated method stub
        final int FRAGMENT_COUNT = getSupportFragmentManager()
                .getBackStackEntryCount();
        if (FRAGMENT_COUNT > 0)
        {
            super.onBackPressed();
        }
        else if(mNextBackExit)
        {
            //退出应用
            finish();
            KernelManager._GetObject().exitApp();
        }
        else
        {
            mNextBackExit = true;
            Toast.makeText(getApplicationContext(), R.string.exit_tip, Toast.LENGTH_SHORT).show();
            findViewById(R.id.container).postDelayed(new Runnable() {
                @Override
                public void run() {
                    // TODO Auto-generated method stub
                    mNextBackExit = false;
                }
            }, 2000);
        }
    }

    /**
    @Override
    public void onSensorChanged(SensorEvent event) {
        //可以得到传感器实时测量出来的变化值
        final float x = event.values[SensorManager.DATA_X];
        float y = event.values[SensorManager.DATA_Y];
        float z = event.values[SensorManager.DATA_Z];
        //过滤掉用力过猛会有一个反向的大数值
        if (((x > -15 && x < -10) || (x < 15 && x > 10)) && Math.abs(y) < 1.5) {
            if ((System.currentTimeMillis() - mLastAutoChangeTime) > 2000) {
                if (x > 0) {
                    setRequestedOrientation(
                            ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE);
                }else{
                    setRequestedOrientation(
                            ActivityInfo.SCREEN_ORIENTATION_REVERSE_LANDSCAPE);
                }
                mLastAutoChangeTime = System.currentTimeMillis();
            }
        }
    }

    @Override
    public void onAccuracyChanged(Sensor sensor, int accuracy) {

    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data){
        super.onActivityResult(requestCode, resultCode, data);
        LogTrace.log("requestCode:" + requestCode + ", resultCode:" + resultCode);
        if (IConstants.REQ_OPENABLE == requestCode && RESULT_OK == resultCode){
            //选择一张图片
        }
    }
    **/

    /**
     * A native method that is implemented by the 'native-lib' native library,
     * which is packaged with this application.
     */
    //public native String stringFromJNI();
}
