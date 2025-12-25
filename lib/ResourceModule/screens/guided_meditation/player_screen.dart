import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:mindspace/ResourceModule/models/meditation_model.dart';

class PlayerScreen extends StatefulWidget {
  final MeditationModel meditation;

  const PlayerScreen({super.key, required this.meditation});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  VideoPlayerController? _videoPlayerController;
  AudioPlayer? _audioPlayer;
  bool _isPlaying = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    if (widget.meditation.mediaType == MediaType.video) {
      if (widget.meditation.mediaPath.startsWith('http')) {
        _videoPlayerController = VideoPlayerController.networkUrl(
          Uri.parse(widget.meditation.mediaPath),
        );
      } else {
        _videoPlayerController = VideoPlayerController.file(
          File(widget.meditation.mediaPath),
        );
      }
      await _videoPlayerController!.initialize();
      setState(() {
        _isInitialized = true;
      });
    } else {
      _audioPlayer = AudioPlayer();
      setState(() {
        _isInitialized = true;
      });
    }
  }

  void _playPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (widget.meditation.mediaType == MediaType.video && _videoPlayerController != null) {
        _isPlaying
            ? _videoPlayerController!.play()
            : _videoPlayerController!.pause();
      } else if (_audioPlayer != null) {
        if (_isPlaying) {
          if (widget.meditation.mediaPath.startsWith('http')) {
            _audioPlayer!.play(UrlSource(widget.meditation.mediaPath));
          } else {
            _audioPlayer!.play(DeviceFileSource(widget.meditation.mediaPath));
          }
        } else {
          _audioPlayer!.pause();
        }
      }
    });
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.meditation.title),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_isInitialized)
              const CircularProgressIndicator()
            else if (widget.meditation.mediaType == MediaType.video && _videoPlayerController != null)
              _videoPlayerController!.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: _videoPlayerController!.value.aspectRatio,
                      child: VideoPlayer(_videoPlayerController!),
                    )
                  : const CircularProgressIndicator()
            else
              const Icon(Icons.music_note, size: 100),
            const SizedBox(height: 20),
            IconButton(
              icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, size: 50),
              onPressed: _playPause,
            ),
          ],
        ),
      ),
    );
  }
}

