import 'dart:io';

import 'package:edit_srt_for_youtube/model/srt.dart';

Future<void> saveSrtRecords(List<SrtRecord> records, String filePath) =>
    File(filePath).writeAsString(_srtRecordsToStrings(records).join('\n'));

List<String> _srtRecordsToStrings(List<SrtRecord> records) =>
    records.expand((r) => r.toTexts()).toList();
