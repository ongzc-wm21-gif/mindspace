import 'dart:async';
import 'package:flutter/material.dart';

class BreathingPattern {
  final String name;
  final int inhale;
  final int holdAfterInhale;
  final int exhale;
  final int holdAfterExhale;

  BreathingPattern({
    required this.name,
    required this.inhale,
    required this.holdAfterInhale,
    required this.exhale,
    required this.holdAfterExhale,
  });
}

class BreathingExerciseScreen extends StatefulWidget {
  const BreathingExerciseScreen({super.key});

  @override
  State<BreathingExerciseScreen> createState() => _BreathingExerciseScreenState();
}

class _BreathingExerciseScreenState extends State<BreathingExerciseScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  String _text = 'Start';
  bool _isAnimating = false;
  Timer? _countdownTimer;
  int _remainingTime = 0;
  int _selectedDuration = 60;

  final List<BreathingPattern> _patterns = [
    BreathingPattern(name: 'Box Breathing', inhale: 4, holdAfterInhale: 4, exhale: 4, holdAfterExhale: 4),
    BreathingPattern(name: 'Deep Calm', inhale: 4, holdAfterInhale: 0, exhale: 6, holdAfterExhale: 0),
    BreathingPattern(name: 'Energizing', inhale: 3, holdAfterInhale: 0, exhale: 3, holdAfterExhale: 0),
    BreathingPattern(name: 'Stress Relief', inhale: 4, holdAfterInhale: 4, exhale: 8, holdAfterExhale: 0),
  ];

  late BreathingPattern _selectedPattern;

  @override
  void initState() {
    super.initState();
    _selectedPattern = _patterns[0];

    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: _selectedPattern.inhale),
    );

    _animation = Tween<double>(begin: 100, end: 200).animate(_controller)
      ..addListener(() {
        setState(() {});
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            _text = 'Hold';
          });
          Timer(Duration(seconds: _selectedPattern.holdAfterInhale), () {
            if (mounted && _isAnimating) {
              setState(() {
                _text = 'Exhale';
                _controller.duration = Duration(seconds: _selectedPattern.exhale);
              });
              _controller.reverse();
            }
          });
        } else if (status == AnimationStatus.dismissed) {
          if (_selectedPattern.holdAfterExhale > 0) {
            setState(() {
              _text = 'Hold';
            });
          }
          Timer(Duration(seconds: _selectedPattern.holdAfterExhale), () {
            if (mounted && _isAnimating) {
              setState(() {
                _text = 'Inhale';
                _controller.duration = Duration(seconds: _selectedPattern.inhale);
              });
              _controller.forward();
            }
          });
        }
      });
  }

  void _startAnimation() {
    if (mounted) {
      setState(() {
        _isAnimating = true;
        _text = 'Inhale';
        _controller.duration = Duration(seconds: _selectedPattern.inhale);
        _remainingTime = _selectedDuration;
      });
      _controller.forward();
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingTime > 0) {
          setState(() {
            _remainingTime--;
          });
        } else {
          _stopAnimation();
        }
      });
    }
  }

  void _stopAnimation() {
    if (mounted) {
      _controller.stop();
      _countdownTimer?.cancel();
      setState(() {
        _isAnimating = false;
        _text = 'Start';
        _remainingTime = 0;
      });
    }
  }

  void _onPatternSelected(BreathingPattern pattern) {
    if (!_isAnimating) {
      setState(() {
        _selectedPattern = pattern;
      });
    }
  }

  void _onDurationSelected(int duration) {
    if (!_isAnimating) {
      setState(() {
        _selectedDuration = duration;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      appBar: AppBar(
        title: const Text(
          'Breathing Exercise',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            if (_isAnimating)
              Text(
                _formatTime(_remainingTime),
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
              ),
            Container(
              width: _animation.value * 1.5,
              height: _animation.value * 1.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF4D4C7D).withOpacity(0.7),
              ),
              child: Center(
                child: Container(
                  width: _animation.value,
                  height: _animation.value,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF3EC3D5),
                  ),
                  child: Center(
                    child: Text(
                      _text,
                      style: const TextStyle(color: Colors.black, fontSize: 24),
                    ),
                  ),
                ),
              ),
            ),
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildBreathingButton(_patterns[0]),
                    _buildBreathingButton(_patterns[1]),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildBreathingButton(_patterns[2]),
                    _buildBreathingButton(_patterns[3]),
                  ],
                ),
              ],
            ),
            if (!_isAnimating)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildDurationChip(60, '1 Min'),
                  _buildDurationChip(180, '3 Min'),
                  _buildDurationChip(300, '5 Min'),
                ],
              ),
            ElevatedButton(
              onPressed: _isAnimating ? _stopAnimation : _startAnimation,
              style: ElevatedButton.styleFrom(
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: Text(_isAnimating ? 'Stop' : 'Start', style: const TextStyle(fontSize: 20)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreathingButton(BreathingPattern pattern) {
    bool isSelected = _selectedPattern.name == pattern.name;
    return ElevatedButton(
      onPressed: () => _onPatternSelected(pattern),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? const Color(0xFF3EC3D5) : const Color(0xFF4D4C7D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Text(pattern.name, style: const TextStyle(color: Colors.white)),
    );
  }

  Widget _buildDurationChip(int duration, String label) {
    bool isSelected = _selectedDuration == duration;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          _onDurationSelected(duration);
        }
      },
    );
  }
}

