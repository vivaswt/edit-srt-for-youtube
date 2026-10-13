import 'dart:convert';
import 'dart:io';

import 'package:edit_srt_for_youtube/model/sentence_segment.dart';
import 'package:edit_srt_for_youtube/io/word_io.dart';

Future<void> saveAsJson(List<SentenceSegment> segments, String filePath) =>
    File(filePath).writeAsString(jsonEncode(segments));

Future<List<SentenceSegment>> loadFromJson(String filePath) =>
    File(filePath).readAsString().then(jsonDecode).then(decodeSentences);

List<SentenceSegment> decodeSentences(dynamic json) => switch (json) {
  final List<dynamic> sg when sg.every(isSentence) =>
    sg.map((w) => SentenceSegment.fromJson(w)).toList(),
  _ => throw FormatException(
    'Invalid JSON format as a list of SentenceSegment',
  ),
};

bool isSentence(dynamic json) => switch (json) {
  {'words': final List<dynamic> ws} when ws.every(isWord) => true,
  _ => false,
};
