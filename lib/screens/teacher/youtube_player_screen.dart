import 'dart:async';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';

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
  VideoPlayerController? _mp4Controller;
  bool _isPlayerReady = false;
  String? _error;
  double _playbackSpeed = 1.0;
  bool _isMuted = false;
  double _volume = 50.0; // Add volume state
  bool _isPlaying = false; // Add playing state
  bool _isMp4 = false;
  // Dummy video info
  String _channel = 'Unknown Channel';
  String _description = 'No description available.';

  bool _isInFullscreen = false; // Only updated by controller listener

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    // Optionally, fetch video/channel info from YouTube Data API if you want real info
  }

  void _initializePlayer() {
    try {
      final uri = Uri.tryParse(widget.videoUrl);
      final path = uri?.path.toLowerCase() ?? widget.videoUrl.toLowerCase();
      _isMp4 = path.endsWith('.mp4');
      print('Video URL: ${widget.videoUrl} | isMp4=$_isMp4');

      if (_isMp4) {
        _mp4Controller =
            VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
        _mp4Controller!.initialize().then((_) {
          setState(() {
            _isPlayerReady = true;
            _isMuted = false;
            _isPlaying = false;
          });
          _mp4Controller!.play();
          _isPlaying = true;
        }).catchError((e) {
          print('Error initializing mp4 player: $e');
          setState(() {
            _error = 'Error initializing video: $e';
          });
        });
        _mp4Controller!.addListener(() {
          if (mounted) {
            setState(() {
              _isPlaying = _mp4Controller!.value.isPlaying;
            });
          }
        });
      } else {
        final videoId = YoutubePlayer.convertUrlToId(widget.videoUrl);
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
          if (mounted) {
            setState(() {
              _isPlaying = _controller.value.isPlaying;
            });
          }
        });
        // Add listener to track fullscreen changes
        _controller.addListener(() {
          if (mounted) {
            setState(() {
              _isInFullscreen = _controller.value.isFullScreen;
            });
          }
        });
      }
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
    if (!_isMp4) {
      _controller.removeListener(_onPlayerChanged);
      _controller.dispose();
    } else {
      _mp4Controller?.dispose();
    }
    super.dispose();
  }

  void _toggleMute() {
    if (_isMp4) {
      if (_isMuted) {
        _mp4Controller?.setVolume(_volume / 100.0);
      } else {
        _mp4Controller?.setVolume(0.0);
      }
    } else {
      if (_isMuted) {
        _controller.unMute();
        _controller.setVolume(_volume.toInt());
      } else {
        _controller.mute();
      }
    }
    setState(() {
      _isMuted = !_isMuted;
    });
  }

  void _togglePlayPause() {
    if (_isMp4) {
      if (_isPlaying) {
        _mp4Controller?.pause();
      } else {
        _mp4Controller?.play();
      }
    } else {
      if (_isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    }
  }

  void _setVolume(double value) {
    setState(() {
      _volume = value;
    });
    if (!_isMuted) {
      if (_isMp4) {
        _mp4Controller?.setVolume(value / 100.0);
      } else {
        _controller.setVolume(value.toInt());
      }
    }
  }

  void _seekForward() {
    if (_isMp4) {
      final pos = _mp4Controller?.value.position ?? Duration.zero;
      _mp4Controller?.seekTo(pos + const Duration(seconds: 10));
    } else {
      final pos = _controller.value.position;
      _controller.seekTo(pos + const Duration(seconds: 10));
    }
  }

  void _seekBackward() {
    if (_isMp4) {
      final pos = _mp4Controller?.value.position ?? Duration.zero;
      _mp4Controller?.seekTo(pos - const Duration(seconds: 10));
    } else {
      final pos = _controller.value.position;
      _controller.seekTo(pos - const Duration(seconds: 10));
    }
  }

  void _changeSpeed(double speed) {
    if (_isMp4) {
      _mp4Controller?.setPlaybackSpeed(speed);
    } else {
      _controller.setPlaybackRate(speed);
    }
    setState(() {
      _playbackSpeed = speed;
    });
  }

  void _toggleFullscreen() {
    if (_isMp4) {
      _enterMp4Fullscreen();
    } else {
      _controller.toggleFullScreenMode();
    }
  }

  Future<void> _enterMp4Fullscreen() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            _Mp4FullscreenScaffold(controller: _mp4Controller),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
      ),
    );

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
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
    if (_isMp4) {
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
                    Text(_error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center),
                  ],
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      if (_mp4Controller != null &&
                          _mp4Controller!.value.isInitialized)
                        AspectRatio(
                          aspectRatio: _mp4Controller!.value.aspectRatio == 0
                              ? 16 / 9
                              : _mp4Controller!.value.aspectRatio,
                          child: VideoPlayer(_mp4Controller!),
                        )
                      else
                        const SizedBox(
                            height: 200,
                            child: Center(child: CircularProgressIndicator())),
                      if (_mp4Controller != null &&
                          _mp4Controller!.value.isInitialized)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8.0),
                          child: Column(
                            children: [
                              VideoProgressIndicator(_mp4Controller!,
                                  allowScrubbing: true),
                            ],
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            _buildControls(),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed:
                                  _isPlayerReady ? _toggleFullscreen : null,
                              icon: const Icon(Icons.fullscreen),
                              label: const Text('Fullscreen'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      );
    }

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
                                                _controller
                                                    .metadata.duration.inSeconds
                                                    .toDouble()),
                                        min: 0.0,
                                        max: _controller
                                            .metadata.duration.inSeconds
                                            .toDouble(),
                                        onChanged: (value) {
                                          _controller.seekTo(
                                              Duration(seconds: value.toInt()));
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

class _Mp4FullscreenScaffold extends StatefulWidget {
  final VideoPlayerController? controller;
  const _Mp4FullscreenScaffold({Key? key, required this.controller})
      : super(key: key);

  @override
  State<_Mp4FullscreenScaffold> createState() => _Mp4FullscreenScaffoldState();
}

class _Mp4FullscreenScaffoldState extends State<_Mp4FullscreenScaffold> {
  bool _showControls = true;
  bool _isMuted = false;
  double _volume = 0.5;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _volume = widget.controller!.value.volume;
      _isMuted = _volume == 0.0;
    }
    _startHideTimer();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
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

  void _togglePlayPause() {
    if (widget.controller != null) {
      if (widget.controller!.value.isPlaying) {
        widget.controller!.pause();
      } else {
        widget.controller!.play();
      }
      setState(() {});
    }
  }

  void _stop() {
    if (widget.controller != null) {
      widget.controller!.pause();
      widget.controller!.seekTo(Duration.zero);
      setState(() {});
    }
  }

  void _seekBackward() {
    if (widget.controller != null) {
      final position = widget.controller!.value.position;
      final newPosition = position - const Duration(seconds: 10);
      widget.controller!
          .seekTo(newPosition < Duration.zero ? Duration.zero : newPosition);
    }
  }

  void _seekForward() {
    if (widget.controller != null) {
      final position = widget.controller!.value.position;
      final duration = widget.controller!.value.duration;
      final newPosition = position + const Duration(seconds: 10);
      widget.controller!
          .seekTo(newPosition > duration ? duration : newPosition);
    }
  }

  void _toggleMute() {
    if (widget.controller != null) {
      if (_isMuted) {
        widget.controller!.setVolume(_volume);
        _isMuted = false;
      } else {
        widget.controller!.setVolume(0.0);
        _isMuted = true;
      }
      setState(() {});
    }
  }

  void _setVolume(double value) {
    if (widget.controller != null) {
      _volume = value;
      if (!_isMuted) {
        widget.controller!.setVolume(value);
      }
      setState(() {});
    }
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startHideTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.controller == null || !widget.controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            // Video Player
            Center(
              child: AspectRatio(
                aspectRatio: widget.controller!.value.aspectRatio == 0
                    ? 16 / 9
                    : widget.controller!.value.aspectRatio,
                child: VideoPlayer(widget.controller!),
              ),
            ),

            // Controls Overlay
            if (_showControls)
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.8),
                    ],
                  ),
                ),
              ),

            // Top Controls (Back button and title)
            if (_showControls)
              Positioned(
                top: 20,
                left: 10,
                right: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back,
                            color: Colors.white, size: 28),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Expanded(
                        child: Text(
                          'Fullscreen Video - Tap to hide controls',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48), // Balance for back button
                    ],
                  ),
                ),
              ),

            // Center Controls (Previous, Play/Pause, Stop, Next)
            if (_showControls)
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Previous (Seek Backward)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withOpacity(0.3), width: 2),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.replay_10,
                            color: Colors.white, size: 32),
                        onPressed: _seekBackward,
                      ),
                    ),
                    const SizedBox(width: 20),

                    // Play/Pause
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withOpacity(0.5), width: 3),
                      ),
                      child: IconButton(
                        icon: Icon(
                          widget.controller!.value.isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                          color: Colors.white,
                          size: 40,
                        ),
                        onPressed: _togglePlayPause,
                      ),
                    ),
                    const SizedBox(width: 20),

                    // Stop
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withOpacity(0.3), width: 2),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.stop,
                            color: Colors.white, size: 32),
                        onPressed: _stop,
                      ),
                    ),
                    const SizedBox(width: 20),

                    // Next (Seek Forward)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withOpacity(0.3), width: 2),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.forward_10,
                            color: Colors.white, size: 32),
                        onPressed: _seekForward,
                      ),
                    ),
                  ],
                ),
              ),

            // Bottom Controls (Progress, Volume, Time)
            if (_showControls)
              Positioned(
                bottom: 20,
                left: 10,
                right: 10,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Progress Bar
                    Row(
                      children: [
                        StreamBuilder(
                          stream: Stream.periodic(
                              const Duration(milliseconds: 500)),
                          builder: (context, snapshot) {
                            return Text(
                              _formatDuration(
                                  widget.controller!.value.position),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12),
                            );
                          },
                        ),
                        Expanded(
                          child: StreamBuilder(
                            stream: Stream.periodic(
                                const Duration(milliseconds: 500)),
                            builder: (context, snapshot) {
                              return Slider(
                                value: widget
                                    .controller!.value.position.inSeconds
                                    .toDouble()
                                    .clamp(
                                        0.0,
                                        widget.controller!.value.duration
                                            .inSeconds
                                            .toDouble()),
                                min: 0.0,
                                max: widget.controller!.value.duration.inSeconds
                                    .toDouble(),
                                onChanged: (value) {
                                  widget.controller!
                                      .seekTo(Duration(seconds: value.toInt()));
                                },
                                activeColor: Colors.red,
                                inactiveColor: Colors.white.withOpacity(0.3),
                              );
                            },
                          ),
                        ),
                        Text(
                          _formatDuration(widget.controller!.value.duration),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),

                    // Volume Controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(
                            _isMuted ? Icons.volume_off : Icons.volume_up,
                            color: Colors.white,
                            size: 24,
                          ),
                          onPressed: _toggleMute,
                        ),
                        SizedBox(
                          width: 200,
                          child: Slider(
                            value: _isMuted ? 0.0 : _volume,
                            min: 0.0,
                            max: 1.0,
                            onChanged: _setVolume,
                            activeColor: Colors.white,
                            inactiveColor: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.volume_down,
                              color: Colors.white, size: 20),
                          onPressed: () =>
                              _setVolume((_volume - 0.1).clamp(0.0, 1.0)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.volume_up,
                              color: Colors.white, size: 20),
                          onPressed: () =>
                              _setVolume((_volume + 0.1).clamp(0.0, 1.0)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
