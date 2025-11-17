import 'package:edit_srt_for_youtube/model/sentence_segment.dart';

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

  factory SrtRecord.fromSentenceSegment(int id, SentenceSegment segment) {
    final text = segment.words.map((word) => word.text).join(' ');
    return SrtRecord(
      id: id,
      text: text,
      start: segment.start,
      end: segment.end,
    );
  }

  String msecToString(int msec) {
    final d = Duration(milliseconds: msec);
    final s = d.toString();
    return s.substring(0, s.length - 3).padLeft(12, '0').replaceAll('.', ',');
  }

  List<String> toTexts() => [
    id.toString(),
    '${msecToString(start)} --> ${msecToString(end)}',
    text,
    '',
  ];
}

/// Converts a list of [SrtRecord]s into a list of strings.
List<String> srtRecordsToStrings(List<SrtRecord> records) =>
    records.expand((r) => r.toTexts()).toList();

/// Converts a list of [SentenceSegment]s into a list of [SrtRecord]s.
List<SrtRecord> segmentsToSrtRecords(List<SentenceSegment> segments) =>
    List.generate(
      segments.length,
      (i) => SrtRecord.fromSentenceSegment(i + 1, segments[i]),
    );
