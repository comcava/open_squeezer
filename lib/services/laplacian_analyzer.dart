import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:image_edge_detection/functions.dart';

import 'package:photo_manager/photo_manager.dart';

import 'package:image/image.dart' as l_img;

/// Width the image should be resized to
const resizedWidth = 300;

/// Arithmetic mean of the bytes in the array
double mean(Uint8List bytes) {
  int sum = bytes.reduce((value, element) => value += element);
  int n = bytes.length;

  return sum / n;
}

/// Estimated population variance.
/// Based on https://stackoverflow.com/a/47252945/14110680
double variance(Uint8List bytes) {
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

/// From [fast_image_resizer].
/// Copied because they didn't support `ui.ImageByteFormat`
///
/// [fast_image_resizer]: https://pub.dev/packages/fast_image_resizer
Future<ByteData?> resizeImage(Uint8List rawImage,
    {int? width, int? height}) async {
  final codec = await ui.instantiateImageCodec(rawImage,
      targetWidth: width, targetHeight: height);
  final resizedImage = (await codec.getNextFrame()).image;
  return resizedImage.toByteData(format: ui.ImageByteFormat.rawRgba);
}

/// Calculate laplacian variance for the image asset
Future<double?> assetBlur(AssetEntity image) async {
  var title = image.title;
  if (kDebugMode) {
    // title is only used for logging.
    // we won't need to load it in production
    title = await image.titleAsync;
  }

  if (image.typeInt != AssetType.image.index) {
    debugPrint("'$title' is not AssetType.image");
    return null;
  }

  bool exists = await image.exists;

  if (!exists) {
    debugPrint("'$title' does not exist");
    return null;
  }

  Uint8List? rawBytes = await image.originBytes;

  if (rawBytes == null || rawBytes.isEmpty) {
    debugPrint("rawBytes is empty for '$title'");
    return null;
  }

  ByteData? resizedBytes = await resizeImage(rawBytes, width: resizedWidth);

  if (resizedBytes == null) {
    debugPrint("couldn't resize ${image.title}");
    return null;
  }

  // 4 channels in rgba
  var resizedHeight = (resizedBytes.lengthInBytes / resizedWidth / 4).ceil();

  var decoded = l_img.Image.fromBytes(
    resizedWidth,
    resizedHeight,
    resizedBytes.buffer.asUint8List(),
    format: l_img.Format.rgba,
  );

  var laplacian = await applyLaplaceOnImage(decoded);

  var grayBytes = laplacian.getBytes(
    format: l_img.Format.luminance,
  );

  var varianceNum = variance(grayBytes);

  return varianceNum;
}
