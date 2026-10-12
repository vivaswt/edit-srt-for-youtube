import 'dart:async';
import 'package:flutter/material.dart';

//--- Effect ---
sealed class Effect<EV> {}

typedef Thunk<EV> = EV Function();

class NoEffect<EV> extends Effect<EV> {}

class FutureEffect<EV> extends Effect<EV> {
  final Thunk<Future<EV>> thunk;

  FutureEffect(this.thunk);
}

class StreamEffect<EV> extends Effect<EV> {
  final String taskId;
  final Thunk<Stream<EV>> thunk;

  StreamEffect(this.thunk, {required this.taskId});
}

class CancelEffect<EV> extends Effect<EV> {
  final String taskId;

  CancelEffect({required this.taskId});
}

//--- Reducer ---
typedef Reducer<M, EV> = UpdateResult<M, EV> Function(M, EV);

class UpdateResult<M, EV> {
  final M model;
  final Effect<EV>? effect;

  UpdateResult(this.model, [this.effect]);
}

// --- Controller ---
class ViewController<M, EV> {
  final ValueNotifier<M> modelNotifier;
  final Reducer<M, EV> reducer;
  final Map<String, StreamSubscription> _subscriptions = {};
  ViewController({required M initialModel, required this.reducer})
    : modelNotifier = ValueNotifier<M>(initialModel);

  Future<void> dispatch(EV event) async {
    final result = reducer(modelNotifier.value, event);
    modelNotifier.value = result.model;

    _handleEffect(result.effect);
  }

  Future<void> _handleEffect(Effect<EV>? effect) async {
    switch (effect) {
      case FutureEffect(:final thunk):
        thunk().then(dispatch);

      case StreamEffect(:final thunk, taskId: final taskId):
        final stream = thunk();
        _subscriptions[taskId]?.cancel();
        _subscriptions[taskId] = stream.listen(
          dispatch,
          onDone: () => _subscriptions.remove(taskId),
        );

      case CancelEffect(:final taskId):
        _subscriptions[taskId]?.cancel();
        _subscriptions.remove(taskId);

      case NoEffect():
      case null:
      // NOP
    }
  }

  Future<void> dispose() async {
    await Future.wait(_subscriptions.values.map((s) => s.cancel()));
    _subscriptions.clear();
    modelNotifier.dispose();
  }
}
