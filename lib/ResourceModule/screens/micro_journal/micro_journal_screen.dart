import 'package:flutter/material.dart';
import 'package:mindspace/ResourceModule/screens/micro_journal/journal_history_screen.dart';
import 'package:mindspace/ResourceModule/models/journal_entry_model.dart';
import 'package:mindspace/database/supabase_service.dart';

class MicroJournalScreen extends StatefulWidget {
  const MicroJournalScreen({super.key});

  @override
  State<MicroJournalScreen> createState() => _MicroJournalScreenState();
}

class _MicroJournalScreenState extends State<MicroJournalScreen> {
  final _textController = TextEditingController();
  final SupabaseService _dbHelper = SupabaseService.instance;
  bool _isSaved = false;
  bool _isLoading = false;

  Future<void> _saveEntry() async {
    if (_textController.text.trim().isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
      _isSaved = false;
    });

    try {
      final uid = _dbHelper.currentUserId;
      if (uid == null) {
        throw Exception('User not authenticated');
      }
      
      await _dbHelper.insertJournalEntry(
        JournalEntryModel(
          userId: uid,
          text: _textController.text.trim(),
        ),
      );

      setState(() {
        _textController.clear();
        _isSaved = true;
        _isLoading = false;
      });

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isSaved = false;
          });
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving entry: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Micro-Journal'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const JournalHistoryScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'QUICK PROMPT',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '"What is one thing that went well today?"',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _textController,
                  decoration: const InputDecoration(
                    hintText: 'Type here...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 5,
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _saveEntry,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2C3E50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Save Entry'),
                        ),
                ),
                if (_isSaved)
                  const Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Saved!',
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

