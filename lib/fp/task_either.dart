import 'package:edit_srt_for_youtube/fp/either.dart';

class TaskEither<L, R> {
  final Future<Either<L, R>> Function() _run;

  TaskEither(this._run);

  factory TaskEither.of(R right) => TaskEither(() async => Right(right));

  factory TaskEither.left(L left) => TaskEither(() async => Left(left));

  Future<Either<L, R>> run() => _run();

  factory TaskEither.tryCatch(
    Future<R> Function() run,
    L Function(Object error) onError,
  ) => TaskEither<L, R>(() async {
    try {
      return Right<L, R>(await run());
    } catch (error) {
      return Left<L, R>(onError(error));
    }
  });

  TaskEither<L, B> map<B>(B Function(R right) f) {
    return TaskEither(() async {
      final result = await _run();
      return result.map(f);
    });
  }

  TaskEither<L, B> bind<B>(TaskEither<L, B> Function(R right) f) {
    return TaskEither(() async {
      final result = await _run();
      return switch (result) {
        Left(value: final l) => Left(l),
        Right(value: final r) => await f(r).run(),
      };
    });
  }

  static TaskEither<L, R1> doNotation<L, R1>(
    Future<R1> Function(Future<R2> Function<R2>(TaskEither<L, R2>) $) callback,
  ) {
    Future<U> resolver<U>(TaskEither<L, U> taskEither) async {
      final result = await taskEither.run();
      return switch (result) {
        Left(value: final l) => throw _DoException(l),
        Right(value: final r) => r,
      };
    }

    return TaskEither(() async {
      try {
        return Either.of(await callback(resolver));
      } on _DoException<L> catch (e) {
        return Left(e.value);
      }
    });
  }

  static TaskEither<L, List<R>> sequence<L, R>(
    Iterable<TaskEither<L, R>> taskEithers,
  ) => taskEithers.fold(
    TaskEither<L, List<R>>.of([]),
    (previousValue, element) => previousValue.bind(
      (values) => element.bind(
        (value) => TaskEither<L, List<R>>.of([...values, value]),
      ),
    ),
  );

  factory TaskEither.fromEither(Either<L, R> either) =>
      TaskEither(() async => either);
}

class _DoException<L> implements Exception {
  final L value;
  const _DoException(this.value);

  @override
  String toString() => 'DoException: $value';
}
