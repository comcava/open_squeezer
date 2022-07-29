import 'dart:typed_data';

import 'package:fast_image_resizer/fast_image_resizer.dart';
import 'package:flutter/foundation.dart';
import 'package:image_edge_detection/functions.dart';
import 'package:photo_manager/photo_manager.dart';

import 'package:image/image.dart' as l_img;

import '../domain/album.dart';

class LaplacianAnalyzer {
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

  Future<PhotoItem?> assetBlur(AssetEntity image) async {
    if (image.typeInt != AssetType.image.index) {
      return null;
    }

    bool exists = await image.exists;

    if (!exists) {
      return null;
    }

    debugPrint("processing ${image.title}");

    final rawImage = await image.file;

    if (rawImage == null) {
      return null;
    }

    Uint8List? rawBytes = await rawImage.readAsBytes();

    ByteData? resizedBytes = await resizeImage(rawBytes, width: 200);

    if (resizedBytes == null) {
      debugPrint("couldn't resize ${image.title}");
      return null;
    }

    var decoded = l_img.decodeImage(resizedBytes.buffer.asUint32List());

    if (decoded == null) {
      print("decoded null ${image.title}");
      return null;
    }

    var laplacian = await applyLaplaceOnImage(decoded);

    var varianceNum = variance(laplacian.data.buffer.asUint8List());

    return PhotoItem(photo: image, varianceNum: varianceNum);
  }

  Future<List<PhotoItem>> allAssetsBlur(List<AssetEntity> assets) async {
    return [];
  }
}
