cmake_minimum_required(VERSION 3.4.1)

include_directories(../include)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../include/libheif)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../include/libheif/libheif)

add_library(lib_opencv SHARED IMPORTED)
set_target_properties(lib_opencv PROPERTIES IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/src/main/jniLibs/${ANDROID_ABI}/libopencv_java4.so)

find_library(log-lib log)

SET(CMAKE_C_LINK_EXECUTABLE ${CMAKE_CXX_LINK_EXECUTABLE})

add_library(libheif STATIC ../include/libheif/libheif)
set_target_properties(libheif PROPERTIES LINKER_LANGUAGE CXX) 

add_library(native_opencv SHARED ../ios/Classes/native_opencv.cpp)

target_include_directories(
        native_opencv PUBLIC
        ../include/libheif/libheif
)

target_link_libraries(native_opencv lib_opencv libheif ${log-lib})
