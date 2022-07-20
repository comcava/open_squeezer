

mkdir -p download
cd download

echo "Downloading opencv"

# you can use `curl -L <url> -o <file>`, but it sometimes
# doesn't like the SSL certificate, so we're using wget here
wget -O opencv-4.6.0-android-sdk.zip https://sourceforge.net/projects/opencvlibrary/files/4.6.0/opencv-4.6.0-android-sdk.zip/download
wget -O opencv-4.6.0-ios-framework.zip https://sourceforge.net/projects/opencvlibrary/files/4.6.0/opencv-4.6.0-ios-framework.zip/download

unzip opencv-4.6.0-android-sdk.zip
unzip opencv-4.6.0-ios-framework.zip

cp -r opencv2.framework ../../plugins/native_opencv/ios
cp -r OpenCV-android-sdk/sdk/native/jni/include ../../plugins/native_opencv
mkdir -p ../../plugins/native_opencv/android/src/main/jniLibs/
cp -r OpenCV-android-sdk/sdk/native/libs/* ../../plugins/native_opencv/android/src/main/jniLibs/

echo "Downloading libheif"

wget -O libheif-1.12.0.tar.gz https://github.com/strukturag/libheif/releases/download/v1.12.0/libheif-1.12.0.tar.gz
tar -xvf libheif-1.12.0.tar.gz
cp -r libheif-1.12.0 ../../plugins/native_opencv/include/
