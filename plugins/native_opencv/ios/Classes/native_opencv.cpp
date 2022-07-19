#include <opencv2/opencv.hpp>
#include <chrono>

#if defined(WIN32) || defined(_WIN32) || defined(__WIN32)
#define IS_WIN32
#endif

#ifdef __ANDROID__
#include <android/log.h>
#endif

#ifdef IS_WIN32
#include <windows.h>
#endif

#if defined(__GNUC__)
// Attributes to prevent 'unused' function from being removed and to make it visible
#define FUNCTION_ATTRIBUTE __attribute__((visibility("default"))) __attribute__((used))
#elif defined(_MSC_VER)
// Marking a function for export
#define FUNCTION_ATTRIBUTE __declspec(dllexport)
#endif

using namespace cv;
using namespace std;

long long int get_now()
{
    return chrono::duration_cast<std::chrono::milliseconds>(
               chrono::system_clock::now().time_since_epoch())
        .count();
}

void platform_log(const char *fmt, ...)
{
    va_list args;
    va_start(args, fmt);
#ifdef __ANDROID__
    __android_log_vprint(ANDROID_LOG_VERBOSE, "ndk", fmt, args);
#elif defined(IS_WIN32)
    char *buf = new char[4096];
    std::fill_n(buf, 4096, '\0');
    _vsprintf_p(buf, 4096, fmt, args);
    OutputDebugStringA(buf);
    delete[] buf;
#else
    vprintf(fmt, args);
#endif
    va_end(args);
}

// Avoiding name mangling
extern "C"
{
    FUNCTION_ATTRIBUTE
    const char *version()
    {
        return CV_VERSION;
    }

    FUNCTION_ATTRIBUTE
    float laplacian_blur(char *inputImagePath)
    {
        long long start = get_now();

        Mat input = imread(inputImagePath, IMREAD_COLOR);

        // TODO: remove platform log
        platform_log("loaded %s", inputImagePath);

        const int croppedRows = 200;
        int croppedTimes = input.rows / croppedRows;
        Size croppedSize = Size(croppedRows, input.cols / croppedTimes);

        Mat resized;

        cv::resize(input, resized, croppedSize);
        delete[] & input;
        platform_log("resize done");

        Mat discolored;

        cv::cvtColor(resized, discolored, COLOR_BGR2GRAY);
        delete[] & resized;
        platform_log("resized done");

        Mat laplacian;
        cv::Laplacian(discolored, laplacian, 1);
        delete[] & discolored;

        platform_log("laplacian done");

        Scalar scalarMean = cv::mean(laplacian);
        float mean = scalarMean.val[0];

        platform_log("mean done");

        int evalInMillis = static_cast<int>(get_now() - start);
        platform_log("Processing %s done in %dms\n", inputImagePath, evalInMillis);

        return mean;
    }
}
