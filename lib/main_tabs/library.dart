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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.inkBgMain,
      appBar: AppBar(
      backgroundColor: AppTheme.inkBgMain,
      elevation: 0,
      centerTitle: true,
      title: const Text(
          'Library',
          style: TextStyle(
            fontFamily: 'Paytone One',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.inkEspresso,
           
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.inkTerracotta,
          indicatorWeight: 3,
          labelColor: AppTheme.inkEspresso,
          unselectedLabelColor: AppTheme.inkUmber.withValues(alpha: 0.5),
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(text: 'My Collection'),
            Tab(text: 'Recent Reads'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyCollection(),
          _buildRecentReads(),
        ],
      ),
    );
  }

  // ── My Collection ──────────────────────────────────────────────────────────
  // Reads from users/{uid}/library — populated by the "Add to Library" button
  // on the Home screen. Ordered by when the user saved the story.
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
        if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.inkTerracotta),
          );
        }

        final savedDocs = snapshot.data?.docs ?? [];
        if (savedDocs.isEmpty) return _buildEmptyState(isCollection: true);

        // Fetch full story documents so the card has all fields.
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchStoriesFromLibrary(savedDocs),
          builder: (context, storySnap) {
            if (storySnap.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                    color: AppTheme.inkTerracotta),
              );
            }

            final stories = storySnap.data ?? [];
            if (stories.isEmpty) return _buildEmptyState(isCollection: true);

            return GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 20,
                childAspectRatio: 0.58,
              ),
              itemCount: stories.length,
              itemBuilder: (context, index) {
                final item = stories[index];
                return _LibraryBookCard(
                  data: item,
                  docId: item['storyId'] as String,
                  onTap: () => _openStory(item),
                );
              },
            );
          },
        );
      },
    );
  }

  /// Fetches full story documents for each library entry.
  /// Falls back to the metadata stored in the library doc if the story is gone.
  Future<List<Map<String, dynamic>>> _fetchStoriesFromLibrary(
    List<QueryDocumentSnapshot> libraryDocs,
  ) async {
    final results = <Map<String, dynamic>>[];

    for (final libDoc in libraryDocs) {
      final storyId = libDoc.id;
      final libData = libDoc.data() as Map<String, dynamic>;

      try {
        final storyDoc = await FirebaseFirestore.instance
            .collection('stories')
            .doc(storyId)
            .get();

        if (storyDoc.exists) {
          results.add({
            ...(storyDoc.data() as Map<String, dynamic>),
            'storyId': storyId,
          });
        } else {
          // Story was deleted — show library metadata as fallback.
          results.add({...libData, 'storyId': storyId});
        }
      } catch (e) {
        debugPrint('Error fetching story $storyId: $e');
        results.add({...libData, 'storyId': storyId});
      }
    }

    return results;
  }

  // ── Recent Reads ───────────────────────────────────────────────────────────
  // Reads from users/{uid}/readingProgress ordered by lastOpenedAt.
  // _openStory stamps lastOpenedAt on every open, keeping this list current.
  Widget _buildRecentReads() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Please login to view library'));
    }

    final progressQuery = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('readingProgress')
        .orderBy('lastOpenedAt', descending: true);

    return StreamBuilder<QuerySnapshot>(
      key: const ValueKey('library_grid_recent'),
      stream: progressQuery.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.inkTerracotta),
          );
        }

        final progressDocs = snapshot.data?.docs ?? [];
        if (progressDocs.isEmpty) {
          return _buildEmptyState(isCollection: false);
        }

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchStoriesForProgress(progressDocs),
          builder: (context, storySnap) {
            if (storySnap.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                    color: AppTheme.inkTerracotta),
              );
            }

            final stories = storySnap.data ?? [];
            if (stories.isEmpty) {
              return _buildEmptyState(isCollection: false);
            }

            return GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 20,
                childAspectRatio: 0.58,
              ),
              itemCount: stories.length,
              itemBuilder: (context, index) {
                final item = stories[index];
                return _LibraryBookCard(
                  data: item,
                  docId: item['storyId'] as String,
                  onTap: () => _openStory(item),
                );
              },
            );
          },
        );
      },
    );
  }

  /// Fetches the story document for each readingProgress entry.
  Future<List<Map<String, dynamic>>> _fetchStoriesForProgress(
    List<QueryDocumentSnapshot> progressDocs,
  ) async {
    final results = <Map<String, dynamic>>[];

    for (final progressDoc in progressDocs) {
      final storyId = progressDoc.id;
      try {
        final storyDoc = await FirebaseFirestore.instance
            .collection('stories')
            .doc(storyId)
            .get();

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

  // ── Open story ─────────────────────────────────────────────────────────────
  // Stamps lastOpenedAt FIRST → story immediately appears in Recent Reads.
  Future<void> _openStory(Map<String, dynamic> storyData) async {
    final user = FirebaseAuth.instance.currentUser;
    final storyType = storyData['storyType'] as String? ?? 'Short Story';
    final storyId = storyData['storyId'] as String? ?? '';

    // ① Stamp open time so Recent Reads reflects the actual open order.
    if (user != null && storyId.isNotEmpty) {
      _saveLastOpened(storyId);
    }

    // ② Novels: resume from last chapter or start at chapter 1.
    if (storyType == 'Novel' && storyId.isNotEmpty) {
      try {
        int chapterToOpen = 1;
        if (user != null) {
          try {
            final progressDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('readingProgress')
                .doc(storyId)
                .get();

            if (progressDoc.exists) {
              chapterToOpen =
                  progressDoc.data()?['lastChapterNumber'] ?? 1;
            }
          } catch (e) {
            debugPrint('Error loading reading progress: $e');
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

        final finalSnap =
            chaptersSnap.docs.isNotEmpty ? chaptersSnap : fallbackSnap;

        if (finalSnap.docs.isNotEmpty) {
          final chapterData =
              finalSnap.docs.first.data() as Map<String, dynamic>;
          final payload = {
            ...storyData,
            'title': chapterData['title'] ??
                chapterData['contentType'] ??
                'Prologue',
            'body': chapterData['body'] ?? '',
            'chapterNumber': chapterData['chapterNumber'] ?? 1,
            'contentType': chapterData['contentType'] ?? 'Chapter',
          };

          if (!mounted) return;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => StoryReadScreen(story: payload),
            ),
          );
          return;
        }
      } catch (e) {
        debugPrint('Error loading chapter: $e');
      }
    }

    // ③ Short stories / poetry / flash fiction.
    final payload = {
      ...storyData,
      'body': storyData['body'] ?? '',
      'chapterNumber': 1,
      'contentType': storyData['contentType'] ?? 'Chapter',
    };

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StoryReadScreen(story: payload),
      ),
    );
  }

  // ── Persistence helpers ────────────────────────────────────────────────────

  /// Stamps lastOpenedAt so Recent Reads stays sorted by actual open time.
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

  // ── Empty state ────────────────────────────────────────────────────────────
  Widget _buildEmptyState({required bool isCollection}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isCollection
                ? Icons.bookmark_outline
                : Icons.auto_stories_outlined,
            size: 64,
            color: AppTheme.inkUmber.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            isCollection
                ? 'Your collection is empty'
                : 'Your shelf is empty',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.inkEspresso,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isCollection
                ? 'Save stories from Home to fill it up!'
                : 'Open a story to start your reading history!',
            textAlign: TextAlign.center,
            style:
                TextStyle(color: AppTheme.inkUmber.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }
}

// ── Book card ──────────────────────────────────────────────────────────────
class _LibraryBookCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  final VoidCallback onTap;

  const _LibraryBookCard(
      {required this.data, required this.docId, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final genre = data['genre'] ?? 'Fantasy';
    final color = PostScreenUtils.getGenreTagColor(genre);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Container(
                    width: 8,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                    ),
                  ),
                  Center(
                    child: Icon(
                      PostScreenUtils.getGenreIcon(genre),
                      size: 40,
                      color: color.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 32, // fixed height = exactly 2 lines worth of title text
            child: Text(
              data['title'] ?? 'Untitled',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: AppTheme.inkEspresso,
              ),
            ),
          ),
          const SizedBox(height: 2),
          SizedBox(
            height: 14, // fixed height for author line
            child: Text(
              data['authorUsername'] ?? 'Unknown Author',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.inkUmber.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}