import 'package:edit_srt_for_youtube/extension/fp_iterable.dart';

extension FpListExtensions<T> on List<T> {
  Iterable<(List<T>, List<T>)> splits() => inits().zip(tails());
  Iterable<List<T>> inits() => isNotEmpty
      ? Iterable.generate(length + 1, (i) => sublist(0, i))
      : Iterable.empty();
  Iterable<List<T>> tails() => isNotEmpty
      ? Iterable.generate(length + 1, (i) => sublist(i))
      : Iterable.empty();

  (List<T>, List<T>, List<T>) splitAtRange({
    required int start,
    required int end,
  }) {
    if ((start < 0) ||
        (start > length) ||
        (end < 0) ||
        (end > length) ||
        start > end) {
      throw Exception('Invalid range');
    }

    return (sublist(0, start), sublist(start, end), sublist(end));
  }

  List<T> mapRange({
    required int start,
    required int end,
    required List<T> Function(List<T>) convert,
  }) {
    final (pre, sub, post) = splitAtRange(start: start, end: end);
    return [...pre, ...convert(sub), ...post];
  }
}

extension FpListOfListExtensions<T> on List<List<T>> {
  List<T> flatten() => expand((ls) => ls).toList();
}
