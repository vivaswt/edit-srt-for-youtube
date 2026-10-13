import 'dart:io';

import 'package:edit_srt_for_youtube/converter/ssg_srt.dart';
import 'package:edit_srt_for_youtube/extension/object.dart';
import 'package:edit_srt_for_youtube/io/srt_io.dart';
import 'package:edit_srt_for_youtube/io/srv2_parser.dart';
import 'package:edit_srt_for_youtube/io/sentence_segment_io.dart';
import 'package:edit_srt_for_youtube/model/sentence_segment.dart';
import 'package:edit_srt_for_youtube/converter/word_ssg.dart';

Future<File> createSentenceSegmentFileFromSrv2(
  String srv2FilePath,
  String ssgFilePath,
) async {
  List<SentenceSegment> splitLongSentence(segment) =>
      splitLongSegment(segment, minTotalWords: 15, minPartWords: 5);

  final contents = await File(srv2FilePath).readAsString();
  final segments = contents
      .pipe(parseSrv2)
      .pipe(splitBySentence)
      .expand(splitLongSentence)
      .toList();

  return saveAsJson(segments, ssgFilePath).then((_) => File(ssgFilePath));
}

Future<File> createSrtRecordFileFromSrv2(
  String srv2FilePath,
  String srtFilePath,
) async {
  List<SentenceSegment> splitLongSentence(segment) =>
      splitLongSegment(segment, minTotalWords: 15, minPartWords: 5);

  final contents = await File(srv2FilePath).readAsString();
  final srtRecords = contents
      .pipe(parseSrv2)
      .pipe(splitBySentence)
      .expand(splitLongSentence)
      .toList()
      .pipe(segmentsToSrtRecords);

  return saveSrtRecords(srtRecords, srtFilePath).then((_) => File(srtFilePath));
}
