import 'package:flutter/material.dart';
import 'package:mindspace/ResourceModule/screens/guided_meditation/manage_guided_meditation_screen.dart';
import 'package:mindspace/ResourceModule/screens/guided_meditation/player_screen.dart';
import 'package:mindspace/ResourceModule/models/meditation_model.dart';
import 'package:mindspace/database/supabase_service.dart';

class GuidedMeditationScreen extends StatefulWidget {
  final bool isAdmin;

  const GuidedMeditationScreen({super.key, required this.isAdmin});

  @override
  State<GuidedMeditationScreen> createState() => _GuidedMeditationScreenState();
}

class _GuidedMeditationScreenState extends State<GuidedMeditationScreen> {
  final SupabaseService _dbHelper = SupabaseService.instance;
  List<MeditationModel> _meditations = [];
  List<MeditationModel> _filteredMeditations = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _loadMeditations();
  }

  Future<void> _loadMeditations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final meditations = await _dbHelper.getAllMeditations();
      setState(() {
        _meditations = meditations;
        _filteredMeditations = meditations;
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading meditations: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredMeditations = _meditations.where((meditation) {
        final titleMatches =
            meditation.title.toLowerCase().contains(_searchQuery.toLowerCase());
        if (_filter == 'All') {
          return titleMatches;
        } else if (_filter == 'Favorites') {
          return titleMatches && meditation.isFavorited;
        } else {
          return titleMatches && meditation.category.name == _filter;
        }
      }).toList();
    });
  }

  Future<void> _toggleFavorite(MeditationModel meditation) async {
    if (meditation.id == null) return;

    try {
      await _dbHelper.toggleFavoriteMeditation(meditation.id!);
      _loadMeditations(); // Reload to update favorite status
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error toggling favorite: ${e.toString()}'),
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
      appBar: AppBar(
        title: const Text('Guided Meditation'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        actions: [
          if (widget.isAdmin)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ManageGuidedMeditationScreen(),
                  ),
                );
                if (result == true) {
                  _loadMeditations();
                }
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                _applyFilters();
              },
              decoration: const InputDecoration(
                labelText: 'Search',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              children: [
                for (final category in ['All', 'Favorites', 'Sleep', 'Focus', 'Anxiety'])
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: _filter == category,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _filter = category;
                          });
                          _applyFilters();
                        }
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredMeditations.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.spa_outlined, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No meditations found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredMeditations.length,
                        itemBuilder: (context, index) {
                          final meditation = _filteredMeditations[index];
                          return Card(
                            margin: const EdgeInsets.all(12.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                            elevation: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              PlayerScreen(meditation: meditation),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      height: 150,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10.0),
                                        gradient: const LinearGradient(
                                          colors: [Colors.blue, Colors.purple],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.play_arrow,
                                          color: Colors.white,
                                          size: 60,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          meditation.title,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          meditation.isFavorited
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          color: meditation.isFavorited
                                              ? Colors.red
                                              : Colors.grey,
                                        ),
                                        onPressed: () => _toggleFavorite(meditation),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                      '${_formatDuration(meditation.duration)} • ${meditation.category.name}'),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

