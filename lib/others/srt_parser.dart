import 'package:edit_srt_for_youtube/others/either.dart';
import 'package:edit_srt_for_youtube/others/parser.dart';
import 'package:edit_srt_for_youtube/model/srt.dart';

/// A parser that consumes a single line.
final pLine = any<String>();

/// A parser that consumes a line containing only an integer.
final pIntLine = satisfy<String>(
  (s) => int.tryParse(s) != null && !s.contains(RegExp(r'\D')),
).map(int.parse);

/// A parser that consumes a blank line.
final pBlankLine = satisfy<String>((s) => s.trim().isEmpty);

/// Parses an SRT timestamp component (e.g., "00:02:15,333") into milliseconds.
int _parseSrtTimestamp(String h, String m, String s, String ms) => Duration(
  hours: int.parse(h),
  minutes: int.parse(m),
  seconds: int.parse(s),
  milliseconds: int.parse(ms),
).inMilliseconds;

/// A parser for a single SRT timestamp line.
/// e.g., "00:02:15,333 --> 00:02:17,001"
final pTimestampLine = () {
  final regex = RegExp(
    r'^(\d{2}):(\d{2}):(\d{2}),(\d{3})\s*-->\s*(\d{2}):(\d{2}):(\d{2}),(\d{3})$',
  );

  return satisfy<String>((s) => regex.hasMatch(s)).map((line) {
    final match = regex.firstMatch(line)!;
    final start = _parseSrtTimestamp(
      match.group(1)!,
      match.group(2)!,
      match.group(3)!,
      match.group(4)!,
    );
    final end = _parseSrtTimestamp(
      match.group(5)!,
      match.group(6)!,
      match.group(7)!,
      match.group(8)!,
    );
    return (start: start, end: end);
  });
}();

/// A parser that consumes one or more lines of text until a blank line is found.
final pTextLines = many(satisfy<String>((s) => s.trim().isNotEmpty));

/// A parser for a single, complete SRT record block.
/// An SRT block consists of an ID, a timestamp, text, and a blank line separator.
final pSrtRecord = pIntLine.bind(
  (id) => pTimestampLine.bind(
    (times) => pTextLines.bind(
      (textLines) => pBlankLine.map(
        (_) => SrtRecord(
          id: id,
          text: textLines.join('\n'),
          start: times.start,
          end: times.end,
        ),
      ),
    ),
  ),
);

/// The main SRT parser.
/// It parses zero or more SRT records from a list of lines.
/// It also handles optional blank lines at the start or between records.
final srtParser = many(pBlankLine).bind((_) => many(pSrtRecord));

/// Helper function to run the SRT parser on a list of strings.
List<SrtRecord> parseSrt(List<String> lines) {
  final result = srtParser(lines);

  switch (result) {
    case Right(value: (final records, final rest)):
      if (rest.isNotEmpty && rest.any((line) => line.isNotEmpty)) {
        // If there's non-empty content left over, it's a partial parse.
        // You might want to handle this as an error depending on requirements.
        print('Warning: Parser finished with unconsumed input: $rest');
      }
      return records;
    case Left(value: final errors):
      // In a real app, you'd throw or return a result type.
      throw Exception('Failed to parse SRT file: ${errors.join(', ')}');
  }
}
