# Copyright (C) 2009 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

# Enable OpenCV libraries processing
OPENCV_CAMERA_MODULES:=on
OPENCV_INSTALL_MODULES:=on

# When building this JNI library it is required to pass the OPENCV_MK_PATH environment variable to NDK-BUILD script.
# This variable shall point to: OpenCV.mk file from the OpenCV SDK you are using
include $(OPENCV_MK_PATH)



LOCAL_MODULE    := camerawriter_jni
LOCAL_SRC_FILES := camerawriter_jni.cpp

LOCAL_SHARED_LIBRARIES += libopencv_java

# TODO - add referemce to OpenCV native libs


LOCAL_LDLIBS += -llog 



include $(BUILD_SHARED_LIBRARY)
