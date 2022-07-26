NDK=$HOME/Library/Android/sdk/ndk/21.4.7075529

# TODO: tell to install libde as in https://github.com/strukturag/libheif/blob/master/scripts/install-ci-linux.sh#L45-L56

# for ABI in "arm64-v8a" "x86_64" "x86" "armeabi-v7a"; do
for ABI in "arm64-v8a"; do
    # BUILD_LIBDE=../build-libde/$ABI
    # mkdir -p $BUILD_LIBDE

    # cmake -S ../libde265 -B $BUILD_LIBDE \
    #     -DCMAKE_TOOLCHAIN_FILE=$NDK/build/cmake/android.toolchain.cmake \
    #     -DANDROID_ABI=$ABI \
    #     -DANDROID_NATIVE_API_LEVEL=29
    
    # cmake --build $BUILD_LIBDE -j 4

    BUILD_LIBHEIF=../build-libheif/$ABI     
    mkdir -p $BUILD_LIBHEIF

    cmake -S . -B $BUILD_LIBHEIF \
        -DCMAKE_TOOLCHAIN_FILE=$NDK/build/cmake/android.toolchain.cmake \
        -DWITH_LIBDE265=ON \
        -DANDROID_ABI=$ABI \
        -DANDROID_NATIVE_API_LEVEL=29

    cmake --build $BUILD_LIBHEIF -j 4
done

