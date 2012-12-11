package org.opencv.sample.videowriter;

import org.opencv.android.Utils;
import org.opencv.core.Mat;
import org.opencv.core.Size;
import org.opencv.highgui.Highgui;
import org.opencv.highgui.VideoCapture;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.util.AttributeSet;
import android.util.Log;
import android.view.SurfaceHolder;
import android.view.SurfaceView;

/**
 * This is a basic class, implementing the interaction with Camera and OpenCV library.  
 * The main responsibility of it - is to control when camera can be enabled, process the frame,
 * call external listener to make any adjustments to the frame and then draw the resulting
 * frame to the screen.
 * The clients shall implement CvCameraViewListener 
 */
public class SampleCvViewBase extends SurfaceView implements SurfaceHolder.Callback {
	
	
    private VideoCapture mCamera;
	
	
	public SampleCvViewBase(Context context, AttributeSet attrs) {
		super(context,attrs);
		getHolder().addCallback(this);
	}

	public interface CvCameraViewListener {
		/**
		 * This method is invoked when camera preview has started. After this method is invoked
		 * the frames will start to be delivered to client via the onCameraFrame() callback.
		 * @param width -  the width of the frames that will be delivered
		 * @param height - the height of the frames that will be delivered
		 */
		public void onCameraViewStarted(int width, int height);
		
		/**
		 * This method is invoked when camera preview has been stopped for some reason.
		 * No frames will be delivered via onCameraFrame() callback after this method is called. 
		 */
		public void onCameraViewStopped();
		
		/**
		 * This method is invoked when delivery of the frame needs to be done.
		 * The returned values - is a modified frame which needs to be displayed on the screen. 
		 */
		public Mat onCameraFrame(Mat inputFrame);
		
	}

	
	private static final int STOPPED = 0;
	private static final int STARTED = 1;
	private  static final String TAG = "SampleCvBase";

	private CvCameraViewListener mListener;
	private int mState = STOPPED;
	
	private boolean mEnabled;
	private boolean mSurfaceExist;
	
	private boolean mStopThread;
	
	private Thread mThread;
	
	private Object mSyncObject = new Object();
	private int mFrameWidth;
	private int mFrameHeight;

	public void surfaceChanged(SurfaceHolder arg0, int arg1, int arg2, int arg3) {
		synchronized(mSyncObject) {
			if (!mSurfaceExist) {
				mSurfaceExist = true;
				checkCurrentState();
			} else {
				/* TODO:Process surface changed event in corresponding state */
			}
		}
	}

	public void surfaceCreated(SurfaceHolder holder) {
		/* Do nothing. Wait until surfaceChanged delivered */
	}

	public void surfaceDestroyed(SurfaceHolder holder) {
		synchronized(mSyncObject) {
			mSurfaceExist = false;
			checkCurrentState();
		}
	}
	

	/**
	 * This method is provided for clients, so they can enable the camera connection.
	 * The actuall onCameraViewStarted callback will be delivered only after both this method is called and surface is available 
	 */
	public void enableView() {
		synchronized(mSyncObject) {
			mEnabled = true;
			checkCurrentState();
		}
	}

	/**
	 * This method is provided for clients, so they can disable camera connection and stop
	 * the delivery of frames eventhough the surfaceview itself is not destroyed and still stays on the scren
	 */
	public void disableView() {
		synchronized(mSyncObject) {
			mEnabled = false;
			checkCurrentState();
		}
	}
	
	
	public void setCvCameraViewListener(CvCameraViewListener listener) {
		mListener = listener;
	}

	/**
	 * Called when mSyncObject lock is held
	 */
	private void checkCurrentState() {
		int targetState;
		
		if (mEnabled && mSurfaceExist) {
			targetState = STARTED;
		} else {
			targetState = STOPPED;
		}
		
		if (targetState != mState) {
			/* The state change detected. Need to exit the current state and enter target state */
			processExitState(mState);
			mState = targetState;
			processEnterState(mState);
		}
	}

