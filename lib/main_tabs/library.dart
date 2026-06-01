import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import 'package:vibewrite_app/story/read_screen.dart';
import 'package:vibewrite_app/main_tabs/post/post_screen_utils.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() => _searchQuery = '');
        _searchController.clear();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Matching the warm, off-white/textured canvas background from the UI mockups
      backgroundColor: const Color(0xFFF6ECE1), 
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildLibraryHeader(),
            _buildSearchBar(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMyCollection(),
                  _buildRecentReads(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLibraryHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: AppTheme.inkEspresso,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFAC5C37).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.menu_book_rounded,
                  color: Color(0xFFFDF5E6),
                  size: 32,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'My Library',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your personal reading shelf',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            _buildStoryCountDisplay(),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryCountDisplay() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('library')
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
                Text(
                  'Stories',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Collected',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            _buildBookStackIcon(),
          ],
        );
      },
    );
  }

  Widget _buildBookStackIcon() {
    return SizedBox(
      width: 32,
      height: 38,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          _spineLayer(bottomOffset: 0, width: 30, height: 7, color: const Color(0xFFEEDC82)),
          _spineLayer(bottomOffset: 5, width: 28, height: 7, color: const Color(0xFFDEB887)),
          _spineLayer(bottomOffset: 10, width: 29, height: 7, color: const Color(0xFFF4A460)),
          _spineLayer(bottomOffset: 15, width: 26, height: 7, color: const Color(0xFFFFF8DC)),
        ],
      ),
    );
  }

  Widget _spineLayer({
    required double bottomOffset, 
    required double width, 
    required double height, 
    required Color color
  }) {
    return Positioned(
      bottom: bottomOffset,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 1,
              offset: const Offset(0, 1),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFFEFE4D6),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.05), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Color(0xFFC87A53), width: 1.5),
          ),
          hintText: 'Search library...',
          hintStyle: TextStyle(
            color: AppTheme.inkUmber.withValues(alpha: 0.5),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: AppTheme.inkUmber.withValues(alpha: 0.7),
            size: 20,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        style: const TextStyle(color: AppTheme.inkEspresso, fontSize: 14),
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFEFE4D6),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildTabButton(
                'Collection',
                _selectedTab == 0,
                () {
                  setState(() => _selectedTab = 0);
                  _tabController.animateTo(0);
                },
              ),
            ),
            Expanded(
              child: _buildTabButton(
                'Recent Reads',
                _selectedTab == 1,
                () {
                  setState(() => _selectedTab = 1);
                  _tabController.animateTo(1);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFC87A53) : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.inkUmber,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildMyCollection() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Please login to view library'));
    }

    final query = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('library')
        .orderBy('savedAt', descending: true);

    return StreamBuilder<QuerySnapshot>(
      key: const ValueKey('library_grid_collection'),
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text('Something went wrong'));
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFC87A53)));
        }

        final savedDocs = snapshot.data?.docs ?? [];
        if (savedDocs.isEmpty) return _buildEmptyState(isCollection: true);

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchStoriesFromLibrary(savedDocs),
          builder: (context, storySnap) {
            if (storySnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFFC87A53)));
            }

            var stories = storySnap.data ?? [];
            if (_searchQuery.isNotEmpty) {
              stories = stories
                  .where((story) =>
                      (story['title'] as String? ?? '').toLowerCase().contains(_searchQuery) ||
                      (story['authorUsername'] as String? ?? '').toLowerCase().contains(_searchQuery))
                  .toList();
            }

            if (stories.isEmpty) return _buildEmptyState(isCollection: true);

            return _buildShelfGrid(stories);
          },
        );
      },
    );
  }

  Widget _buildRecentReads() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text('Please login to view library'));

    final progressQuery = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('readingProgress')
        .orderBy('lastOpenedAt', descending: true);

    return StreamBuilder<QuerySnapshot>(
      key: const ValueKey('library_grid_recent'),
      stream: progressQuery.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text('Something went wrong'));
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFC87A53)));
        }

        final progressDocs = snapshot.data?.docs ?? [];
        if (progressDocs.isEmpty) return _buildEmptyState(isCollection: false);

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchStoriesForProgress(progressDocs),
          builder: (context, storySnap) {
            if (storySnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFFC87A53)));
            }

            var stories = storySnap.data ?? [];
            if (_searchQuery.isNotEmpty) {
              stories = stories
                  .where((story) =>
                      (story['title'] as String? ?? '').toLowerCase().contains(_searchQuery) ||
                      (story['authorUsername'] as String? ?? '').toLowerCase().contains(_searchQuery))
                  .toList();
            }

            if (stories.isEmpty) return _buildEmptyState(isCollection: false);

            return _buildShelfGrid(stories);
          },
        );
      },
    );
  }

  // Visual Architecture Engine drawing row-by-row wooden ledge structures under the books
  Widget _buildShelfGrid(List<Map<String, dynamic>> stories) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: (stories.length / 3).ceil(),
      itemBuilder: (context, rowIndex) {
        final int startIndex = rowIndex * 3;
        
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(3, (colIndex) {
                  final itemIndex = startIndex + colIndex;
                  if (itemIndex >= stories.length) {
                    return const Expanded(child: SizedBox.shrink());
                  }

                  final item = stories[itemIndex];
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: _LibraryBookCard(
                        data: item,
                        docId: item['storyId'] as String,
                        onTap: () => _openStory(item),
                      ),
                    ),
                  );
                }),
              ),
            ),
            // The Realistic Wood Shelf Render Layer
            Container(
              height: 14,
              margin: const EdgeInsets.only(bottom: 24, top: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFD2B48C), // Highlighting top wood lip reflection
                    Color(0xFFB58A55), // Mid wood core
                    Color(0xFF8B5A2B), // Deep ambient baseline shadow
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 5,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchStoriesFromLibrary(
    List<QueryDocumentSnapshot> libraryDocs,
  ) async {
    final results = <Map<String, dynamic>>[];
    for (final libDoc in libraryDocs) {
      final storyId = libDoc.id;
      final libData = libDoc.data() as Map<String, dynamic>;
      try {
        final storyDoc = await FirebaseFirestore.instance.collection('stories').doc(storyId).get();
        if (storyDoc.exists) {
          results.add({
            ...(storyDoc.data() as Map<String, dynamic>),
            'storyId': storyId,
          });
        } else {
          results.add({...libData, 'storyId': storyId});
        }
      } catch (e) {
        results.add({...libData, 'storyId': storyId});
      }
    }
    return results;
  }

  Future<List<Map<String, dynamic>>> _fetchStoriesForProgress(
    List<QueryDocumentSnapshot> progressDocs,
  ) async {
    final results = <Map<String, dynamic>>[];
    for (final progressDoc in progressDocs) {
      final storyId = progressDoc.id;
      try {
        final storyDoc = await FirebaseFirestore.instance.collection('stories').doc(storyId).get();
        if (storyDoc.exists) {
          results.add({
            ...(storyDoc.data() as Map<String, dynamic>),
            'storyId': storyId,
          });
        }
      } catch (e) {
        debugPrint('Error fetching story $storyId: $e');
      }
    }
    return results;
  }

  Future<void> _openStory(Map<String, dynamic> storyData) async {
    final user = FirebaseAuth.instance.currentUser;
    final storyType = storyData['storyType'] as String? ?? 'Short Story';
    final storyId = storyData['storyId'] as String? ?? '';

    if (user != null && storyId.isNotEmpty) {
      _saveLastOpened(storyId);
    }

    if (storyType == 'Novel' && storyId.isNotEmpty) {
      try {
        int chapterToOpen = 1;
        if (user != null) {
          final progressDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('readingProgress')
              .doc(storyId)
              .get();

          if (progressDoc.exists) {
            chapterToOpen = progressDoc.data()?['lastChapterNumber'] ?? 1;
          }
        }

        final chaptersSnap = await FirebaseFirestore.instance
            .collection('stories')
            .doc(storyId)
            .collection('chapters')
            .where('chapterNumber', isEqualTo: chapterToOpen)
            .limit(1)
            .get();

        late QuerySnapshot fallbackSnap;
        if (chaptersSnap.docs.isEmpty) {
          fallbackSnap = await FirebaseFirestore.instance
              .collection('stories')
              .doc(storyId)
              .collection('chapters')
              .orderBy('chapterNumber')
              .limit(1)
              .get();
        }

        final finalSnap = chaptersSnap.docs.isNotEmpty ? chaptersSnap : fallbackSnap;

        if (finalSnap.docs.isNotEmpty) {
          final chapterData = finalSnap.docs.first.data() as Map<String, dynamic>;
          final payload = {
            ...storyData,
            'title': chapterData['title'] ?? chapterData['contentType'] ?? 'Prologue',
            'body': chapterData['body'] ?? '',
            'chapterNumber': chapterData['chapterNumber'] ?? 1,
            'contentType': chapterData['contentType'] ?? 'Chapter',
          };

          if (!mounted) return;
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => StoryReadScreen(story: payload)),
          );
          return;
        }
      } catch (e) {
        debugPrint('Error loading chapter: $e');
      }
    }

    final payload = {
      ...storyData,
      'body': storyData['body'] ?? '',
      'chapterNumber': 1,
      'contentType': storyData['contentType'] ?? 'Chapter',
    };

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => StoryReadScreen(story: payload)),
    );
  }

  static Future<void> _saveLastOpened(String storyId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('readingProgress')
          .doc(storyId)
          .set(
            {'lastOpenedAt': FieldValue.serverTimestamp()},
            SetOptions(merge: true),
          );
    } catch (e) {
      debugPrint('Error saving lastOpenedAt: $e');
    }
  }

  Widget _buildEmptyState({required bool isCollection}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isCollection ? Icons.bookmark_outline : Icons.auto_stories_outlined,
            size: 64,
            color: AppTheme.inkUmber.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            isCollection ? 'Your collection is empty' : 'Your shelf is empty',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.inkEspresso),
          ),
          const SizedBox(height: 8),
          Text(
            isCollection ? 'Save stories from Home to fill it up!' : 'Open a story to start your reading history!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppTheme.inkUmber.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }
}

