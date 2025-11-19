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
}

class Left<L, R> extends Either<L, R> {
  final L value;
  const Left(this.value);

  @override
  Either<L, R2> bind<R2>(Either<L, R2> Function(R value) f) =>
      Left<L, R2>(value);

  @override
  Either<L, R2> map<R2>(R2 Function(R value) f) => Left<L, R2>(value);
}

class Right<L, R> extends Either<L, R> {
  final R value;
  const Right(this.value);

  @override
  Either<L, R2> bind<R2>(Either<L, R2> Function(R value) f) => f(value);

  @override
  Either<L, R2> map<R2>(R2 Function(R value) f) => Right(f(value));
}