	private void processEnterState(int state) {
		switch(state) {
		case STARTED:
			onEnterStartedState();
			if (mListener != null) {
				mListener.onCameraViewStarted(mFrameWidth, mFrameHeight);
			}
			break;
		case STOPPED:
			onEnterStoppedState();
			if (mListener != null) {
				mListener.onCameraViewStopped();
			}
			break;
		};
	}


	private void processExitState(int state) {
		switch(state) {
		case STARTED:
			onExitStartedState();
			break;
		case STOPPED:
			onExitStoppedState();
			break;
		};
	}
	
	private void onEnterStoppedState() {
		/* nothing to do */
	}
	
	private void onExitStoppedState() {
		/* nothing to do */
	}

	private void onEnterStartedState() {
		/* 1. We need to instantiate camera
		 * 2. We need to start thread which will be getting frames
		 */
		/* First step - initialize camera connection */
		initializeCamera(getWidth(), getHeight());
		
		/* now we can start update thread */
		mThread = new Thread(new CameraWorker(getWidth(), getHeight()));
		mThread.start();
	}
	
	private void onExitStartedState() {
		/* 1. We need to stop thread which updating the frames
		 * 2. Stop camera and release it
		 */
		try {
			mStopThread = true;
			mThread.join();
		} catch (InterruptedException e) {
			e.printStackTrace();
		} finally {
			mThread =  null;
			mStopThread = false;
		}
		
		/* Now release camera */
		releaseCamera();
		
	}
	
	private void initializeCamera(int width, int height) {
        mCamera = new VideoCapture(Highgui.CV_CAP_ANDROID);
        //TODO: improve error handling
        
        java.util.List<Size> sizes = mCamera.getSupportedPreviewSizes();
        int maxWidth = 640;
        int maxHeight = 480;
        
        int frameWidth = width;
        int frameHeight = height;

        // selecting optimal camera preview size
        {
            double minDiff = Double.MAX_VALUE;
            for (Size size : sizes) {
                if (size.width <= maxWidth && size.height <= maxHeight) {
                    frameWidth = (int) size.width;
                    frameHeight = (int) size.height;
                    break;
                }
            }
        }

        mCamera.set(Highgui.CV_CAP_PROP_FRAME_WIDTH, frameWidth);
        mCamera.set(Highgui.CV_CAP_PROP_FRAME_HEIGHT, frameHeight);
        
        mFrameWidth = frameWidth;
        mFrameHeight = frameHeight;
        
        Log.i(TAG, "Selected camera frame size = (" + mFrameWidth + ", " + mFrameHeight + ")");
       
	}
	
	private void releaseCamera() {
		if (mCamera != null) {
			mCamera.release();
		}
	}
	
	private class CameraWorker implements Runnable {
		
	    private Mat mRgba = new Mat();
	    private int mWidth;
	    private int mHeight;
	    
	    CameraWorker(int w, int h) {
	    	mWidth = w;
	    	mHeight = h;
	    }

		@Override
		public void run() {
			Mat modified;
			Bitmap cacheBitmap = Bitmap.createBitmap(mFrameWidth, mFrameHeight, Bitmap.Config.ARGB_8888);
			
			
			do {
				synchronized(mSyncObject) {
					if (!mCamera.grab()) {
						Log.e(TAG, "Camera frame grab failed");
						break;
					}
		            mCamera.retrieve(mRgba, Highgui.CV_CAP_ANDROID_COLOR_FRAME_RGBA);
				}
	            if (mListener != null) {
	            	modified = mListener.onCameraFrame(mRgba);
	            } else {
	            	modified = mRgba;
	            }
	            
	            if (modified != null) {
	                Utils.matToBitmap(mRgba, cacheBitmap);
	            }
	            
	            if (cacheBitmap != null) {
	                Canvas canvas = getHolder().lockCanvas();
	                if (canvas != null) {
	                    canvas.drawBitmap(cacheBitmap, (canvas.getWidth() - cacheBitmap.getWidth()) / 2, (canvas.getHeight() - cacheBitmap.getHeight()) / 2, null);
	                    getHolder().unlockCanvasAndPost(canvas);
	                }
	            }

			} while (!mStopThread);
			
			if (cacheBitmap != null) {
				cacheBitmap.recycle();
			}
		}
	}

}
