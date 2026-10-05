import 'package:edit_srt_for_youtube/api/youtube.dart';
import 'package:edit_srt_for_youtube/fp/either.dart';
import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class DownloadVideoScreen extends StatefulWidget {
  const DownloadVideoScreen({super.key});

  @override
  State<DownloadVideoScreen> createState() => _DownloadVideoScreenState();
}

class _DownloadVideoScreenState extends State<DownloadVideoScreen> {
  final _controller = ViewController();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Download Video Only')),
    body: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) => Column(
            children: [
              YouTubeUrlTextField(
                onChanged: (v) => _controller.dispatch(VideoUrlChanged(v)),
                enabled: _controller.model.phase != ViewPhase.fetchingVideoInfo,
              ),
              Text(_controller.model.title),
              Text(_controller.model.message),
            ],
          ),
        ),
      ),
    ),
  );
}

class YouTubeUrlTextField extends StatelessWidget {
  final void Function(String) onChanged;
  final bool enabled;

  const YouTubeUrlTextField({
    super.key,
    required this.onChanged,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(labelText: 'Youtube URL'),
      enabled: enabled,
      onChanged: onChanged,
    );
  }
}

// --- Model ---
class Model {
  final ViewPhase phase;
  final String videoUrl;
  final String title;
  final String message;

  Model({
    required this.phase,
    required this.videoUrl,
    required this.title,
    required this.message,
  });

  Model copyWith({
    ViewPhase? phase,
    String? videoUrl,
    String? title,
    String? message,
  }) => Model(
    phase: phase ?? this.phase,
    videoUrl: videoUrl ?? this.videoUrl,
    title: title ?? this.title,
    message: message ?? this.message,
  );
}

enum ViewPhase {
  waitingUrlInputed,
  fetchingVideoInfo,
  readyToDownload,
  errorOnFetchInfo,
}

// --- Events ---
sealed class ViewEvent {}

class VideoUrlChanged extends ViewEvent {
  final String url;
  VideoUrlChanged(this.url);

  @override
  String toString() => 'VideoUrlChanged';
}

class VideoInfoFetched extends ViewEvent {
  final Either<String, Video> result;
  VideoInfoFetched(this.result);

  @override
  String toString() => 'VideoInfoFetched';
}

class StartDownload extends ViewEvent {
  @override
  String toString() => 'StartDownload';
}

//--- Effect ---
typedef Effect = Future<ViewEvent> Function();

//-- Update ---
class UpdateResult {
  final Model model;
  final Effect? effect;

  UpdateResult(this.model, [this.effect]);
}

UpdateResult update(Model model, ViewEvent event) {
  switch ((model.phase, event)) {
    case (
      ViewPhase.waitingUrlInputed ||
          ViewPhase.readyToDownload ||
          ViewPhase.errorOnFetchInfo,
      VideoUrlChanged(:final url),
    ):
      final newModel = model.copyWith(
        phase: ViewPhase.fetchingVideoInfo,
        videoUrl: url,
        message: '',
        title: '',
      );
      Future<ViewEvent> effect() async =>
          VideoInfoFetched(await getVideoInfo(url));
      return UpdateResult(newModel, effect);

    case (ViewPhase.fetchingVideoInfo, VideoInfoFetched(:final result)):
      switch (result) {
        case Right(value: final video):
          final newModel = model.copyWith(
            phase: ViewPhase.readyToDownload,
            title: video.title,
          );
          return UpdateResult(newModel);

        case Left(value: _):
          final newModel = model.copyWith(
            phase: ViewPhase.errorOnFetchInfo,
            message: 'Unknown video url',
          );
          return UpdateResult(newModel);
      }
    case (_, _):
      return UpdateResult(
        model.copyWith(
          phase: ViewPhase.waitingUrlInputed,
          message: 'Unknown pattern of (${model.phase}, $event)',
        ),
      );
  }
}

// --- Controller ---
class ViewController extends ChangeNotifier {
  Model model = Model(
    phase: ViewPhase.waitingUrlInputed,
    videoUrl: '',
    title: '',
    message: '',
  );

  Future<void> dispatch(ViewEvent event) async {
    final result = update(model, event);
    model = result.model;
    notifyListeners();

    if (result.effect case final effect?) {
      final newEvent = await effect();
      dispatch(newEvent);
    }
  }
}
