#include "video_connector.hpp"

#include <dlfcn.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <dirent.h>
#include <android/log.h>

#include "EngineCommon.h"
#include <opencv2/core/version.hpp>

using namespace std;

#undef LOGE
#undef LOGD
#undef LOGI

#define VIDEO_LOG_TAG "OpenCV::video"
#define LOGD(...) ((void)__android_log_print(ANDROID_LOG_DEBUG, VIDEO_LOG_TAG, __VA_ARGS__))
#define LOGI(...) ((void)__android_log_print(ANDROID_LOG_INFO, VIDEO_LOG_TAG, __VA_ARGS__))
#define LOGE(...) ((void)__android_log_print(ANDROID_LOG_ERROR, VIDEO_LOG_TAG, __VA_ARGS__))

#define PREFIX_VIDEO_WRAPPER_LIB "libnative_video"

AndroidVideoLibConnector* AndroidVideoLibConnector::sInstance = NULL;

/************** AndroidVideoLibConnector methods implementation ********************/

AndroidVideoLibConnector::AndroidVideoLibConnector()
{
    /* Do this at the constructor. As this is a singleton it will be executed just once */
    pathLibFolder = getPathLibFolder();
    mIsConnected = false;
}

AndroidVideoLibConnector::~AndroidVideoLibConnector()
{
    /* TODO: Release the library handle */
}

bool AndroidVideoLibConnector::connectToLib()
{
    if (mIsConnected) return true;

    /* Not connected yet. Need to connect and initalize */
    std::string folderPath = getPathLibFolder();
    if (folderPath.empty())
    {
        LOGD("Trying to find native video in default OpenCV packages");
        folderPath = getDefaultPathLibFolder();
    }

    LOGD("VideoWrapperConnector::connectToLib: folderPath=%s", folderPath.c_str());

    vector<string> listLibs;
    fillListWrapperLibs(folderPath, listLibs);
    std::sort(listLibs.begin(), listLibs.end(), std::greater<string>());

    string cur_path;
    for(size_t i = 0; i < listLibs.size(); i++) {
        cur_path=folderPath + listLibs[i];
        LOGD("try to load library '%s'", listLibs[i].c_str());
        libHandle = dlopen(cur_path.c_str(), RTLD_LAZY);
        if (libHandle) {
            LOGD("Loaded library '%s'", cur_path.c_str());
            break;
        } else {
            LOGD("VideoWrapperConnector::connectToLib ERROR: cannot dlopen video wrapper library %s, dlerror=\"%s\"",
                 cur_path.c_str(), dlerror());
        }
    }

    if (!libHandle) {
        LOGE("VideoWrapperConnector::connectToLib ERROR: cannot dlopen video wrapper library");
        return false;
    }

    /* Now get the functions from the library: PREPARE, WRITE_FRAME, STOP */
    prepareRecorder = (prepareVideoRecorder_t)getSymbolAdress("prepareVideoRecorder");
    destroyRecorder = (destroyVideoRecorder_t)getSymbolAdress("destroyVideoRecorder");
    writeRecorderNextFrame = (writeVideRecorderNextFrame_t)getSymbolAdress("writeVideRecorderNextFrame");

    mIsConnected = (prepareRecorder && destroyRecorder && writeRecorderNextFrame);

    return mIsConnected;
}

void AndroidVideoLibConnector::fillListWrapperLibs(const string& folderPath, vector<string>& listLibs)
{
    DIR *dp;
    struct dirent *ep;

    dp = opendir (folderPath.c_str());
    if (dp != NULL)
    {
        while ((ep = readdir (dp))) {
            const char* cur_name=ep->d_name;
            if (strstr(cur_name, PREFIX_VIDEO_WRAPPER_LIB)) {
                listLibs.push_back(cur_name);
                LOGE("||%s", cur_name);
            }
        }
        (void) closedir (dp);
    }
}

void* AndroidVideoLibConnector::getSymbolAdress(const char* symbolName)
{
    dlerror();
    void * pSymbol = dlsym(libHandle, symbolName);

    const char* error_dlsym_init=dlerror();
    if (error_dlsym_init)
    {
        LOGE("AndroidVideoLibConnector::getSymbolFromLib ERROR: cannot get symbol of the function '%s' from the camera wrapper library, dlerror=\"%s\"",
             symbolName, error_dlsym_init);
        return NULL;
    }
    return pSymbol;
}

