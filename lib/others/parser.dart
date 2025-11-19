import 'package:edit_srt_for_youtube/others/either.dart';

typedef StateFn<S, A> = Either<List<String>, (A, S)> Function(S);

class Parser<S, A> {
  final StateFn<S, A> run;

  Parser(this.run);

  Either<List<String>, (A, S)> call(S state) => run(state);

  /// Lifts a value into the Parser context.
  /// Creates a parser that always succeeds with the given value and consumes no input.
  static Parser<S, A> of<S, A>(A value) => Parser((s) => Right((value, s)));

  /// Maps a function over the successful result of a parser.
  Parser<S, B> map<B>(B Function(A value) f) {
    return Parser((s) {
      final result = run(s);
      // Use Either.map to transform the successful result
      return result.map((res) {
        final (a, sPrime) = res;
        return (f(a), sPrime);
      });
    });
  }

  /// Chains a new parser based on the result of this one.
  Parser<S, B> bind<B>(Parser<S, B> Function(A value) f) {
    return Parser((s) {
      final result = run(s);
      // Use Either.bind to chain the next parsing operation
      return result.bind((res) => f(res.$1).run(res.$2));
    });
  }
}

extension ParserAlt<S, A> on Parser<S, A> {
  Parser<S, A> or(Parser<S, A> other) {
    return Parser((s) {
      final res1 = run(s);
      final res2 = other.run(s);
      return _eitherOr(res1, res2);
    });
  }
}

Either<List<String>, (A, S)> _eitherOr<A, S>(
  Either<List<String>, (A, S)> a,
  Either<List<String>, (A, S)> b,
) {
  switch (a) {
    case Left(value: final valueA):
      switch (b) {
        case Left(value: final valueB):
          // Combine both errors (reversed order)
          return Left([...valueB, ...valueA]);
        default:
          // If 'a' fails, return 'b'
          return b;
      }
    default:
      // If 'a' succeeds, take it
      return a;
  }
}

Parser<List<S>, S> any<S>() => Parser(
  (List<S> input) => switch (input) {
    [final s, ...(final ss)] => Right((s, ss)),
    _ => Left(['any: unexpected end of input']),
  },
);

Parser<List<S>, S> satisfy<S>(bool Function(S) predicate) => Parser(
  (List<S> input) => switch (input) {
    [final s, ...(final ss)] when predicate(s) => Right((s, ss)),
    [final _, ...(final _)] => Left(['satisfy: predicate not satisfied']),
    _ => Left(['satisfy: unexpected end of input']),
  },
);

Parser<List<S>, List<A>> many<S, A>(Parser<List<S>, A> p) => Parser(
  (List<S> input) => p(input).bind(
    (a) => many(p)(a.$2).bind((as) => Either.of(([a.$1, ...as.$1], as.$2))),
  ),
).or(Parser.of([]));
