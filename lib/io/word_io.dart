import 'dart:convert';
import 'dart:io';

import 'package:edit_srt_for_youtube/io/srv2_parser.dart';
import 'package:edit_srt_for_youtube/model/word.dart';

Future<List<Word>> loadFromSrv2(String filePath) =>
    File(filePath).readAsString().then(parseSrv2);

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
