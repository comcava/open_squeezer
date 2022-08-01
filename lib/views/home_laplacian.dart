// Laplacian analyzer function. Has to be a part of home

part of 'home.dart';

class LaplacianHomeIsolateMsg {
  final String id;
  final String? title;
  final String path;

  const LaplacianHomeIsolateMsg({
    required this.id,
    this.title,
    required this.path,
  });

  String toJson() {
    return jsonEncode({
      "id": id,
      "title": title,
      "path": path,
    });
  }

  static LaplacianHomeIsolateMsg? fromJson(String source) {
    final v = jsonDecode(source);

    if (v["id"] == null || v["path"] == null) {
      return null;
    }

    return LaplacianHomeIsolateMsg(
      id: v["id"],
      title: v["title"],
      path: v["path"],
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
  /// Takes a `List<LaplacianHomeIsolateMsg>`
  /// and returns `List<LaplacianHomeIsolateResp>`
  static Future<List<String>> processMsg(
    List<String> messages,
  ) async {
    Future<String> getInsertVariance(LaplacianHomeIsolateMsg message) async {
      try {
        var variance = await assetBlur(
          title: message.title ?? "",
          imagePath: message.path,
        );

        if (variance == null || variance < kLaplacianBlurThreshold) {
          return LaplacianHomeIsolateResp(
            id: message.id,
            variance: variance ?? 0,
          ).toJson();
        }
      } catch (e) {
        debugPrint("Error getting variance for ");
      }

      return "";
    }

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

      varianceFutures.add(getInsertVariance(message));
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
