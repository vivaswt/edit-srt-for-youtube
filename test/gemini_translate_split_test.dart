import 'dart:io';

import 'package:edit_srt_for_youtube/fp/either.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edit_srt_for_youtube/api/gemini_translate_split.dart';

void main() {
  group('normal', () {
    test('translateTextLines', () async {
      final textLines = [
        'You made the right decision.',
        'Passing raw SRT files often confuses LLMs',
        'because the timestamps look like math or data that shouldn'
            't be touched.',
      ];
      final result = await translateTextLines(
        textLines,
        Platform.environment['GEMINI_API_KEY']!,
      ).run();
      result.map((r) => print(r));
      expect(
        result,
        isA<Right<Exception, List<String>>>().having(
          (r) => r.value,
          'value',
          hasLength(3),
        ),
      );
    });

    test('translateSrt', () async {});
  });
}
