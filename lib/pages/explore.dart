import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../main_tabs/profile.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  bool _isSearchingStories = true; // Toggle between Stories and Users
  final Set<String> _savedStoryIds = {};

  late Stream<QuerySnapshot> _storiesStream;
  late Stream<QuerySnapshot> _usersStream;

  @override
  void initState() {
    super.initState();
    _loadSavedStoryIds();
    // Initialize streams here to prevent flickering/resets during search typing
    _storiesStream = FirebaseFirestore.instance.collection('stories').snapshots();
    _usersStream = FirebaseFirestore.instance.collection('users').snapshots();
  }

  Future<void> _loadSavedStoryIds() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('library')
          .get();
      if (mounted) {
        setState(() {
          _savedStoryIds.addAll(snap.docs.map((d) => d.id));
        });
      }
    } catch (e) {
      debugPrint('Error loading saved story IDs: $e');
    }
  }

  Future<void> _toggleLibrary(String storyId, Map<String, dynamic> storyData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to save stories')),
      );
      return;
    }

    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('library')
        .doc(storyId);

    final alreadySaved = _savedStoryIds.contains(storyId);

    setState(() {
      if (alreadySaved) {
        _savedStoryIds.remove(storyId);
      } else {
        _savedStoryIds.add(storyId);
      }
    });

    try {
      if (alreadySaved) {
        await ref.delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Removed from Library')),
          );
        }
      } else {
        await ref.set({
          'storyId': storyId,
          'savedAt': FieldValue.serverTimestamp(),
          'title': storyData['title'] ?? '',
          'authorUsername': storyData['authorUsername'] ?? '',
          'genre': storyData['genre'] ?? '',
          'storyType': storyData['storyType'] ?? 'Short Story',
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Added to Library')),
          );
        }
      }
    } catch (e) {
      setState(() {
        if (alreadySaved) {
          _savedStoryIds.add(storyId);
        } else {
          _savedStoryIds.remove(storyId);
        }
      });
      debugPrint('Error adding to library: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.inkBgMain,
      appBar: AppBar(
        backgroundColor: AppTheme.inkBgMain,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          color: AppTheme.inkEspresso,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Container(
          height: 40,
          margin: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: AppTheme.inkCanvas,
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            textAlignVertical: TextAlignVertical.center,
            onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Search stories or writers...',
              prefixIcon: const Icon(Icons.search, color: AppTheme.inkUmber, size: 20),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              hintStyle: TextStyle(color: AppTheme.inkUmber.withValues(alpha: 0.6), fontSize: 14),
            ),
            style: const TextStyle(fontSize: 14, color: AppTheme.inkEspresso),
          ),
        ),
      ),
      body: Column(
        children: [
          // Tab Selector
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildFilterChip('Stories', _isSearchingStories, () {
                  setState(() => _isSearchingStories = true);
                }),
                const SizedBox(width: 12),
                _buildFilterChip('Writers', !_isSearchingStories, () {
                  setState(() => _isSearchingStories = false);
                }),
              ],
            ),
          ),
          Expanded(
            child: _searchQuery.isEmpty
                ? _buildInitialState()
                : (_isSearchingStories ? _buildStoryResults() : _buildUserResults()),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.inkTerracotta : AppTheme.inkCanvas,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.inkUmber,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.explore_outlined, size: 64, color: AppTheme.inkUmber.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          const Text('Search for your next favorite story',
              style: TextStyle(color: AppTheme.inkUmber)),
        ],
      ),
    );
  }

  Widget _buildStoryResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: _storiesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.inkTerracotta));
        }

        final docs = (snapshot.data?.docs ?? []).where((doc) {
          final data = doc.data() as Map<String, dynamic>?;
          final title = (data?['title'] as String? ?? '').toLowerCase();
          return title.contains(_searchQuery);
        }).toList() ?? [];

        if (docs.isEmpty) return const Center(child: Text('No stories found'));

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final storyId = docs[index].id;
            final bool isSaved = _savedStoryIds.contains(storyId);

            return Card(
              elevation: 0,
              color: AppTheme.inkCanvas.withValues(alpha: 0.5),
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                title: Text(data['title'], 
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.inkEspresso)),
                subtitle: Text('by ${data['authorUsername'] ?? 'Unknown'}',
                  style: const TextStyle(color: AppTheme.inkUmber)),
                trailing: IconButton(
                  icon: Icon(
                    isSaved ? Icons.library_add_check : Icons.library_add_outlined,
                    color: AppTheme.inkTerracotta,
                  ),
                  onPressed: () => _toggleLibrary(storyId, data),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildUserResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: _usersStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.inkTerracotta));
        }

        final docs = (snapshot.data?.docs ?? []).where((doc) {
          final data = doc.data() as Map<String, dynamic>?;
          final name = (data?['displayName'] as String? ?? "").toLowerCase();
          final username = (data?['username'] as String? ?? "").toLowerCase();
          // Only show public profiles (default to true if not set)
          final isPublic = (data?['isPublic'] as bool?) ?? true;
          
          return isPublic && (name.contains(_searchQuery) || username.contains(_searchQuery));
        }).toList() ?? [];

        if (docs.isEmpty) return const Center(child: Text('No writers found'));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final photoUrl = data['photoUrl'] as String?;
            // Default to true if isPublic is not set
            final isPublic = (data['isPublic'] as bool?) ?? true;

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.inkCanvas,
                backgroundImage: (photoUrl != null && photoUrl.isNotEmpty) ? NetworkImage(photoUrl) : null,
                child: (photoUrl == null || photoUrl.isEmpty) ? const Icon(Icons.person, color: AppTheme.inkUmber) : null,
              ),
              title: Text(data['displayName'] as String? ?? 'Writer'),
              subtitle: Text('@${data['username'] ?? 'user'}'),
              trailing: !isPublic ? const Icon(Icons.lock_outline, size: 16) : null,
              onTap: () {
                if (isPublic) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(userId: docs[index].id),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('This profile is private')),
                  );
                }
              },
            );
          },
        );
      },
    );
  }
}