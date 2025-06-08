import 'package:flutter/material.dart';
import 'package:custom_preload_videos/interface/controller_interface.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class MyChewieController extends CustomVideoController {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  final String _url;
  final bool autoPlay;
  final bool showControls;

  MyChewieController(
    this._url, {
    this.autoPlay = false,
    this.showControls = true,
  }) {
    _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(_url));
  }

  // Expose the controllers for UI access
  VideoPlayerController get videoPlayerController => _videoPlayerController;
  ChewieController? get chewieController => _chewieController;

  @override
  Future<void> initialize() async {
    await _videoPlayerController.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: autoPlay,
      showControls: showControls,
      aspectRatio: _videoPlayerController.value.aspectRatio,
      // Add some additional options for better control
      looping: false,
      errorBuilder: (context, errorMessage) {
        return Center(
          child: Text(
            'Error: $errorMessage',
            style: const TextStyle(color: Colors.white),
          ),
        );
      },
    );
  }

  @override
  Future<void> play() async {
    await _videoPlayerController.play();
  }

  @override
  Future<void> pause() async {
    await _videoPlayerController.pause();
  }

  @override
  Future<void> dispose() async {
    _chewieController?.dispose();
    await _videoPlayerController.dispose();
  }

  @override
  bool get isPlaying => _videoPlayerController.value.isPlaying;

  @override
  bool get isInitialized => _videoPlayerController.value.isInitialized;

  @override
  String get dataSource => _url;

  Duration get position => _videoPlayerController.value.position;
  Duration get duration => _videoPlayerController.value.duration;

  // Additional helper methods
  bool get hasError => _videoPlayerController.value.hasError;
  String? get errorDescription => _videoPlayerController.value.errorDescription;
}
