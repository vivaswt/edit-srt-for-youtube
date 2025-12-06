import 'dart:convert';
import 'dart:io';

import 'package:edit_srt_for_youtube/extension/fp_list.dart';
import 'package:edit_srt_for_youtube/model/word.dart';

/// A part of a sentence or a sentence it self.
class SentenceSegment {
  final List<Word> words;
  SentenceSegment(this.words);

  int get start => words.first.start;
  int get end => words.last.end;

  Map<String, dynamic> toJson() => {
    'words': words.map((w) => w.toJson()).toList(),
  };

  factory SentenceSegment.fromJson(Map<String, dynamic> json) {
    final words = decodeWords(json['words']);
    return SentenceSegment(words);
  }
}

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

/// Splits a list of [Word] objects into a list of [SentenceSegment]s.
List<SentenceSegment> splitBySentence(List<Word> words) {
  if (words.isEmpty) {
    return [];
  }

  final sentencesAsWords = words.fold<List<List<Word>>>([], (sentences, word) {
    if (sentences.isEmpty || _isEndOfSentence(sentences.last.last)) {
      sentences.add([word]);
    } else {
      sentences.last.add(word);
    }
    return sentences;
  });

  return sentencesAsWords.map((wordList) => SentenceSegment(wordList)).toList();
}

List<SentenceSegment> splitLongSegment(
  SentenceSegment segment, {
  required int minTotalWords,
  required int minPartWords,
}) => splitLongWords(
  segment.words,
  minTotalWords: minTotalWords,
  minPartWords: minPartWords,
).map(SentenceSegment.new).toList();

/// Returns true if the given [Word] is the end of a sentence.
bool _isEndOfSentence(Word word) =>
    word.text.endsWith('.') ||
    word.text.endsWith('?') ||
    word.text.endsWith('!');

List<List<Word>> splitLongWords(
  List<Word> words, {
  required int minTotalWords,
  required int minPartWords,
}) {
  if (words.length < minTotalWords) {
    return [words];
  }

  final matchPair = words.splits().firstWhere((wordListPair) {
    final preList = wordListPair.$1;
    final postList = wordListPair.$2;

    if (preList.isEmpty || postList.isEmpty) {
      return false;
    }

    return preList.last.text.endsWith(',') &&
        preList.length >= minPartWords &&
        postList.length >= minPartWords;
  }, orElse: () => (words, []));

  return [
    matchPair.$1,
    if (matchPair.$2.isNotEmpty)
      ...splitLongWords(
        matchPair.$2,
        minTotalWords: minTotalWords,
        minPartWords: minPartWords,
      ),
  ];
}

List<List<Word>> splitLongWords2(
  List<Word> words, {
  required int minTotalWords,
  required int minPartWords,
  int start = 0,
}) {
  if (words.length < minTotalWords) {
    return [words];
  }

  final r = words.indexWhere((w) => w.text.endsWith(','));
  if (r < 0) {
    return [words];
  }

  final x = words.sublist(0, r);
  final y = words.sublist(r + 1);
  if (x.length >= minPartWords && y.length >= minPartWords) {
    return [
      x,
      ...splitLongWords(
        y,
        minTotalWords: minTotalWords,
        minPartWords: minPartWords,
      ),
    ];
  }
  if (x.length >= minPartWords && y.length < minPartWords) {
    return [words];
  }
  if (y.length >= minPartWords) {
    // TODO
    return [words];
  }

  return [words];
}
