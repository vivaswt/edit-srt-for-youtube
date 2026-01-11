import 'dart:math';

import 'package:edit_srt_for_youtube/extension/fp_iterable.dart';
import 'package:edit_srt_for_youtube/model/sentence_segment.dart';
import 'package:edit_srt_for_youtube/model/word.dart';
import 'package:edit_srt_for_youtube/fp/either.dart';

/// A single SRT record.
class SrtRecord {
  final int id;
  final String text;
  final int start;
  final int end;

  SrtRecord({
    required this.id,
    required this.text,
    required this.start,
    required this.end,
  });

  /// Creates an SrtRecord from a SentenceSegment.
  factory SrtRecord.fromSentenceSegment(int id, SentenceSegment segment) {
    final text = segment.words.map((word) => word.text).join(' ');
    return SrtRecord(
      id: id,
      text: text,
      start: segment.start,
      end: segment.end,
    );
  }

  /// Converts milliseconds to an SRT timestamp string (HH:MM:SS,ms).
  String msecToString(int msec) {
    final d = Duration(milliseconds: msec);
    final s = d.toString();
    return s.substring(0, s.length - 3).padLeft(12, '0').replaceAll('.', ',');
  }

  /// Converts the record into the standard SRT block format as a list of strings.
  List<String> toTexts() => [
    id.toString(),
    '${msecToString(start)} --> ${msecToString(end)}',
    text,
    '',
  ];

  SrtRecord copyWith({int? id, String? text, int? start, int? end}) =>
      SrtRecord(
        id: id ?? this.id,
        text: text ?? this.text,
        start: start ?? this.start,
        end: end ?? this.end,
      );
}

/// Converts a list of [SrtRecord]s into a list of strings ready to be written to a .srt file.
List<String> srtRecordsToStrings(List<SrtRecord> records) =>
    records.expand((r) => r.toTexts()).toList();

/// Converts a list of [SentenceSegment]s into a list of [SrtRecord]s, assigning sequential IDs.
List<SrtRecord> segmentsToSrtRecords(List<SentenceSegment> segments) =>
    List.generate(
      segments.length,
      (i) => SrtRecord.fromSentenceSegment(i + 1, segments[i]),
    );

/// Converts a list of [SrtRecord]s back into [SentenceSegment]s
/// using timing information from a list of [Word]s.
Either<String, List<SentenceSegment>> srtRecordsToSegments(
  List<SrtRecord> records,
  List<Word> wordsInfo,
) {
  if (_checkIfEachWordIsSame(records, wordsInfo) case (true, final index)) {
    return Left('The ${index}th word is not matched in the SRT file.');
  }
  final lengths = records.map((r) => r.text.split(' ').length).toList();
  final segments = _splitByLength(
    wordsInfo,
    lengths,
  ).map(SentenceSegment.new).toList();
  return Either.of(segments);
}

/// Splits a list `ts` into a list of sublists, where the length of
/// each sublist is determined by the `lengths` parameter.
List<List<T>> _splitByLength<T>(List<T> ts, List<int> lengths) =>
    switch (lengths) {
      [] => [],
      [final l, ...(final ls)] => [
        if (ts.length >= l) ts.sublist(0, l),
        if (ts.length >= l) ..._splitByLength(ts.sublist(l), ls),
        if (ts.length < l) ts,
      ],
    };

/// Checks if the sequence of words from SRT records matches a given list of words.
/// Returns a tuple with a boolean indicating success and the index of the first mismatch.
(bool, int) _checkIfEachWordIsSame(
  List<SrtRecord> srtRecords,
  List<Word> words,
) {
  final srtWordsList = srtRecords.expand((r) => r.text.split(' ')).toList();
  final infoWordsList = words.map((w) => w.text).toList();
  final comparingResult = srtWordsList.zipAllWith(
    infoWordsList,
    (st, wt) => st == wt,
    ifLonger: (_) => false,
    ifShorter: (_) => false,
  );
  final indexes = List.generate(
    max(srtWordsList.length, infoWordsList.length),
    (i) => i,
  );
  final resultWithIndex = comparingResult.zip(indexes);
  final result = resultWithIndex.firstWhere(
    (r) => !r.$1,
    orElse: () => (true, 0),
  );

  return result;
}
