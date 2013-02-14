#ifndef _VIDEOCONNECTOR_H_
#define _VIDEOCONNECTOR_H_

#include <string>
#include <vector>
#include <opencv2/core/core.hpp>

#define DEFAULT_WRAPPER_PACKAGE_NAME "org.itseez.opencv"
#define DEFAULT_PATH_LIB_FOLDER "/data/data/" DEFAULT_WRAPPER_PACKAGE_NAME "/lib/"

#define ANDROID_VIDEO_LIBRARY_NAME "libnative_video_r4.2.0.so"

typedef void* (*prepareVideoRecorder_t)(char* fileName, int width, int height);
typedef void (*destroyVideoRecorder_t)(void* context);
typedef bool (*writeVideRecorderNextFrame_t)(void* context, char* buffer, int size);

/** Definition of the AndroidVideoLibConnector class for Android. ******
 * To avoid direct dependency on the Android headers this class is a proxy around
 * the functios provided by a separate libandroidvideo.so object.
 * This class connects to library, checks that the required video writer can be created.
 * This class is a singleton.
 ****/

class AndroidVideoLibConnector
{
public:
    ~AndroidVideoLibConnector();

    static AndroidVideoLibConnector* getInstance();

    bool connectToLib();

    /* Record control functions */
    void* prepareVideoRecorder(char* fileName, int width, int height);
    bool writeVideRecorderNextFrame(void* context, const IplImage* image);
    void destroyVideoRecorder(void* context);

private:
    AndroidVideoLibConnector();

    std::string getPathLibFolder();
    void fillListWrapperLibs(const std::string& folderPath, std::vector<std::string>& listLibs);
    std::string getDefaultPathLibFolder();
    void* getSymbolAdress(const char* name);

    std::string pathLibFolder;
    bool mIsConnected;

    static AndroidVideoLibConnector* sInstance;

    prepareVideoRecorder_t prepareRecorder;
    destroyVideoRecorder_t destroyRecorder;
    writeVideRecorderNextFrame_t writeRecorderNextFrame;

    void* libHandle;
};

#endif
