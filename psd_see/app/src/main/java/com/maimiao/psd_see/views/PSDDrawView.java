package com.maimiao.psd_see.views;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Rect;
import android.util.AttributeSet;
import android.view.MotionEvent;
import android.view.View;

import com.maimiao.psd_see.R;

/**
 * Created by larry on 17/1/16.
 */

public class PSDDrawView extends View implements View.OnTouchListener {
    private final int TOUCH_MODE_NONE = 0; //没有触摸操作
    private final int TOUCH_MODE_PAN = 1; //平移
    private final int TOUCH_MODE_SCALE = 2; //缩放操作

    private Bitmap mBitmap;
    private boolean mIsFullScreen;
    private int mTouchMode; //触摸模式
    private float mMovieX; //平移的x距离
    private float mMovieY; //平移的Y距离
    private float mFirstX; //首次平移的x坐标
    private float mFirstY; //首次平移的y坐标
    private float mScale = 1; //缩放的倍数
    private float mOldDist = 1; //上次的缩放倍数

    public PSDDrawView(Context context) {
        super(context);
    }

    public PSDDrawView(Context context, AttributeSet attrs){
        super(context, attrs);
    }

    /**
     * 绘制背景
     * @param canvas
     */
    private void drawBackground(Canvas canvas){
        final  int GRID_WH = getResources().getDimensionPixelSize(R.dimen.grid_wh); //格子的宽高
        Paint grayPaint = new Paint();
        grayPaint.setColor(getResources().getColor(R.color.gray_color));
        grayPaint.setStrokeWidth(GRID_WH);

        int GRID_NUM_ROW = canvas.getWidth() / GRID_WH + 2; //每行的格子数
        GRID_NUM_ROW = (0 == GRID_NUM_ROW % 2) ? GRID_NUM_ROW : (GRID_NUM_ROW + 1);
        final int GRID_NUM_COL = canvas.getHeight() / GRID_WH + 1; //每列的格子数
        final int GRID_POINT_NUM = GRID_NUM_ROW * GRID_NUM_COL; //每个格子2个点

        float[] grids = new float[GRID_POINT_NUM];

        int index = 0;
        //计算格子的坐标
        for (int y = 0; y < GRID_NUM_COL; y++){
            index = 0;
            for (int x = 0; x < GRID_NUM_ROW; x += 2){
                if (0 == y % 2) {
                    //偶数行,从0开始
                    grids[y * GRID_NUM_ROW + x] = index * GRID_WH * 2; //x坐标
                }
                else{
                    //奇数行,从1开始
                    grids[y * GRID_NUM_ROW + x] = index * GRID_WH * 2 + GRID_WH; //x坐标
                }
                grids[y * GRID_NUM_ROW + x + 1] = y * GRID_WH; //y坐标
                index++;
            }
        }

        canvas.drawColor(Color.WHITE);
        canvas.drawPoints(grids, grayPaint);
    }

    private float spacing(MotionEvent event) {
        float x = event.getX(0) - event.getX(1);
        float y = event.getY(0) - event.getY(1);
        return (float) (Math.sqrt(x * x + y * y));
    }

