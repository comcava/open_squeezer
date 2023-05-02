import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:isolate_handler/isolate_handler.dart';

import '../views/home.dart';

/// Calculate laplacian on 2 isolates
class LaplacianIsolate {
  final _isolates = IsolateHandler();
  StreamController? _stream;

  late String name;
  bool _isInit = false;

  LaplacianIsolate() {
    int nameId = Random().nextInt(100000);
    name = "squeezer_$nameId";

    _spawnIsolate();
  }

  /// Message should be of type
  /// `List<LaplacianHomeIsolateMsg.toJson()>`.
  Future<void> _spawnIsolate() async {
    try {
      _isolates.spawn<dynamic>(
        LaplacianHomeIsolate.isolateHandler,
        name: name,
        onReceive: (msg) {
          _stream?.add(msg);
        },
        onInitialized: () {
          _isInit = true;
        },
      );
    } catch (e) {
      debugPrint("Error spawning isolate: $e");
    }
  }

  Future<void> waitInit() async {
    if (_isInit) {
      return Future.value();
    }

    var completer = Completer();
    check() {
      if (_isInit) {
        completer.complete();
      } else {
        Timer(const Duration(milliseconds: 50), check);
      }
    }

    check();
    await completer.future;
  }

  /// Calculate blur for all assets with laplacian analyzer.
  /// Will send all the payload to an isolate
  Future<List<LaplacianHomeIsolateResp>> allAssetsBlur(
    Iterable<String> assetsIds,
  ) async {
    List<String> messages = List.empty(growable: true);

    for (final assetId in assetsIds) {
      messages.add(
        LaplacianHomeIsolateMsg(id: assetId).toJson(),
      );
    }

    List<String> allItems = await _sendPayload(messages);

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

  Future<List<String>> _sendPayload(List<String> message) async {
    if (!_isInit) {
      throw "Uninitialized. Use waitInit() to wait before the isolate is initialized";
    }

    _stream = StreamController();

    _isolates.send(message, to: name);

    var event = await _stream!.stream.first;

    await _stream!.close();
    _stream = null;

    List<String> respMessage;
    if (event is! List<String>) {
      debugPrint(
        "sendPayload event is not List<String>, is ${event.runtimeType}",
      );
      respMessage = [];
    } else {
      respMessage = event;
    }

    return respMessage;
  }

  void kill() {
    _isolates.kill(name);
  }
}
