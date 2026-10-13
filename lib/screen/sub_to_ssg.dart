import 'dart:io';

import 'package:edit_srt_for_youtube/core/view_controller.dart';
import 'package:edit_srt_for_youtube/fp/either.dart';
import 'package:edit_srt_for_youtube/service/setting_service.dart';
import 'package:edit_srt_for_youtube/io/srv2_parser.dart';
import 'package:edit_srt_for_youtube/service/subtitle.dart';
import 'package:file_picker/file_picker.dart' show FilePicker, FileType;
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

class SubtitleToSsgScreen extends StatefulWidget {
  const SubtitleToSsgScreen({super.key});

  @override
  State<SubtitleToSsgScreen> createState() => _SubtitleToSsgScreenState();
}

class _SubtitleToSsgScreenState extends State<SubtitleToSsgScreen> {
  final _controller = ViewController(
    initialModel: Model(
      phase: ViewPhase.waitingFileNameInputed,
      fileName: '',
      message: '',
    ),
    reducer: update,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Convert Subtitle to Sentence Segment')),
    body: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: ValueListenableBuilder<Model>(
          valueListenable: _controller.modelNotifier,
          builder: (context, model, _) => Column(
            spacing: 8,
            children: [
              FileSelection(
                fileName: model.fileName,
                isEnabled: model.phase != ViewPhase.converting,
                onFileSelected: (selectedFileName) =>
                    _controller.dispatch(FileNameChanged(selectedFileName)),
              ),

              ConvertButton(
                isEnabled: model.phase == ViewPhase.readyToConvert,
                onPressed: () => _controller.dispatch(StartConversion()),
              ),

              Text(model.message),
            ],
          ),
        ),
      ),
    ),
  );
}

// --- Widget ---
class FileSelection extends StatelessWidget {
  final String fileName;
  final bool isEnabled;
  final void Function(String) onFileSelected;

  const FileSelection({
    super.key,
    required this.fileName,
    required this.isEnabled,
    required this.onFileSelected,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'File Name',
            border: OutlineInputBorder(),
          ),
          child: Text(
            fileName.isEmpty ? 'SRV2 file is not specified.' : fileName,
          ),
        ),
      ),

      IconButton(
        onPressed: isEnabled ? _selectFile : null,
        icon: Icon(Icons.file_open),
      ),
    ],
  );

  Future<void> _selectFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['srv2'],
      lockParentWindow: true,
    );

    if (result != null) {
      onFileSelected(result.files.single.path!);
    }
  }
}

class ConvertButton extends StatelessWidget {
  final bool isEnabled;
  final void Function() onPressed;

  const ConvertButton({
    super.key,
    required this.isEnabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => ElevatedButton(
    onPressed: isEnabled ? onPressed : null,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [Icon(Icons.start), const Text('Convert')],
    ),
  );
}

// --- Model ---
enum ViewPhase { waitingFileNameInputed, readyToConvert, converting }

class Model {
  final ViewPhase phase;
  final String fileName;
  final String message;

  Model({required this.phase, required this.fileName, required this.message});

  Model copyWith({ViewPhase? phase, String? fileName, String? message}) =>
      Model(
        phase: phase ?? this.phase,
        fileName: fileName ?? this.fileName,
        message: message ?? this.message,
      );
}

// --- Events ---
sealed class ViewEvent {}

class FileNameChanged extends ViewEvent {
  final String fileName;
  FileNameChanged(this.fileName);

  @override
  String toString() => 'FileNameChanged';
}

class StartConversion extends ViewEvent {
  @override
  String toString() => 'StartConversion';
}

class ConversionCompleted extends ViewEvent {
  final Either<String, String> result;
  ConversionCompleted(this.result);

  @override
  String toString() => 'ConversionCompleted';
}

//--- Effect ---
FutureEffect<ViewEvent> convertSubToSsgEffect(String subtitleFilePath) =>
    FutureEffect(
      () => Future.delayed(
        Duration(seconds: 1),
        () => convertSubToSsg(subtitleFilePath),
      ),
    );

Future<ConversionCompleted> convertSubToSsg(String subtitleFilePath) async {
  final saveFolderPath = await SettingsService().getSaveFolderPath();
  final ssgFilePath = p.join(
    saveFolderPath,
    '${p.basenameWithoutExtension(subtitleFilePath)}.ssg',
  );
  await createSentenceSegmentFileFromSrv2(subtitleFilePath, ssgFilePath);
  return ConversionCompleted(Right(ssgFilePath));
}

//--- Reducer ---
Reducer<Model, ViewEvent> update = (model, event) {
  switch ((model.phase, event)) {
    case (
      ViewPhase.waitingFileNameInputed,
      FileNameChanged(fileName: final fileName),
    ):
      return UpdateResult(
        model.copyWith(
          fileName: fileName,
          phase: fileName.isEmpty
              ? ViewPhase.waitingFileNameInputed
              : ViewPhase.readyToConvert,
        ),
      );

    case (ViewPhase.readyToConvert, StartConversion()):
      return UpdateResult(
        model.copyWith(phase: ViewPhase.converting, message: 'Converting...'),
        convertSubToSsgEffect(model.fileName),
      );

    case (ViewPhase.converting, ConversionCompleted(result: final result)):
      final message = switch (result) {
        Right(value: final fileName) => 'Conversion is completed: $fileName',
        Left(value: final message) => 'Conversion is failed: $message',
      };
      return UpdateResult(
        model.copyWith(phase: ViewPhase.readyToConvert, message: message),
      );

    default:
      return UpdateResult(
        model.copyWith(
          message: 'unknown (phase, event) = (${model.phase}, $event)',
        ),
      );
  }
};
