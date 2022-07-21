#include <opencv2/opencv.hpp>
#include <chrono>

#include <libheif/heif.h>

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

bool is_type(string path, string f_type)
{
    if (path.length() == 0 || path.length() <= f_type.length())
    {
        return false;
    }

    int extensionIdx = path.length() - f_type.length();

    return &path[extensionIdx] == f_type;
}

Mat read_heif(char *input_path)
{
    heif_context *ctx = heif_context_alloc();
    heif_context_read_from_file(ctx, input_path, nullptr);

    // get a handle to the primary image
    heif_image_handle *handle;
    heif_context_get_primary_image_handle(ctx, &handle);

    // decode the image and convert colorspace to RGB, saved as 24bit interleaved
    heif_image *img;
    heif_decode_image(handle, &img, heif_colorspace_RGB, heif_chroma_interleaved_RGB, nullptr);

    int stride;
    const uint8_t *data = heif_image_get_plane_readonly(img, heif_channel_interleaved, &stride);

    int width = heif_image_handle_get_width(handle);
    int height = heif_image_handle_get_height(handle);

    Mat map = Mat(width, height, CV_8UC3);

    int arr_index = 0;
    for (int w = 0; w < width; w++)
    {
        for (int h = 0; h < height; h++)
        {
            map.at<unsigned short int>(w, h, 0) = data[arr_index];
            map.at<unsigned short int>(w, h, 1) = data[arr_index + 1];
            map.at<unsigned short int>(w, h, 2) = data[arr_index + 2];

            arr_index += 3;
        }
    }

    return map;
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
    float laplacian_blur(char *input_image_path)
    {
        try
        {
            long long start = get_now();

            Mat input;

            if (is_type(input_image_path, ".heif") || is_type(input_image_path, ".heic"))
            {
                input = read_heif(input_image_path);
            }
            else
            {
                input = imread(input_image_path, IMREAD_COLOR);
            }

            const int croppedRows = 200;
            int croppedTimes = input.rows / croppedRows;
            Size croppedSize = Size(croppedRows, input.cols / croppedTimes);

            Mat resized = Mat(croppedSize, input.type());
            cv::resize(input, resized, croppedSize);

            Mat discolored;
            cv::cvtColor(resized, discolored, COLOR_BGR2GRAY);

            Mat laplacian;
            cv::Laplacian(discolored, laplacian, 0);

            Scalar scalarMean = cv::mean(laplacian);
            float mean = scalarMean.val[0];

            int evalInMillis = static_cast<int>(get_now() - start);
            platform_log("Processing %s done in %dms\n", input_image_path, evalInMillis);

            return mean;
        }
        catch (Exception e)
        {
            platform_log("Error processing %s: %s", input_image_path, e.what());
            return 0;
        }
    }
}
