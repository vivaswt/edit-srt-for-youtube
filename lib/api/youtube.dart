import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:edit_srt_for_youtube/extension/stream.dart';
import 'package:edit_srt_for_youtube/fp/either.dart';
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

Future<Either<String, Video>> getVideoInfo(String videoUrl) async {
  final yt = YoutubeExplode();
  try {
    final video = await yt.videos.get(videoUrl);
    return Right(video);
  } catch (e) {
    return Left(e.toString());
  } finally {
    yt.close();
  }
}

String _getThumbnailUrlFromId(String videoId) =>
    'https://img.youtube.com/vi/$videoId/0.jpg';

String _getVideoId(String url) => Uri.parse(url).pathSegments[0];

String getThumbnailUrl(String url) =>
    url.pipe(_getVideoId).pipe(_getThumbnailUrlFromId);

sealed class DownloadEvent {}

class DownloadProgressUpdated extends DownloadEvent {
  final double progress;
  DownloadProgressUpdated(this.progress);
}

class DownloadSuccess extends DownloadEvent {
  final String fileName;
  DownloadSuccess(this.fileName);
}

class DownloadFailure extends DownloadEvent {
  final int exitCode;
  final String message;
  DownloadFailure(this.exitCode, this.message);
}

Stream<DownloadEvent> downloadVideo(
  String videoUrl, {
  required String folder,
  required String baseName,
}) async* {
  final process = await startDownloadVideoProcess(
    videoUrl,
    folder: folder,
    baseName: baseName,
  );

  yield* runDownloadLogic(
    process,
    extractPercentage: extractPercentageForVideo,
    extractFileName: extractFileNameForVideo,
  ).onDispose(process.kill);
}

Stream<DownloadEvent> runDownloadLogic(
  Process process, {
  required double? Function(String) extractPercentage,
  required String? Function(String) extractFileName,
}) async* {
  final errorMessageFuture = toErrorMessage(process.stderr);

  final logLines = process.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter());

  String fileName = '';

  await for (final logLine in logLines) {
    final percentage = extractPercentage(logLine);
    if (percentage != null) {
      yield DownloadProgressUpdated(percentage);
    }

    final name = extractFileName(logLine);
    if (name != null) {
      fileName = name;
    }
  }

  final exitCode = await process.exitCode;
  if (exitCode != 0) {
    final errorMessage = await errorMessageFuture;
    yield DownloadFailure(exitCode, errorMessage);
    return;
  }

  if (fileName.isNotEmpty) {
    yield DownloadSuccess(fileName);
  } else {
    yield DownloadFailure(0, 'download file name is not found.');
  }
}

Future<String> toErrorMessage(Stream<List<int>> stderr) => stderr
    .transform(utf8.decoder)
    .transform(const LineSplitter())
    .fold('', (previousValue, element) => '$previousValue\n$element');

Future<Process> startDownloadVideoProcess(
  String videoUrl, {
  required String folder,
  required String baseName,
}) {
  const formatOption = 'bv*[vcodec^=avc1]+ba[acodec^=mp4a]';
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

  return Process.start('yt-dlp', arguments);
}

double? extractPercentageForVideo(String logLine) {
  final r = RegExp(r'^\[download\]\s+(\d+(\.\d+)?)%\s+of').firstMatch(logLine);
  if (r != null) {
    final percentage = double.parse(r.groups([1]).first!);
    return percentage / 100;
  } else {
    return null;
  }
}

String? extractFileNameForVideo(String logLine) {
  final r = RegExp(r'Destination: (.+)').firstMatch(logLine);
  if (r != null) {
    return r.groups([1]).first!;
  } else {
    return null;
  }
}

Stream<DownloadEvent> downloadSubTitle(
  String videoUrl, {
  required String format,
  required String folder,
  required String baseName,
}) async* {
  final process = await startDownloadSubTitleProcess(
    videoUrl,
    format: format,
    folder: folder,
    baseName: baseName,
  );

  yield* runDownloadLogic(
    process,
    extractPercentage: extractPercentageForSubTitle,
    extractFileName: extractFileNameForSubTitle,
  ).map(verifyFormat(format)).onDispose(process.kill);
}

DownloadEvent Function(DownloadEvent event) verifyFormat(String format) =>
    (event) => switch (event) {
      DownloadSuccess(:final fileName)
          when path_lib.extension(fileName) != '.$format' =>
        DownloadFailure(0, 'Error downloading subtitle: $format not found'),
      _ => event,
    };

Future<Process> startDownloadSubTitleProcess(
  String videoUrl, {
  required String format,
  required String folder,
  required String baseName,
}) {
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

  return Process.start('yt-dlp', arguments);
}

double? extractPercentageForSubTitle(String logLine) {
  final r = RegExp(r'^\[download\]\s+(\d+(\.\d+)?)%\s+of').firstMatch(logLine);
  if (r != null) {
    final percentage = double.parse(r.groups([1]).first!);
    return percentage / 100;
  } else {
    return null;
  }
}

String? extractFileNameForSubTitle(String logLine) {
  final r = RegExp(
    r'\[MoveFiles\] Moving file ".+?" to "(.+?)"',
  ).firstMatch(logLine);
  if (r != null) {
    return r.groups([1]).first!;
  } else {
    return null;
  }
}
