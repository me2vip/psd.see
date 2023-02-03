package com.maimiao.psd_see.activity_fragment;

import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.webkit.WebChromeClient;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.TextView;
import android.widget.Toast;

import com.maimiao.psd_see.R;
import com.maimiao.psd_see.common.BaseFragment;

/**
 * Created by larry on 17/1/18.
 */

public class FragmentHelp extends BaseFragment {

    private class LocalWebClient extends WebViewClient {
        @Override
        public boolean shouldOverrideUrlLoading(WebView view, String url) {
            view.loadUrl(url);
            return true;
        }

        @Override
        public void onPageFinished(WebView view, String url) {
        }

        @Override
        public void onReceivedError(WebView view, int errorCode, String description, String failingUrl) {
            Toast.makeText(getActivity(), description, Toast.LENGTH_SHORT).show();
        }
    }

    private class LocalChromeClient extends WebChromeClient {
        @Override
        public void onReceivedTitle(WebView view, String title) {
            /**
            View rootView = getView();
            TextView txtTitle = (TextView) rootView.findViewById(R.id.ID_TXT_TITLE);
            txtTitle.setText(title);
             **/
        }
    }

    private View mRootView;

    public static Fragment create(){
        return new FragmentHelp();
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        mRootView = inflater.inflate(R.layout.fragment_webview, container, false);

        TextView textView = (TextView)(mRootView.findViewById(R.id.ID_TXT_TITLE));
        textView.setText(R.string.help);

        // 打开链接
        WebView webView = (WebView) (mRootView.findViewById(R.id.ID_VIEW_WEB));
        WebSettings settings = webView.getSettings();
        settings.setBuiltInZoomControls(true);
        settings.setJavaScriptEnabled(true);
        settings.setSupportZoom(true);
        webView.setWebViewClient(new LocalWebClient());
        webView.setWebChromeClient(new LocalChromeClient());
        settings.setUseWideViewPort(true);
        settings.setLoadWithOverviewMode(true);
        //webView.addJavascriptInterface(new AndroidJavaScript(), "native");

        webView.loadUrl("file:///android_asset/help_en.html");

        return mRootView;
    }

    @Override
    public void onDestroyView() {
        // TODO Auto-generated method stub
        super.onDestroyView();

        WebView webView = (WebView) (mRootView.findViewById(R.id.ID_VIEW_WEB));
        webView.stopLoading();
    }
}
