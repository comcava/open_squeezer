// An isolate that receives laplacian messages.
// Has to be a part of home, otherwise dart throws an error

part of 'home.dart';

/// Message to be sent to laplacian isolate
class LaplacianHomeIsolateMsg {
  final String id;

  const LaplacianHomeIsolateMsg({
    required this.id,
  });

  String toJson() {
    return jsonEncode({
      "id": id,
    });
  }

  static LaplacianHomeIsolateMsg? fromJson(String source) {
    if (source.isEmpty) {
      return null;
    }

    final v = jsonDecode(source);

    if (v["id"] == null) {
      return null;
    }

    return LaplacianHomeIsolateMsg(
      id: v["id"],
    );
  }
}

/// Response that laplacian isolate returns
class LaplacianHomeIsolateResp {
  final String id;
  final double variance;

  const LaplacianHomeIsolateResp({
    required this.id,
    required this.variance,
  });

  String toJson() {
    return jsonEncode({
      "id": id,
      "variance": variance,
    });
  }

  static LaplacianHomeIsolateResp? fromJson(String source) {
    if (source.isEmpty) {
      return null;
    }

    final v = jsonDecode(source);

    if (v["id"] == null || v["variance"] == null) {
      return null;
    }

    return LaplacianHomeIsolateResp(
      id: v["id"],
      variance: v["variance"],
    );
  }
}

class LaplacianHomeIsolate {
  static Future<String> getVariance(LaplacianHomeIsolateMsg message) async {
    try {
      var asset = await pm.AssetEntity.fromId(message.id);

      if (asset == null) {
        debugPrint("asset is null for ${message.id}");
        return "";
      }

      var variance = await assetBlur(asset);

      if (variance == null || variance == 0) {
        debugPrint("variance 0 for ${message.id}");
      }

      return LaplacianHomeIsolateResp(
        id: message.id,
        variance: variance ?? 0,
      ).toJson();
    } catch (e) {
      debugPrint("Error getting variance for ${message.id}: $e");
    }

    return "";
  }

  /// Takes a `List<LaplacianHomeIsolateMsg>`
  /// and returns `List<LaplacianHomeIsolateResp>`
  static Future<List<String>> processMsg(
    List<String> messages,
  ) async {
    if (messages.isEmpty) {
      return [];
    }

    List<Future<String>> varianceFutures = List.empty(growable: true);

    for (var messageJson in messages) {
      var message = LaplacianHomeIsolateMsg.fromJson(messageJson);
      if (message == null) {
        debugPrint(
            "Couldn't deserialize message in LaplacianHomeIsolate.processMsg");
        continue;
      }

      varianceFutures.add(getVariance(message));
    }

    List<String> res = await Future.wait(varianceFutures);

    return res;
  }

  /// Handle blur processing.
  /// Should have a list of messages containing List<LaplacianHomeIsolateMsg>
  @pragma('vm:entry-point')
  static void isolateHandler(dynamic context) async {
    final messenger = ih.HandledIsolate.initialize(context);

    // Assume we got all permissions on the main thread.
    // Permission request requires an activity to be attached to.
    pm.PhotoManager.setIgnorePermissionCheck(true);

    messenger.listen((msg) async {
      if (msg is! List<String>) {
        debugPrint(
          "Invalid message type '${msg.runtimeType}' "
          "in LaplacianHomeIsolate.analyze, skipping",
        );
        return;
      }

      var res = await LaplacianHomeIsolate.processMsg(msg);

      messenger.send(res);
    });
  }
}
