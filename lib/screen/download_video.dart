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
            spacing: 8,
            children: [
              YouTubeUrlTextField(
                onChanged: (v) => _controller.dispatch(VideoUrlChanged(v)),
                enabled: _controller.model.phase != ViewPhase.fetchingVideoInfo,
              ),
              YouTubeVideoInfo(
                thumbnailUrl: _controller.model.thumbnailUrl,
                title: _controller.model.title,
              ),
              DownloadButton(
                enabled: _controller.model.phase == ViewPhase.readyToDownload,
                onPressed: () => _controller.dispatch(StartDownload()),
              ),
              Text(_controller.model.message),
            ],
          ),
        ),
      ),
    ),
  );
}

// --- Widgets ---
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

class YouTubeVideoInfo extends StatelessWidget {
  final String title;
  final String thumbnailUrl;

  const YouTubeVideoInfo({
    super.key,
    required this.title,
    required this.thumbnailUrl,
  });

  @override
  Widget build(BuildContext context) => Row(
    spacing: 8,
    children: [
      YouTubeThumbnail(url: thumbnailUrl),
      Text(title),
    ],
  );
}

class YouTubeThumbnail extends StatelessWidget {
  final String url;

  const YouTubeThumbnail({super.key, required this.url});

  @override
  Widget build(BuildContext context) => url.isNotEmpty
      ? SizedBox(width: 200, child: Image(image: NetworkImage(url)))
      : SizedBox.shrink();
}

class DownloadButton extends StatelessWidget {
  const DownloadButton({
    super.key,
    required this.enabled,
    required this.onPressed,
  });

  final bool enabled;
  final void Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: enabled ? onPressed : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [Icon(Icons.download), const Text('Download')],
      ),
    );
  }
}

// --- Model ---
class Model {
  final ViewPhase phase;
  final String videoUrl;
  final String thumbnailUrl;
  final String title;
  final String message;

  Model({
    required this.phase,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.title,
    required this.message,
  });

  Model copyWith({
    ViewPhase? phase,
    String? videoUrl,
    String? thumbnailUrl,
    String? title,
    String? message,
  }) => Model(
    phase: phase ?? this.phase,
    videoUrl: videoUrl ?? this.videoUrl,
    thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
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
            thumbnailUrl: video.thumbnails.mediumResUrl,
          );
          return UpdateResult(newModel);

        case Left(value: _):
          final newModel = model.copyWith(
            phase: ViewPhase.errorOnFetchInfo,
            title: '',
            thumbnailUrl: '',
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
    thumbnailUrl: '',
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
