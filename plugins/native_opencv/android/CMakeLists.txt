cmake_minimum_required(VERSION 3.4.1)

include_directories(../include)

add_subdirectory(../include/libheif ${CMAKE_CURRENT_BINARY_DIR}/libheif)

add_library(lib_opencv SHARED IMPORTED)
set_target_properties(lib_opencv PROPERTIES IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/src/main/jniLibs/${ANDROID_ABI}/libopencv_java4.so)

find_library(log-lib log)

add_library(libheif ../include/libheif/libheif/heif.h)
set_target_properties(libheif PROPERTIES LINKER_LANGUAGE CPP)

add_library(native_opencv SHARED ../ios/Classes/native_opencv.cpp)
target_link_libraries(native_opencv lib_opencv libheif ${log-lib})
