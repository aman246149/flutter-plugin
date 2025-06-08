import 'package:flutter/foundation.dart';
import 'package:preload_videos/interface/controller_interface.dart';
import 'package:preload_videos/my_custom_controller_impl/my_video_controller.dart';

/// Factory function type for creating custom video controllers
typedef CustomVideoControllerFactory =
    CustomVideoController Function(String url);

class PreloadVideos {
  late int _preloadBackward;
  late int _preloadForward;
  late int _windowSize;
  late final List<CustomVideoController> _preloadWindow = [];
  late int _end;
  int _prevIndex = 0;
  int _start = 0;
  int _currentPlayingIndex = -1; // Track currently playing video
  final bool _autoplayFirstVideo;
  bool _firstVideoPlayed = false;

  List<String> _videoUrls = [];

  // Pagination constants and configuration
  static const int _DEFAULT_PAGINATION_THRESHOLD = 5;
  int _paginationThreshold = _DEFAULT_PAGINATION_THRESHOLD;

  // Custom controller factory
  late CustomVideoControllerFactory _controllerFactory;

  /// Callback after controller is initialized
  final void Function(CustomVideoController controller)?
  onControllerInitialized;

  /// Callback when video play state changes
  final void Function()? onPlayStateChanged;

  /// Callback for pagination when threshold is reached
  final Future<List<String>> Function()? onPaginationNeeded;

  PreloadVideos({
    int? preloadBackward,
    int? preloadForward,
    int? windowSize,
    required List<String> videoUrls,
    this.onControllerInitialized,
    this.onPlayStateChanged,
    this.onPaginationNeeded,
    int? paginationThreshold,
    CustomVideoControllerFactory? controllerFactory,
    bool autoplayFirstVideo = false,
  }) : _autoplayFirstVideo = autoplayFirstVideo {
    _videoUrls = videoUrls;
    _paginationThreshold = paginationThreshold ?? _DEFAULT_PAGINATION_THRESHOLD;
    _controllerFactory =
        controllerFactory ?? ((url) => DefaultVideoController(url));

    _preloadBackward = preloadBackward ?? 3;
    _preloadForward = preloadForward ?? 3;
    _windowSize = windowSize ?? 8;

    assert(
      _preloadBackward <= _windowSize,
      'preloadBackward must not exceed windowSize',
    );
    assert(
      _preloadForward <= _windowSize,
      'preloadForward must not exceed windowSize',
    );
    assert(
      _preloadBackward + _preloadForward < _windowSize,
      'Sum of preloadBackward and preloadForward must be less than windowSize',
    );

    int initialLoadSize =
        _windowSize > _videoUrls.length ? _videoUrls.length : _windowSize;

    for (int i = 0; i < initialLoadSize; i++) {
      _preloadWindow.add(_initController(_videoUrls[i], i));
    }

    _start = 0;
    _end = _preloadWindow.length;

    _seeWhatsInsidePreloadWindow();
  }

  int _lastActivePaginationIndex = -1;

  /// Colorful logging with emojis
  void _log(String message, {String emoji = '📱', String color = 'blue'}) {
    if (kDebugMode) {
      // ANSI color codes for terminal output
      const colors = {
        'red': '\x1B[31m',
        'green': '\x1B[32m',
        'yellow': '\x1B[33m',
        'blue': '\x1B[34m',
        'magenta': '\x1B[35m',
        'cyan': '\x1B[36m',
        'white': '\x1B[37m',
        'reset': '\x1B[0m',
      };

      final colorCode = colors[color] ?? colors['blue'];
      final resetCode = colors['reset'];

      print('$colorCode$emoji $message$resetCode');
    }
  }

  CustomVideoController _initController(String url, int index) {
    final controller = _controllerFactory(url);
    controller
        .initialize()
        .then((_) {
          _log(
            'Controller initialized successfully for: $url',
            emoji: '✅',
            color: 'green',
          );
          if (_autoplayFirstVideo && index == 0 && !_firstVideoPlayed) {
            _autoPlayCurrent(0);
            _firstVideoPlayed = true;
          }
          if (onControllerInitialized != null) {
            onControllerInitialized!(controller);
          }
        })
        .catchError((error) {
          _log(
            'Failed to initialize controller for: $url - Error: $error',
            emoji: '❌',
            color: 'red',
          );
        });
    return controller;
  }

  Future<void> _disposeController(CustomVideoController controller) async {
    try {
      await controller.pause();
      await controller.dispose();
      _log('Controller disposed successfully', emoji: '🗑️', color: 'yellow');
    } catch (e) {
      _log('Error disposing controller: $e', emoji: '⚠️', color: 'red');
    }
  }

