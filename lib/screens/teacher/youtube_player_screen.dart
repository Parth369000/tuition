import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:share_plus/share_plus.dart';

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
  double _playbackSpeed = 1.0;
  bool _isMuted = false;
  double _volume = 50.0; // Add volume state
  bool _isPlaying = false; // Add playing state
  // Dummy video info
  String _channel = 'Unknown Channel';
  String _description = 'No description available.';
  bool _liked = false;
  bool _disliked = false;

  bool _isInFullscreen = false; // Only updated by controller listener

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    // Optionally, fetch video/channel info from YouTube Data API if you want real info
  }

  void _initializePlayer() {
    try {
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
          mute: false, // Set initial state to unmuted
          enableCaption: true,
          forceHD: true,
          hideControls: false,
          hideThumbnail: true,
        ),
      );

      setState(() {
        _isPlayerReady = true;
        _isMuted = false;
      });

      // Add listener to track player state and fullscreen changes
      _controller.addListener(_onPlayerChanged);
      // Add listener to track player state
      _controller.addListener(() {
        setState(() {
          _isPlaying = _controller.value.isPlaying;
        });
      });
      // Add listener to track fullscreen changes
      _controller.addListener(() {
        setState(() {
          _isInFullscreen = _controller.value.isFullScreen;
        });
      });
    } catch (e) {
      print('Error initializing player: $e');
      setState(() {
        _error = 'Error initializing player: $e';
      });
    }
  }

  void _onPlayerChanged() {
    // Rebuild widget when player state (including fullscreen) changes
    setState(() {});
  }

  void _retry() {
    setState(() {
      _error = null;
      _isPlayerReady = false;
    });
    _initializePlayer();
  }

  @override
  void dispose() {
    _controller.removeListener(_onPlayerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _toggleMute() {
    if (_isMuted) {
      _controller.unMute();
      _controller.setVolume(_volume.toInt());
    } else {
      _controller.mute();
    }
    setState(() {
      _isMuted = !_isMuted;
    });
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
  }

  void _setVolume(double value) {
    setState(() {
      _volume = value;
    });
    if (!_isMuted) {
      _controller.setVolume(value.toInt());
    }
  }

  void _seekForward() {
    final pos = _controller.value.position;
    _controller.seekTo(pos + const Duration(seconds: 10));
  }

  void _seekBackward() {
    final pos = _controller.value.position;
    _controller.seekTo(pos - const Duration(seconds: 10));
  }

  void _changeSpeed(double speed) {
    _controller.setPlaybackRate(speed);
    setState(() {
      _playbackSpeed = speed;
    });
  }

  void _toggleFullscreen() {
    _controller.toggleFullScreenMode();
  }

  void _shareVideo() {
    // Disable sharing to prevent URL exposure
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sharing is disabled for security reasons'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    final twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    } else {
      return "$twoDigitMinutes:$twoDigitSeconds";
    }
  }

  Widget _buildControls() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.replay_10),
              onPressed: _isPlayerReady ? _seekBackward : null,
              tooltip: 'Back 10s',
            ),
            IconButton(
              icon: Icon(_isMuted ? Icons.volume_off : Icons.volume_up),
              onPressed: _isPlayerReady ? _toggleMute : null,
              tooltip: _isMuted ? 'Unmute' : 'Mute',
            ),
            // Play/Pause button
            IconButton(
              icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: _isPlayerReady ? _togglePlayPause : null,
              tooltip: _isPlaying ? 'Pause' : 'Play',
            ),
            PopupMenuButton<double>(
              initialValue: _playbackSpeed,
              tooltip: 'Playback speed',
              onSelected: _changeSpeed,
              itemBuilder: (context) => [
                for (final speed in [0.5, 1.0, 1.5, 2.0])
                  PopupMenuItem(
                    value: speed,
                    child: Text('${speed}x'),
                  ),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.speed),
                    Text('${_playbackSpeed}x'),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.forward_10),
              onPressed: _isPlayerReady ? _seekForward : null,
              tooltip: 'Forward 10s',
            ),
            IconButton(
              icon: const Icon(Icons.fullscreen),
              onPressed: _isPlayerReady ? _toggleFullscreen : null,
              tooltip: 'Fullscreen',
            ),
          ],
        ),
        // Volume control row
        if (!_isMuted)
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                const Icon(Icons.volume_down, size: 20),
                Expanded(
                  child: Slider(
                    value: _volume,
                    min: 0.0,
                    max: 100.0,
                    divisions: 10,
                    onChanged: _setVolume,
                  ),
                ),
                const Icon(Icons.volume_up, size: 20),
              ],
            ),
          ),
        // Row(
        //   mainAxisAlignment: MainAxisAlignment.center,
        //   children: [
        //     IconButton(
        //       icon: Icon(_liked ? Icons.thumb_up : Icons.thumb_up_outlined,
        //           color: _liked ? Colors.blue : null),
        //       onPressed: () {
        //         setState(() {
        //           _liked = !_liked;
        //           if (_liked) _disliked = false;
        //         });
        //       },
        //       tooltip: 'Like',
        //     ),
        //     IconButton(
        //       icon: Icon(
        //           _disliked ? Icons.thumb_down : Icons.thumb_down_outlined,
        //           color: _disliked ? Colors.red : null),
        //       onPressed: () {
        //         setState(() {
        //           _disliked = !_disliked;
        //           if (_disliked) _liked = false;
        //         });
        //       },
        //       tooltip: 'Dislike',
        //     ),
        //     // Remove share button to prevent URL exposure
        //     // IconButton(
        //     //   icon: const Icon(Icons.share),
        //     //   onPressed: _shareVideo,
        //     //   tooltip: 'Share',
        //     // ),
        //   ],
        // ),
      ],
    );
  }

  Widget _buildVideoInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Youtube video',
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 4),
          Text('Channel: $_channel',
              style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(_description, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      player: YoutubePlayer(
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
      builder: (context, player) {
        // If in fullscreen, show only the player
        if (_isInFullscreen) {
          return Scaffold(
            body: Center(child: player),
            backgroundColor: Colors.black,
          );
        }
        // Not in fullscreen: show player with rest of UI
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
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _retry,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        // Video player (not fixed height)
                        player,
                        // Controls and info below the player
                        // Video progress slider
                        if (_isPlayerReady &&
                            _controller.metadata.duration.inSeconds > 0) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      _formatDuration(
                                          _controller.value.position),
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.grey),
                                    ),
                                    Expanded(
                                      child: Slider(
                                        value: _controller
                                            .value.position.inSeconds
                                            .toDouble()
                                            .clamp(
                                                0,
                                                _controller.metadata.duration
                                                    .inSeconds
                                                    .toDouble()),
                                        min: 0.0,
                                        max: _controller
                                            .metadata.duration.inSeconds
                                            .toDouble(),
                                        onChanged: (value) {
                                          _controller.seekTo(Duration(
                                              seconds: value.toInt()));
                                        },
                                      ),
                                    ),
                                    Text(
                                      _formatDuration(
                                          _controller.metadata.duration),
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              _buildControls(),
                              const SizedBox(height: 16),
                              _buildVideoInfo(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }
}
