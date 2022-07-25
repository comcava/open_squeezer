cmake_minimum_required(VERSION 3.4.1)

include_directories(../include)

add_library(lib_opencv SHARED IMPORTED)
set_target_properties(lib_opencv PROPERTIES IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/src/main/jniLibs/${ANDROID_ABI}/libopencv_java4.so)

find_library(log-lib log)

add_library(native_opencv SHARED ../ios/Classes/native_opencv.cpp)

set( PROJECT_VERSION 1.0 )
set( PROJECT_VERSION_MAJOR 1.0 )

set( libheif_src_DIR ../include/libheif/libheif )

add_library( libheif STATIC IMPORTED )
set_target_properties( libheif PROPERTIES IMPORTED_LOCATION
                        ${CMAKE_SOURCE_DIR}/../include/build-libheif/${ANDROID_ABI}/libheif/libheif.so
                    )

include_directories(${CMAKE_SOURCE_DIR}/${libheif_src_DIR})

target_link_libraries( native_opencv ... libheif )


target_link_libraries(native_opencv lib_opencv libheif ${log-lib})
