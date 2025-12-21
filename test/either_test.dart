import 'package:flutter_test/flutter_test.dart';
import 'package:edit_srt_for_youtube/fp/either.dart';

void main() {
  group('normal', () {
    test('doNotation should correctly sum the values of two Right eithers', () {
      final Either<String, int> e1 = Either.of(1);
      final Either<String, int> e2 = Either.of(2);
      final Either<String, int> result = Either.doNotation(($) {
        final a = $(e1);
        final b = $(e2);
        return a + b;
      });

      expect(result, Right<String, int>(3));
    });

    test('return left', () {
      final Either<String, int> e1 = Either.of(1);
      final Either<String, int> e2 = Left('NG');
      final Either<String, int> result = Either.doNotation(($) {
        final a = $(e1);
        final b = $(e2);
        return a + b;
      });

      expect(result, Left<String, int>('NG'));
    });
  });
}
