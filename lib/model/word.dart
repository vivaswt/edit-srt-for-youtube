import 'dart:convert';
import 'dart:io';

/// Represents a single transcribed word with its timing information.
class Word {
  final String text;
  final int start;
  final int end;

  Word({required this.text, required this.start, required this.end});

  Map<String, dynamic> toJson() {
    return {'text': text, 'start': start, 'end': end};
  }
}

Future<void> saveAsJson(List<Word> words, String filePath) =>
    File(filePath).writeAsString(jsonEncode(words));

Future<List<Word>> loadFromJson(String filePath) =>
    File(filePath).readAsString().then(jsonDecode).then(_decodeWords);

List<Word> _decodeWords(dynamic json) => switch (json) {
  final List<dynamic> ws when ws.every((w) => w is Word) => ws.cast<Word>(),
  _ => throw FormatException('Invalid JSON format as a list of Word'),
};
