#include "video_connector.hpp"

#include <android/log.h>
#include <dlfcn.h>

#if !defined(LOGD) && !defined(LOGI) && !defined(LOGE)
#define LOG_TAG "CV_WRITER_ANDROID"
#define LOGD(...) ((void)__android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__))
#define LOGI(...) ((void)__android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__))
#define LOGE(...) ((void)__android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__))
#endif

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
    std::string cur_path = pathLibFolder + ANDROID_VIDEO_LIBRARY_NAME;
    LOGD("try to load library '%s'", cur_path.c_str());
    libHandle = dlopen(cur_path.c_str(), RTLD_LAZY);
    if (libHandle) {
        LOGD("Loaded library '%s'", cur_path.c_str());
        mIsConnected = true;
        /* Now get the functions from the library: PREPARE, WRITE_FRAME, STOP */
        /*TODO: Check that all symbols are present */
        prepareRecorder = (prepareVideoRecorder_t)getSymbolAdress("prepareVideoRecorder");
        destroyRecorder = (destroyVideoRecorder_t)getSymbolAdress("destroyVideoRecorder");
        writeRecorderNextFrame = (writeVideRecorderNextFrame_t)getSymbolAdress("writeVideRecorderNextFrame");
        return true;

    } else {
        LOGD("AndroidVideoLibConnector::connectToLib ERROR: cannot dlopen video library %s, dlerror=\"%s\"",
             cur_path.c_str(), dlerror());
        return false;
    }
}

void* AndroidVideoLibConnector::getSymbolAdress(const char* symbolName)
{
    dlerror();
    void * pSymbol = dlsym(libHandle, symbolName);

    const char* error_dlsym_init=dlerror();
    if (error_dlsym_init) {
        LOGE("AndroidVideoLibConnector::getSymbolFromLib ERROR: cannot get symbol of the function '%s' from the camera wrapper library, dlerror=\"%s\"",
             symbolName, error_dlsym_init);
        return NULL;
    }
    return pSymbol;
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
