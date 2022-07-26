NDK=$HOME/Library/Android/sdk/ndk/21.4.7075529

# TODO: tell to install libde as in https://github.com/strukturag/libheif/blob/master/scripts/install-ci-linux.sh#L45-L56

# for ABI in "arm64-v8a" "x86_64" "x86" "armeabi-v7a"; do
for ABI in "arm64-v8a"; do

    cmake -S . -B $DESTINATION_DIR \
        -DCMAKE_TOOLCHAIN_FILE=$NDK/build/cmake/android.toolchain.cmake \
        -DLIBDE265_INCLUDE_DIR=./libde265 \
        -DLIBDE265_LIBRARY=./libde265 \
        -DANDROID_ABI=$ABI \
        -DANDROID_NATIVE_API_LEVEL=29

    DESTINATION_DIR=../build-libheif/$ABI     
    mkdir -p $DESTINATION_DIR

    cmake -S . -B $DESTINATION_DIR \
        -DCMAKE_TOOLCHAIN_FILE=$NDK/build/cmake/android.toolchain.cmake \
        -DLIBDE265_INCLUDE_DIR=./libde265 \
        -DLIBDE265_LIBRARY=./libde265 \
        -DANDROID_ABI=$ABI \
        -DANDROID_NATIVE_API_LEVEL=29

    cmake --build $DESTINATION_DIR -j 4
done

