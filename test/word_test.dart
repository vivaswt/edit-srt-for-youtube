import 'package:edit_srt_for_youtube/model/word.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('json', () {
    test('load words from json file', () async {
      final result = await loadFromJson(
        r'test_data\Behind Ireland’s Economic Miracle _ Infinite Explorer With Hannah Fry _ National Geographic UK_words.json',
      );

      expect(result, isA<List<Word>>());
    });
  });
}
