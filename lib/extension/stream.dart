extension StreamCleanupExt<T> on Stream<T> {
  /// Runs [action] when the stream is fully consumed OR canceled early.
  Stream<T> onDispose(void Function() action) async* {
    try {
      yield* this;
    } finally {
      action();
    }
  }
}