    @Override
    protected void onDraw (Canvas canvas) {
        super.onDraw(canvas);
        //先绘制背景
        drawBackground(canvas);

        if (null == mBitmap) {
            return;
        }

        Rect srcRect = new Rect(0, 0, mBitmap.getWidth(), mBitmap.getHeight());
        Rect dstRect = new Rect(0, 0, canvas.getWidth(), canvas.getHeight());
        Paint paint = new Paint();
        int dstWidth = 0;
        int dstHeight = 0;
        paint.setDither(true);

        if (mIsFullScreen)
        {
        }
        else if (mBitmap.getWidth() <= canvas.getWidth()
                && mBitmap.getHeight() <= canvas.getHeight())
        {
            //图片的宽高都小于屏幕的宽高
            dstRect.left = (canvas.getWidth() - mBitmap.getWidth())/2;
            dstRect.top = (canvas.getHeight() - mBitmap.getHeight()) /2;
            dstRect.right = dstRect.left + mBitmap.getWidth();
            dstRect.bottom = dstRect.top + mBitmap.getHeight();
        }
        else if( mBitmap.getWidth() > canvas.getWidth()
                && mBitmap.getHeight() > canvas.getHeight() )
        {
            //图片的宽度和高度都大于屏幕的宽高
            if (canvas.getWidth() > canvas.getHeight())
            {
                dstRect.top = 0;
                //dstX = fabsf((rect.size.width - self.psFile.psImage.size.width)/2);
                dstRect.bottom = canvas.getHeight();
                dstWidth = (canvas.getHeight() * mBitmap.getWidth()) /mBitmap.getHeight();
                if(dstWidth > canvas.getWidth())
                {
                    dstRect.left = 0;
                }
                else
                {
                    dstRect.left = Math.abs((canvas.getWidth() - dstWidth)/2);
                }
                dstRect.right = dstRect.left + dstWidth;
            }
            else
            {
                dstRect.left = 0;
                //dstY = fabsf((rect.size.height - self.psFile.psImage.size.height) / 2);
                dstRect.right = canvas.getWidth();
                dstHeight = (canvas.getWidth() * mBitmap.getHeight()) /mBitmap.getWidth();
                if (dstHeight > canvas.getHeight())
                {
                    dstRect.top = 0;
                }
                else
                {
                    dstRect.top = Math.abs((canvas.getHeight() - dstHeight) / 2);
                }
                dstRect.bottom = dstRect.top + dstHeight;
            }
        }
        else if(mBitmap.getHeight() > canvas.getHeight())
        {
            dstRect.top = 0;
            //dstX = fabsf((rect.size.width - self.psFile.psImage.size.width)/2);
            dstRect.bottom = canvas.getHeight();
            dstWidth = (canvas.getHeight() * mBitmap.getWidth()) /mBitmap.getHeight();
            dstRect.left = Math.abs((canvas.getWidth() - dstWidth)/2);
            dstRect.right = dstRect.left + dstWidth;
        }
        else if(mBitmap.getWidth() > canvas.getWidth())
        {
            dstRect.left = 0;
            //dstY = fabsf((rect.size.height - self.psFile.psImage.size.height) / 2);
            dstRect.right = canvas.getWidth();
            dstHeight = (canvas.getWidth() * mBitmap.getHeight()) /mBitmap.getWidth();
            dstRect.top = Math.abs((canvas.getHeight() - dstHeight) / 2);
            dstRect.bottom = dstRect.top + dstHeight;
        }

        canvas.save();

        canvas.scale(mScale, mScale, canvas.getWidth() / 2, canvas.getHeight() / 2);
        canvas.translate(mMovieX, mMovieY);
        canvas.drawBitmap(mBitmap, srcRect, dstRect, paint);

        canvas.restore();
    }

    public void setBitmap(Bitmap bitmap){
        mBitmap = bitmap;
        mIsFullScreen = false;
        mMovieX = 0;
        mMovieY = 0;
        mScale = 1;
        mFirstX = 0;
        mFirstY = 0;

        invalidate();
        if (null != mBitmap){
            setOnTouchListener(this);
        }
    }

    public void destroy(){
        if (null != mBitmap && false == mBitmap.isRecycled()){
            mBitmap.recycle();
        }
        mBitmap = null;
    }

    /**
     * 设置是否全屏
     * @param fullScreen
     */
    public void fullScreen(boolean fullScreen){
        mIsFullScreen = fullScreen;
        mMovieX = 0;
        mMovieY = 0;
        mScale = 1;
        mFirstX = 0;
        mFirstY = 0;
        invalidate();
    }

    @Override
    public boolean onTouch(View v, MotionEvent event) {
        switch (event.getAction() & MotionEvent.ACTION_MASK) {
            case MotionEvent.ACTION_DOWN:
                mFirstX = event.getRawX() - mMovieX;
                mFirstY = event.getRawY() - mMovieY;
                mTouchMode = TOUCH_MODE_PAN;
                // Log.i("Mode", "单点按下");
                break;
            case MotionEvent.ACTION_UP:
                mTouchMode = TOUCH_MODE_NONE;
                postInvalidate();
                // Log.i("Mode", "单点松开");
                break;
            case MotionEvent.ACTION_POINTER_UP:
                mTouchMode = TOUCH_MODE_NONE;
                postInvalidate();
                // Log.i("Mode", "多点松开");
                break;
            case MotionEvent.ACTION_POINTER_DOWN:
                mOldDist = spacing(event) / mScale;
                mTouchMode = TOUCH_MODE_SCALE;
                // Log.i("Mode", "多点按下");
                break;
            case MotionEvent.ACTION_MOVE:
                if (mTouchMode == TOUCH_MODE_SCALE) {
                    float newDist = spacing(event);
                    mScale = newDist / mOldDist;
                    //LogTrace.log("newDist:" + newDist + ", mOldDist:" + mOldDist + ", mScale:" + mScale);
                    postInvalidate();
                } else if (mTouchMode == TOUCH_MODE_PAN) {
                    // 平移
                    mMovieX = (event.getRawX() - mFirstX);
                    mMovieY = (event.getRawY() - mFirstY);
                    postInvalidate();
                }
                break;
        }
        return false;
    }
}
