NDK=$HOME/Library/Android/sdk/ndk/21.4.7075529

for ABI in "arm64-v8a" "x86_64" "x86" "armeabi-v7a"; do
# for ABI in "armeabi-v7a"; do

    DESTINATION_DIR=../build-libheif/$ABI     
    mkdir -p $DESTINATION_DIR

    cmake -S . -B $DESTINATION_DIR \
        -DCMAKE_TOOLCHAIN_FILE=$NDK/build/cmake/android.toolchain.cmake \
        -DANDROID_ABI=$ABI \
        -DANDROID_NATIVE_API_LEVEL=29

    cmake --build $DESTINATION_DIR -j 4
done

