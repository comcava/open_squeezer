import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

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

Future<double?> assetBlur(AssetEntity image) async {
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

  var decoded = l_img.decodeImage(resizedBytes.buffer.asUint8List());

  if (decoded == null) {
    print("decoded null ${image.title}");
    return null;
  }

  var laplacian = await applyLaplaceOnImage(decoded);

  var varianceNum = variance(laplacian.data.buffer.asUint8List());

  return varianceNum;
}

Future<List<PhotoItem>> allAssetsBlur(List<AssetEntity> assets) async {
  Future<List<PhotoItem>> processThread(Iterable<AssetEntity> photos) async {
    if (photos.isEmpty) {
      return [];
    }

    List<PhotoItem> res = List.empty(growable: true);

    for (var photo in photos) {
      var variance = await assetBlur(photo);

      if (variance == null || variance < kLaplacianBlurThreshold) {
        res.add(PhotoItem(
          photo: photo,
          varianceNum: variance ?? 0,
        ));
      }
    }

    return res;
  }

  var windowSize = (assets.length / 5).floor();

  var allItems = await // Future.wait([
      spawnIsolate(
    assets.take(windowSize).toList(),
    (message) {
      AssetEntity photo = message[0];

      // var file = await photo.file;

      ;

      return [];
      // return await processThread(message);
    },
  );
  // spawnIsolate(
  //   assets.skip(windowSize).take(windowSize),
  //   (message) async {
  //     return await processThread(message);
  //   },
  // ),
  // spawnIsolate(
  //   assets.skip(windowSize * 2).take(windowSize),
  //   (message) async {
  //     return await processThread(message);
  //   },
  // ),
  // spawnIsolate(
  //   assets.skip(windowSize * 3).take(windowSize),
  //   (message) async {
  //     return await processThread(message);
  //   },
  // ),
  // spawnIsolate(
  //   assets.skip(windowSize * 4),
  //   (message) async {
  //     return await processThread(message);
  //   },
  // ),
  // ]);

  List<PhotoItem> items = [];

  for (final itemsList in allItems) {
    items.addAll(itemsList);
  }

  return items;
}

Future<dynamic> spawnIsolate(
  dynamic message,
  dynamic Function(dynamic message) payloadFut,
) async {
  final isolates = IsolateHandler();
  final stream = StreamController();

  int nameId = Random().nextInt(100000);
  String name = "squeezer_$nameId";

  isolates.spawn<dynamic>(
    LaplacianIsolate.analyze,
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

  // return await payloadFut(message);
}
