cmake_minimum_required(VERSION 3.4.1)

include_directories(../include)

add_library(lib_opencv SHARED IMPORTED)
set_target_properties(lib_opencv PROPERTIES IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/src/main/jniLibs/${ANDROID_ABI}/libopencv_java4.so)

find_library(log-lib log)

add_library(native_opencv SHARED ../ios/Classes/native_opencv.cpp)

set( PROJECT_VERSION 1.0 )
set( PROJECT_VERSION_MAJOR 1.0 )

set( libheif_src_DIR ../include/libheif/libheif )
set( libheif_build_DIR ../include/libheif-build )
file(MAKE_DIRECTORY ${libheif_build_DIR})

add_subdirectory(${libheif_src_DIR} ${libheif_build_DIR})

add_library( libheif STATIC IMPORTED )
set_target_properties( libheif PROPERTIES IMPORTED_LOCATION
                       ${libheif_build_DIR}/${ANDROID_ABI}/libheif.a )
include_directories( ${libheif_src_DIR} )

target_link_libraries( native_opencv ... libheif )


target_link_libraries(native_opencv lib_opencv libheif ${log-lib})
