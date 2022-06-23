import 'dart:async';
import 'dart:html';

import '../isolate_contactor_controller_web.dart';

class IsolateContactorControllerImplWorker<T>
    implements IsolateContactorControllerImpl<T> {
  late Worker _delegate;

  final StreamController<T> _mainStreamController =
      StreamController.broadcast();
  final StreamController _isolateStreamController =
      StreamController.broadcast();
  @override
  final Function()? onDispose;
  dynamic _initialParams;

  IsolateContactorControllerImplWorker(dynamic params, {this.onDispose}) {
    if (params is List) {
      _delegate = params.last.controller;
      _initialParams = params.first;
    } else {
      _delegate = params;
    }

    _delegate.onMessage.listen((event) {
      _mainStreamController.add(event.data as T);
    });
  }

  @override
  Worker get controller => _delegate;

  /// Get initial params for `createOwnIsolate`
  @override
  dynamic get initialParams => _initialParams;

  @override
  Stream<T> get onMessage => _mainStreamController.stream;

  @override
  Stream get onIsolateMessage => _isolateStreamController.stream;

  @override
  void sendIsolate(dynamic message) {
    try {
      _delegate.postMessage(message);
    } catch (_) {
      // The delegate may be closed
    }
  }

  @override
  void sendResult(T message) => throw UnimplementedError();

  @override
  Future<void> close() async {
    _delegate.terminate();
    await Future.wait([
      _mainStreamController.close(),
      _isolateStreamController.close(),
    ]);
  }
}