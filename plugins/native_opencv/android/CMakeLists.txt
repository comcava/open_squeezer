cmake_minimum_required(VERSION 3.4.1)

include(${CMAKE_CURRENT_SOURCE_DIR}/conan_build/conanbuildinfo.cmake)
set(CMAKE_CXX_COMPILER_VERSION "8") # Unknown miss-detection of the compiler by CMake
conan_basic_setup(TARGETS)

include_directories(../include)

add_library(lib_opencv SHARED IMPORTED)
set_target_properties(lib_opencv PROPERTIES IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/src/main/jniLibs/${ANDROID_ABI}/libopencv_java4.so)

find_library(log-lib log)

add_library( libde265 SHARED IMPORTED)
set_target_properties( libde265 PROPERTIES IMPORTED_LOCATION
                       ${CMAKE_CURRENT_SOURCE_DIR}/../include/build-libde/${ANDROID_ABI}/libde265/libde265.so )

include_directories(../include/libheif)
add_library( libheif SHARED IMPORTED)
set_target_properties( libheif PROPERTIES IMPORTED_LOCATION
                       ${CMAKE_CURRENT_SOURCE_DIR}/../include/build-libheif/${ANDROID_ABI}/libheif/libheif.so )

add_library(native_opencv SHARED ../ios/Classes/native_opencv.cpp)

link_libraries(libheif libde265)

target_link_libraries(native_opencv lib_opencv libheif ${log-lib})
