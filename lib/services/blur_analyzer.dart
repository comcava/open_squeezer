import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:uuid/uuid.dart';

import 'package:isolate_handler/isolate_handler.dart';

import 'package:opencv_4/factory/pathfrom.dart';
import 'package:opencv_4/opencv_4.dart';
import 'package:fast_image_resizer/fast_image_resizer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as l_img;

import 'package:photo_manager/photo_manager.dart';

import '../config/constants.dart';
import '../domain/album.dart';

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
  static Future<double?> assetBlur(AssetEntity image, String tempDir) async {
    if (image.typeInt == AssetType.video.index) {
      return null;
    }

    var imgName = image.title ?? const Uuid().v4();

    Future<String> saveTempFile(Uint8List data) async {
      String tempPath = "$tempDir/$imgName.png";

      await File(tempPath).writeAsBytes(data);

      return tempPath;
    }

    clearTempFile() {
      String tempPath = "$tempDir/$imgName.png";
      File(tempPath).delete();
    }

    bool exists = await image.exists;

    debugPrint("processing $imgName");

    if (!exists) {
      return null;
    }

    final rawImage = await image.file;

    if (rawImage == null) {
      return null;
    }

    Uint8List? rawBytes = await rawImage.readAsBytes();

    ByteData? bytes = await resizeImage(rawBytes, width: 200);

    rawBytes = null;

    if (bytes == null) {
      throw Exception("Couldn't resize the image");
    }

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

    var decoded = l_img.decodeImage(filteredBytes);

    filteredBytes = null;
    clearTempFile();

    var decodedByte = decoded!.getBytes(format: l_img.Format.luminance);

    var varianceNum = variance(decodedByte);

    return varianceNum;
  }

  Future<List<PhotoItem>> assetBlur4Futures(
      List<AssetEntity> origPhotos) async {
    Directory tempDirectory = await getTemporaryDirectory();
    String tempDir = tempDirectory.path;

    var windowSize = (origPhotos.length / 4).floor();

    var allResults = await Future.wait([
      (() async {
        var message = origPhotos.take(windowSize).toList();
        return await _processPhotos(message, tempDir);
      })(),
      (() async {
        var message = origPhotos.skip(windowSize).take(windowSize).toList();
        return await _processPhotos(message, tempDir);
      })(),
      (() async {
        var message = origPhotos.skip(windowSize * 2).take(windowSize).toList();
        return await _processPhotos(message, tempDir);
      })(),
      (() async {
        var message = origPhotos.skip(windowSize * 3).toList();
        return await _processPhotos(message, tempDir);
      })(),
    ]);

    List<PhotoItem> result = List.empty(growable: true);

    for (var r in allResults) {
      result.addAll(r);
    }

    return result;
  }
}

Future<List<PhotoItem>> _processPhotos(
    List<AssetEntity> photos, String tempDir) async {
  List<PhotoItem> results = [];

  for (final photo in photos) {
    double? blurNum;

    try {
      blurNum = await LaplacianBlurAnalyzer.assetBlur(photo, tempDir);
    } catch (e) {
      debugPrint("Error trying to find blur for ${photo.title}: $e");
    }

    if (blurNum == null) {
      debugPrint("Blur item is null for ${photo.title}");
      continue;
    }

    if (blurNum <= blurryBefore) {
      results.add(PhotoItem(photo: photo, varianceNum: blurNum));
    }
  }

  return results;
}

Future<dynamic> spawnIsolate(
  dynamic message,
  dynamic Function(dynamic) payloadFut,
) async {
  final isolates = IsolateHandler();

  final stream = StreamController();

  void entryPoint(dynamic context) {
    final messenger = HandledIsolate.initialize(context);

    // Triggered every time data is received from the main isolate.
    messenger.listen((msg) async {
      var res = await payloadFut(msg);
      messenger.send(res);
    });
  }

  int nameId = Random().nextInt(100000);
  String name = "blur_analyzer_$nameId";

  isolates.spawn<dynamic>(
    entryPoint,
    name: name,
    onReceive: (msg) {
      isolates.kill(name);
      stream.add(msg);
    },
    onInitialized: () {
      isolates.send(message, to: name);
    },
  );

  return await stream.stream.first;
}
