import 'dart:async';
import 'dart:math';

import 'package:isolate_handler/isolate_handler.dart';

import '../views/home.dart';

class LaplacianIsolate {
  final isolates = IsolateHandler();
  final stream = StreamController();

  late String name;
  bool _isInit = false;

  LaplacianIsolate() {
    _spawnIsolate();

    int nameId = Random().nextInt(100000);
    name = "squeezer_$nameId";
  }

  /// Message should be of type
  /// `List<LaplacianHomeIsolateMsg.toJson()>`
  Future<void> _spawnIsolate() async {
    isolates.spawn<dynamic>(
      LaplacianHome.isolateHandler,
      name: name,
      onReceive: (msg) {
        print("isolate onReceive");
        stream.add(msg);
      },
      onInitialized: () {
        print("isolate oninit");
        _isInit = true;
      },
    );
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
    return completer.future;
  }

  /// Send all payload messages to an isolate.
  /// When all the messages are resolved, returns the result.
  Future<List<String>> sendPayload(List<String> message) async {
    if (!_isInit) {
      throw "Uninitialized. Use waitInit() to wait before the isolate is initialized";
    }

    stream.add(message);

    // List<List<String>> respMessages = List.empty(growable: true);
    List<String> respMessage = [];
    // var messagesLeft = messages.length;

    var completer = Completer();

    stream.stream.listen((event) {
      if (event is! List<String>) {
        respMessage = [];
        // messagesLeft -= 1;

        // if (messagesLeft <= 0) {
        stream.stream.listen((event) {});
        completer.complete();
        // }
      }
    });

    await completer.future;

    return respMessage;
  }

  void kill() {
    isolates.kill(name);
  }
}
