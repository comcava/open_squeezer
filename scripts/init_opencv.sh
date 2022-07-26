

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

IBDE265_VERSION=1.0.2
wget -O libde265-${LIBDE265_VERSION}.tar.gz https://github.com/strukturag/libde265/releases/download/v${LIBDE265_VERSION}/libde265-${LIBDE265_VERSION}.tar.gz
tar xf libde265-${LIBDE265_VERSION}.tar.gz
cd libde265-${LIBDE265_VERSION}
./autogen.sh

cd ..
emconfigure ./configure --disable-sse --disable-dec265 --disable-sherlock265
emmake make -j${CORES}

wget -O libheif-1.12.0.tar.gz https://github.com/strukturag/libheif/releases/download/v1.12.0/libheif-1.12.0.tar.gz
tar -xvf libheif-1.12.0.tar.gz
cp -r libheif-1.12.0 ../../plugins/native_opencv/include/
