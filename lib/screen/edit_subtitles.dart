import 'dart:io';

import 'package:edit_srt_for_youtube/extension/fp_list.dart';
import 'package:edit_srt_for_youtube/extension/object.dart';
import 'package:edit_srt_for_youtube/extension/widget_wrap.dart';
import 'package:edit_srt_for_youtube/model/sentence_segment.dart';
import 'package:edit_srt_for_youtube/model/srt.dart';
import 'package:edit_srt_for_youtube/model/word.dart' as wd;
import 'package:edit_srt_for_youtube/fp/either.dart';
import 'package:edit_srt_for_youtube/others/srt_parser.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

class EditFirstScreen extends StatefulWidget {
  const EditFirstScreen({super.key});

  @override
  State<EditFirstScreen> createState() => _EditFirstScreenState();
}

class _EditFirstScreenState extends State<EditFirstScreen> {
  String? fileName;
  List<SentenceSegment> sentenceSegments = [];
  bool isSelectingFile = false;
  bool isExporting = false;
  String errorMesage = '';

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Edit Subtitles')),
    body: _bodyContent(context)
        .wrapWithColumn(spacing: 8)
        .wrapWithAlign(alignment: Alignment.center)
        .wrapWithPadding(padding: const EdgeInsets.all(8.0)),
  );

  Widget _topBodyContent(BuildContext context) => [
    Text(fileName ?? 'file is not specified')
        .wrapWithInputDecorator(
          decoration: InputDecoration(
            labelText: 'File Name',
            border: OutlineInputBorder(),
          ),
        )
        .wrapWithExpanded(),
    IconButton(
      onPressed: isSelectingFile || isExporting ? null : _selectFile,
      icon: Icon(Icons.file_open),
    ),
  ].wrapWithRow(spacing: 8);

  Widget _rightBodyContent(BuildContext context) => FilledButton(
    onPressed: isExporting || isSelectingFile ? null : _export,
    child: [Icon(Icons.download), const Text('Export as SRT')].wrapWithRow(),
  ).wrapWithContainer(width: 160, alignment: Alignment.topCenter);

  List<Widget> _bodyContent(BuildContext context) => [
    _topBodyContent(context),
    if (errorMesage.isNotEmpty)
      Text(
        errorMesage,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    sentenceSegments.isNotEmpty
        ? [
            SentenceSegmentsView(
              segments: sentenceSegments,
              splitSegment: splitSegment,
              mergeSegments: mergeSegments,
            ).wrapWithExpanded(),
            _rightBodyContent(context),
          ].wrapWithRow(spacing: 8).wrapWithExpanded()
        : const Text('No data is found.'),
  ];

  Future<void> _selectFile() async {
    setState(() {
      isSelectingFile = true;
      errorMesage = '';
    });

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['ssg'],
      lockParentWindow: true,
    );

    if (result == null) {
      setState(() {
        isSelectingFile = false;
      });
      return;
    }

    setState(() {
      fileName = result.files.single.path;
    });

    await _load();
  }

  Future<void> _load() async {
    try {
      final result = await loadFromJson(fileName!);
      setState(() {
        sentenceSegments = result;
        isSelectingFile = false;
      });
    } catch (e) {
      setState(() {
        sentenceSegments = [];
        errorMesage = 'Fail to load the file : ${e.toString()}';
        isSelectingFile = false;
      });
    }
  }

  void splitSegment(int segmentIndex, int wordIndex) {
    List<SentenceSegment> split(SentenceSegment segment, int wordIndex) => [
      SentenceSegment(segment.words.sublist(0, wordIndex)),
      SentenceSegment(segment.words.sublist(wordIndex)),
    ];

    setState(() {
      sentenceSegments = sentenceSegments.mapRange(
        start: segmentIndex,
        end: segmentIndex + 1,
        convert: (segments) => split(segments.first, wordIndex),
      );
    });
  }

  void mergeSegments(int segmentIndex) {
    List<SentenceSegment> merge(List<SentenceSegment> segments) => [
      segments.expand((sg) => sg.words).toList().pipe(SentenceSegment.new),
    ];

    setState(() {
      sentenceSegments = sentenceSegments.mapRange(
        start: segmentIndex - 1,
        end: segmentIndex + 1,
        convert: merge,
      );
    });
  }

  Future<void> _export() async {
    setState(() {
      isExporting = true;
      errorMesage = '';
    });

    final contents = sentenceSegments
        .pipe(segmentsToSrtRecords)
        .pipe(srtRecordsToStrings)
        .join('\n');

    try {
      await File(_srtFileName(fileName!)).writeAsString(contents);
      setState(() {
        isExporting = false;
      });
    } catch (e) {
      setState(() {
        errorMesage = 'Fail to export the file : ${e.toString()}';
        isExporting = false;
      });
    }
  }

  String _srtFileName(String ssgFileName) {
    final dirPath = p.dirname(ssgFileName);
    final baseName = p.basenameWithoutExtension(ssgFileName);
    return p.join(dirPath, '$baseName.srt');
  }
}

