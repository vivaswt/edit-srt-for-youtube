import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path_lib;

import 'package:edit_srt_for_youtube/extension/object.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

Future<String> getVideoTitle(String videoUrl) async {
  final yt = YoutubeExplode();
  try {
    final video = await yt.videos.get(videoUrl);
    return video.title;
  } catch (e) {
    throw Exception('Error getting video title: $e');
  } finally {
    yt.close();
  }
}

String _getThumbnailUrlFromId(String videoId) =>
    'https://img.youtube.com/vi/$videoId/0.jpg';

String _getVideoId(String url) => Uri.parse(url).pathSegments[0];

String getThumbnailUrl(String url) =>
    url.pipe(_getVideoId).pipe(_getThumbnailUrlFromId);

sealed class DownloadResult {}

class DownloadSuccess extends DownloadResult {
  final File file;
  DownloadSuccess(this.file);
}

class DownloadFailure extends DownloadResult {
  final int exitCode;
  final String message;
  DownloadFailure(this.exitCode, this.message);
}

Future<DownloadResult> downloadVideo(
  String videoUrl, {
  required String folder,
  required String baseName,
  void Function(double)? onProgress,
}) async {
  double? extractPercentage(String logLine) {
    final r = RegExp(
      r'^\[download\]\s+(\d+(\.\d+)?)%\s+of',
    ).firstMatch(logLine);
    if (r != null) {
      final percentage = double.parse(r.groups([1]).first!);
      return percentage / 100;
    } else {
      return null;
    }
  }

  String? extranctFileName(String logLine) {
    final r = RegExp(r'Destination: (.+)').firstMatch(logLine);
    if (r != null) {
      return r.groups([1]).first!;
    } else {
      return null;
    }
  }

  const formatOption = 'bv*[vcodec=avc1]+ba[acodec=mp4a]/b[vcodec=avc1]/best';
  final arguments = [
    '--encoding',
    'utf-8',
    '-f',
    formatOption,
    '--force-overwrites',
    '-P',
    folder,
    '-o',
    '$baseName.%(ext)s',
    videoUrl,
  ];

  final process = await Process.start('yt-dlp', arguments);
  String fileName = '';

  process.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen(
    (logLine) {
      final percentage = extractPercentage(logLine);
      if (percentage != null) {
        onProgress?.call(percentage);
      }

      final name = extranctFileName(logLine);
      if (name != null) {
        fileName = name;
      }
    },
  );

  final exitCode = await process.exitCode;
  if (exitCode != 0) {
    final message = await process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .fold('', (previousValue, element) => '$previousValue\n$element');
    return DownloadFailure(exitCode, message);
  }

  return DownloadSuccess(File(fileName));
}

Future<DownloadResult> getSubTitleContents(
  String videoUrl, {
  required String format,
  required String folder,
  required String baseName,
  void Function(double)? onProgress,
}) async {
  double? extractPercentage(String logLine) {
    final r = RegExp(
      r'^\[download\]\s+(\d+(\.\d+)?)%\s+of',
    ).firstMatch(logLine);
    if (r != null) {
      final percentage = double.parse(r.groups([1]).first!);
      return percentage / 100;
    } else {
      return null;
    }
  }

  String? extranctFileName(String logLine) {
    final r = RegExp(
      r'\[MoveFiles\] Moving file ".+?" to "(.+?)"',
    ).firstMatch(logLine);
    if (r != null) {
      return r.groups([1]).first!;
    } else {
      return null;
    }
  }

  final arguments = [
    '--encoding',
    'utf-8',
    '--force-overwrites',
    '--write-auto-subs',
    '--sub-format',
    format,
    '--skip-download',
    '-o',
    'subtitle:$baseName.%(ext)s',
    '-P',
    folder,
    videoUrl,
  ];

  final process = await Process.start('yt-dlp', arguments);
  String fileName = '';

  process.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen(
    (logLine) {
      final percentage = extractPercentage(logLine);
      if (percentage != null) {
        onProgress?.call(percentage);
      }

      final name = extranctFileName(logLine);
      if (name != null) {
        fileName = name;
      }
    },
  );

  final exitCode = await process.exitCode;
  if (exitCode != 0) {
    final message = await process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .fold('', (previousValue, element) => '$previousValue\n$element');
    return DownloadFailure(exitCode, message);
  }

  if (fileName == "") {
    throw Exception('Error downloading subtitle: cannot find file name');
  }

  if (path_lib.extension(fileName) != '.$format') {
    throw Exception('Error downloading subtitle: $format not found');
  }

  return DownloadSuccess(File(fileName));
}
