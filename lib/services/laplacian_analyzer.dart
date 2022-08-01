import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
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

Future<ByteData?> resizeImage(Uint8List rawImage,
    {int? width, int? height}) async {
  final codec = await ui.instantiateImageCodec(rawImage,
      targetWidth: width, targetHeight: height);
  final resizedImage = (await codec.getNextFrame()).image;
  return resizedImage.toByteData(format: ui.ImageByteFormat.rawRgba);
}

Future<double?> assetBlur(AssetEntity image) async {
  if (image.typeInt != AssetType.image.index) {
    return null;
  }

  bool exists = await image.exists;

  if (!exists) {
    return null;
  }

  var title = image.title;
  if (kDebugMode) {
    // title is only used for logging.
    // we won't need to load it in production
    title = await image.titleAsync;
  }

  debugPrint("processing image '$title'");

  Uint8List? rawBytes = await image.thumbnailData;

  if (rawBytes == null || rawBytes.isEmpty) {
    debugPrint("  rawBytes is empty for '$title'");
    return null;
  }

  const resizedWidth = 100;
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

  var varianceNum = variance(laplacian.data.buffer.asUint8List());

  print("got variance: $varianceNum");

  return varianceNum;
}

/// Process all assets with laplacian analyzer
Future<List<LaplacianHomeIsolateResp>> allAssetsBlur(
  Iterable<String> assetsIds,
) async {
  var windowSize = (assetsIds.length / 2).floor();

  List<String> messages = List.empty(growable: true);

  print("start finding all files");
  for (final assetId in assetsIds) {
    messages.add(
      LaplacianHomeIsolateMsg(id: assetId).toJson(),
    );
  }

  print("done finding all files");

  List<List<String>> allItems = await Future.wait([
    spawnIsolate(messages.take(windowSize).toList()),
    spawnIsolate(messages.skip(windowSize).toList()),
  ]);

  List<LaplacianHomeIsolateResp> responses = List.empty(growable: true);

  for (var respJson in allItems.expand((l) => l).toList()) {
    var r = LaplacianHomeIsolateResp.fromJson(respJson);

    if (r == null) {
      continue;
    }

    responses.add(r);
  }

  return responses;
}

// TODO: reuse isolate
/// Message should be of type
/// `List<LaplacianHomeIsolateMsg.toJson()>`
Future<List<String>> spawnIsolate(
  List<String> message,
) async {
  final isolates = IsolateHandler();
  final stream = StreamController();

  int nameId = Random().nextInt(100000);
  String name = "squeezer_$nameId";

  isolates.spawn<dynamic>(
    LaplacianHome.isolateHandler,
    name: name,
    onReceive: (msg) {
      print("isolate onReceive");
      isolates.kill(name);
      stream.add(msg);
    },
    onInitialized: () {
      print("isolate oninit");
      isolates.send(message, to: name);
    },
  );

  var firstMsg = await stream.stream.first;

  if (firstMsg is! List<String>) {
    return [];
  }

  return firstMsg;
}
