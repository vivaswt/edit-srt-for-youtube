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
