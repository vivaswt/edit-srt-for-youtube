import 'package:edit_srt_for_youtube/extension/object.dart';
import 'package:edit_srt_for_youtube/others/either.dart';

typedef ParserErrorMessage = String;

typedef StateFn<A> =
    Either<ParserErrorMessage, (A, ParserInput)> Function(ParserInput);

class _DoException implements Exception {
  final ParserErrorMessage message;
  const _DoException(this.message);

  @override
  String toString() => 'DoException: $message';
}

class Parser<A> {
  final StateFn<A> run;

  Parser(this.run);

  Either<ParserErrorMessage, (A, ParserInput)> call(ParserInput state) =>
      run(state);

  /// Lifts a value into the Parser context.
  /// Creates a parser that always succeeds with the given value and consumes no input.
  static Parser<A> of<A>(A value) => Parser((s) => Right((value, s)));

  /// Maps a function over the successful result of a parser.
  Parser<B> map<B>(B Function(A value) f) {
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
  Parser<B> bind<B>(Parser<B> Function(A value) f) {
    return Parser((s) {
      final result = run(s);
      // Use Either.bind to chain the next parsing operation
      return result.bind((res) => f(res.$1).run(res.$2));
    });
  }

  static Parser<B> doNotation<B>(
    B Function(T Function<T>(Parser<T>) $) callback,
  ) {
    return Parser<B>((s) {
      ParserInput currentState = s;

      U resolver<U>(Parser<U> stateOp) {
        final result = stateOp(currentState);
        switch (result) {
          case Left(value: final error):
            throw _DoException(error);
          case Right(value: final value):
            currentState = value.$2;
            return value.$1;
        }
      }

      try {
        final resultValue = callback(resolver);
        return Either.of((resultValue, currentState));
      } on _DoException catch (e) {
        return Left(e.message);
      }
    });
  }
}

extension ParserAlt<A> on Parser<A> {
  Parser<A> or(Parser<A> other) {
    return Parser((s) {
      final res1 = run(s);
      final res2 = other.run(s);
      return _eitherOr(res1, res2);
    });
  }
}

Parser<List<A>> sequence<A>(Iterable<Parser<A>> ps) => ps.fold(
  Parser.of([]),
  (acc, p) => acc.bind((accr) => p.map((pr) => [...accr, pr])),
);

Either<String, (A, S)> _eitherOr<A, S>(
  Either<String, (A, S)> a,
  Either<String, (A, S)> b,
) => switch ((a, b)) {
  (Left(value: final _), _) => b,
  _ => a,
};

Parser<String> satisfy(
  bool Function(String) predicate, {
  String expected = '',
}) => Parser(
  (s) => s.isEmpty
      ? Left('Expected $expected, found end of input ${s.postionText}')
      : (predicate(s.char)
            ? Either.of((s.char, s.next()))
            : Left('Expected $expected, found ${s.char} $s.postionText')),
);

Parser<String> any = satisfy((_) => true, expected: 'any character');

Parser<List<A>> many<A>(Parser<A> p) => Parser(
  (s) => p(s).bind(
    (a) => many(p)(a.$2).bind((as) => Either.of(([a.$1, ...as.$1], as.$2))),
  ),
).or(Parser.of([]));

Parser<List<A>> many1<A>(Parser<A> p) => Parser(
  (s) => p(s).bind(
    (a) => many(p)(a.$2).bind((as) => Either.of(([a.$1, ...as.$1], as.$2))),
  ),
);

/// Parses one or more occurrences of `p`, separated by `sep`.
Parser<List<A>> sepBy1<A, S>(Parser<A> p, Parser<S> sep) =>
    Parser.doNotation(($) {
      final head = $(p);
      final tail = $(many(sep.bind((_) => p)));

      return [head, ...tail];
    });

Parser<List<A>> sepBy<A, S>(Parser<A> p, Parser<S> sep) =>
    sepBy1(p, sep).or(Parser.of([]));

Parser<List<A>> count<A>(int n, Parser<A> p) =>
    List.generate(n, (_) => p).pipe(sequence);

Parser<String> char(String c) => satisfy((char) => char == c, expected: c);

Parser<String> string(String s) =>
    s.split('').map(char).pipe(sequence).map((ss) => ss.join());

Parser<String> newLine = satisfy((c) => c == '\n', expected: 'newline');

Parser<void> eof = Parser(
  (s) => s.isEmpty
      ? Either.of((null, s))
      : Left('Expected end of input, found ${s.char} ${s.postionText}}'),
);

Parser<String> digit = satisfy(
  (c) => '0123456789'.contains(c),
  expected: 'digit',
);

Parser<String> noneOf(String s) =>
    satisfy((c) => !s.contains(c), expected: 'none of $s');

class ParserInput {
  final String _buffer;
  final int offset;
  final int lineNo;

  bool get isEmpty => _buffer.isEmpty;
  bool get isNotEmpty => !isEmpty;
  String get char => _buffer[0];

  ParserInput._(this._buffer, this.offset, this.lineNo);

  ParserInput(String buffer) : this._(buffer, 0, 1);

  @override
  int get hashCode => Object.hash(_buffer, offset, lineNo);

  @override
  bool operator ==(Object other) =>
      other is ParserInput &&
      other._buffer == _buffer &&
      other.offset == offset &&
      other.lineNo == lineNo;

  ParserInput next() {
    if (isEmpty) {
      throw Exception('Unexpected end of input');
    }
    if (_buffer[0] == '\n') {
      return ParserInput._(_buffer.substring(1), 1, lineNo + 1);
    } else {
      return ParserInput._(_buffer.substring(1), offset + 1, lineNo);
    }
  }

  String get postionText => '[line: $lineNo, offset: $offset]';
}
