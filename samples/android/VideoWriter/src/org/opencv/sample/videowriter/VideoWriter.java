package org.opencv.sample.videowriter;

import org.opencv.core.Mat;

import android.util.Log;
/** 
 * Special OpenCV class which interacts with native OpenCV VideoWriter interface.
 * It is initialzed with a file name where to save the video.
 * After startRecording is called the client may start calling writeNextFrame() to write
 * the video frame by frame.
 * After stop recording is called, the file is closed and VideoWriter object can't be used anymore.
 * To start writing new file - new object to be created.
 */
public class VideoWriter  {
	
	private static final String TAG = "VideoWriter";

	private static boolean sInitialized = false;
	
	private String mFileName;
	
	private int mWidth;
	private int mHeight; 
	
	public VideoWriter(String fileName, int width, int height) {
		mFileName = fileName;
		mWidth = width;
		mHeight = height;
		
		if (!sInitialized) {
			try {
			System.loadLibrary("camerawriter_jni");
			sInitialized = true;
			} catch (UnsatisfiedLinkError ex) {
				Log.e(TAG, "Can't load camerawriter_jni library", ex);
			}
		}
	}
	
	public synchronized  void startRecording() {
		
		nativeStartRecording(mFileName, mWidth, mHeight);
	}
	
	public synchronized void stopRecording() {
		nativeStopRecording();
	}
	
	public synchronized void writeNextFrame(Mat aRgbFrame) {
		nativeWriteNextFrame(aRgbFrame.getNativeObjAddr());
	}

	/*** Set of native functions which talks to video write functionality */
	private native void nativeStartRecording(String fileName, int width, int height);
	private native void nativeStopRecording();
	private native void nativeWriteNextFrame(long matAddress);
}
