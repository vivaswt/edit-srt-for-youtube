import 'dart:async';

import 'package:edit_srt_for_youtube/api/youtube.dart';
import 'package:edit_srt_for_youtube/fp/either.dart';
import 'package:edit_srt_for_youtube/model/setting_service.dart';
import 'package:edit_srt_for_youtube/others/io_util.dart';
import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class DownloadVideoScreen extends StatefulWidget {
  const DownloadVideoScreen({super.key});

  @override
  State<DownloadVideoScreen> createState() => _DownloadVideoScreenState();
}

class _DownloadVideoScreenState extends State<DownloadVideoScreen> {
  final _controller = ViewController(
    initialModel: Model(
      phase: ViewPhase.waitingUrlInputed,
      videoUrl: '',
      thumbnailUrl: '',
      title: '',
      message: '',
      downloadProgress: 0.0,
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
    appBar: AppBar(title: const Text('Download Video Only')),
    body: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: ValueListenableBuilder<Model>(
          valueListenable: _controller.modelNotifier,
          builder: (context, model, _) => Column(
            spacing: 8,
            children: [
              YouTubeUrlTextField(
                onChanged: (v) => _controller.dispatch(VideoUrlChanged(v)),
                enabled: model.phase != ViewPhase.fetchingVideoInfo,
              ),
              YouTubeVideoInfo(
                thumbnailUrl: model.thumbnailUrl,
                title: model.title,
              ),
              DownloadButton(
                enabled: model.phase == ViewPhase.readyToDownload,
                onPressed: () => _controller.dispatch(StartDownload()),
              ),
              Text(model.message),
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
  final double downloadProgress;

  Model({
    required this.phase,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.title,
    required this.message,
    required this.downloadProgress,
  });

  Model copyWith({
    ViewPhase? phase,
    String? videoUrl,
    String? thumbnailUrl,
    String? title,
    String? message,
    double? downloadProgress,
  }) => Model(
    phase: phase ?? this.phase,
    videoUrl: videoUrl ?? this.videoUrl,
    thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
    title: title ?? this.title,
    message: message ?? this.message,
    downloadProgress: downloadProgress ?? this.downloadProgress,
  );
}

enum ViewPhase {
  waitingUrlInputed,
  fetchingVideoInfo,
  readyToDownload,
  downloading,
  // TODO: Add Download Complete Phase and etc.
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

class DownloadProgressUpdated extends ViewEvent {
  final double progress;
  DownloadProgressUpdated(this.progress);

  @override
  String toString() => 'DownloadProgressUpdated';
}

class DownloadCompleted extends ViewEvent {
  final String fileName;

  DownloadCompleted({required this.fileName});

  @override
  String toString() => 'DownloadCompleted';
}

class DownloadFailed extends ViewEvent {
  final String errorMessage;
  DownloadFailed(this.errorMessage);

  @override
  String toString() => 'DownloadFailed';
}

//--- Effect ---
typedef Effect = Stream<ViewEvent> Function();

//-- Update ---
class UpdateResult {
  final Model model;
  final Effect? effect;

  UpdateResult(this.model, [this.effect]);
}

Effect fetchVideoInfoEffect(String videoUrl) => () async* {
  final result = await getVideoInfo(videoUrl);
  yield VideoInfoFetched(result);
};

Effect downloadVideoEffect(String videoTitle, String url) => () async* {
  final baseName = sanitizeFileName(videoTitle);
  final saveFolderPath = await SettingsService().getSaveFolderPath();
  final videoResult = await downloadVideo(
    url,
    folder: saveFolderPath,
    baseName: baseName,
    onProgress: (p) async* {
      yield DownloadProgressUpdated(p);
    },
  );

  switch (videoResult) {
    case DownloadSuccess(:final file):
      yield DownloadCompleted(fileName: file.path);
    case DownloadFailure(message: final message):
      yield DownloadFailed(message);
  }
};

//--- Reducer ---
typedef Reducer = UpdateResult Function(Model, ViewEvent);

Reducer update = (model, event) {
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

      return UpdateResult(newModel, fetchVideoInfoEffect(url));

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

    case (ViewPhase.readyToDownload, StartDownload()):
      final newModel = model.copyWith(
        phase: ViewPhase.downloading,
        message: 'Downloading...',
        downloadProgress: 0.0,
      );
      return UpdateResult(
        newModel,
        downloadVideoEffect(model.title, model.videoUrl),
      );

    case (_, _):
      return UpdateResult(
        model.copyWith(
          phase: ViewPhase.waitingUrlInputed,
          message: 'Unknown pattern of (${model.phase}, $event)',
        ),
      );
  }
};

// --- Controller ---
class ViewController {
  final ValueNotifier<Model> modelNotifier;
  final Reducer reducer;
  final List<StreamSubscription> _subscriptions = [];

  ViewController({required Model initialModel, required this.reducer})
    : modelNotifier = ValueNotifier<Model>(initialModel);

  Future<void> dispatch(ViewEvent event) async {
    final result = reducer(modelNotifier.value, event);
    modelNotifier.value = result.model;

    if (result.effect case final effect?) {
      final events = effect();
      final subscription = events.listen(dispatch);
      _subscriptions.add(subscription);
      subscription.asFuture().whenComplete(() {
        _subscriptions.remove(subscription);
      });
    }
  }

  Future<void> dispose() async {
    await Future.wait(_subscriptions.map((it) => it.cancel()));
    _subscriptions.clear();
    modelNotifier.dispose();
  }
}
