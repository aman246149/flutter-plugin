# custom_preload_videos

[![pub package](https://img.shields.io/pub/v/preload_videos.svg)](https://pub.dev/packages/preload_videos)

A powerful and flexible Flutter video preloading package that allows you to create seamless video experiences, similar to platforms like TikTok or Instagram Reels. It preloads a window of videos to ensure smooth playback as the user scrolls.

This package is highly customizable, allowing you to integrate any video player through a simple interface.

## Features

- **Efficient Video Preloading**: Preloads a configurable window of videos to minimize buffering.
- **Customizable Window**: Set the number of videos to preload forward and backward.
- **Pagination Support**: Automatically fetches more videos when the user nears the end of the list.
- **Pluggable Architecture**: Bring your own video player! Easily create custom controllers for `video_player`, `chewie`, `flick_video_player`, or any other player.
- **Autoplay Control**: Full control over autoplay behavior, including for the very first video.
- **Lifecycle Management**: Automatically handles initialization and disposal of controllers as the user scrolls.
- **Informative Logging**: Optional colorful logging to see what's happening under the hood.

## Getting Started

### 1. Add Dependency

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  preload_videos: ^latest_version # Replace with the latest version
```

### 2. Basic Usage

Here's a simple example using the default `video_player` implementation.

```dart
import 'package:flutter/material.dart';
import 'package:preload_videos/preload_videos.dart';
import 'package:video_player/video_player.dart';

class VideoScreen extends StatefulWidget {
  @override
  _VideoScreenState createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  late PreloadVideos _preloadVideos;
  final List<String> videoUrls = [
    // Your video URLs here
  ];

  @override
  void initState() {
    super.initState();
    _preloadVideos = PreloadVideos(
      videoUrls: videoUrls,
      preloadForward: 3,
      preloadBackward: 2,
      windowSize: 6,
      autoplayFirstVideo: true,
      onPaginationNeeded: () async {
        // Fetch more video URLs from your API
        return ["new_url_1.mp4", "new_url_2.mp4"];
      },
    );
  }

  @override
  void dispose() {
    _preloadVideos.disposeAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      scrollDirection: Axis.vertical,
      itemCount: videoUrls.length,
      onPageChanged: (index) {
        _preloadVideos.scroll(index);
      },
      itemBuilder: (context, index) {
        final controller = _preloadVideos.getControllerAtIndex(index);

        if (controller == null || !controller.isInitialized) {
          return Center(child: CircularProgressIndicator());
        }

        // The default controller is DefaultVideoController, which wraps VideoPlayerController
        final videoPlayerController = (controller as dynamic).videoPlayerController;

        return AspectRatio(
          aspectRatio: videoPlayerController.value.aspectRatio,
          child: VideoPlayer(videoPlayerController),
        );
      },
    );
  }
}
```

## Creating a Custom Video Controller

One of the most powerful features of this package is the ability to use your own video player. To do this, you need to create a class that extends `CustomVideoController`.

### 1. Implement the `CustomVideoController` Interface

The `CustomVideoController` abstract class defines the contract your custom controller must follow.

`preload_videos/lib/interface/controller_interface.dart`:
```dart
abstract class CustomVideoController {
  Future<void> initialize();
  Future<void> play();
  Future<void> pause();
  Future<void> dispose();
  bool get isPlaying;
  bool get isInitialized;
  String get dataSource;
}
```

### 2. Example: Creating a `Chewie` Controller

Let's say you want to use the popular `chewie` package. Here's how you would create a custom controller for it.

**`my_chewie_controller.dart`:**
```dart
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:preload_videos/interface/controller_interface.dart';
import 'package:video_player/video_player.dart';

class MyChewieController extends CustomVideoController {
  final String _url;
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;

  // Expose ChewieController for the UI
  ChewieController? get chewieController => _chewieController;

  MyChewieController(this._url) {
    _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(_url));
  }

  @override
  Future<void> initialize() async {
    await _videoPlayerController.initialize();
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: true, // You can configure this
      looping: false,
    );
  }

  @override
  Future<void> play() async {
    _chewieController?.play();
  }

  @override
  Future<void> pause() async {
    _chewieController?.pause();
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
}
```

### 3. Use Your Custom Controller

Now, pass a factory function to the `PreloadVideos` constructor to tell it how to create instances of your new controller.

```dart
_preloadVideos = PreloadVideos(
  videoUrls: videoUrls,
  // ... other parameters
  controllerFactory: (String url) => MyChewieController(url),
);
```

That's it! The preloader will now use your `MyChewieController` for all video operations.

## API Reference

### `PreloadVideos` Constructor

| Parameter               | Type                               | Description                                                                                              |
| ----------------------- | ---------------------------------- | -------------------------------------------------------------------------------------------------------- |
| `videoUrls`             | `required List<String>`            | A list of video URLs to preload.                                                                         |
| `preloadBackward`       | `int?` (Default: 3)                | The number of videos to keep initialized behind the current index.                                       |
| `preloadForward`        | `int?` (Default: 3)                | The number of videos to initialize ahead of the current index.                                           |
| `windowSize`            | `int?` (Default: 8)                | The total number of controllers to keep in memory. Must be greater than `preloadBackward + preloadForward`.|
| `paginationThreshold`   | `int?` (Default: 5)                | The number of remaining videos that triggers the `onPaginationNeeded` callback.                          |
| `autoplayFirstVideo`    | `bool` (Default: `false`)          | Whether to automatically play the first video as soon as it is initialized.                              |
| `onControllerInitialized`| `Function(CustomVideoController)?` | A callback that fires when a controller has finished initializing.                                       |
| `onPlayStateChanged`    | `Function()?`                      | A callback that fires when a video's play state changes (play/pause).                                    |
| `onPaginationNeeded`    | `Future<List<String>> Function()?` | A callback that fires when more videos need to be fetched for pagination.                                |
| `controllerFactory`     | `CustomVideoControllerFactory?`    | A factory function to create instances of your custom video controller.                                  |


### Public Methods

- **`scroll(int index)`**: Notifies the preloader that the user has scrolled to a new index. This is the primary method to trigger preloading logic.
- **`getControllerAtIndex(int index)`**: Safely retrieves the controller for a specific index. Returns `null` if the index is outside the current preload window.
- **`disposeAll()`**: Disposes all active controllers. Call this in your widget's `dispose` method.
- **`forceAutoPlay(int index)`**: Manually triggers autoplay for a specific index.
- **`togglePlayPause(CustomVideoController controller)`**: Toggles the play/pause state of a given controller.

## Contributing

Contributions are welcome! If you find a bug or have a feature request, please file an issue. If you want to contribute code, please submit a pull request.
