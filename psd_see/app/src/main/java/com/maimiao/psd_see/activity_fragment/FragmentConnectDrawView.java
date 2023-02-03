package com.maimiao.psd_see.activity_fragment;

import android.content.pm.ActivityInfo;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.os.Bundle;
import android.os.Handler;
import android.os.Message;
import android.support.v4.app.Fragment;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;
import android.widget.Toast;

import com.google.android.gms.ads.AdRequest;
import com.google.android.gms.ads.AdView;
import com.maimiao.psd_see.IConstants;
import com.maimiao.psd_see.R;
import com.maimiao.psd_see.common.BaseFragment;
import com.maimiao.psd_see.common.EncryptDecrypt;
import com.maimiao.psd_see.common.LogTrace;
import com.maimiao.psd_see.kernel.DataModel;
import com.maimiao.psd_see.kernel.KernelManager;
import com.maimiao.psd_see.views.PSDDrawView;

import org.json.JSONException;

import java.io.ByteArrayOutputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.List;

import io.netty.bootstrap.Bootstrap;
import io.netty.buffer.ByteBuf;
import io.netty.buffer.Unpooled;
import io.netty.channel.Channel;
import io.netty.channel.ChannelDuplexHandler;
import io.netty.channel.ChannelFuture;
import io.netty.channel.ChannelFutureListener;
import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.ChannelId;
import io.netty.channel.ChannelInitializer;
import io.netty.channel.ChannelOption;
import io.netty.channel.ChannelPipeline;
import io.netty.channel.nio.NioEventLoopGroup;
import io.netty.channel.socket.SocketChannel;
import io.netty.channel.socket.nio.NioSocketChannel;
import io.netty.handler.codec.ByteToMessageDecoder;
import io.netty.handler.codec.MessageToByteEncoder;
import io.netty.handler.timeout.IdleState;
import io.netty.handler.timeout.IdleStateEvent;
import io.netty.handler.timeout.IdleStateHandler;

import static android.R.attr.fragment;

/**
 * Created by larry on 17/1/16.
 */