std::string AndroidVideoLibConnector::getDefaultPathLibFolder()
{
    #define BIN_PACKAGE_NAME(x) "org.opencv.lib_v" CVAUX_STR(CV_VERSION_EPOCH) CVAUX_STR(CV_VERSION_MAJOR) "_" x
    const char* const packageList[] = {BIN_PACKAGE_NAME("armv7a"), OPENCV_ENGINE_PACKAGE};
    for (size_t i = 0; i < sizeof(packageList)/sizeof(packageList[0]); i++)
    {
        char path[128];
        sprintf(path, "/data/data/%s/lib/", packageList[i]);
        LOGD("Trying package \"%s\" (\"%s\")", packageList[i], path);

        DIR* dir = opendir(path);
        if (!dir)
        {
            LOGD("Package not found");
            continue;
        }
        else
        {
            closedir(dir);
            return path;
        }
    }

    return string();
}

void probeFunction();
void probeFunction() {}

std::string AndroidVideoLibConnector::getPathLibFolder()
{
    if (!pathLibFolder.empty())
        return pathLibFolder;

    Dl_info dl_info;
    if(0 != dladdr((void*)probeFunction, &dl_info))
    {
        LOGD("Library name: %s", dl_info.dli_fname);
        LOGD("Library base address: %p", dl_info.dli_fbase);

        const char* libName=dl_info.dli_fname;
        while( ((*libName)=='/') || ((*libName)=='.') )
            libName++;

        char lineBuf[2048];
        FILE* file = fopen("/proc/self/smaps", "rt");

        if(file)
        {
            while (fgets(lineBuf, sizeof lineBuf, file) != NULL)
            {
                //verify that line ends with library name
                int lineLength = strlen(lineBuf);
                int libNameLength = strlen(libName);

                //trim end
                for(int i = lineLength - 1; i >= 0 && isspace(lineBuf[i]); --i)
                {
                    lineBuf[i] = 0;
                    --lineLength;
                }

                if (0 != strncmp(lineBuf + lineLength - libNameLength, libName, libNameLength))
                {
                    //the line does not contain the library name
                    continue;
                }

                //extract path from smaps line
                char* pathBegin = strchr(lineBuf, '/');
                if (0 == pathBegin)
                {
                    LOGE("Strange error: could not find path beginning in lin \"%s\"", lineBuf);
                    continue;
                }

                char* pathEnd = strrchr(pathBegin, '/');
                pathEnd[1] = 0;

                LOGD("Libraries folder found: %s", pathBegin);

                fclose(file);
                return pathBegin;
            }
            fclose(file);
            LOGE("Could not find library path.");
        }
        else
        {
            LOGE("Could not read /proc/self/smaps");
        }
    }
    else
    {
        LOGE("Could not get library name and base address.");
    }

    return DEFAULT_PATH_LIB_FOLDER ;
}

void* AndroidVideoLibConnector::prepareVideoRecorder(char* fileName, int width, int height)
{
    if (prepareRecorder != NULL)
    {
        void* res;
        res = prepareRecorder(fileName, width, height);

        return res;
    }
    return NULL;
}
bool AndroidVideoLibConnector::writeVideRecorderNextFrame(void* context, const IplImage* image)
{
    if (writeRecorderNextFrame != NULL)
    {
        char* buffer = NULL;
        int size = 0;

        size = image->imageSize;
        buffer = (char*) image->imageData;

        /*TODO: Convert the image from IplImage to an array of bytes of the RGBA format and pass it to the library for recording */
        return writeRecorderNextFrame(context, buffer, size);
    }
    return false;
}
/**
 * Method to destroy the recorder. It will stop recording, close the output file and release
 * reources associated with recorder.
 */
void AndroidVideoLibConnector::destroyVideoRecorder(void* context)
{
    if (destroyRecorder!= NULL)
    {
        destroyRecorder(context);
    }
}

/**
 * AndroidVideoLibConnector is a singleton class in applications, as only one connection to lib required.
 * At the same time many video writers can be created at a time.
 */

AndroidVideoLibConnector* AndroidVideoLibConnector::AndroidVideoLibConnector::getInstance()
{
    if (sInstance == NULL)
    {
        sInstance = new AndroidVideoLibConnector();
    }

    return sInstance;
}
