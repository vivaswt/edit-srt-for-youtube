import 'package:edit_srt_for_youtube/api/youtube.dart' as yt;
import 'package:edit_srt_for_youtube/core/view_controller.dart';
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
  static const String downloadTaskId = 'download_video';

  final _controller = ViewController<Model, ViewEvent>(
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
                enabled:
                    model.phase != ViewPhase.fetchingVideoInfo &&
                    model.phase != ViewPhase.downloading,
              ),

              YouTubeVideoInfo(
                thumbnailUrl: model.thumbnailUrl,
                title: model.title,
              ),

              if (model.phase != ViewPhase.downloading)
                DownloadButton(
                  enabled: model.phase == ViewPhase.readyToDownload,
                  onPressed: () => _controller.dispatch(
                    StartDownload(taskId: downloadTaskId),
                  ),
                )
              else
                DownloadCancelButton(
                  onPressed: () => _controller.dispatch(
                    CancelDownload(taskId: downloadTaskId),
                  ),
                ),

              if (model.phase == ViewPhase.downloading)
                LinearProgressIndicator(value: model.downloadProgress),

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

class DownloadCancelButton extends StatelessWidget {
  final void Function() onPressed;

  const DownloadCancelButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) => ElevatedButton(
    onPressed: onPressed,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [Icon(Icons.cancel), const Text('Cancel')],
    ),
  );
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
  final String taskId;
  StartDownload({required this.taskId});

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

class CancelDownload extends ViewEvent {
  final String taskId;
  CancelDownload({required this.taskId});

  @override
  String toString() => 'CancelDownload';
}

//--- Effect ---
FutureEffect<ViewEvent> fetchVideoInfoEffect(String videoUrl) =>
    FutureEffect(() => yt.getVideoInfo(videoUrl).then(VideoInfoFetched.new));

StreamEffect<ViewEvent> downloadVideoEffect(
  String videoTitle,
  String url,
  String taskId,
) => StreamEffect(() async* {
  final baseName = sanitizeFileName(videoTitle);
  final saveFolderPath = await SettingsService().getSaveFolderPath();
  final events = yt.downloadVideo(
    url,
    folder: saveFolderPath,
    baseName: baseName,
  );

  yield* events.map(
    (event) => switch (event) {
      yt.DownloadSuccess(:final fileName) => DownloadCompleted(
        fileName: fileName,
      ),
      yt.DownloadFailure(:final message) => DownloadFailed(message),
      yt.DownloadProgressUpdated(:final progress) => DownloadProgressUpdated(
        progress,
      ),
    },
  );
}, taskId: taskId);

//--- Reducer ---
Reducer<Model, ViewEvent> update = (model, event) {
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

    case (ViewPhase.readyToDownload, StartDownload(:final taskId)):
      final newModel = model.copyWith(
        phase: ViewPhase.downloading,
        message: 'Downloading...',
        downloadProgress: 0.0,
      );
      return UpdateResult(
        newModel,
        downloadVideoEffect(model.title, model.videoUrl, taskId),
      );

    case (ViewPhase.downloading, DownloadProgressUpdated(:final progress)):
      final newModel = model.copyWith(downloadProgress: progress);
      return UpdateResult(newModel);

    case (ViewPhase.downloading, DownloadCompleted(:final fileName)):
      final newModel = model.copyWith(
        phase: ViewPhase.readyToDownload,
        downloadProgress: 0.0,
        message: 'complete downloading. $fileName',
      );
      return UpdateResult(newModel);

    case (ViewPhase.downloading, DownloadFailed(:final errorMessage)):
      final newModel = model.copyWith(
        phase: ViewPhase.readyToDownload,
        downloadProgress: 0.0,
        message: 'failed downloading. $errorMessage',
      );
      return UpdateResult(newModel);

    case (ViewPhase.downloading, CancelDownload(:final taskId)):
      final newModel = model.copyWith(
        phase: ViewPhase.readyToDownload,
        downloadProgress: 0.0,
        message: 'download canceled.',
      );
      return UpdateResult(newModel, CancelEffect(taskId: taskId));

    case (_, _):
      return UpdateResult(
        model.copyWith(
          phase: ViewPhase.waitingUrlInputed,
          message: 'Unknown pattern of (${model.phase}, $event)',
        ),
      );
  }
};
