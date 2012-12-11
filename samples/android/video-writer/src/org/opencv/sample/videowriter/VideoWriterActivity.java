package org.opencv.sample.videowriter;

import java.io.File;
import java.io.IOException;

import org.opencv.android.OpenCVLoader;
import org.opencv.core.Mat;

import android.media.MediaPlayer;
import android.os.Bundle;
import android.app.Activity;
import android.util.Log;
import android.view.Menu;
import android.view.MenuItem;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.View;


public class VideoWriterActivity extends Activity implements SampleCvViewBase.CvCameraViewListener, MediaPlayer.OnCompletionListener {

    private String VIDEO_FILE_NAME = "/mnt/sdcard/video.mp4";
    private VideoWriter mCameraWriter;
    SampleCvViewBase mCameraView;
    SurfaceView mVideoSurface;


    private static final int NO_MODE = 0;
    private static final int CAMERA_MODE = 1;
    private static final int VIDEO_MODE = 2;
    private static final String TAG = "CameraWriterActivity";

    private int mMode = NO_MODE;
    private MediaPlayer mVideoPlayer;
    private int mWidth;
    private int mHeight;



    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_camera_writer);

        /* TODO: convert the sample to new framework to use dynamic OpenCV loading */
        OpenCVLoader.initDebug();

        mCameraView = (SampleCvViewBase)findViewById(R.id.camera_surface_view);
        mCameraView.setCvCameraViewListener(this);

        mVideoSurface = (SurfaceView) findViewById(R.id.video_surface_view);

        /* By default camera mode is started */
        startCameraMode();
        //startVideoPlaybackMode();
    }


    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        getMenuInflater().inflate(R.menu.activity_camera_writer, menu);
        return true;
    }

    public boolean onOptionsItemSelected (MenuItem item) {

        if (item.getItemId() == R.id.menu_item_camera) {
            if (mMode == VIDEO_MODE) {
                stopVideoPlaybackMode();
            }
            startCameraMode();
        } else if (item.getItemId() == R.id.menu_item_video) {
            if (mMode == CAMERA_MODE) {
                stopCameraMode();
            }
            startVideoPlaybackMode();
        }
        return true;
    }

    /** Mode swtiching functyions: Stops camera mode and starts Video Playback mode ****/
    private void startCameraMode() {
        mCameraView.setVisibility(View.VISIBLE);
        mCameraView.enableView();
        mMode = CAMERA_MODE;
    }

    private void stopCameraMode() {
        mCameraView.disableView();
        mCameraView.setVisibility(View.GONE);
        mMode = NO_MODE;
    }

    private class VideoSurfaceCallback implements SurfaceHolder.Callback {
        public VideoSurfaceCallback() {

        }

        @Override
        public void surfaceChanged(SurfaceHolder holder, int format, int width,
                int height) {
            File baseDir = getFilesDir();
            File path = new File(baseDir, VIDEO_FILE_NAME);

            try {

                mVideoPlayer = new MediaPlayer();
                mVideoPlayer.setDataSource(path.toString());
                mVideoPlayer.setDisplay(mVideoSurface.getHolder());
                mVideoPlayer.setOnCompletionListener(VideoWriterActivity.this);
                mVideoPlayer.prepare();

                mVideoPlayer.start();

            } catch (Exception ex) {
                ex.printStackTrace();
            }
        }

        @Override
        public void surfaceCreated(SurfaceHolder holder) {

        }

        @Override
        public void surfaceDestroyed(SurfaceHolder holder) {

            mVideoPlayer.stop();
            mVideoPlayer.release();
        }
    }

    private void startVideoPlaybackMode() {
        mVideoSurface.setVisibility(View.VISIBLE);
        mVideoSurface.getHolder().addCallback(new VideoSurfaceCallback());


        mMode = VIDEO_MODE;
    }
    private void stopVideoPlaybackMode() {
        mVideoSurface.setVisibility(View.GONE);
        mMode = NO_MODE;
    }

    /**
     * Implementation of the SampleCvViewBase.CvCameraViewListener interface methods.
     * Bridges the Camera preview and the VideoWriter class
     */
    @Override
    public void onCameraViewStarted(int width, int height) {
        /* Camera preview started. Frames will start to be delivered soon. Create Video Writer */
        File baseDir = getFilesDir();
        File path = new File(baseDir, VIDEO_FILE_NAME);

        mWidth = width;
        mHeight = height;

        mCameraWriter = new VideoWriter(VIDEO_FILE_NAME/*path.toString()*/, width, height);
        mCameraWriter.startRecording();
    }

    @Override
    public void onCameraViewStopped() {

        mCameraWriter.stopRecording();
    }

    @Override
    public Mat onCameraFrame(Mat inputFrame) {
        Log.i(TAG, "Writing next frame");
        mCameraWriter.writeNextFrame(inputFrame);
        Log.i(TAG, "Wrote next frame");
        return inputFrame;
    }


    @Override
    public void onCompletion(MediaPlayer mp) {
        Log.i(TAG, "Video playback completed");

    }
}
