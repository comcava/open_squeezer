// Laplacian analyzer function. Has to be a part of home

part of 'home.dart';

class LaplacianHome {
  static Future<List<PhotoItem>> processMsg(List<pm.AssetEntity> photos) async {
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

  static void isolateHandler(dynamic context) async {
    final messenger = ih.HandledIsolate.initialize(context);

    messenger.listen((msg) async {
      if (msg is! List<pm.AssetEntity>) {
        debugPrint("Invalid message type in LaplacianHome.analyze, skipping");
        return;
      }

      var res = await LaplacianHome.processMsg(msg);

      messenger.send(res);
    });
  }
}
