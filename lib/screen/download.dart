import 'dart:io';

import 'package:edit_srt_for_youtube/extension/object.dart';
import 'package:edit_srt_for_youtube/api/youtube.dart';
import 'package:edit_srt_for_youtube/model/sentence_segment.dart';
import 'package:edit_srt_for_youtube/model/srt.dart';
import 'package:edit_srt_for_youtube/model/srv2_parser.dart';
import 'package:edit_srt_for_youtube/model/word.dart';
import 'package:edit_srt_for_youtube/others/io_util.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

class DownloadScreen extends StatefulWidget {
  const DownloadScreen({super.key});

  @override
  State<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen> {
  String url = '';
  String videoTitle = '';
  double progress = 0;
  DownloadState state = DownloadState.yet;
  String videoFileName = '';
  String srtFileName = '';
  String wordsFileName = '';
  String errorMessage = '';

  Future<void> startDownload() async {
    setState(() {
      state = DownloadState.downloading;
      progress = 0;
      videoFileName = '';
      srtFileName = '';
      wordsFileName = '';
      errorMessage = '';
    });

    final baseName = sanitizeFileName(videoTitle);

    final videoResult = await downloadVideo(
      url,
      folder: r'G:\マイドライブ\Movie',
      baseName: baseName,
      onProgress: handleProgress,
    );

    switch (videoResult) {
      case DownloadSuccess(file: final file):
        setState(() {
          progress = 0;
          videoFileName = file.path;
        });
      case DownloadFailure(message: final message):
        setState(() {
          progress = 0;
          state = DownloadState.done;
          errorMessage = message;
        });
        return;
    }

    final subtitleResult = await getSubTitleContents(
      url,
      format: 'srv2',
      folder: r'G:\マイドライブ\Movie',
      baseName: 'subtitles',
      onProgress: handleProgress,
    );

    String subtitleFileName = '';

    switch (subtitleResult) {
      case DownloadSuccess(file: final file):
        subtitleFileName = file.path;
        final srtFile = await createSrtFile(
          subtitleFileName: file.path,
          baseName: baseName,
        );
        setState(() {
          progress = 0;
          srtFileName = srtFile.path;
        });
      case DownloadFailure(message: final message):
        setState(() {
          progress = 0;
          state = DownloadState.done;
          errorMessage = message;
        });
        return;
    }

    final wordsFile = await createWordsFile(subtitleFileName, baseName);
    setState(() {
      progress = 0;
      wordsFileName = wordsFile.path;
      state = DownloadState.done;
    });
  }

  Future<File> createWordsFile(String subtitleFileName, String baseName) async {
    final words = await File(subtitleFileName).readAsString().then(parseSrv2);
    final filePath = p.join(
      p.dirname(subtitleFileName),
      '${baseName}_words.json',
    );

    return saveAsJson(words, filePath).then((_) => File(filePath));
  }

  Future<File> createSrtFile({
    required String subtitleFileName,
    required String baseName,
  }) async {
    List<SentenceSegment> splitLongSentence(segment) =>
        splitLongSegment(segment, minTotalWords: 15, minPartWords: 5);

    final contents = await File(subtitleFileName).readAsString();
    final srtLines = contents
        .pipe(parseSrv2)
        .pipe(splitBySentence)
        .expand(splitLongSentence)
        .toList()
        .pipe(segmentsToSrtRecords)
        .pipe(srtRecordsToStrings);

    final fileName = p.join(p.dirname(subtitleFileName), '$baseName.srt');
    final file = File(fileName);
    await file.writeAsString(srtLines.join('\n'));
    return file;
  }

  void handleProgress(double percentage) {
    setState(() {
      progress = percentage;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Download Video and Subtitles')),
    body: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Align(
        alignment: Alignment.center,
        child: Column(
          spacing: 8,
          children: [
            SizedBox(
              width: 600,
              child: TextField(
                decoration: InputDecoration(labelText: 'Youtube URL'),
                onChanged: handleUrlChanging,
                readOnly: state == DownloadState.downloading,
              ),
            ),

            if (videoTitle.isNotEmpty) ...[
              SizedBox(
                width: 200,
                child: Image(
                  image: getThumbnailUrl(url).pipe(NetworkImage.new),
                ),
              ),
              Text(videoTitle),
              ElevatedButton(
                onPressed: (state != DownloadState.downloading)
                    ? startDownload
                    : null,
                child: const Text('Download'),
              ),
            ] else
              const Text('No video is found'),

            if (state == DownloadState.downloading) ...[
              SizedBox(
                width: 200,
                child: LinearProgressIndicator(
                  value: progress,
                  semanticsLabel: 'Download the video',
                ),
              ),
            ],

            if (state != DownloadState.yet) ...[
              if (videoFileName.isNotEmpty) Text('Downloaded: $videoFileName'),
              if (srtFileName.isNotEmpty) Text('Downloaded: $srtFileName'),
              if (wordsFileName.isNotEmpty) Text('Downloaded: $wordsFileName'),
              if (errorMessage.isNotEmpty) Text('Error: $errorMessage'),
            ],
          ],
        ),
      ),
    ),
  );

  void handleUrlChanging(String value) {
    setState(() {
      state = DownloadState.yet;
      videoFileName = '';
      srtFileName = '';
      wordsFileName = '';
      errorMessage = '';
    });
    getVideoTitle(value)
        .then((title) {
          setState(() {
            url = value;
            videoTitle = title;
          });
        })
        .catchError((_) {
          setState(() {
            videoTitle = '';
          });
        });
  }
}

enum DownloadState { yet, downloading, done }