public class FragmentConnectDrawView extends BaseFragment implements View.OnClickListener
        , FragmentChooseImage.IChoseImage {

    private class ClientChannelFactory extends ChannelInitializer<SocketChannel>
    {
        public static final String MESSAGE_ENCODER = "MESSAGE_ENCODER";
        public static final String MESSAGE_DECODER = "MESSAGE_DECODER";
        public static final String DECODER_HANDLE = "DECODER_HANDLE";

        public ClientChannelFactory()
        {
        }

        @Override
        protected void initChannel(SocketChannel ch) throws Exception
        {
            // TODO Auto-generated method stub
            ChannelPipeline pipeline = ch.pipeline();

            pipeline.addLast(MESSAGE_ENCODER, new MessageEncoder());
            pipeline.addLast(MESSAGE_DECODER, new MessageDecoder());
            pipeline.addLast(new IdleStateHandler(0, 0, 30));
            pipeline.addLast(DECODER_HANDLE, new MessageChannelHandler());
        }
    }

    private class MessageChannelHandler extends ChannelDuplexHandler {
        @Override
        public void channelActive(ChannelHandlerContext ctx) throws Exception {
            super.channelActive(ctx);
            LogTrace.log("channelActive");
            mClientChannelId = ctx.channel().id();
            KernelManager.channelGroup.add(ctx.channel());

            sendData2Photoshop(PS_NETWROK_EVENT.getBytes("utf-8"), CONTENT_TYPE_JAVASCRIPT);
        }
        @Override
        public void channelReadComplete(ChannelHandlerContext ctx)
        {
            ctx.flush();
        }

        @Override
        public void channelRead(ChannelHandlerContext ctx, Object msg)
        {
            try {
                mMainHandler.sendMessage(mMainHandler.obtainMessage(MSG_PHOTOSHOP, msg));

            } catch (Exception e) {
                e.printStackTrace();
            }
        }

        @Override
        public void channelWritabilityChanged(ChannelHandlerContext ctx) throws Exception {
            super.channelWritabilityChanged(ctx);
            LogTrace.log("channelWritabilityChanged");
        }

        @Override
        public void exceptionCaught(ChannelHandlerContext ctx, Throwable cause)
        {
            cause.printStackTrace();
            LogTrace.log("exceptionCaught:" + cause);

            ctx.close();
        }

        @Override
        public void userEventTriggered(ChannelHandlerContext ctx, Object evt) throws IOException, JSONException
        {
            if (evt instanceof IdleStateEvent)
            {
                IdleStateEvent e = (IdleStateEvent) evt;
                if (e.state() == IdleState.ALL_IDLE)
                {
                    writeHeartMessage(ctx);
                }
            }
        }

        private void writeHeartMessage(ChannelHandlerContext ctx)
        {
            try {
                sendData2Photoshop(PS_HEART_EVENT.getBytes("utf-8"), CONTENT_TYPE_JAVASCRIPT);
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }

    private class MessageEncoder extends MessageToByteEncoder<byte[]>
    {
        @Override
        protected void encode(ChannelHandlerContext arg0, byte[] msg,
                              ByteBuf buffer)
        {
            // TODO Auto-generated method stub
            /* -------------------------------------------------------
            we're writing things in this order:
             Unencrypted:
             1. total message length (not including the length itself) 4byte
             2. communication stat 4byte
             Encrypted:
             3. Protocol version 4byte
             4. Transaction ID 4byte
             5. Message type 4byte
             6. The message itself
             ------------------------------------------------------- */
            try {
                byte[] encrypt = mEncryptDecrypt.encrypt(msg); //对明文进行加密

                //最终要发送的数据
                buffer.writeInt(encrypt.length + LENGTH_COMM_STATUS); //消息的长度,不包含长度本身
                // the communication status is NOT encrypted
                // write communication status value as 32 bit unsigned int
                buffer.writeInt(0);
                buffer.writeBytes(encrypt);
            } catch (Exception e) {
                mMainHandler.sendMessage(mMainHandler.obtainMessage(MSG_CONNECT_ERROR));
                e.printStackTrace();
            }

        }
    }

    private class MessageDecoder extends ByteToMessageDecoder {
        @Override
        protected void decode(ChannelHandlerContext arg0, ByteBuf buffer,
                              List<Object> arg2) {
            while (buffer.readableBytes() >= 4) {

                final int MSG_LEN = buffer.getInt(buffer.readerIndex());
                LogTrace.log("MSG_LEN:" + MSG_LEN + ", readableBytes:" + buffer.readableBytes()
                + ", readerIndex:" + buffer.readerIndex());
                //设置进度条
                mMainHandler.sendMessage(mMainHandler.obtainMessage(
                        MSG_PROGRESS, (int)(buffer.readableBytes() * 100.0 / (MSG_LEN + 4)), 0));

                if (buffer.readableBytes() < MSG_LEN + 4) {
                    return;
                }

                try {
                    DataModel.PhotoshopMessage photomsg = new DataModel.PhotoshopMessage();
                    photomsg.msgLen = buffer.readInt();
                    photomsg.msgStatus = buffer.readInt();

                    if (COMM_STATUS_NO_ERROR == photomsg.msgStatus) {
                        //消息正确
                        byte[] encryptData = new byte[photomsg.msgLen - 4];
                        buffer.readBytes(encryptData);

                        byte[] decryptData = mEncryptDecrypt.decrypt(encryptData); //解密消息

                        ByteBuf bodyBuffer = Unpooled.wrappedBuffer(decryptData);
                        photomsg.protocolVersion = bodyBuffer.readInt();
                        photomsg.transactionId = bodyBuffer.readInt();
                        photomsg.contentType = bodyBuffer.readInt();
                        photomsg.body = new byte[decryptData.length - 12];
                        bodyBuffer.readBytes(photomsg.body);
                    } else {
                        //消息错误
                        photomsg.protocolVersion = buffer.readInt();
                        photomsg.transactionId = buffer.readInt();
                        photomsg.contentType = buffer.readInt();
                        photomsg.body = new byte[photomsg.msgLen - 16]; //去掉消息头
                        buffer.readBytes(photomsg.body);
                    }

                    arg2.add(photomsg);
                } catch (Exception e) {
                    mMainHandler.sendMessage(mMainHandler.obtainMessage(MSG_CONNECT_ERROR));
                    e.printStackTrace();
                }
            }
        }
    }


    private View mRootView;
    private DataModel.ServerInfo mServerInfo;
    private Bitmap mBitmap;
    private EncryptDecrypt mEncryptDecrypt;
    private int mTransactionId = 1;
    private int mConnectFailNum;
    private Bootstrap mBootstrap;
    private volatile boolean mImageGeting; //是否正在获取图片
    private volatile ChannelId mClientChannelId;

    private final int MSG_PHOTOSHOP = 1000; //图片数据
    private final int MSG_CONNECT_ERROR = 1001; //连接错误
    private final int MSG_PROGRESS = 1002; //进度条
    private final int MSG_RECONNECT = 1003; //重新连接

    private final int MAX_FAIL = 5; //最大失败次数
    private final int COMM_STATUS_NO_ERROR = 0; //Communication 状态正常
    private final int PROTOCOL_VERSION = 1; //协议版本
    private final int CONTENT_TYPE_ERROR_INFO = 1; //错误信息
    private final int CONTENT_TYPE_JAVASCRIPT = 2; //JavaScript代码
    private final int CONTENT_TYPE_IMAGE_DATA = 3; //图像数据
    private final int CONTENT_TYPE_PROFILE = 4; //ICC profile
    private final int CONTENT_TYPE_ARBITRARY = 5; //Arbitrary data to be saved as temporary file

    private final int IMAGE_TYPE_JPEG = 1; //jpeg 格式图像
    private final int IMAGE_TYPE_PIXMAP = 2; //原始的像素数据

    private final int LENGTH_COMM_STATUS = 4; //Communication Status 的长度
    private final int LENGTH_PROTOCOL_VERSION = 4; //协议版本长度
    private final int LENGTH_TRANSACTION_ID = 4; //transaction id 长度
    private final int LENGTH_CONTENT_TYPE = 4; //content type 长度

    private final int LENGTH_KEY = 24; //key的长度
    private final int SERVER_PORT = 49494;
    private final String PS_NETWROK_EVENT = "var idNS = stringIDToTypeID( 'networkEventSubscribe' );\r var doc_desc = new ActionDescriptor();\r doc_desc.putClass( stringIDToTypeID( 'eventIDAttr' ), stringIDToTypeID( 'documentChanged' ) );\r executeAction( idNS, doc_desc, DialogModes.NO );\r var cur_doc_desc = new ActionDescriptor();\r cur_doc_desc.putClass( stringIDToTypeID( 'eventIDAttr' ), stringIDToTypeID( 'currentDocumentChanged' ) ); \r executeAction( idNS, cur_doc_desc, DialogModes.NO );\r 'NETWORK_SUCCESS';";
    private final String PS_HEART_EVENT = "'HEART_BEAT_MSG';";

    public static Fragment create(DataModel.ServerInfo serverInfo){
        FragmentConnectDrawView fragment = new FragmentConnectDrawView();
        fragment.mServerInfo = serverInfo;

        return fragment;
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        mRootView = inflater.inflate(R.layout.fragment_connect_draw_view, container, false);

        getActivity().setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_SENSOR); //根据重力感应自动切换屏幕方向
        KernelManager.fullScreen(true, getActivity());

        mBootstrap = new Bootstrap();
        mBootstrap.group(new NioEventLoopGroup())
                .channel(NioSocketChannel.class)
                .option(ChannelOption.SO_KEEPALIVE, true)
                .handler(new ClientChannelFactory());

        mRootView.findViewById(R.id.ID_PRGRSS_LOADING).setVisibility(View.VISIBLE);
        mRootView.findViewById(R.id.ID_BTN_REFRESH).setVisibility(View.GONE);
        mRootView.findViewById(R.id.ID_LAYOUT_BOTTOM).setVisibility(View.GONE);

        mRootView.findViewById(R.id.ID_VIEW_DRAW).setOnClickListener(this);
        mRootView.findViewById(R.id.ID_BTN_FULLSCREEN).setOnClickListener(this);
        mRootView.findViewById(R.id.ID_BTN_RESTORE).setOnClickListener(this);
        mRootView.findViewById(R.id.ID_BTN_SAVE).setOnClickListener(this);
        mRootView.findViewById(R.id.ID_BTN_NEW).setOnClickListener(this);
        mRootView.findViewById(R.id.ID_BTN_REFRESH).setOnClickListener(this);

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
        //adView.setAdSize(AdSize.FULL_BANNER);

        try {
            mEncryptDecrypt = new EncryptDecrypt(mServerInfo.password);
            mConnectFailNum = 0;
            connectDelay();
        } catch (Exception e) {
            Toast.makeText(getActivity(), R.string.server_error, Toast.LENGTH_SHORT).show();
            e.printStackTrace();
        }

        return mRootView;
    }

    private Handler mMainHandler = new Handler() {
        @Override
        public void handleMessage(Message msg) {
            try {
                if (msg.obj instanceof DataModel.PhotoshopMessage) {
                    parsePhotoshopMessage((DataModel.PhotoshopMessage)(msg.obj));
                } else if (MSG_PROGRESS == msg.what) {
                    setLoadingProgress(msg.arg1);
                } else if (MSG_RECONNECT == msg.what) {
                    connectServer();
                } else {
                    throw new Exception("message type error");
                }
            } catch (Exception e) {
                connectEnd();
                Toast.makeText(getActivity(), R.string.server_error, Toast.LENGTH_SHORT).show();
                e.printStackTrace();
            }

            super.handleMessage(msg);
        }
    };

    /**
     * 解析错误消息
     * @param message
     */
    private void parseErrorMessage(DataModel.PhotoshopMessage message)
            throws Exception {
        String errorString = new String(message.body, "UTF-8");
        LogTrace.log("errorString:" + errorString);

        throw new Exception(errorString);
    }

    private void parsePhotoshopMessage(DataModel.PhotoshopMessage message)
            throws Exception {

        if(CONTENT_TYPE_PROFILE == message.contentType)
        {
        }
        else if(CONTENT_TYPE_ARBITRARY == message.contentType)
        {
        }
        else if(CONTENT_TYPE_IMAGE_DATA == message.contentType)
        {
            //收到的图像数据
            parseImageData(message);
        }
        else if(CONTENT_TYPE_JAVASCRIPT == message.contentType)
        {
            //js脚本
            parseJavaScript(message);
        }
        else if(CONTENT_TYPE_ERROR_INFO == message.contentType)
        {
            //错误信息
            parseErrorMessage(message);
        }
    }

    /**
     * 解析图像数据
     * @param message
     */
    private void parseImageData(DataModel.PhotoshopMessage message) throws Exception {
        LogTrace.log("thread:" + Thread.currentThread());
        if (null != mBitmap && false == mBitmap.isRecycled()) {
            mBitmap.recycle();
        }
        //数组的第一位是图像的类型，需要跳过
        mBitmap = BitmapFactory.decodeByteArray(message.body, 1, message.body.length -1);
        if (null == mBitmap) {
            throw new Exception("bitmap is null");
        }

        PSDDrawView psdView = (PSDDrawView) (mRootView.findViewById(R.id.ID_VIEW_DRAW));
        psdView.setBitmap(mBitmap);
    }

    /**
     * 解析javascipt
     * @param message
     */
    private void parseJavaScript(DataModel.PhotoshopMessage message) throws Exception {
        String jsString = new String(message.body, "UTF-8");
        LogTrace.log("jsString:" + jsString);

        if (jsString.contains("documentChanged") || jsString.contains("currentDocumentChanged")
                || jsString.contains("NETWORK_SUCCESS"))
        {
            //photoshop 文档有更新,获取图片数据
            mRootView.findViewById(R.id.ID_BTN_REFRESH).setVisibility(View.GONE);
            mRootView.findViewById(R.id.ID_PRGRSS_LOADING).setVisibility(View.VISIBLE);
            TextView txtPrgrss = (TextView)(mRootView.findViewById(R.id.ID_TXT_PRGRSS));
            txtPrgrss.setVisibility(View.VISIBLE);
            txtPrgrss.setText("0");
            mImageGeting = true;

            final int MAX_WH = mRootView.getWidth() < mRootView.getHeight() ? mRootView.getWidth()
                    : mRootView.getHeight();
            String imgJs = String.format("var idNS = stringIDToTypeID( 'sendDocumentThumbnailToNetworkClient' );\r var image_desc = new ActionDescriptor();\r image_desc.putInteger( stringIDToTypeID( 'width' ), %d );\r image_desc.putInteger( stringIDToTypeID('height' ), %d );\r image_desc.putInteger( stringIDToTypeID( 'format' ), 1 );\r executeAction( idNS, image_desc, DialogModes.NO );\r 'GET_IMAGE_SUCCESS';"
                    , MAX_WH, MAX_WH);
            LogTrace.log("imgJs:" + imgJs);
            sendData2Photoshop(imgJs.getBytes("utf-8"), CONTENT_TYPE_JAVASCRIPT);
        } else if (jsString.contains("GET_IMAGE_SUCCESS")) {
            //图片获取完成
            connectEnd();
        }
    }

    /**
     * 设置加载进度
     * @param progress
     */
    private void setLoadingProgress(final int progress) {
        LogTrace.log("progress:" + progress);
        TextView txtView = (TextView)(mRootView.findViewById(R.id.ID_TXT_PRGRSS));
        if (View.VISIBLE != txtView.getVisibility()) {
            txtView.setVisibility(View.VISIBLE);
        }
        if (progress < 100) {
            txtView.setText(progress + "");
        } else {
            txtView.setText("100");
        }
    }

    /**
     * 连接结束
     */
    private void connectEnd() {
        mImageGeting = false;
        mRootView.findViewById(R.id.ID_BTN_REFRESH).setVisibility(View.VISIBLE);
        mRootView.findViewById(R.id.ID_PRGRSS_LOADING).setVisibility(View.GONE);
        mRootView.findViewById(R.id.ID_AD_VIEW).setVisibility(View.GONE);
        mRootView.findViewById(R.id.ID_TXT_PRGRSS).setVisibility(View.GONE);
    }

    /**
     * 连接失败, 延后连接
     */
    private void connectDelay() {
        mConnectFailNum++;
        LogTrace.log("mConnectFailNum:" + mConnectFailNum);

        if (mConnectFailNum > MAX_FAIL) {
            mMainHandler.sendMessage(mMainHandler.obtainMessage(MSG_CONNECT_ERROR));
            return;
        }

        mMainHandler.sendEmptyMessageDelayed(MSG_RECONNECT, 2000);
    }

    /**
     * 连接服务器
     */
    private void connectServer() {
        if (null == mEncryptDecrypt) {
            return;
        }

        Channel channel = KernelManager.getChannelById(mClientChannelId);
        if (null != channel && channel.isActive()) {
            return; //客户端连接正常无需连接
        }

        mImageGeting = true;
        mBootstrap.connect(mServerInfo.serverIp, SERVER_PORT).addListener(new ChannelFutureListener()
        {
            @Override
            public void operationComplete(ChannelFuture arg0) throws Exception
            {
                // TODO Auto-generated method stub
                LogTrace.log(new StringBuilder("result:").append(arg0.isSuccess()).append(", cause:" + arg0.cause())
                        .append(", channel:").append(arg0.channel()).toString());
                if(arg0.isSuccess())
                {
                    //连接服务器成功
                }
                else
                {
                    //链接服务器失败
                    connectDelay(); //连接失败，重连
                }
            }});
    }

    /**
     * 向服务器发送数据
     * @param data
     */
    private void sendData2Photoshop(byte[] data, int type) throws Exception {
        Channel channel = KernelManager.getChannelById(mClientChannelId);

        if (null == channel || false == channel.isActive()) {
            throw new Exception("server not connected");
        }

        /* -------------------------------------------------------
         we're writing things in this order:
         Unencrypted:
         1. total message length (not including the length itself) 4byte
         2. communication stat 4byte
         Encrypted:
         3. Protocol version 4byte
         4. Transaction ID 4byte
         5. Message type 4byte
         6. The message itself
         ------------------------------------------------------- */
        ByteBuf plainBuffer = Unpooled.buffer(LENGTH_PROTOCOL_VERSION
                + LENGTH_TRANSACTION_ID + LENGTH_CONTENT_TYPE + data.length);
        plainBuffer.writeInt(1);
        plainBuffer.writeInt(mTransactionId++);
        plainBuffer.writeInt(type);
        plainBuffer.writeBytes(data);

        channel.writeAndFlush(plainBuffer.array());
    }

    /**
     * 保存图片
     */
    private void saveImage() throws IOException {
        LogTrace.log("thread:" + Thread.currentThread());
        DateFormat dateFormat = new SimpleDateFormat("yyyyMMddHHmmssSS");
        String filePath = KernelManager.getSdcardDir()
                + IConstants.SAVE_PATH + dateFormat.format(new Date());

        FileOutputStream outputStream = new FileOutputStream(filePath, false);
        mBitmap.compress(Bitmap.CompressFormat.JPEG, 100, outputStream);
        outputStream.flush();
        outputStream.close();

        DataModel.FileItemEx fileItem = new DataModel.FileItemEx();
        fileItem.filePath = filePath;
        fileItem.height = mBitmap.getHeight();
        fileItem.fileSize = mBitmap.getByteCount();
        fileItem.width = mBitmap.getWidth();

        for (Fragment fragment : getFragmentManager().getFragments()) {
            if (fragment instanceof FragmentHome) {
                FragmentHome fragmentHome = (FragmentHome)fragment;
                fragmentHome.onSelectedFile(fileItem);
                break;
            }
        }

        Toast.makeText(getActivity(), R.string.image_save_ok, Toast.LENGTH_SHORT).show();
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
        
        mBootstrap.config().group().shutdownGracefully(); //关闭客户端所有连接

        KernelManager.fullScreen(false, getActivity());
        getActivity().setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_PORTRAIT);

        mMainHandler.removeCallbacksAndMessages(null);

        LogTrace.log("close fragment");
    }

    @Override
    public void onClick(View v) {
        try {
            if (R.id.ID_VIEW_DRAW == v.getId()) {
                //显示或隐藏标题栏和底部工具栏
                final int visiable = mRootView.findViewById(R.id.ID_LAYOUT_TITLE).getVisibility();
                if (View.VISIBLE == visiable) {
                    mRootView.findViewById(R.id.ID_LAYOUT_TITLE).setVisibility(View.GONE);
                    mRootView.findViewById(R.id.ID_LAYOUT_BOTTOM).setVisibility(View.GONE);
                } else {
                    mRootView.findViewById(R.id.ID_LAYOUT_TITLE).setVisibility(View.VISIBLE);
                    mRootView.findViewById(R.id.ID_LAYOUT_BOTTOM).setVisibility(View.VISIBLE);
                }
            } else if (mImageGeting) {
                //正在获取图片
                Toast.makeText(getActivity(), R.string.busy, Toast.LENGTH_SHORT).show();
            } else if(R.id.ID_BTN_REFRESH == v.getId()) {
                //刷新
                onClickRefresh();
            } else if (R.id.ID_BTN_NEW == v.getId()) {
                //添加新的图片
                getFragmentManager().beginTransaction().add(R.id.container
                        , FragmentChooseImage.create(this))
                        .addToBackStack(IConstants.FRAGMENT_MAIN_THREAD).commit();
            }
            else if (null == mBitmap || mBitmap.isRecycled()) {
                //图片数据错误
                Toast.makeText(getActivity(), R.string.image_error, Toast.LENGTH_SHORT).show();
            } else if (R.id.ID_BTN_FULLSCREEN == v.getId()) {
                mRootView.findViewById(R.id.ID_LAYOUT_TITLE).setVisibility(View.GONE);
                mRootView.findViewById(R.id.ID_LAYOUT_BOTTOM).setVisibility(View.GONE);
                PSDDrawView psdView = (PSDDrawView) (mRootView.findViewById(R.id.ID_VIEW_DRAW));
                psdView.fullScreen(true);
            } else if (R.id.ID_BTN_RESTORE == v.getId()) {
                mRootView.findViewById(R.id.ID_LAYOUT_TITLE).setVisibility(View.GONE);
                mRootView.findViewById(R.id.ID_LAYOUT_BOTTOM).setVisibility(View.GONE);
                PSDDrawView psdView = (PSDDrawView) (mRootView.findViewById(R.id.ID_VIEW_DRAW));
                psdView.fullScreen(false);
            } else if (R.id.ID_BTN_SAVE == v.getId()) {
                //保存图片
                saveImage();
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void onClickRefresh() {
        try {
            Channel channel = KernelManager.getChannelById(mClientChannelId);
            mRootView.findViewById(R.id.ID_BTN_REFRESH).setVisibility(View.GONE);
            mRootView.findViewById(R.id.ID_PRGRSS_LOADING).setVisibility(View.VISIBLE);
            mImageGeting = true;

            if (null == channel || false == channel.isActive()) {
                //连接服务器
                connectServer();
            } else {
                //刷新图片
                //sendData2Photoshop(PS_NETWROK_EVENT.getBytes("utf-8"), CONTENT_TYPE_JAVASCRIPT);
                final int MAX_WH = mRootView.getWidth() < mRootView.getHeight() ? mRootView.getWidth()
                        : mRootView.getHeight();
                String imgJs = String.format("var idNS = stringIDToTypeID( 'sendDocumentThumbnailToNetworkClient' );\r var image_desc = new ActionDescriptor();\r image_desc.putInteger( stringIDToTypeID( 'width' ), %d );\r image_desc.putInteger( stringIDToTypeID('height' ), %d );\r image_desc.putInteger( stringIDToTypeID( 'format' ), 1 );\r executeAction( idNS, image_desc, DialogModes.NO );\r 'GET_IMAGE_SUCCESS';"
                        , MAX_WH, MAX_WH);
                LogTrace.log("imgJs:" + imgJs);
                sendData2Photoshop(imgJs.getBytes("utf-8"), CONTENT_TYPE_JAVASCRIPT);
            }
        } catch (Exception e) {
            connectEnd();
            Toast.makeText(getActivity(), R.string.server_error, Toast.LENGTH_SHORT).show();
            e.printStackTrace();
        }
    }

    @Override
    public void onImageChose(DataModel.FileItemEx fileItem) {
        LogTrace.log("thread:" + Thread.currentThread());
        try {
            mImageGeting = true;
            if (null != mBitmap && false == mBitmap.isRecycled()) {
                mBitmap.recycle();
            }
            final int SCREEN_W = mRootView.getWidth();
            final int SCREEN_H = mRootView.getHeight();
            String imgFilePath = "";

            if (fileItem.filePath.toLowerCase().contains(".psd")){
                //psd文件
                imgFilePath = KernelManager.getSdcardDir()
                        + IConstants.SAVE_PATH + KernelManager.getStringMD5(fileItem.filePath);
            }
            else {
                imgFilePath = fileItem.filePath;
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

            PSDDrawView psdView = (PSDDrawView) (mRootView.findViewById(R.id.ID_VIEW_DRAW));
            psdView.setBitmap(mBitmap);

            //将图片放到byte数组中
            ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
            outputStream.write(1); //图片的类型
            mBitmap.compress(Bitmap.CompressFormat.JPEG, 100, outputStream);
            sendData2Photoshop(outputStream.toByteArray(), CONTENT_TYPE_IMAGE_DATA);
            outputStream.close();

            mRootView.findViewById(R.id.ID_PRGRSS_LOADING).setVisibility(View.VISIBLE);
            mRootView.findViewById(R.id.ID_BTN_REFRESH).setVisibility(View.GONE);
        } catch (Exception e) {
            connectEnd();
            Toast.makeText(getActivity(), R.string.server_error, Toast.LENGTH_SHORT).show();
            e.printStackTrace();
        }
    }
}
