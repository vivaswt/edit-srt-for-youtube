extension Pipe<T> on T {
  /// Passes this object as an argument to the given function [f].
  R pipe<R>(R Function(T) f) => f(this);

  /// Applies two separate functions, [f] and [g], to this object and returns
  /// the results as a record (tuple). This is also known as a "fan-out".
  ///
  /// Useful for performing two independent operations on the same data.
  (R, S) fork<R, S>(R Function(T) f, S Function(T) g) => (f(this), g(this));

  T tap(void Function(T) f) {
    f(this);
    return this;
  }

  T check(({bool expect, String message}) Function(T) convert) {
    final result = convert(this);
    if (!result.expect) {
      throw Exception(result.message);
    }
    return this;
  }
}
