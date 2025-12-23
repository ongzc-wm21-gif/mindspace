import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:calmmind/ResourceModule/models/meditation_model.dart';
import 'package:calmmind/database/supabase_service.dart';

class AddEditMeditationScreen extends StatefulWidget {
  final MeditationModel? meditation;

  const AddEditMeditationScreen({super.key, this.meditation});

  @override
  State<AddEditMeditationScreen> createState() => _AddEditMeditationScreenState();
}

class _AddEditMeditationScreenState extends State<AddEditMeditationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final SupabaseService _dbHelper = SupabaseService.instance;
  late String _category;
  late MediaType _mediaType;
  String _mediaPath = '';
  Duration _duration = Duration.zero;
  bool _isLoading = false;
  final List<String> _categories = ['Sleep', 'Focus', 'Anxiety'];

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.meditation?.title ?? '';
    _category = widget.meditation?.category.name ?? _categories.first;
    _mediaType = widget.meditation?.mediaType ?? MediaType.audio;
    _mediaPath = widget.meditation?.mediaPath ?? '';
    _duration = widget.meditation?.duration ?? Duration.zero;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: _mediaType == MediaType.audio ? FileType.audio : FileType.video,
    );

    if (result != null && result.files.single.path != null) {
      final pickedFile = File(result.files.single.path!);
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = path.basename(pickedFile.path);
      final newPath = path.join(appDir.path, fileName);

      final savedFile = await pickedFile.copy(newPath);

      Duration fileDuration = Duration.zero;
      if (_mediaType == MediaType.video) {
        final controller = VideoPlayerController.file(savedFile);
        await controller.initialize();
        fileDuration = controller.value.duration;
        await controller.dispose();
      } else {
        final player = AudioPlayer();
        await player.setSourceDeviceFile(savedFile.path);
        fileDuration = await player.getDuration() ?? Duration.zero;
        await player.dispose();
      }

      setState(() {
        _mediaPath = savedFile.path;
        _duration = fileDuration;
      });
    }
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_mediaPath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick a file')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final meditation = MeditationModel(
        id: widget.meditation?.id,
        title: _titleController.text.trim(),
        duration: _duration,
        category: MeditationCategory.values.firstWhere(
          (e) => e.name == _category,
          orElse: () => MeditationCategory.Sleep,
        ),
        mediaPath: _mediaPath,
        mediaType: _mediaType,
      );

      if (widget.meditation?.id != null) {
        await _dbHelper.updateMeditation(meditation);
      } else {
        await _dbHelper.insertMeditation(meditation);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving meditation: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.meditation == null ? 'Add Meditation' : 'Edit Meditation'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<MediaType>(
                value: _mediaType,
                decoration: InputDecoration(
                  labelText: 'Type',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: MediaType.values.map((MediaType type) {
                  return DropdownMenuItem<MediaType>(
                    value: type,
                    child: Text(type.name[0].toUpperCase() + type.name.substring(1)),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _mediaType = newValue!;
                    _mediaPath = '';
                    _duration = Duration.zero;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: InputDecoration(
                  labelText: 'Category',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _category = newValue!;
                  });
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _pickFile,
                icon: Icon(_mediaType == MediaType.video
                    ? Icons.videocam_outlined
                    : Icons.audiotrack_outlined),
                label: Text(
                    _mediaType == MediaType.video ? 'Pick Video' : 'Pick Audio'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple.withOpacity(0.1),
                  foregroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  side: const BorderSide(color: Colors.deepPurple),
                ),
              ),
              if (_mediaPath.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'File: ${path.basename(_mediaPath)}',
                    textAlign: TextAlign.center,
                  ),
                ),
              if (_duration != Duration.zero)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Duration: ${_formatDuration(_duration)}',
                    textAlign: TextAlign.center,
                  ),
                ),
              const Spacer(),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _saveForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Save'),
                    ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