  /// Check if pagination is needed and trigger it
  Future<void> _checkAndTriggerPagination(int currentIndex) async {
    final remainingItems = _videoUrls.length - currentIndex - 1;

    if (remainingItems <= _paginationThreshold && onPaginationNeeded != null) {
      _log(
        'Pagination threshold reached! Remaining items: $remainingItems',
        emoji: '📄',
        color: 'magenta',
      );

      try {
        final newUrls = await onPaginationNeeded!();
        if (newUrls.isNotEmpty) {
          _videoUrls.addAll(newUrls);
          _log(
            'Added ${newUrls.length} new videos via pagination',
            emoji: '➕',
            color: 'green',
          );
        }
      } catch (e) {
        _log('Pagination failed: $e', emoji: '❌', color: 'red');
      }
    }
  }

  Future<void> _onScrollForward(
    int index,
    Function() paginationCallback,
  ) async {
    // Check for pagination before processing scroll
    await _checkAndTriggerPagination(index);

    if (_end >= _videoUrls.length) {
      _log(
        "Cannot scroll forward - reached end of videos",
        emoji: '🛑',
        color: 'yellow',
      );

      if (_lastActivePaginationIndex == -1) {
        _lastActivePaginationIndex = index - 1;
      }
      return;
    }

    var newController = _initController(_videoUrls[_end], _end);
    _preloadWindow.add(newController);

    if (_preloadWindow.length > _windowSize) {
      await _disposeController(_preloadWindow.removeAt(0));
    }

    _start++;
    _end++;
    _log(
      'Scrolled forward - Window: $_start to $_end',
      emoji: '⏩',
      color: 'cyan',
    );
    _seeWhatsInsidePreloadWindow();
  }

  Future<void> _onScrollBackward(int index) async {
    if (_start <= 0) {
      _log(
        "Cannot scroll backward - reached beginning",
        emoji: '🛑',
        color: 'yellow',
      );
      return;
    }

    if (_lastActivePaginationIndex != -1 &&
        _lastActivePaginationIndex < index) {
      _log(
        "Index not active yet for backward scroll",
        emoji: '⏸️',
        color: 'yellow',
      );
      return;
    }

    _lastActivePaginationIndex = -1;

    int newStart = _start - 1;
    if (newStart >= 0 && newStart < _videoUrls.length) {
      var newController = _initController(_videoUrls[newStart], newStart);
      _preloadWindow.insert(0, newController);

      if (_preloadWindow.length > _windowSize) {
        await _disposeController(_preloadWindow.removeLast());
      }

      _start = newStart;
      _end--;
      _log(
        'Scrolled backward - Window: $_start to $_end',
        emoji: '⏪',
        color: 'cyan',
      );
    }

    _seeWhatsInsidePreloadWindow();
  }

  /// Pause all videos except the one at the specified index
  void _pauseAllExcept(int currentIndex) {
    int pausedCount = 0;
    for (int i = 0; i < _preloadWindow.length; i++) {
      int globalIndex = _start + i;
      if (globalIndex != currentIndex && _preloadWindow[i].isPlaying) {
        _preloadWindow[i].pause();
        pausedCount++;
      }
    }

    if (pausedCount > 0) {
      _log(
        'Paused $pausedCount video(s) except index: $currentIndex',
        emoji: '⏸️',
        color: 'yellow',
      );
    }

    // Notify UI of play state change
    if (onPlayStateChanged != null) {
      onPlayStateChanged!();
    }
  }

  /// Auto-play the video at the current index with retry mechanism
  void _autoPlayCurrent(int currentIndex) {
    final controller = getControllerAtIndex(currentIndex);
    if (controller != null) {
      if (controller.isInitialized && !controller.isPlaying) {
        controller.play();
        _currentPlayingIndex = currentIndex;
        _log(
          'Auto-playing video at index: $currentIndex',
          emoji: '▶️',
          color: 'green',
        );
        // Notify UI of play state change
        if (onPlayStateChanged != null) {
          onPlayStateChanged!();
        }
      } else if (!controller.isInitialized) {
        // If not initialized yet, wait and try again
        _log(
          'Waiting for video initialization at index: $currentIndex',
          emoji: '⏳',
          color: 'yellow',
        );
        Future.delayed(Duration(milliseconds: 100), () {
          _autoPlayCurrent(currentIndex);
        });
      }
    }
  }

  Future<void> scroll(int index) async {
    _log(
      'Scrolling to index: $index (previous: $_prevIndex)',
      emoji: '🔄',
      color: 'blue',
    );

    // Pause all videos except the current one
    _pauseAllExcept(index);

    if (index > _prevIndex) {
      await _onScrollForward(index, () {});
    } else if (index < _prevIndex) {
      await _onScrollBackward(index);
    }

    _prevIndex = index;

    // Auto-play the current video with a small delay to ensure initialization
    _autoPlayCurrent(index);
  }

