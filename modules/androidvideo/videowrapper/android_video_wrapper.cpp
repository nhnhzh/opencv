#include <stdio.h>
#include <fcntl.h>
#include <pthread.h>
#include <unistd.h>

#include <android/log.h>
#define TAG "AndroidVideRecorder"
#define LOGV(...) __android_log_print(ANDROID_LOG_VERBOSE, TAG, __VA_ARGS__)

#include <android/native_window.h>

/*** Headers from the android buid, but not included into NDK */
#include <binder/IServiceManager.h>
#include <media/IMediaPlayerService.h>
#include <media/IMediaRecorder.h>
#include <media/mediarecorder.h>

#include <gui/ISurfaceTexture.h>
#include <gui/SurfaceTextureClient.h>

/*
typedef void* (*prepareVideoRecorder_t)(char* fileName, int width, int height);
typedef void (*destroyVideoRecorder_t)(void* context);
typedef bool (*writeVideRecorderNextFrame_t)(void* context, char* buffer, int size);
*/

using namespace android;

class RecorderContext {

public:
    RecorderContext() {};

    sp<IMediaRecorder>  mediaRecorder;
    int fileDescriptor;
    sp<SurfaceTextureClient> surfaceClient;
    ANativeWindow* nativeWindow;
};

int prepareFd(char* file_name)
{
	int fd;

	fd = open(file_name, O_CREAT | O_WRONLY);

	return  fd;
}


extern "C" void* prepareVideoRecorder(char* fileName, int width, int height)
{
    status_t status;
    RecorderContext* context = new RecorderContext;

    LOGV("prepareVideoRecorder called\n");

    sp<IServiceManager>  serviceManager = defaultServiceManager();
    sp<IMediaPlayerService> mediaService;

    getService(String16("media.player"), &mediaService);
    sp<IMediaRecorder>  mediaRecorder = mediaService->createMediaRecorder(getpid());

    if (mediaRecorder == NULL)
    {
        delete context;
        return NULL;
    }

    context->mediaRecorder = mediaRecorder;

    status = mediaRecorder->setVideoSource(VIDEO_SOURCE_GRALLOC_BUFFER);
    LOGV("setVideoSource status: %d\n", status);
    if (status)
    {
        delete context;
        return NULL;
    }

    status = mediaRecorder->setOutputFormat(OUTPUT_FORMAT_MPEG_4);
    LOGV("setOutputFormat status: %d\n", status);
    if (status)
    {
        delete context;
        return NULL;
    }

	int fd = prepareFd(fileName);
    if (fd < 0)
    {
        LOGV("Failed to create output file");
        delete context;
        return NULL;
    }
    context->fileDescriptor = fd;

    status = mediaRecorder->setOutputFile(fd, 0, 0);
    status = mediaRecorder->setVideoEncoder(VIDEO_ENCODER_MPEG_4_SP);
    status = mediaRecorder->setVideoSize(width, height);

    if (status)
    {
        LOGV("Failed to set requested video size %d", status);
        close(context->fileDescriptor);
        delete context;
        return NULL;
    }

    status = mediaRecorder->prepare();
    if (status)
    {
        LOGV("Failed to prepare recorder %d", status);
        close(context->fileDescriptor);
        delete context;
        return NULL;
    }

    status = mediaRecorder->start();
    LOGV("Media Recorder start: %d\n", status);
    if (status)
    {
        LOGV("Failed to start recorder %d", status);
        mediaRecorder->release();
        close(context->fileDescriptor);
        delete context;
        return NULL;
    }

    /* Can this return NULL if all previous checks passed? */
    sp<ISurfaceTexture> surfaceTexture = mediaRecorder->querySurfaceMediaSource();
    context->surfaceClient = new SurfaceTextureClient(surfaceTexture);

    context->nativeWindow = context->surfaceClient.get();
    ANativeWindow_setBuffersGeometry(context->nativeWindow, ANativeWindow_getWidth(context->nativeWindow), ANativeWindow_getHeight(context->nativeWindow), WINDOW_FORMAT_RGBA_8888);

    /* Aquire the native window. It will connect to the GUI server */
    ANativeWindow_acquire(context->nativeWindow);

    return context;
}

// FIXME: Why return NULL? is return value realy needed?
void* destroyFunction(void* context)
{
    RecorderContext* recContext = (RecorderContext*) context;
    ANativeWindow_Buffer bufferContainer;
    ANativeWindow_Buffer* buffer = &bufferContainer;

    LOGE("Destroy function is called");

    // HACK: Ugly workaround. Get rid of the sleep function
    sleep(1);

    ANativeWindow_lock(recContext->nativeWindow, buffer, NULL);
    ANativeWindow_unlockAndPost(recContext->nativeWindow);

    LOGE("Destroy fucntion finished");

    return NULL;
}

extern "C" void destroyVideoRecorder(void* context)
{
    status_t status;
    RecorderContext* recContext = (RecorderContext*) context;

    LOGV("destroyVideoRecorder called\n");

    /* HACK: This is an ugly workaround of the Android media recorder bug. It stop function may stuck forever because it would wait for
     * media source read function to return. But it would not return until one more frame would be available or stop method is called.
     * stop method is not available for our process and the only way is to put one more "dummy" frame.
     * Another thread is started, waits for some time and then put's one more frame
     */
    pthread_t thread;
    int tid = pthread_create(&thread, NULL, destroyFunction, context);

    /* Stop the media recorder */
    status = recContext->mediaRecorder->stop();
    LOGV("Media Recorder stop: %d\n", status);

    /* Wait till workaround thread completes before releasing native window */
    pthread_join(thread, NULL);

    /* Now we can release native window */
    ANativeWindow_release(recContext->nativeWindow);

    status = recContext->mediaRecorder->release();
    LOGV("Media Recorder release: %d\n", status);

    close(recContext->fileDescriptor);

    delete recContext;
}

extern "C" bool writeVideRecorderNextFrame(void* context, char* imageBuffer, int size)
{
    status_t status;
    RecorderContext* recContext = (RecorderContext*) context;
    ANativeWindow_Buffer bufferContainer;
    ANativeWindow_Buffer* buffer = &bufferContainer;

    if (ANativeWindow_lock(recContext->nativeWindow, buffer, NULL) >=  0)
    {
        int bpp;
        if (buffer != NULL)
        {
            if (buffer->format == WINDOW_FORMAT_RGBA_8888 || buffer->format == WINDOW_FORMAT_RGBX_8888)
            {
                bpp = 4;
            }
            else
            {
                bpp = 2;
            }

            if ((buffer->stride * buffer->height * bpp) < size)
            {
                /* Too big data passed. May be simply ignore part of the buffer? */
                ANativeWindow_unlockAndPost(recContext->nativeWindow);
                LOGV("Frame passed to recorder is bigger then the original size");
                return false;
            }
            memcpy(buffer->bits, imageBuffer, size);
        }

        ANativeWindow_unlockAndPost(recContext->nativeWindow);
        return true;

    }
    else
    {
        return false;
    }
}
