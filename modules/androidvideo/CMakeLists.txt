set(the_description "Auxiliary module for Android native video writer support")
#set(OPENCV_MODULE_TYPE STATIC)

#ocv_define_module(androidvideo INTERNAL log dl)
#ocv_include_directories("${CMAKE_CURRENT_SOURCE_DIR}/androidvideo")

if(BUILD_ANDROID_VIDEO_WRAPPER)
  add_subdirectory(videowrapper)
else()
  # use prebuilt
  set(video_wrapper "${CMAKE_CURRENT_SOURCE_DIR}/../../3rdparty/lib/${ANDROID_NDK_ABI_NAME}/libandroidvideo.so")

  ADD_CUSTOM_COMMAND(
    TARGET androidvideo POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy "${video_wrapper}" "${LIBRARY_OUTPUT_PATH}"
  )

  get_filename_component(wrapper_name "${video_wrapper}" NAME)
  install(
    FILES "${LIBRARY_OUTPUT_PATH}/${wrapper_name}"
    DESTINATION ${OPENCV_LIB_INSTALL_PATH}
    COMPONENT main
  )
endif()
