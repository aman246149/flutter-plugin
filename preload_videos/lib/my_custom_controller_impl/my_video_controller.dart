import 'package:custom_preload_videos/interface/controller_interface.dart' show CustomVideoController;
import 'package:video_player/video_player.dart';

/// Default implementation using VideoPlayerController
class DefaultVideoController extends CustomVideoController {
  late VideoPlayerController _controller;
  final String _url;

  DefaultVideoController(this._url) {
    _controller = VideoPlayerController.networkUrl(Uri.parse(_url));
  }

  /// Get the underlying VideoPlayerController (for backward compatibility)
  VideoPlayerController get videoPlayerController => _controller;

  @override
  Future<void> initialize() async {
    await _controller.initialize();
  }

  @override
  Future<void> play() async {
    await _controller.play();
  }

  @override
  Future<void> pause() async {
    await _controller.pause();
  }

  @override
  Future<void> dispose() async {
    await _controller.dispose();
  }

  @override
  bool get isPlaying => _controller.value.isPlaying;

  @override
  bool get isInitialized => _controller.value.isInitialized;

  @override
  String get dataSource => _url;
}
