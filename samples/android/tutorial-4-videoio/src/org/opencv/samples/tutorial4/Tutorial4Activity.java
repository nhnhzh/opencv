package org.opencv.samples.tutorial4;

import org.opencv.android.BaseLoaderCallback;
import org.opencv.android.CameraBridgeViewBase.CvCameraViewFrame;
import org.opencv.android.LoaderCallbackInterface;
import org.opencv.android.OpenCVLoader;
import org.opencv.core.Mat;
import org.opencv.core.Size;
import org.opencv.highgui.VideoWriter;
import org.opencv.android.CameraBridgeViewBase;
import org.opencv.android.CameraBridgeViewBase.CvCameraViewListener2;

import android.app.Activity;
import android.os.Bundle;
import android.util.Log;
import android.view.Menu;
import android.view.MenuItem;
import android.view.SurfaceView;
import android.view.WindowManager;
import android.view.View;
import android.view.View.OnTouchListener;
import android.view.MotionEvent;
import android.os.Environment;
import android.widget.Toast;

public class Tutorial4Activity extends Activity implements OnTouchListener, CvCameraViewListener2 {
    private static final String TAG = "OCVSample::Activity";

    private CameraBridgeViewBase mOpenCvCameraView;
    private String               VIDEO_FILE_NAME;
    private VideoWriter          mCameraWriter = null;
    private boolean              mIsWritting = false;
    private int                  mWidth = 640;
    private int                  mHeight = 480;

    private BaseLoaderCallback mLoaderCallback = new BaseLoaderCallback(this) {
        @Override
        public void onManagerConnected(int status) {
            switch (status) {
                case LoaderCallbackInterface.SUCCESS:
                {
                    Log.i(TAG, "OpenCV loaded successfully");
                    mOpenCvCameraView.enableView();
                } break;
                default:
                {
                    super.onManagerConnected(status);
                } break;
            }
        }
    };

    public Tutorial4Activity() {
        Log.i(TAG, "Instantiated new " + this.getClass());
    }

    /** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState) {
        Log.i(TAG, "called onCreate");
        super.onCreate(savedInstanceState);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);

        setContentView(R.layout.tutorial4_surface_view);
        mOpenCvCameraView = (CameraBridgeViewBase) findViewById(R.id.tutorial4_activity_surface_view);
        mOpenCvCameraView.setVisibility(SurfaceView.VISIBLE);
        mOpenCvCameraView.setCvCameraViewListener(this);
        mOpenCvCameraView.setOnTouchListener(Tutorial4Activity.this);
    }

    @Override
    public void onPause()
    {
        super.onPause();
        if (mOpenCvCameraView != null)
            mOpenCvCameraView.disableView();
    }

    @Override
    public void onResume()
    {
        super.onResume();
        OpenCVLoader.initAsync(OpenCVLoader.OPENCV_VERSION_2_4_3, this, mLoaderCallback);
    }

    public void onDestroy() {
        super.onDestroy();
        if (mOpenCvCameraView != null)
            mOpenCvCameraView.disableView();
    }

    @Override
    public boolean onTouch(View v, MotionEvent event) {
        String toastMesage = new String();
        Log.i(TAG, "Screen touched! VideoWriter state triggered!");

        if (mIsWritting) {
            mCameraWriter.release();
            mIsWritting = false;
            toastMesage = "Recording stoped";
        } else {
            VIDEO_FILE_NAME = Environment.getExternalStorageDirectory().getPath() +
                    "/sample_video.avi";
            mCameraWriter = new VideoWriter(VIDEO_FILE_NAME, 0, 25, new Size(mWidth, mHeight));
            toastMesage = "Start recording to " + VIDEO_FILE_NAME;
            mIsWritting = true;
        }

        Toast toast = Toast.makeText(this, toastMesage, Toast.LENGTH_LONG);
        toast.show();

        return false;
    }

    public void onCameraViewStarted(int width, int height) {
    }

    public void onCameraViewStopped() {
        mCameraWriter = null;
    }

    public Mat onCameraFrame(CvCameraViewFrame inputFrame) {
        Mat frame = inputFrame.rgba();
        if (mIsWritting && (mCameraWriter != null)) {
            Log.d(TAG, "Writing frame to file");
            mCameraWriter.write(frame);
        }
        return frame;
    }
}