class SentenceSegmentsView extends StatelessWidget {
  final List<SentenceSegment> segments;
  final void Function(int, int) splitSegment;
  final void Function(int) mergeSegments;
  const SentenceSegmentsView({
    super.key,
    required this.segments,
    required this.splitSegment,
    required this.mergeSegments,
  });

  void _manupulateSegment(int segmentIndex, int wordIndex) {
    if (wordIndex == 0) {
      return segmentIndex > 0 ? mergeSegments(segmentIndex) : null;
    }
    return splitSegment(segmentIndex, wordIndex);
  }

  @override
  Widget build(BuildContext context) => ListView.builder(
    itemCount: segments.length,
    itemBuilder: (context, index) {
      final segment = segments[index];
      final words = segment.words
          .asMap()
          .entries
          .map((entry) {
            final void Function()? manipulate = (index == 0 && entry.key == 0)
                ? null
                : () => _manupulateSegment(index, entry.key);

            return Text(
              entry.value.text,
              style: Theme.of(context).textTheme.bodyLarge,
            ).wrapWithInkWell(onTap: manipulate);
          })
          .toList()
          .wrapWithWrap(spacing: 4);

      // return words
      //     .wrapWithPadding(padding: const EdgeInsets.all(8.0))
      //     .wrapWithCard();

      return ListTile(
        leading: Text('#${index + 1}'),
        title: words,
      ).wrapWithCard();
    },
  );
}

class StateMachine {
  ScreenState state = InitalState();

  StateMachine();

  void dispatch(Action action) {
    switch (action) {
      case SetFileName(fileName: _):
        state = LoadingState();
      case TransitNextScreen():
        state = InitalState();
    }
  }
}

Future<Either<String, List<SentenceSegment>>> loadSentenceSegments(
  String srtFileName,
) async {
  final srtParseResult = await File(srtFileName).readAsString().then(parseSrt);
  final wordsInfoFileName = _getWordInfoFilePath(srtFileName);
  if (!File(wordsInfoFileName).existsSync()) {
    return Left('The words info file is not found.');
  }

  final wordsInfo = await wd.loadFromJson(wordsInfoFileName);
  final result = srtParseResult.bind(
    (srtRecords) => srtRecordsToSegments(srtRecords, wordsInfo),
  );

  return result;
}

String _getWordInfoFilePath(String srtFileName) {
  final dirPath = p.dirname(srtFileName);
  final baseName = p.basenameWithoutExtension(srtFileName) + '_words';
  return p.join(dirPath, '$baseName.json');
}

sealed class ScreenState {}

class InitalState extends ScreenState {}

class SelectingFileState extends ScreenState {}

class LoadingFileState extends ScreenState {}

class LoadingState extends ScreenState {}

class ErrorState extends ScreenState {}

sealed class Action {}

class SetFileName extends Action {
  final String fileName;

  SetFileName(this.fileName);
}

class TransitNextScreen extends Action {}
