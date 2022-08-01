// Laplacian analyzer function. Has to be a part of home

part of 'home.dart';

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
    final v = jsonDecode(source);

    if (v["id"] == null) {
      return null;
    }

    return LaplacianHomeIsolateMsg(
      id: v["id"],
    );
  }
}

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

class LaplacianHome {
  static Future<String> getVariance(LaplacianHomeIsolateMsg message) async {
    try {
      var asset = await pm.AssetEntity.fromId(message.id);

      if (asset == null) {
        print("asset is null for ${message.id}");
        return "";
      }

      var variance = await assetBlur(asset);

      if (variance == 0) {
        print("variance 0 for ${message.id}");
      }

      return LaplacianHomeIsolateResp(
        id: message.id,
        variance: variance ?? 0,
      ).toJson();
    } catch (e) {
      debugPrint("Error getting variance for ");
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
        debugPrint("Couldn't deserialize message in LaplacianHome.processMsg");
        continue;
      }

      varianceFutures.add(getVariance(message));
    }

    List<String> res = await Future.wait(varianceFutures);

    return res;
  }

  /// Handle blur processing.
  /// Should have a list of messages containing List<LaplacianHomeIsolateMsg>
  static void isolateHandler(dynamic context) async {
    final messenger = ih.HandledIsolate.initialize(context);

    messenger.listen((msg) async {
      if (msg is! List<String>) {
        debugPrint(
          """Invalid message type '${msg.runtimeType}' 
            in LaplacianHome.analyze, skipping""",
        );
        return;
      }

      var res = await LaplacianHome.processMsg(msg);

      messenger.send(res);
    });
  }
}
