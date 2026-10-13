import 'package:edit_srt_for_youtube/model/sentence_segment.dart';
import 'package:edit_srt_for_youtube/model/srt.dart';

/// Creates an SrtRecord from a SentenceSegment.
SrtRecord _segmentToSrtRecord(int id, SentenceSegment segment) {
  final text = segment.words
      .map((word) => word.text)
      .where((text) => text != '[music]')
      .join(' ');
  return SrtRecord(id: id, text: text, start: segment.start, end: segment.end);
}

/// Converts a list of [SentenceSegment]s into a list of [SrtRecord]s, assigning sequential IDs.
List<SrtRecord> segmentsToSrtRecords(List<SentenceSegment> segments) =>
    List.generate(
      segments.length,
      (i) => _segmentToSrtRecord(i + 1, segments[i]),
    );
