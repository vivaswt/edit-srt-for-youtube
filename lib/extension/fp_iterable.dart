extension FpIterableExtensions<T> on Iterable<T> {
  Iterable<(T, U)> zip<U>(Iterable<U> other) =>
      zipWith(other, (a, b) => (a, b));

  Iterable<V> zipWith<V, U>(Iterable<U> other, V Function(T, U) f) sync* {
    final myIterator = iterator;
    final otherIterator = other.iterator;

    while (myIterator.moveNext() && otherIterator.moveNext()) {
      yield f(myIterator.current, otherIterator.current);
    }
  }

  /// Zips `this` iterable with `other`, applying `f` to paired elements.
  ///
  /// Unlike [zipWith], this method continues until both iterables are exhausted.
  /// Optional functions [ifLonger] and [ifShorter] can be provided to handle
  /// remaining elements when one iterable is longer than the other.
  Iterable<V> zipAllWith<V, U>(
    Iterable<U> other,
    V Function(T, U) f, {
    V Function(U)? ifShorter,
    V Function(T)? ifLonger,
  }) sync* {
    final thisIterator = iterator;
    final otherIterator = other.iterator;

    while (true) {
      final thisHas = thisIterator.moveNext();
      final otherHas = otherIterator.moveNext();

      if (thisHas && otherHas) {
        yield f(thisIterator.current, otherIterator.current);
        continue;
      }

      if (thisHas && ifLonger != null) {
        yield ifLonger(thisIterator.current);
        continue;
      }

      if (otherHas && ifShorter != null) {
        yield ifShorter(otherIterator.current);
        continue;
      }

      break;
    }
  }

  Iterable<List<T>> chunk(int size) sync* {
    if (size <= 0) throw ArgumentError.value(size, 'size', 'must be positive');
    final iterator = this.iterator;
    while (iterator.moveNext()) {
      final chunk = [iterator.current];
      while (chunk.length < size && iterator.moveNext()) {
        chunk.add(iterator.current);
      }
      yield chunk;
    }
  }
}
