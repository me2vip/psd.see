package com.maimiao.psd_see.activity_fragment;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;
import android.net.wifi.WifiInfo;
import android.net.wifi.WifiManager;
import android.os.Bundle;
import android.support.v4.app.Fragment;
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
import com.maimiao.psd_see.kernel.DataModel;
import com.maimiao.psd_see.kernel.KernelManager;
import com.maimiao.psd_see.listener.IAdapterObjectList;

import java.util.List;


/**
 * Created by larry on 17/1/18.
 */

public class FragmentConnections extends BaseFragment implements View.OnClickListener, IAdapterObjectList, AdapterView.OnItemClickListener, FragmentAddConnection.IConnectionAdd {
    private View mRootView;
    private boolean mIsDeleting;

    public static Fragment create(){
        return new FragmentConnections();
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        mRootView = inflater.inflate(R.layout.fragment_connects, container, false);

        TextView textView = (TextView)(mRootView.findViewById(R.id.ID_TXT_TITLE));
        textView.setText(R.string.connections);

        mRootView.findViewById(R.id.ID_BTN_ADD).setOnClickListener(this);
        mRootView.findViewById(R.id.ID_BTN_REMOVE).setOnClickListener(this);

        ListView listView = (ListView)(mRootView.findViewById(R.id.ID_LIST_VIEW));
        ObjectAdapterList adapterList = new ObjectAdapterList(this, listView);
        listView.setAdapter(adapterList);
        listView.setOnItemClickListener(this);

        IntentFilter filter = new IntentFilter();
        filter.addAction(ConnectivityManager.CONNECTIVITY_ACTION);
        getActivity().registerReceiver(mReceiver, filter);

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

        setWifiState();

        List<?> serverList = (List<?>)(DataModel.ServerInfo.getServerList());
        adapterList.addList((List<Object>)serverList);

        return mRootView;
    }

    private BroadcastReceiver mReceiver = new BroadcastReceiver() {

        @Override
        public void onReceive(Context context, Intent intent) {
            setWifiState();
        }
    };

    private void setWifiState() {
        ConnectivityManager connManager = (ConnectivityManager)
                (getActivity().getApplicationContext().getSystemService(
                Context.CONNECTIVITY_SERVICE));
        NetworkInfo.State state = connManager.getNetworkInfo(ConnectivityManager.TYPE_WIFI)
                .getState();
        TextView textView = (TextView)(mRootView.findViewById(R.id.ID_TXT_WIFI));
        ImageView imgWifi = (ImageView)(mRootView.findViewById(R.id.ID_IMG_WIFI));

        if (NetworkInfo.State.CONNECTED == state){
            //已连接到wifi
            WifiManager wifiManager = (WifiManager)
                    (getActivity().getApplicationContext().getSystemService(Context.WIFI_SERVICE));
            WifiInfo wifiInfo = wifiManager.getConnectionInfo();
            textView.setText(wifiInfo.getSSID().replace("\"", ""));
            imgWifi.setImageResource(R.mipmap.wiff_enabel);

        } else {
            //未连接到wifi
            textView.setText(R.string.no_wifi);
            imgWifi.setImageResource(R.mipmap.wiff_disable);
        }
    }

    /**
     * 删除选中的服务器
     * @param list
     */
    private void removeServer(List<Object> list) {
        DataModel.ServerInfo sverItem = null;
        for (int index = 0; index < list.size();) {
            sverItem = (DataModel.ServerInfo)(list.get(index));
            if (sverItem.selected) {
                list.remove(sverItem);
                DataModel.ServerInfo.remove(sverItem);
            } else {
                index++;
            }
        }
    }

    private void gotoDrawing(final DataModel.ServerInfo serverInfo) {
        mRootView.postDelayed(new Runnable() {
            @Override
            public void run() {
                getFragmentManager().beginTransaction().add(R.id.container
                        , FragmentConnectDrawView.create(serverInfo))
                        .addToBackStack(IConstants.FRAGMENT_MAIN_THREAD).commit();
            }
        }, 200);
    }

    @Override
    public void onDestroyView() {
        super.onDestroyView();

        getActivity().unregisterReceiver(mReceiver);
    }

