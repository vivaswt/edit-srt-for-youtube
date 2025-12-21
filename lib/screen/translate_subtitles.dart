import 'dart:async';
import 'dart:io';

import 'package:edit_srt_for_youtube/api/gemini_translate.dart';
import 'package:edit_srt_for_youtube/extension/fp_iterable.dart';
import 'package:edit_srt_for_youtube/extension/widget_wrap.dart';
import 'package:edit_srt_for_youtube/model/srt.dart';
import 'package:edit_srt_for_youtube/fp/either.dart';
import 'package:edit_srt_for_youtube/others/srt_parser.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

enum RunState { yet, running, done }

class TranslateScreen extends StatefulWidget {
  const TranslateScreen({super.key});

  @override
  State<TranslateScreen> createState() => _TranslateScreenState();
}

class _TranslateScreenState extends State<TranslateScreen> {
  final ValueNotifier<String?> _fileName = ValueNotifier(null);
  final ValueNotifier<RunState> _runState = ValueNotifier(RunState.yet);
  final ListenableStopwatch _stopwatch = ListenableStopwatch();
  final ValueNotifier<String> _message = ValueNotifier('');

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Translate Subtitles')),
    body:
        [
              FileSelection(fileName: _fileName, runState: _runState),
              StartButton(
                runState: _runState,
                fileName: _fileName,
                translate: _translate,
              ),
              ProcessingTimerDisplay(stopwatch: _stopwatch),
              MessageViewer(message: _message),
            ]
            .wrapWithColumn(spacing: 8)
            .wrapWithAlign(alignment: Alignment.topCenter)
            .wrapWithPadding(padding: EdgeInsets.all(8)),
  );

  @override
  void dispose() {
    _fileName.dispose();
    _runState.dispose();
    _stopwatch.dispose();
    super.dispose();
  }

  Future<void> _translate() async {
    _runState.value = RunState.running;
    _message.value = '';
    _stopwatch.reset();
    _stopwatch.start();

    final Either<String, void> result = await Either.asyncDoNotation(($) async {
      final srtText = await File(_fileName.value!).readAsString();
      final srtRecords = $(parseSrt(srtText));
      final srtLinesJp = await translateSrt(
        srtRecords,
        Platform.environment['GEMINI_API_KEY']!,
      );
      await File(
        _srtJpFileName(_fileName.value!),
      ).writeAsString(srtLinesJp.join('\n'));

      final srtRecordsJp = $(parseSrt(srtLinesJp.join('\n')));
      $(compareSrts(srtRecords, srtRecordsJp));

      return;
    });

    _message.value = switch (result) {
      Right(value: _) => 'Done',
      Left(value: final message) => message,
    };

    _runState.value = RunState.done;
    _stopwatch.stop();
  }

  String _srtJpFileName(String srtFileName) {
    final dirPath = p.dirname(srtFileName);
    final baseName = p.basenameWithoutExtension(srtFileName);
    return p.join(dirPath, '${baseName}_JP.srt');
  }

  Either<String, void> compareSrts(
    List<SrtRecord> srts,
    List<SrtRecord> srtsJp,
  ) {
    if (srts.length != srtsJp.length) return Left('The lengths are not same.');

    final idMatch = srts
        .zip(srtsJp)
        .where((st) => st.$1.id != st.$2.id)
        .toList();
    if (idMatch.isNotEmpty) {
      final unmatch = idMatch.first;
      return Left(
        'The IDs are not same (${unmatch.$1.id} / ${unmatch.$2.id}).',
      );
    }

    final timeMatch = srts
        .zip(srtsJp)
        .where((st) => st.$1.start != st.$2.start || st.$1.end != st.$2.end)
        .toList();
    if (timeMatch.isNotEmpty) {
      final unmatch = timeMatch.first;
      return Left('The times are not same at the record id ${unmatch.$1.id}.');
    }

    return Either.of(null);
  }
}

class MessageViewer extends StatelessWidget {
  final ValueNotifier<String> _message;
  const MessageViewer({super.key, required ValueNotifier<String> message})
    : _message = message;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: _message,
    builder: (context, value, _) => Text(value),
  );
}

