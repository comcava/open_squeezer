import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:blur_detector/services/laplacian_isolate.dart';
import 'package:path/path.dart' as path;

// import 'package:fast_image_resizer/fast_image_resizer.dart';
import 'package:flutter/foundation.dart';
import 'package:image_edge_detection/functions.dart';
import 'package:isolate_handler/isolate_handler.dart';
import 'package:photo_manager/photo_manager.dart';

import 'package:image/image.dart' as l_img;

import '../config/constants.dart';
import '../domain/album.dart';
import '../views/home.dart';

/// The threshold before which
/// we consider the pixel black.
/// Pixels representing edges are considered white.
const int kWhiteThreshold = 230;

/// Mean of the pixels. It is hardcoded to be
/// `(255 (white) - 0 (black)) / 2`, because
/// otherwise the mean was close to 0 for
/// mostly blurry images:
/// ```
///                   ┌─            2  ─┐
///               sum │  ( i - avg )    │
///                   └─               ─┘
///                    i
///  variance  =      ─────────────────────
///                          n - 1
///
/// ```
///
/// where `n` - number of images, `avg` - arithmetic mean.
///
/// For *mostly blurry* images the variance was high,
/// as `avg` was low (close to 0) and `i` was sometimes high (a few
/// white pixels).
///
/// For *sharp images* the variance was high,
/// as the `avg` was about medium (close to 100) and `i` was
/// sometimes high and sometimes low (some white and some black pixels).
const double average = 255 / 2;

/// Estimated population variance.
/// Based on https://stackoverflow.com/a/47252945/14110680
double variance(Uint8List bytes) {
  var n = bytes.length;

  double sqDifferencesSum = 0;

  for (var byte in bytes) {
    // we only want to count in white pixels,
    // only they represent the useful payload for us.
    //
    // otherwise (255 - 127) and (0 - 127) are the
    // same value.
    if (byte > kWhiteThreshold) {
      var diff = byte - average;
      sqDifferencesSum += diff * diff;
    }
  }

  var variance = sqDifferencesSum / (n - 1);

  return variance;
}

/// From fast_image_resizer
Future<ByteData?> resizeImage(Uint8List rawImage,
    {int? width, int? height}) async {
  final codec = await ui.instantiateImageCodec(rawImage,
      targetWidth: width, targetHeight: height);
  final resizedImage = (await codec.getNextFrame()).image;
  return resizedImage.toByteData(format: ui.ImageByteFormat.rawRgba);
}

Future<double?> assetBlur(AssetEntity image) async {
  var title = image.title;
  if (kDebugMode) {
    // title is only used for logging.
    // we won't need to load it in production
    title = await image.titleAsync;
  }

  if (image.typeInt != AssetType.image.index) {
    print("'$title' is not AssetType.image");
    return null;
  }

  bool exists = await image.exists;

  if (!exists) {
    print("'$title' does not exist");
    return null;
  }

  debugPrint("processing image '$title'");

  Uint8List? rawBytes = await image.thumbnailData;

  if (rawBytes == null || rawBytes.isEmpty) {
    debugPrint("rawBytes is empty for '$title'");
    return null;
  }

  const resizedWidth = 150;
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

  var varianceColor = variance(decoded.data.buffer.asUint8List());
  print("got color variance for $title: $varianceColor");

  var laplacian = await applySobelOnImage(decoded);

  var varianceNum = variance(
    laplacian.getBytes(
      format: l_img.Format.luminance,
    ),
  );

  print("got laplacian variance for $title: $varianceNum");

  return varianceNum;
}

// TODO: remove
Future<l_img.Image?> assetBlur1(AssetEntity image) async {
  var title = image.title;
  if (kDebugMode) {
    // title is only used for logging.
    // we won't need to load it in production
    title = await image.titleAsync;
  }

  if (image.typeInt != AssetType.image.index) {
    print("'$title' is not AssetType.image");
    return null;
  }

  bool exists = await image.exists;

  if (!exists) {
    print("'$title' does not exist");
    return null;
  }

  debugPrint("processing image '$title'");

  Uint8List? rawBytes = await image.thumbnailData;

  if (rawBytes == null || rawBytes.isEmpty) {
    debugPrint("rawBytes is empty for '$title'");
    return null;
  }

  const resizedWidth = 150;
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

  var laplacian = await applySobelOnImage(decoded);

  List<int> newLBytes = laplacian
      .getBytes(
    format: l_img.Format.luminance,
  )
      .map((e) {
    if (e < kWhiteThreshold) {
      return 0;
    }

    return e;
  }).toList();

  var laplacian1 = l_img.Image.fromBytes(
      laplacian.width, laplacian.height, newLBytes,
      format: l_img.Format.luminance);

  return laplacian1;
}

/// Process all assets with laplacian analyzer
Future<List<LaplacianHomeIsolateResp>> allAssetsBlur(
    Iterable<String> assetsIds, LaplacianIsolate isolate) async {
  // var windowSize = (assetsIds.length / 2).floor();

  List<String> messages = List.empty(growable: true);

  print("start finding all files");
  for (final assetId in assetsIds) {
    messages.add(
      LaplacianHomeIsolateMsg(id: assetId).toJson(),
    );
  }

  print("done finding all files, ${assetsIds.length}");

  // List<List<String>> allItems = ;

  List<String> allItems = await isolate.sendPayload(messages);

  List<LaplacianHomeIsolateResp> responses = List.empty(growable: true);

  for (var respJson in allItems) {
    var r = LaplacianHomeIsolateResp.fromJson(respJson);

    if (r == null) {
      continue;
    }

    responses.add(r);
  }

  return responses;
}
