import 'package:chewie/chewie.dart';
import 'package:custom_preload_videos/preload_videos.dart' show PreloadVideos;
import 'package:flutter/material.dart';

import 'custom_implementaion/chewie_controller.dart';

class ChewieExampleScreen extends StatefulWidget {
  const ChewieExampleScreen({super.key});

  @override
  State<ChewieExampleScreen> createState() => _ChewieExampleScreenState();
}

class _ChewieExampleScreenState extends State<ChewieExampleScreen> {
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
      controllerFactory: (url) => MyChewieController(url),
      onControllerInitialized: (_) {
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
        await Future.delayed(const Duration(seconds: 1));
        return [
          "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
          "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
        ];
      },
    );

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

  Future<void> _onPageChanged(int index) async {
    _currentIndex = index;
    await _preloadVideos!.scroll(index);
    setState(() {});
  }

  Widget _buildVideoPlayer(int index) {
    final customController = _preloadVideos!.getControllerAtIndex(index);

    if (customController is MyChewieController) {
      final chewieController = customController.chewieController;
      if (customController.isInitialized && chewieController != null) {
        return Chewie(controller: chewieController);
      }
    }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chewie Player Example')),
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
    );
  }
}
