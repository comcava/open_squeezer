NDK=$HOME/Library/Android/sdk/ndk/21.4.7075529


# for ABI in "arm64-v8a" "x86_64" "x86" "armeabi-v7a"; do
for ABI in "arm64-v8a"; do
    BUILD_DIR=../build-libheif/$ABI     
    mkdir -p $BUILD_DIR

    cmake -S . -B $BUILD_DIR \
        -DCMAKE_TOOLCHAIN_FILE=$NDK/build/cmake/android.toolchain.cmake \
        -DANDROID_ABI=$ABI \
        -DLIBDE265_LIBRARY=../build-libde/$ABI/libde265/libde265.so \
        -DLIBDE265_INCLUDE_DIR=../libde265 \
        -DANDROID_NATIVE_API_LEVEL=29

    cmake --build $BUILD_DIR -j 4
done