class _LibraryBookCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  final VoidCallback onTap;

  const _LibraryBookCard({required this.data, required this.docId, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final genre = data['genre'] ?? 'Fantasy';
    final color = PostScreenUtils.getGenreTagColor(genre);
    
    // Applying pastel colors from mockup
    final pastelColor = _getRefinedPastelColor(genre);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 0.76, // Matching structural dimensions of hardbound notebook curves
            child: Container(
              decoration: BoxDecoration(
                color: pastelColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  bottomLeft: Radius.circular(6),
                  topRight: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(3, 4),
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.4),
                    blurRadius: 0,
                    offset: const Offset(-1, 0), // Subtle paper page stack edge highlight
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Book Spine Crease Line 
                  Positioned(
                    left: 8,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 1.5,
                      color: Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                  // Left Spine Shaded Binding Overlay
                  Container(
                    width: 8,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.08),
                          Colors.white.withValues(alpha: 0.08),
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(6),
                        bottomLeft: Radius.circular(6),
                      ),
                    ),
                  ),
                  // Center Graphic Icon Asset Render
                  Center(
                    child: Opacity(
                      opacity: 0.45,
                      child: Icon(
                        PostScreenUtils.getGenreIcon(genre),
                        size: 36,
                        color: AppTheme.inkEspresso,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data['title'] ?? 'Untitled',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: AppTheme.inkEspresso,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data['authorUsername'] ?? 'Unknown Author',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              color: AppTheme.inkUmber.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.favorite, size: 10, color: Color(0xFFC87A53)),
              const SizedBox(width: 3),
              Text(
                '${data['likes'] ?? 0}',
                style: const TextStyle(fontSize: 10, color: AppTheme.inkEspresso),
              ),
              const SizedBox(width: 8),
              Icon(Icons.visibility, size: 10, color: AppTheme.inkUmber.withValues(alpha: 0.6)),
              const SizedBox(width: 3),
              Text(
                '${data['reads'] ?? 0}',
                style: const TextStyle(fontSize: 10, color: AppTheme.inkEspresso),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getRefinedPastelColor(String genre) {
    // Explicitly mapping the gorgeous soft muted palette variants seen in your mockup
    switch (genre.toLowerCase()) {
      case 'romance':
        return const Color(0xFFF3D1D1); // Soft Valentine Rose
      case 'mystery':
      case 'detective':
        return const Color(0xFFD5D6EA); // Periwinkle Blue
      case 'fantasy':
      case 'adventure':
        return const Color(0xFFD1E7DD); // Soft Mint Green
      default:
        return const Color(0xFFEFE5D8); // Warm Oatmeal Cream Dust
    }
  }
}