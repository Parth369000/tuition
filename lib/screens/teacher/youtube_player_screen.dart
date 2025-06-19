import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class YoutubePlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String title;

  const YoutubePlayerScreen({
    Key? key,
    required this.videoUrl,
    required this.title,
  }) : super(key: key);

  @override
  State<YoutubePlayerScreen> createState() => _YoutubePlayerScreenState();
}

class _YoutubePlayerScreenState extends State<YoutubePlayerScreen> {
  late YoutubePlayerController _controller;
  bool _isPlayerReady = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _initializePlayer() {
    try {
      // Extract video ID from URL
      final videoId = YoutubePlayer.convertUrlToId(widget.videoUrl);
      print('Video URL: ${widget.videoUrl}');
      print('Extracted Video ID: $videoId');

      if (videoId == null) {
        setState(() {
          _error = 'Invalid YouTube URL: ${widget.videoUrl}';
        });
        return;
      }

      _controller = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          enableCaption: true,
          forceHD: true,
        ),
      );

      // Set initial state
      setState(() {
        _isPlayerReady = true;
      });

      _controller.addListener(() {
        print('Player state changed: ${_controller.value.playerState}');
        print('Player is ready: ${_controller.value.isReady}');
        print('Player is playing: ${_controller.value.isPlaying}');
      });
    } catch (e) {
      print('Error initializing player: $e');
      setState(() {
        _error = 'Error initializing player: $e';
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color(0xFF328ECC),
      ),
      body: Center(
        child: _error != null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            : YoutubePlayer(
                controller: _controller,
                showVideoProgressIndicator: true,
                progressIndicatorColor: const Color(0xFF328ECC),
                progressColors: const ProgressBarColors(
                  playedColor: Color(0xFF328ECC),
                  handleColor: Color(0xFF328ECC),
                ),
                onReady: () {
                  print('Player onReady called');
                  setState(() {
                    _isPlayerReady = true;
                  });
                },
                onEnded: (data) {
                  print('Video ended');
                },
              ),
      ),
    );
  }
}
