import 'package:edit_srt_for_youtube/extension/object.dart';
import 'package:edit_srt_for_youtube/fp/either.dart';
import 'package:edit_srt_for_youtube/fp/parser.dart';
import 'package:edit_srt_for_youtube/model/srt.dart';

/// A parser that consumes a line containing only an integer.
final Parser<int> parseNumberingLine = Parser.doNotation(($) {
  final no = $(many1(digit)).join().pipe(int.parse);
  $(newLine);

  return no;
});

/// A parser that consumes a blank line.
final parseBlankLine = newLine;

/// Parses an SRT timestamp component (e.g., "00:02:15,333") into Duration
final Parser<int> parseTimestamp = Parser.doNotation(($) {
  final h = $(count(2, digit)).join();
  $(char(':'));
  final m = $(count(2, digit)).join();
  $(char(':'));
  final s = $(count(2, digit)).join();
  $(char(','));
  final ms = $(count(3, digit)).join();

  return _parseSrtTimestamp(h, m, s, ms);
});

int _parseSrtTimestamp(String h, String m, String s, String ms) => Duration(
  hours: int.parse(h),
  minutes: int.parse(m),
  seconds: int.parse(s),
  milliseconds: int.parse(ms),
).inMilliseconds;

/// A parser for a single SRT timestamp line.
/// e.g., "00:02:15,333 --> 00:02:17,001"
final Parser<({int start, int end})> parseTimestampLine = Parser.doNotation((
  $,
) {
  final start = $(parseTimestamp);
  $(string(' --> '));
  final end = $(parseTimestamp);
  $(newLine);

  return (start: start, end: end);
});

/// A parser that consumes one or more lines of text until a blank line is found.
final _parseTextLine = Parser.doNotation(($) {
  final txt = $(many1(noneOf('\n'))).join();
  $(newLine);

  return txt;
});

final parseTextLines = Parser.doNotation(($) {
  final lines = $(many(_parseTextLine));
  final lastLine = $(optional(many1(noneOf('\n'))))?.join();
  if (lastLine != null) lines.add(lastLine);
  return lines;
});

/// A parser for a single, complete SRT record block.
/// An SRT block consists of an ID, a timestamp, text, and a blank line separator.
final Parser<SrtRecord> parseSrtRecord = Parser.doNotation(($) {
  final id = $(parseNumberingLine);
  final timestamp = $(parseTimestampLine);
  final texts = $(parseTextLines);

  return SrtRecord(
    id: id,
    start: timestamp.start,
    end: timestamp.end,
    text: texts.join('\n'),
  );
});

/// The main SRT parser.
/// It parses zero or more SRT records from a list of lines.
/// It also handles optional blank lines at the start or between records.
final Parser<List<SrtRecord>> _parseSrt = Parser.doNotation(($) {
  final result = $(sepBy1(parseSrtRecord, parseBlankLine));
  $(many(parseBlankLine));
  $(eof);

  return result;
});

/// Helper function to run the SRT parser on a list of strings.
// Either<ParserErrorMessage, List<SrtRecord>> parseSrt(String lines) =>
//     _parseSrt(ParserInput(lines)).map((r) => r.$1);

Either<ParserErrorMessage, List<SrtRecord>> parseSrt(String lines) {
  final input = ParserInput(lines);
  final r1 = _parseSrt(input);
  final r2 = r1.map((r) => r.$1);
  return r2;
}
