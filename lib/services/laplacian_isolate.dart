import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:isolate_handler/isolate_handler.dart';

import '../views/home.dart';

class LaplacianIsolate {
  final _isolate1 = IsolateHandler();
  StreamController? _stream1;
  late String name1;

  final _isolate2 = IsolateHandler();
  StreamController? _stream2;
  late String name2;

  bool _isInit1 = false;
  bool _isInit2 = false;

  LaplacianIsolate() {
    int name1Id = Random().nextInt(100000);
    name1 = "squeezer_$name1Id";

    int name2Id = Random().nextInt(100000);
    name2 = "squeezer_$name2Id";

    _spawnIsolates();
  }

  /// Message should be of type
  /// `List<LaplacianHomeIsolateMsg.toJson()>`.
  Future<void> _spawnIsolates() async {
    _isolate1.spawn<dynamic>(
      LaplacianHomeIsolate.isolateHandler,
      name: name1,
      onReceive: (msg) {
        _stream1?.add(msg);
      },
      onInitialized: () {
        _isInit1 = true;
      },
    );

    _isolate2.spawn<dynamic>(
      LaplacianHomeIsolate.isolateHandler,
      name: name2,
      onReceive: (msg) {
        _stream1?.add(msg);
      },
      onInitialized: () {
        _isInit2 = true;
      },
    );
  }

  /// Wait for all isolates to start
  Future<void> waitInit() async {
    const checkDuration = Duration(milliseconds: 10);

    if (_isInit1 && _isInit2) {
      return Future.value();
    }

    var completer1 = Completer();
    check1() {
      if (_isInit1) {
        completer1.complete();
      } else {
        Timer(checkDuration, check1);
      }
    }

    var completer2 = Completer();
    check2() {
      if (_isInit2) {
        completer2.complete();
      } else {
        Timer(checkDuration, check2);
      }
    }

    check1();
    check2();
    await Future.wait([
      completer1.future,
      completer2.future,
    ]);
  }

  /// Calculate blur for all assets with laplacian analyzer.
  /// Will send all the payload to an isolate
  Future<List<LaplacianHomeIsolateResp>> allAssetsBlur(
      {required Iterable<String> assetsIds, required int idsLength}) async {
    final windowSize = (idsLength / 2).floor();

    List<String> messages1 = List.empty(growable: true);
    List<String> messages2 = List.empty(growable: true);

    int assetsIdx = 0;
    for (final assetId in assetsIds) {
      if (assetsIdx <= windowSize) {
        messages1.add(
          LaplacianHomeIsolateMsg(id: assetId).toJson(),
        );
      } else {
        messages2.add(
          LaplacianHomeIsolateMsg(id: assetId).toJson(),
        );
      }

      assetsIdx++;
    }

    List<String> allItems = await _sendPayload(
      message1: messages1,
      message2: messages2,
    );

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

  Future<List<String>> _sendPayload({
    required List<String> message1,
    required List<String> message2,
  }) async {
    if (!_isInit1 || !_isInit2) {
      throw "Uninitialized. Use waitInit() to wait before the isolate is initialized";
    }

    _stream1 = StreamController();
    _isolate1.send(message1, to: name1);

    _stream2 = StreamController();
    _isolate2.send(message2, to: name1);

    var events1 = await _stream1!.stream.first;
    var events2 = await _stream2!.stream.first;

    await _stream1!.close();
    _stream1 = null;

    await _stream2!.close();
    _stream2 = null;

    List<String> respMessages = [];

    if (events1 is! List<String>) {
      debugPrint(
        "sendPayload event is not List<String>, is ${events1.runtimeType}",
      );
    } else {
      respMessages = events1;
    }

    if (events2 is! List<String>) {
      debugPrint(
        "sendPayload event is not List<String>, is ${events2.runtimeType}",
      );
    } else {
      respMessages.addAll(events2);
    }

    return respMessages;
  }

  void kill() {
    _isolate1.kill(name1);
    _isolate2.kill(name2);
  }
}
