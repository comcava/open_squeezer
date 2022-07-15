import 'dart:io';
import 'dart:typed_data';

import 'package:uuid/uuid.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:opencv_4/factory/pathfrom.dart';
import 'package:opencv_4/opencv_4.dart';
import 'package:fast_image_resizer/fast_image_resizer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as l_img;

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:photo_manager/photo_manager.dart';

import '../config/constants.dart';

/// Analyzes if the image is blurry, using open_cv's laplacian
class LaplacianBlurAnalyzer {
  /// Arithmetic mean of the bytes in the array
  static double mean(Uint8List bytes) {
    int sum = bytes.reduce((value, element) => value += element);
    int n = bytes.length;

    return sum / n;
  }

  /// Estimated population variance.
  /// Based on https://stackoverflow.com/a/47252945/14110680
  static double variance(Uint8List bytes) {
    var n = bytes.length;

    var average = mean(bytes);

    double sqDifferencesSum = 0;

    for (var byte in bytes) {
      var diff = byte - average;
      sqDifferencesSum += diff * diff;
    }

    var variance = sqDifferencesSum / (n - 1);

    return variance;
  }

  /// Calculate how blurry an image is
  static Future<double?> assetBlur(AssetEntity image) async {
    if (image.typeInt == AssetType.video.index) {
      return null;
    }

    Directory tempDir = await getTemporaryDirectory();
    var imgName = image.title ?? const Uuid().v4();

    Future<String> saveTempFile(Uint8List data) async {
      String tempPath = "${tempDir.path}/$imgName.png";

      var file = await File(tempPath).writeAsBytes(data);

      print("made temp path: $tempPath");

      return tempPath;
    }

    clearTempFile() {
      String tempPath = "${tempDir.path}/$imgName.png";
      File(tempPath).delete();
    }

    bool exists = await image.exists;

    print("processing $imgName");

    if (!exists) {
      return null;
    }

    final rawImage = await image.file;

    if (rawImage == null) {
      return null;
    }

    Uint8List? rawBytes = await rawImage.readAsBytes();

    print("raw image len: ${rawBytes.buffer.lengthInBytes}");

    ByteData? bytes = await resizeImage(rawBytes, width: 200);

    rawBytes = null;

    if (bytes == null) {
      throw Exception("Couldn't resize the image");
    }

    print("resize image len: ${bytes.buffer.lengthInBytes}");

    var smallPath = await saveTempFile(bytes.buffer.asUint8List());

    bytes = null;

    Uint8List? grayBytes = await Cv2.cvtColor(
      pathFrom: CVPathFrom.GALLERY_CAMERA,
      pathString: smallPath,
      outputType: Cv2.COLOR_BGR2GRAY,
    );

    if (grayBytes == null) {
      throw Exception("Couldn't convert the image to grayscale");
    }

    print("gray bytes len: ${grayBytes.length}, ${grayBytes.lengthInBytes}");

    var grayPath = await saveTempFile(grayBytes);

    grayBytes = null;

    Uint8List? filteredBytes = await Cv2.laplacian(
      pathFrom: CVPathFrom.GALLERY_CAMERA,
      pathString: grayPath,
      depth: 1,
    );

    if (filteredBytes == null) {
      return null;
    }

    print(
        "filtered bytes len: ${filteredBytes.length}, ${filteredBytes.lengthInBytes}");

    var decoded = l_img.decodeImage(filteredBytes);

    filteredBytes = null;
    clearTempFile();

    var decodedByte = decoded!.getBytes(format: l_img.Format.luminance);

    print("decoded bytes len: ${decodedByte.length}");

    var varianceNum = variance(decodedByte);

    return varianceNum;
  }
}
