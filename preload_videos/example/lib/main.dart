import 'package:custom_preload_videos/preload_videos.dart' show PreloadVideos;
import 'package:flutter/material.dart';
import 'package:custom_preload_videos/interface/controller_interface.dart';
import 'package:custom_preload_videos/my_custom_controller_impl/my_video_controller.dart';
import 'package:video_player/video_player.dart';

import 'chewie_example_screen.dart';

void main() {
  runApp(constApp());
}

class constApp extends StatelessWidget {
  const constApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Video Preloader Demo',
      home: ExampleSelectionScreen(),
    );
  }
}

class ExampleSelectionScreen extends StatelessWidget {
  const ExampleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preload Video Examples')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DefaultPlayerExample(),
                  ),
                );
              },
              child: const Text('Default Player Example'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChewieExampleScreen(),
                  ),
                );
              },
              child: const Text('Chewie Player Example'),
            ),
          ],
        ),
      ),
    );
  }
}

class DefaultPlayerExample extends StatefulWidget {
  const DefaultPlayerExample({super.key});

  @override
  State<DefaultPlayerExample> createState() => _DefaultPlayerExampleState();
}

class _DefaultPlayerExampleState extends State<DefaultPlayerExample> {
  final List<String> videoUrls = [
    "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
    "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
    "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4",
    "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4",
    "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
    "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4",
    "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4",
    "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerMeltdowns.mp4",
    "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/SubaruOutbackOnStreetAndDirt.mp4",
    "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/VolkswagenGTIReview.mp4",
    "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/WeAreGoingOnBullrun.mp4",
  ];

  PreloadVideos? _preloadVideos;
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializePreloadVideos();
  }

  void _initializePreloadVideos() {
    _preloadVideos = PreloadVideos(
      videoUrls: videoUrls,
      preloadBackward: 2,
      preloadForward: 3,
      windowSize: 6,
      paginationThreshold: 3,
      autoplayFirstVideo: true,
      onControllerInitialized: (CustomVideoController controller) {
        if (mounted) {
          setState(() {});
        }
      },
      onPlayStateChanged: () {
        if (mounted) {
          setState(() {});
        }
      },
      onPaginationNeeded: () async {
        // Simulate loading more videos from API
        await Future.delayed(const Duration(seconds: 1));

        // Return more video URLs (in real app, fetch from your API)
        return [
          "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
          "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
        ];
      },
    );

    // Mark loading as complete after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _preloadVideos?.disposeAll();
    _pageController.dispose();
    super.dispose();
  }

  /// Get the underlying VideoPlayerController for display
  VideoPlayerController? _getVideoPlayerController(
    CustomVideoController? controller,
  ) {
    if (controller is DefaultVideoController) {
      return controller.videoPlayerController;
    }
    return null;
  }

  /// Handle page navigation
  Future<void> _onPageChanged(int index) async {
    _currentIndex = index;
    await _preloadVideos!.scroll(index);
    setState(() {});
  }

  /// Navigate to previous page
  void _navigateToPrevious() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Navigate to next page
  void _navigateToNext() {
    if (_currentIndex < _preloadVideos!.getTotalVideoCount() - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Build video player widget
  Widget _buildVideoPlayer(int index) {
    final customController = _preloadVideos!.getControllerAtIndex(index);
    final videoPlayerController = _getVideoPlayerController(customController);

    if (customController == null ||
        !customController.isInitialized ||
        videoPlayerController == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text('Loading video...', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Video player
        Center(
          child: AspectRatio(
            aspectRatio: videoPlayerController.value.aspectRatio,
            child: VideoPlayer(videoPlayerController),
          ),
        ),

        // Play/Pause button
        Center(
          child: GestureDetector(
            onTap: () => _preloadVideos!.togglePlayPause(customController),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: Icon(
                customController.isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 48,
              ),
            ),
          ),
        ),

        // Video info overlay
        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Video ${index + 1}/${_preloadVideos!.getTotalVideoCount()}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),

        // Debug info (only in debug mode)
        if (const bool.fromEnvironment('dart.vm.product') == false)
          Positioned(
            bottom: 100,
            left: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Window: ${_preloadVideos!.getStart()} - ${_preloadVideos!.getStart() + _preloadVideos!.getActiveControllers().length - 1}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  Text(
                    'Playing: ${_preloadVideos!.getCurrentPlayingIndex()}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  Text(
                    'Threshold: ${_preloadVideos!.getPaginationThreshold()}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Preloader Demo',
      theme: ThemeData.dark(),
      home: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('Default Player Example'),
          backgroundColor: Colors.black87,
          elevation: 0,
          actions: [
            Builder(
              builder:
                  (context) => IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () {
                      _showSettingsDialog(context);
                    },
                  ),
            ),
          ],
        ),
        body:
            _isLoading || _preloadVideos == null
                ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Initializing video preloader...'),
                    ],
                  ),
                )
                : PageView.builder(
                  controller: _pageController,
                  itemCount: _preloadVideos!.getTotalVideoCount(),
                  onPageChanged: _onPageChanged,
                  scrollDirection: Axis.vertical,
                  itemBuilder: (context, index) => _buildVideoPlayer(index),
                ),
        floatingActionButton:
            _isLoading || _preloadVideos == null
                ? null
                : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton.small(
                      heroTag: "up",
                      onPressed: _currentIndex > 0 ? _navigateToPrevious : null,
                      backgroundColor: _currentIndex > 0 ? null : Colors.grey,
                      child: const Icon(Icons.keyboard_arrow_up),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton.small(
                      heroTag: "down",
                      onPressed:
                          _currentIndex <
                                  _preloadVideos!.getTotalVideoCount() - 1
                              ? _navigateToNext
                              : null,
                      backgroundColor:
                          _currentIndex <
                                  _preloadVideos!.getTotalVideoCount() - 1
                              ? null
                              : Colors.grey,
                      child: const Icon(Icons.keyboard_arrow_down),
                    ),
                  ],
                ),
      ),
    );
  }

  /// Show settings dialog for configuration
  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Settings'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('Pagination Threshold'),
                  subtitle: Text(
                    'Current: ${_preloadVideos?.getPaginationThreshold() ?? 'N/A'}',
                  ),
                  trailing: const Icon(Icons.edit),
                  onTap: () {
                    Navigator.pop(context);
                    _showThresholdDialog(context);
                  },
                ),
                ListTile(
                  title: const Text('Total Videos'),
                  subtitle: Text(
                    '${_preloadVideos?.getTotalVideoCount() ?? 0} videos loaded',
                  ),
                  trailing: const Icon(Icons.video_library),
                ),
                ListTile(
                  title: const Text('Active Controllers'),
                  subtitle: Text(
                    '${_preloadVideos?.getActiveControllers().length ?? 0} controllers in memory',
                  ),
                  trailing: const Icon(Icons.memory),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  /// Show threshold configuration dialog
  void _showThresholdDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController(
      text: _preloadVideos?.getPaginationThreshold().toString() ?? '5',
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Set Pagination Threshold'),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Threshold',
                hintText:
                    'Enter number of videos remaining to trigger pagination',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  final threshold = int.tryParse(controller.text);
                  if (threshold != null && threshold > 0) {
                    _preloadVideos?.setPaginationThreshold(threshold);
                    setState(() {});
                  }
                  Navigator.pop(context);
                },
                child: const Text('Set'),
              ),
            ],
          ),
    );
  }
}
