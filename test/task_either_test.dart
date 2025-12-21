import 'package:edit_srt_for_youtube/fp/either.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edit_srt_for_youtube/fp/task_either.dart';

void main() {
  group('normal', () {
    test('doNotaion', () async {
      final TaskEither<String, int> taskEither = TaskEither.doNotation((
        $,
      ) async {
        final a = await $(plus1(1));
        final b = await $(double(2));
        print('return');
        return a + b;
      });

      print('start');
      final result = await taskEither.run();
      expect(result, Right<String, int>(6));
      print('done');
    });

    test('if all of them are right, sequence should return right', () async {
      final taskEithers = Iterable.generate(3, plus1);
      final result = await TaskEither.sequence(taskEithers).run();
      expect(
        result,
        isA<Right<String, List<int>>>().having((r) => r.value, 'value', [
          1,
          2,
          3,
        ]),
      );
    });

    test(
      'if one of them is Left, sequence should stop and return Left.',
      () async {
        final taskEithers = Iterable.generate(3, (i) => plus1(i + 9));
        final result = await TaskEither.sequence(taskEithers).run();
        expect(result, Left<String, int>('overflow'));
      },
    );
  });
}

TaskEither<String, int> plus1(int n) => TaskEither(
  () => Future.delayed(Duration(milliseconds: 900), () {
    print('plus1 $n called');
    return n >= 10 ? Left('overflow') : Either.of(n + 1);
  }),
);

TaskEither<String, int> double(int n) => TaskEither(
  () => Future.delayed(Duration(milliseconds: 900), () {
    print('double $n called');
    return Either.of(n + 1);
  }),
);
