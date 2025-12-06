import 'dart:convert';
import 'dart:io';

/// Represents a single transcribed word with its timing information.
class Word {
  final String text;
  final int start;
  final int end;

  Word({required this.text, required this.start, required this.end});

  factory Word.fromJson(Map<String, dynamic> json) {
    return Word(
      text: json['text'] as String,
      start: json['start'] as int,
      end: json['end'] as int,
    );
  }
  Map<String, dynamic> toJson() {
    return {'text': text, 'start': start, 'end': end};
  }
}

Future<void> saveAsJson(List<Word> words, String filePath) =>
    File(filePath).writeAsString(jsonEncode(words));

Future<List<Word>> loadFromJson(String filePath) =>
    File(filePath).readAsString().then(jsonDecode).then(decodeWords);

List<Word> decodeWords(dynamic json) => switch (json) {
  final List<dynamic> ws when ws.every(isWord) =>
    ws.map((w) => Word.fromJson(w)).toList(),
  _ => throw FormatException('Invalid JSON format as a list of Word'),
};

bool isWord(dynamic json) => switch (json) {
  {'text': final String _, 'start': final int _, 'end': final int _} => true,
  _ => false,
};
