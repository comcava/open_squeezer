

mkdir -p download
cd download

# wget -O opencv-4.6.0-android-sdk.zip https://sourceforge.net/projects/opencvlibrary/files/4.6.0/opencv-4.6.0-android-sdk.zip/download
# wget -O opencv-4.6.0-ios-framework.zip https://sourceforge.net/projects/opencvlibrary/files/4.6.0/opencv-4.6.0-ios-framework.zip/download

unzip opencv-4.6.0-android-sdk.zip
unzip opencv-4.6.0-ios-framework.zip

cp -r opencv2.framework ../../plugins/native_opencv/ios
cp -r OpenCV-android-sdk/sdk/native/jni/include ../../plugins/native_opencv
mkdir -p ../../plugins/native_opencv/android/src/main/jniLibs/
cp -r OpenCV-android-sdk/sdk/native/libs/* ../../plugins/native_opencv/android/src/main/jniLibs/

