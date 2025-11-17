import 'package:edit_srt_for_youtube/extension/fp_iterable.dart';

extension FpListExtensions<T> on List<T> {
  Iterable<(List<T>, List<T>)> splits() => inits().zip(tails());
  Iterable<List<T>> inits() => isNotEmpty
      ? Iterable.generate(length + 1, (i) => sublist(0, i))
      : Iterable.empty();
  Iterable<List<T>> tails() => isNotEmpty
      ? Iterable.generate(length + 1, (i) => sublist(i))
      : Iterable.empty();
}
