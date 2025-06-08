/// Abstract base class for video controllers
/// Allows users to implement their own video controller logic
abstract class CustomVideoController {
  /// Initialize the video controller
  Future<void> initialize();

  /// Play the video
  Future<void> play();

  /// Pause the video
  Future<void> pause();

  /// Dispose the video controller and free resources
  Future<void> dispose();

  /// Check if the video is currently playing
  bool get isPlaying;

  /// Check if the video controller is initialized
  bool get isInitialized;

  /// Get the video URL or source identifier
  String get dataSource;

  /// Toggle between play and pause
  Future<void> togglePlayPause() async {
    if (isPlaying) {
      await pause();
    } else {
      await play();
    }
  }
}
