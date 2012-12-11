
#include <string.h>
#include <jni.h>

#include <android/log.h>
#include <opencv2/core/core.hpp>
#include <opencv2/core/mat.hpp>
#include <opencv2/highgui/highgui_c.h>

//#include <opencv/highgui.h>

#define  LOG_TAG "CameraWriter_jni"
#define  LOGI(...)  __android_log_print(ANDROID_LOG_INFO,LOG_TAG,__VA_ARGS__)
#define  LOGE(...)  __android_log_print(ANDROID_LOG_ERROR,LOG_TAG,__VA_ARGS__)


CvVideoWriter* videoWriter;
jfieldID nativeObjId;

using namespace cv;



extern "C" JNIEXPORT void Java_org_opencv_sample_videowriter_VideoWriter_nativeStartRecording( JNIEnv* env, jobject thiz, 
                                                                      jstring jFileName, jint width, jint height)
{
    CvSize frameSize = {width, height};
    const char* filePath = env->GetStringUTFChars(jFileName, 0);


    LOGE("Native Start recording is called(%s)", filePath);
    videoWriter = cvCreateVideoWriter(filePath, 0, 30, frameSize);
    LOGE("Video Writer created: %p", videoWriter);

    env->ReleaseStringUTFChars(jFileName, filePath);

}

extern "C" JNIEXPORT void Java_org_opencv_sample_videowriter_VideoWriter_nativeWriteNextFrame( JNIEnv* env, jobject thiz, jlong matObject)
{
    Mat* nativeMat;
    IplImage* image;

    /* Get a native mat out of JAVA Mat object */
    nativeMat = (Mat*) matObject;
    
    image = new IplImage(*nativeMat);

    LOGE("Native write next frame");
    if (videoWriter != NULL) {
        cvWriteFrame(videoWriter, image);
    } else {
        LOGE("ERROR: Video Writer is null");
    }
    delete image;

}

extern "C" JNIEXPORT void Java_org_opencv_sample_videowriter_VideoWriter_nativeStopRecording( JNIEnv* env, jobject thiz)
{
    LOGE("Native stop recording is called");
    if (videoWriter != NULL) {
        cvReleaseVideoWriter(&videoWriter);
    }
}