    @Override
    public void onClick(View v) {
        final int VIEW_ID = v.getId();
        if(R.id.ID_BTN_ADD == VIEW_ID) {
            getFragmentManager().beginTransaction().add(R.id.container
                    , FragmentAddConnection.create(this))
                    .addToBackStack(IConstants.FRAGMENT_MAIN_THREAD).commit();
        } else if (R.id.ID_BTN_REMOVE == VIEW_ID) {
            ListView listView = (ListView)(mRootView.findViewById(R.id.ID_LIST_VIEW));
            ObjectAdapterList adapterList = (ObjectAdapterList)(listView.getAdapter());
            mIsDeleting = !mIsDeleting;
            if (mIsDeleting) {
                v.setBackgroundResource(R.drawable.btn_remove_2_selector);
            } else {
                v.setBackgroundResource(R.drawable.btn_remove_1_selector);
                removeServer(adapterList.getDataList());
            }

            adapterList.notifyDataSetChanged();
        }
    }

    @Override
    public View onItemChanged(int position, View convertView, ViewGroup parent, ObjectAdapterList adapter) {
        if (null == convertView) {
            convertView = LayoutInflater.from(getActivity()).inflate(
                    R.layout.item_server, null, false);
        }

        DataModel.ServerInfo serverInfo = (DataModel.ServerInfo)(adapter.getItem(position));
        TextView txtServer = (TextView)(convertView.findViewById(R.id.ID_TXT_SERVER));
        txtServer.setText(serverInfo.serverIp);
        txtServer.append(" (");
        txtServer.append(serverInfo.password);
        txtServer.append(")");

        TextView txtTime = (TextView)(convertView.findViewById(R.id.ID_TXT_TIME));
        txtTime.setText(KernelManager.getTimeString(serverInfo.visitTime));

        ImageView imageView = (ImageView)(convertView.findViewById(R.id.ID_CHECK_SEL));

        if (mIsDeleting) {
            imageView.setVisibility(View.VISIBLE);
            convertView.findViewById(R.id.ID_IMG_NEXT).setVisibility(View.GONE);
            if (serverInfo.selected) {
                imageView.setImageResource(R.mipmap.check_sel);
            } else {
                imageView.setImageResource(R.mipmap.check_unsel);
            }
        } else {
            convertView.findViewById(R.id.ID_CHECK_SEL).setVisibility(View.GONE);
            convertView.findViewById(R.id.ID_IMG_NEXT).setVisibility(View.VISIBLE);
        }

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
        DataModel.ServerInfo serverInfo = (DataModel.ServerInfo)
                (parent.getItemAtPosition(position));

        if (mIsDeleting) {
            //删除状态
            serverInfo.selected = !(serverInfo.selected);
            ImageView viewCheck = (ImageView) (view.findViewById(R.id.ID_CHECK_SEL));
            if (serverInfo.selected) {
                viewCheck.setImageResource(R.mipmap.check_sel);
            } else {
                viewCheck.setImageResource(R.mipmap.check_unsel);
            }
            return;
        }

        //连接服务器
        getFragmentManager().beginTransaction().add(R.id.container
                , FragmentConnectDrawView.create(serverInfo))
                .addToBackStack(IConstants.FRAGMENT_MAIN_THREAD).commit();
    }

    @Override
    public void onServerAdd(String serverIp, String password) {
        DataModel.ServerInfo serverInfo = null;
        ListView listView = (ListView)(mRootView.findViewById(R.id.ID_LIST_VIEW));
        ObjectAdapterList adapterList = (ObjectAdapterList)(listView.getAdapter());
        boolean serverIn = false;
        for (Object objItem : adapterList.getDataList()) {
            serverInfo = (DataModel.ServerInfo)(objItem);
            if (serverIp.equals(serverInfo.serverIp) && password.equals(serverInfo.password)) {
                serverIn = true;
                break;
            }
        }

        serverInfo = DataModel.ServerInfo.getServer(serverIp, password);
        if (null == serverInfo) {
            serverInfo = new DataModel.ServerInfo();
            serverInfo.serverIp = serverIp;
            serverInfo.password = password;
        }
        serverInfo.save();


        if (false == serverIn) {
            adapterList.addItem(0, serverInfo);
            adapterList.notifyDataSetChanged();
        }

        gotoDrawing(serverInfo);
    }
}
