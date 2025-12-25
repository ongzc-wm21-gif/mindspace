import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../database/supabase_service.dart';
import 'moments_gallery_screen.dart';

class HappyMoments extends StatefulWidget {
  const HappyMoments({super.key});

  @override
  State<HappyMoments> createState() => _HappyMomentsState();
}

class _HappyMomentsState extends State<HappyMoments> {
  List<File> _moments = [];

  @override
  void initState() {
    super.initState();
    _loadMoments();
  }

  Future<void> _loadMoments() async {
    final paths = await SupabaseService.instance.getHappyMoments();
    setState(() {
      _moments = paths.map((path) => File(path)).toList();
    });
  }

  Future<void> _captureMoment() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      await SupabaseService.instance.insertHappyMoment(image.path);
      _loadMoments();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.yellow.shade100,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.sentiment_very_satisfied, color: Colors.black87),
                    SizedBox(width: 8),
                    Text(
                      'Happy Moments',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MomentsGalleryScreen(),
                      ),
                    ).then((_) => _loadMoments()); // Refresh count when coming back
                  },
                  icon: const Icon(Icons.photo_library, color: Colors.deepPurple, size: 20),
                  label: const Text(
                    'Gallery',
                    style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _captureMoment,
                icon: const Icon(Icons.camera_alt),
                label: const Text(
                  'Capture This Moment',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${_moments.length} moments captured so far',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
