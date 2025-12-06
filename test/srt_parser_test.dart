import 'dart:io';

import 'package:edit_srt_for_youtube/others/either.dart';
import 'package:edit_srt_for_youtube/others/parser.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edit_srt_for_youtube/others/srt_parser.dart';

void main() {
  group('parse numbering line', () {
    test('parse 1 length digit', () {
      final result = parseNumberingLine(ParserInput('1\n'));
      expect(parsedSuccessfully(result, 1), isTrue);
    });

    test('parse digit that is greater than 9', () {
      final result = parseNumberingLine(ParserInput('836\n'));
      expect(parsedSuccessfully(result, 836), isTrue);
    });

    test('fail to parse when containing non-digit', () {
      final result = parseNumberingLine(ParserInput('836x\n'));
      expect(failToParse(result), true);
    });

    test('fail to parse when not ending with new line', () {
      final result = parseNumberingLine(ParserInput('84'));
      expect(failToParse(result), true);
    });
  });

  group('parseTimestampLine', () {
    test('should parse a valid timestamp line', () {
      const input = '00:02:15,333 --> 00:02:17,001\n';
      final result = parseTimestampLine(ParserInput(input));
      expect(
        result,
        isA<Right>().having((r) => r.value.$1, 'value', (
          start: 135333,
          end: 137001,
        )),
      );
    });

    test('should fail with malformed separator', () {
      const input = '00:02:15,333 -> 00:02:17,001\n';
      final result = parseTimestampLine(ParserInput(input));
      expect(result, isA<Left>());
    });

    test('should fail without a newline', () {
      const input = '00:02:15,333 --> 00:02:17,001';
      final result = parseTimestampLine(ParserInput(input));
      expect(result, isA<Left>());
    });
  });

  group('parseTextLines', () {
    test('should parse a single line of text', () {
      const input = 'Hello, world!\n';
      final result = parseTextLines(ParserInput(input));
      expect(
        result,
        isA<Right>().having((r) => r.value.$1, 'value', ['Hello, world!']),
      );
    });

    test('should parse multiple lines of text', () {
      const input = 'First line.\nSecond line.\n';
      final result = parseTextLines(ParserInput(input));
      expect(
        result,
        isA<Right>().having((r) => r.value.$1, 'value', [
          'First line.',
          'Second line.',
        ]),
      );
    });
  });

  group('parseSrt (full parser)', () {
    test('should parse a single valid record with trailing blank line', () {
      const srtContent = '''
1
00:00:01,000 --> 00:00:02,000
Hello

''';
      final result = parseSrt(srtContent);
      expect(result, isA<Right>());
      final records = (result as Right).value;
      expect(records.length, 1);
      expect(records[0].id, 1);
      expect(records[0].text, 'Hello');
    });

    test(
      'should fail to parse a single valid record without trailing blank line',
      () {
        const srtContent = '''
1
00:00:01,000 --> 00:00:02,000
Hello''';
        final result = parseSrt(srtContent);
        expect(result, isA<Left>());
      },
    );

    test('should parse multiple valid records', () {
      const srtContent = '''
1
00:00:01,000 --> 00:00:02,000
First

2
00:00:03,000 --> 00:00:04,000
Second
Multi-line

''';
      final result = parseSrt(srtContent);
      expect(result, isA<Right>());
      final records = (result as Right).value;
      expect(records.length, 2);
      expect(records[0].id, 1);
      expect(records[0].text, 'First');
      expect(records[1].id, 2);
      expect(records[1].text, 'Second\nMulti-line');
    });

    test('should fail to parse for an empty string', () {
      final result = parseSrt('');
      expect(result, isA<Left>());
    });

    test('should success as multiple texts on malformed input', () {
      const srtContent = '''
1
00:00:01,000 --> 00:00:02,000
Missing blank line here
2
00:00:03,000 --> 00:00:04,000
Second
''';
      final result = parseSrt(srtContent);
      expect(result, isA<Right>());
    });
  });

  group('test with real file', () {
    test('test with real file', () async {
      final buffer = await File(
        r'test_data\Behind Ireland’s Economic Miracle _ Infinite Explorer With Hannah Fry _ National Geographic UK.srt',
      ).readAsString();
      final result = parseSrt(buffer);
      if (result case Left(value: final value)) {
        print(value);
      }
      expect(result, isA<Right>());
    });
  });
}

// helper functions
bool parsedSuccessfully<T>(
  Either<String, (T, ParserInput)> result,
  T expectedValue,
) => switch (result) {
  Right(value: final value) => value.$1 == expectedValue,
  _ => false,
};

bool failToParse<T>(Either<String, (T, ParserInput)> result) =>
    switch (result) {
      Left(value: final _) => true,
      _ => false,
    };

void showError<T>(Either<String, (T, ParserInput)> result) => switch (result) {
  Left(value: final message) => print(message),
  _ => null,
};
