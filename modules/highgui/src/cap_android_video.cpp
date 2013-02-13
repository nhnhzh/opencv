/*M///////////////////////////////////////////////////////////////////////////////////////
//
//  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.
//
//  By downloading, copying, installing or using the software you agree to this license.
//  If you do not agree to this license, do not download, install,
//  copy or use the software.
//
//
//                        Intel License Agreement
//                For Open Source Computer Vision Library
//
// Copyright (C) 2000, Intel Corporation, all rights reserved.
// Third party copyrights are property of their respective owners.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
//   * Redistribution's of source code must retain the above copyright notice,
//     this list of conditions and the following disclaimer.
//
//   * Redistribution's in binary form must reproduce the above copyright notice,
//     this list of conditions and the following disclaimer in the documentation
//     and/or other materials provided with the distribution.
//
//   * The name of Intel Corporation may not be used to endorse or promote products
//     derived from this software without specific prior written permission.
//
// This software is provided by the copyright holders and contributors "as is" and
// any express or implied warranties, including, but not limited to, the implied
// warranties of merchantability and fitness for a particular purpose are disclaimed.
// In no event shall the Intel Corporation or contributors be liable for any direct,
// indirect, incidental, special, exemplary, or consequential damages
// (including, but not limited to, procurement of substitute goods or services;
// loss of use, data, or profits; or business interruption) however caused
// and on any theory of liability, whether in contract, strict liability,
// or tort (including negligence or otherwise) arising in any way out of
// the use of this software, even if advised of the possibility of such damage.
//
//M*/

#include "precomp.hpp"
#include "video_connector.hpp"

#include <android/log.h>
#undef LOG_TAG
#undef LOGD
#undef LOGE
#undef LOGI
#define LOG_TAG "OpenCV::camera"
#define LOGD(...) ((void)__android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__))
#define LOGI(...) ((void)__android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__))
#define LOGE(...) ((void)__android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__))

CvVideoWriter* cvCreateVideoWriter_Android(const char* filename, int fourcc,
                                           double fps, CvSize frameSize, int is_color );

/**
 * Implemenation of the CvVideoWriter interface for Android framework.
 * It is using AndroidVideoLibConnector class to access native library communicating with
 * Android services and libs.
 */
class CvVideoWriter_Android : public CvVideoWriter
{
public:
    CvVideoWriter_Android(const char* filename, int fourcc, double fps, CvSize frameSize);
    virtual ~CvVideoWriter_Android();
    virtual bool writeFrame(const IplImage*);
    
    virtual bool prepare();

private:

    enum {

        STATE_INITIAL,
        STATE_CONNECTED,
        STATE_PREPARED
    };

    char* mFileName;
    int mFourcc;
    int mFps;
    int mWidth;
    int mHeight;


    int mState;
    void* mContext;

    AndroidVideoLibConnector* mConnector;
};


/*********** Implementation of the video writer functions *************/
CvVideoWriter_Android::CvVideoWriter_Android(const char* filename, int fourcc,
                                             double fps, CvSize frameSize)
{
    mFileName = strdup(filename);
    mFourcc = fourcc;
    mFps = (int)fps;
    mWidth = frameSize.width;
    mHeight = frameSize.height;
    mState = STATE_INITIAL;

    mConnector = AndroidVideoLibConnector::getInstance();

    LOGI("Instantiated Android Video Writer for %dx%d at %d FPS", mWidth, mHeight, mFps);
}

CvVideoWriter_Android::~CvVideoWriter_Android()
{
    if (mState == STATE_PREPARED)
    {
        mConnector->destroyVideoRecorder(mContext);
        mContext = NULL;
        mState = STATE_CONNECTED;
    }
    if (mState == STATE_CONNECTED)
    {
        /* Nothing specific to do right now */
        mState = STATE_INITIAL;
    }

    if (mFileName) delete mFileName;

    LOGI("Deleted Android Video Writer");
}

bool CvVideoWriter_Android::prepare()
{   
    bool result = false;
    if (mConnector->connectToLib()) 
    {
        mState = STATE_CONNECTED;
        /* connected to library. It is safe to proceed */
        /*TODO: Add support for the FPS and fourcc checking */
        if ((mContext = mConnector->prepareVideoRecorder(mFileName, mWidth, mHeight)) != NULL)
        {
            mState = STATE_PREPARED;
            result = true;
        }
    }
    
    return result;
}

bool CvVideoWriter_Android::writeFrame(const IplImage* image)
{
    if (mState == STATE_PREPARED)
    {
        return mConnector->writeVideRecorderNextFrame(mContext, image);
    }
    else
    {
        /* Can't write frames to non initialized writer */
        return false;
    }
}


CvVideoWriter* cvCreateVideoWriter_Android(const char* filename, int fourcc, double fps,
                                           CvSize frameSize, int is_color )
{
    (void)is_color;
    
    CvVideoWriter_Android* object = NULL;

    object = new CvVideoWriter_Android(filename, fourcc, fps, frameSize);
    if (object != NULL)
    {
        if (!object->prepare())
        {
            // Failed to prepare object. Either lib is not linked or some
            // parameters are not accepted. Destroy object
            delete object;
            object = NULL;
        }

    }
    
    return object;
}
