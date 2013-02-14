IF(NOT ANDROID OR ANDROID_NATIVE_API_LEVEL LESS 8)
  ocv_module_disable(androidvideo)
ENDIF()

set(the_description "Auxiliary module for Android native video i/o support")
set(OPENCV_MODULE_TYPE STATIC)

ocv_define_module(androidvideo INTERNAL opencv_core log dl)
ocv_include_directories("${OpenCV_SOURCE_DIR}/android/service/engine/jni/include")

# Android source tree for video writer
SET (ANDROID_SOURCE_TREE "ANDROID_SOURCE_TREE-NOTFOUND" CACHE PATH
  "Path to Android source tree. Set this variable to path to your Android sources to compile libnative_video_rx.x.x.so for your Android")
SET(BUILD_ANDROID_VIDEO_WRAPPER OFF)
if(ANDROID_SOURCE_TREE)
  FILE(STRINGS "${ANDROID_SOURCE_TREE}/development/sdk/platform_source.properties" ANDROID_VERSION REGEX "Platform\\.Version=[0-9]+\\.[0-9]+(\\.[0-9]+)?" )
  string(REGEX REPLACE "Platform\\.Version=([0-9]+\\.[0-9]+(\\.[0-9]+)?)" "\\1" ANDROID_VERSION "${ANDROID_VERSION}")
  if(ANDROID_VERSION MATCHES "^[0-9]+\\.[0-9]+$")
    SET(ANDROID_VERSION "${ANDROID_VERSION}.0")
  endif()
  if(NOT "${ANDROID_VERSION}" STREQUAL "")
    SET(BUILD_ANDROID_VIDEO_WRAPPER ON)
    set(ANDROID_VERSION "${ANDROID_VERSION}" CACHE INTERNAL "Version of Android source tree")
  endif()
endif()
set(BUILD_ANDROID_VIDEO_WRAPPER ${BUILD_ANDROID_CAMERA_WRAPPER} CACHE INTERNAL "Build new wrapper for Android")
MARK_AS_ADVANCED(ANDROID_SOURCE_TREE)

# process wrapper libs
if(BUILD_ANDROID_VIDEO_WRAPPER)
  add_subdirectory(videowrapper)
else()
  file(GLOB video_wrappers "${CMAKE_CURRENT_SOURCE_DIR}/../../3rdparty/lib/${ANDROID_NDK_ABI_NAME}/libnative_video_r*.so")

  foreach(wrapper ${video_wrappers})
    ADD_CUSTOM_COMMAND(
      TARGET ${the_module} POST_BUILD
      COMMAND ${CMAKE_COMMAND} -E copy "${wrapper}" "${LIBRARY_OUTPUT_PATH}"
    )
    get_filename_component(wrapper_name "${wrapper}" NAME)
    install(
      FILES "${LIBRARY_OUTPUT_PATH}/${wrapper_name}"
      DESTINATION ${OPENCV_LIB_INSTALL_PATH}
      COMPONENT main
    )
  endforeach()
endif()
