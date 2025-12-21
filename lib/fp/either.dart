sealed class Either<L, R> {
  const Either();

  /// Lifts a value of type [R] into the [Either] context, creating a [Right].
  ///
  /// This is equivalent to the `return` or `pure` function in other functional libraries.
  static Either<L, R> of<L, R>(R value) => Right(value);

  /// Monadic bind operation (>>= in Haskell).
  ///
  /// If this is a [Right], applies the function [f] to its value.
  /// If this is a [Left], it passes the [Left] value through.
  Either<L, R2> bind<R2>(Either<L, R2> Function(R value) f);

  /// Functorial map operation.
  ///
  /// If this is a [Right], applies the function [f] to its value and returns a new [Right].
  /// If this is a [Left], it passes the [Left] value through.
  Either<L, R2> map<R2>(R2 Function(R value) f);

  Either<L2, R> mapLeft<L2>(L2 Function(L value) f);

  /// Enables writing sequential computations involving [Either] in a readable,
  /// imperative style, similar to do-notation in Haskell.
  ///
  /// This method allows you to chain operations that return an [Either] without
  /// manually nesting `bind` calls. It automatically handles the short-circuiting
  /// logic: if any operation in the sequence returns a [Left], the entire
  /// computation stops and returns that [Left].
  ///
  /// The `callback` function receives a helper function, conventionally named `$`,
  /// which "unwraps" an [Either]. When `$` is called with a `Right(value)`, it
  /// returns the `value`. When called with a `Left(error)`, it immediately
  /// aborts the `callback` and causes the `doNotation` to return that `Left`.
  ///
  /// Example:
  /// ```dart
  /// Either<String, int> half(int n) =>
  ///     n % 2 == 0 ? Right(n ~/ 2) : Left('$n is not even');
  ///
  /// // Using doNotation for a clean, imperative look.
  /// final result = Either.doNotation<String, int>(($) {
  ///   final a = $(half(10)); // a = 5
  ///   final b = $(half(a));  // short-circuits here, as half(5) is a Left
  ///   return b;             // This line is never reached.
  /// });
  ///
  /// print(result); // Prints: Left(5 is not even)
  /// ```
  static Either<L, R1> doNotation<L, R1>(
    R1 Function(R2 Function<R2>(Either<L, R2>) $) callback,
  ) {
    U resolver<U>(Either<L, U> either) {
      switch (either) {
        case Left(value: final error):
          throw _DoException(error);
        case Right(value: final value):
          return value;
      }
    }

    try {
      final resultValue = callback(resolver);
      return Either.of(resultValue);
    } on _DoException catch (e) {
      return Left(e.message);
    }
  }

  static Future<Either<L, R1>> asyncDoNotation<L, R1>(
    Future<R1> Function(R2 Function<R2>(Either<L, R2>) $) callback,
  ) async {
    U resolver<U>(Either<L, U> either) {
      switch (either) {
        case Left(value: final error):
          throw _DoException(error);
        case Right(value: final value):
          return value;
      }
    }

    try {
      // Await the future returned by the callback
      final resultValue = await callback(resolver);
      return Either.of(resultValue);
    } on _DoException catch (e) {
      // If the resolver throws, catch it and return a Left
      return Left(e.message);
    } catch (e) {
      // Catch any other unexpected errors during the async operation
      return Left(e.toString() as L);
    }
  }
}

class Left<L, R> extends Either<L, R> {
  final L value;
  const Left(this.value);

  @override
  Either<L, R2> bind<R2>(Either<L, R2> Function(R value) f) =>
      Left<L, R2>(value);

  @override
  Either<L, R2> map<R2>(R2 Function(R value) f) => Left<L, R2>(value);

  @override
  int get hashCode => value.hashCode;

  @override
  bool operator ==(Object other) => other is Left && value == other.value;

  @override
  Either<L2, R> mapLeft<L2>(L2 Function(L value) f) => Left(f(value));
}

class Right<L, R> extends Either<L, R> {
  final R value;
  const Right(this.value);

  @override
  Either<L, R2> bind<R2>(Either<L, R2> Function(R value) f) => f(value);

  @override
  Either<L, R2> map<R2>(R2 Function(R value) f) => Right(f(value));

  @override
  int get hashCode => value.hashCode;

  @override
  bool operator ==(Object other) => other is Right && value == other.value;

  @override
  Either<L2, R> mapLeft<L2>(L2 Function(L value) f) => Right(value);
}

class _DoException<M> implements Exception {
  final M message;
  const _DoException(this.message);

  @override
  String toString() => 'DoException: $message';
}