  /// Get the currently focused controller (middle of window)
  CustomVideoController getCurrentController() {
    int center = (_preloadWindow.length / 2).floor();
    return _preloadWindow[center];
  }

  /// Get all active controllers (for debugging or external access)
  List<CustomVideoController> getActiveControllers() => _preloadWindow;

  /// Dispose all controllers
  Future<void> disposeAll() async {
    _log('Disposing all controllers...', emoji: '🧹', color: 'red');
    for (var controller in _preloadWindow) {
      await _disposeController(controller);
    }
    _preloadWindow.clear();
    _log('All controllers disposed', emoji: '✅', color: 'green');
  }

  /// Safe getter: may return null if index out of range
  CustomVideoController? getControllerAtIndex(int index) {
    int relative = index - _start;
    if (relative >= 0 && relative < _preloadWindow.length) {
      return _preloadWindow[relative];
    } else {
      _log(
        "Index $index is out of preload range ($_start - $_end)",
        emoji: '⚠️',
        color: 'yellow',
      );
      return null;
    }
  }

  /// Get start index
  int getStart() => _start;

  /// Get current playing index
  int getCurrentPlayingIndex() => _currentPlayingIndex;

  /// Force autoplay for a specific index (useful for initialization)
  void forceAutoPlay(int index) {
    _log('Force auto-playing index: $index', emoji: '🎬', color: 'magenta');
    _autoPlayCurrent(index);
  }

  /// Toggle play/pause for a specific controller
  void togglePlayPause(CustomVideoController controller) {
    if (controller.isPlaying) {
      controller.pause();
      _log('Video paused', emoji: '⏸️', color: 'yellow');
    } else {
      // Pause all other videos first
      for (var ctrl in _preloadWindow) {
        if (ctrl != controller && ctrl.isPlaying) {
          ctrl.pause();
        }
      }
      controller.play();
      _log('Video resumed', emoji: '▶️', color: 'green');
    }
    // Notify UI of play state change
    if (onPlayStateChanged != null) {
      onPlayStateChanged!();
    }
  }

  /// Get current pagination threshold
  int getPaginationThreshold() => _paginationThreshold;

  /// Set pagination threshold
  void setPaginationThreshold(int threshold) {
    _paginationThreshold = threshold;
    _log(
      'Pagination threshold updated to: $threshold',
      emoji: '⚙️',
      color: 'cyan',
    );
  }

  /// Get total number of videos
  int getTotalVideoCount() => _videoUrls.length;

  /// Set custom controller factory
  void setControllerFactory(CustomVideoControllerFactory factory) {
    _controllerFactory = factory;
    _log('Controller factory updated', emoji: '🏭', color: 'magenta');
  }

  void _seeWhatsInsidePreloadWindow() {
    _log(
      "Preload Window | Start: $_start | End: $_end | Total Videos: ${_videoUrls.length}",
      emoji: '🔍',
      color: 'blue',
    );
  }
}

// Example of custom implementations

/// Example: Custom controller for different video player package
class ExampleCustomVideoController extends CustomVideoController {
  final String _url;
  bool _isInitialized = false;
  bool _isPlaying = false;

  ExampleCustomVideoController(this._url);

  @override
  Future<void> initialize() async {
    // Your custom initialization logic here
    // e.g., await yourVideoPlayer.initialize(_url);
    _isInitialized = true;
  }

  @override
  Future<void> play() async {
    if (_isInitialized) {
      // Your custom play logic here
      _isPlaying = true;
    }
  }

  @override
  Future<void> pause() async {
    // Your custom pause logic here
    _isPlaying = false;
  }

  @override
  Future<void> dispose() async {
    // Your custom disposal logic here
    _isInitialized = false;
    _isPlaying = false;
  }

  @override
  bool get isPlaying => _isPlaying;

  @override
  bool get isInitialized => _isInitialized;

  @override
  String get dataSource => _url;
}

/// Example: YouTube video controller
class YouTubeVideoController extends CustomVideoController {
  final String _videoId;
  bool _isInitialized = false;
  bool _isPlaying = false;

  YouTubeVideoController(this._videoId);

  @override
  Future<void> initialize() async {
    // Initialize YouTube player
    // await youTubePlayerController.load(_videoId);
    _isInitialized = true;
  }

  @override
  Future<void> play() async {
    if (_isInitialized) {
      // youTubePlayerController.play();
      _isPlaying = true;
    }
  }

  @override
  Future<void> pause() async {
    // youTubePlayerController.pause();
    _isPlaying = false;
  }

  @override
  Future<void> dispose() async {
    // Clean up YouTube player resources
    _isInitialized = false;
    _isPlaying = false;
  }

  @override
  bool get isPlaying => _isPlaying;

  @override
  bool get isInitialized => _isInitialized;

  @override
  String get dataSource => _videoId;
}
