import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as path;

import 'package:fast_image_resizer/fast_image_resizer.dart';
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

Future<double?> assetBlur({
  required String title,
  required String imagePath,
}) async {
  var rawImage = File(imagePath);

  bool exists = await rawImage.exists();

  if (!exists) {
    return null;
  }

  debugPrint("processing photo '$title'");

  Uint8List? rawBytes = await rawImage.readAsBytes();

  ByteData? resizedBytes = await resizeImage(rawBytes, width: 150);

  if (resizedBytes == null) {
    debugPrint("  couldn't resize $title");
    return null;
  }

  var decoded = l_img.decodeImage(
    resizedBytes.buffer.asUint8List(),
  );

  if (decoded == null) {
    debugPrint("  decoded null $title");
    return null;
  }

  var laplacian = await applyLaplaceOnImage(decoded);
  var varianceNum = variance(laplacian.data.buffer.asUint8List());

  return varianceNum;
}

/// Process all assets with laplacian analyzer
Future<List<PhotoItem>> allAssetsBlur(List<AssetEntity> assetsList) async {
  var windowSize = (assetsList.length / 2).floor();

  List<String> filePaths = List.empty(growable: true);
  Map<String, AssetEntity> assetsMap = {};

  print("start finding all files");
  for (final asset in assetsList) {
    var file = await asset.originFile;

    if (file == null) {
      continue;
    }

    var title = asset.title;
    if (kDebugMode) {
      // we only want to load async title in debug mode
      // for showing in logs, in production we can skip this
      title = await asset.titleAsync;
    }

    var parentDir = path.basename(file.parent.path);
    if (kScreenshotsFolders.contains(parentDir)) {
      // we don't want to analyze screenshots
      continue;
    }

    filePaths.add(LaplacianHomeIsolateMsg(
      id: asset.id,
      title: title,
      path: file.path,
    ).toJson());

    assetsMap.putIfAbsent(asset.id, () => asset);
  }

  print("done finding all files");

  var allItems = await Future.wait([
    spawnIsolate(filePaths.take(windowSize).toList()),
    // spawnIsolate(filePaths.skip(windowSize).take(windowSize).toList()),
    // spawnIsolate(filePaths.skip(windowSize * 2).take(windowSize).toList()),
    // spawnIsolate(filePaths.skip(windowSize * 3).take(windowSize).toList()),
    spawnIsolate(filePaths.skip(windowSize).toList()),
  ]);

  List<PhotoItem> photoItems = [];

  for (final itemJson in allItems.expand((l) => l)) {
    final item = LaplacianHomeIsolateResp.fromJson(itemJson);

    if (item == null) {
      continue;
    }

    var photo = assetsMap[item.id];

    if (photo == null) {
      debugPrint("no photo with id ${item.id} in assetsMap");
      continue;
    }

    photoItems.add(
      PhotoItem(
        photo: photo,
        varianceNum: item.variance,
      ),
    );
  }

  return photoItems;
}

/// Message should be of type
/// `List<LaplacianHomeIsolateMsg.toJson()>`
Future<dynamic> spawnIsolate(
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
      isolates.send(message, to: name);
    },
  );

  return await stream.stream.first;
}
