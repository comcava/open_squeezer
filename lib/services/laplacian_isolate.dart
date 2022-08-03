import 'dart:async';
import 'dart:math';

import 'package:isolate_handler/isolate_handler.dart';

import '../views/home.dart';

class LaplacianIsolate {
  final isolates = IsolateHandler();
  StreamController? stream;

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
    isolates.spawn<dynamic>(
      LaplacianHome.isolateHandler,
      name: name,
      onReceive: (msg) {
        print("isolate onReceive");
        stream?.add(msg);
      },
      onInitialized: () {
        print("isolate oninit");
        _isInit = true;
      },
    );

    print("done spawnIsolate");
  }

  Future<void> waitInit() async {
    print("start waitInit");
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

    print("done wait.init");

    return;
  }

  /// Send all payload messages to an isolate.
  /// When all the messages are resolved, returns the result.
  Future<List<String>> sendPayload(List<String> message) async {
    if (!_isInit) {
      throw "Uninitialized. Use waitInit() to wait before the isolate is initialized";
    }

    stream = StreamController();

    print("start sendPayload");

    isolates.send(message, to: name);

    var event = await stream!.stream.first;

    await stream!.close();
    stream = null;

    List<String> respMessage;
    if (event is! List<String>) {
      print("event is not List<String>, is ${event.runtimeType}");
      respMessage = [];
    } else {
      respMessage = event;
    }

    print("done send payload");

    return respMessage;
  }

  void kill() {
    isolates.kill(name);
  }
}