class FileSelection extends StatefulWidget {
  final ValueNotifier<String?> _fileName;
  final ValueNotifier<RunState> _runState;

  const FileSelection({
    super.key,
    required ValueNotifier<String?> fileName,
    required ValueNotifier<RunState> runState,
  }) : _fileName = fileName,
       _runState = runState;

  @override
  State<FileSelection> createState() => _FileSelectionState();
}

class _FileSelectionState extends State<FileSelection> {
  final ValueNotifier<bool> _isSelecting = ValueNotifier(false);
  late final Listenable _buttonStateListenable;

  @override
  void initState() {
    super.initState();
    _buttonStateListenable = Listenable.merge([_isSelecting, widget._runState]);
  }

  @override
  void dispose() {
    _isSelecting.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: widget._fileName,
    builder: (context, value, _) => [
      Text(value ?? 'file is not specified')
          .wrapWithInputDecorator(
            decoration: InputDecoration(
              labelText: 'File Name',
              border: OutlineInputBorder(),
            ),
          )
          .wrapWithExpanded(),

      ListenableBuilder(
        listenable: _buttonStateListenable,
        builder: (context, child) => IconButton(
          onPressed:
              (_isSelecting.value || widget._runState.value == RunState.running)
              ? null
              : _selectFile,
          icon: Icon(Icons.file_open),
        ),
      ),
    ].wrapWithRow(spacing: 4),
  );

  Future<void> _selectFile() async {
    _isSelecting.value = true;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['srt'],
      lockParentWindow: true,
    );

    if (result == null) {
      _isSelecting.value = false;
      return;
    }

    _isSelecting.value = false;
    widget._fileName.value = result.files.single.path!;
  }
}

class StartButton extends StatelessWidget {
  final ValueNotifier<RunState> _runState;
  final ValueNotifier<String?> _fileName;
  final Listenable _buttonStateListenable;
  final Future<void> Function() _translate;

  StartButton({
    super.key,
    required ValueNotifier<RunState> runState,
    required ValueNotifier<String?> fileName,
    required Future<void> Function() translate,
  }) : _runState = runState,
       _fileName = fileName,
       _translate = translate,
       _buttonStateListenable = Listenable.merge([runState, fileName]);

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _buttonStateListenable,
    builder: (context, child) => FilledButton(
      onPressed: _runState.value == RunState.running || _fileName.value == null
          ? null
          : _translate,
      child: [
        Icon(Icons.translate),
        const Text('Translate to Japanese'),
      ].wrapWithRow(spacing: 4).wrapWithSizedBox(width: 160),
    ),
  );
}

class ProcessingTimerDisplay extends StatefulWidget {
  final ListenableStopwatch _stopwatch;

  const ProcessingTimerDisplay({
    super.key,
    required ListenableStopwatch stopwatch,
  }) : _stopwatch = stopwatch;

  @override
  State<ProcessingTimerDisplay> createState() => _ProcessingTimerDisplayState();
}

class _ProcessingTimerDisplayState extends State<ProcessingTimerDisplay> {
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget._stopwatch,
    builder: (context, child) => widget._stopwatch.isRunning
        ? <Widget>[
            CircularProgressIndicator(),
            Text('${widget._stopwatch.elapsedTime}'),
          ].wrapWithRow(spacing: 8)
        : <Widget>[
            Icon(Icons.done),
            Text('${widget._stopwatch.elapsedTime}'),
          ].wrapWithRow(),
  ).wrapWithSizedBox(width: 180);
}

class ListenableStopwatch extends ChangeNotifier {
  final Stopwatch _stopwatch = Stopwatch();
  final Duration interval;
  Timer? _timer;

  ListenableStopwatch({this.interval = const Duration(milliseconds: 10)});

  int get elapsedTime => _stopwatch.elapsedMilliseconds ~/ 1000;
  bool get isRunning => _stopwatch.isRunning;

  void start() {
    if (_stopwatch.isRunning) return;
    _stopwatch.start();
    notifyListeners();
    _timer = Timer.periodic(interval, (_) => notifyListeners());
  }

  void stop() {
    _timer?.cancel();
    _stopwatch.stop();
    notifyListeners();
  }

  void reset() {
    _stopwatch.reset();
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
