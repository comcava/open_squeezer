cmake_minimum_required(VERSION 3.4.1)

include_directories(../include)

add_library(lib_opencv SHARED IMPORTED)
set_target_properties(lib_opencv PROPERTIES IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/src/main/jniLibs/${ANDROID_ABI}/libopencv_java4.so)

find_library(log-lib log)

add_library(native_opencv SHARED ../ios/Classes/native_opencv.cpp)

set (LIBHEIF_DIR ../include/libheif/libheif)

add_library(libheif ${LIBHEIF_DIR}/heif.h)

add_subdirectory(${LIBHEIF_DIR} .)
include_directories(LIBHEIF_DIR)

target_link_libraries(native_opencv lib_opencv ${log-lib} libheif)
