import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/new_app_theme.dart';
import '../theme/app_typography.dart';
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
  String _searchQuery = '';
  int _selectedTab = 0; // 0 => Recent Reads, 1 => Collection
  final int _refreshKey = 0;
  @override
  void initState() {
    super.initState();
    // Recent Reads first: 2 tabs, default index 0 = "Recent Reads"
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0);
    _selectedTab = 0;
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
      backgroundColor: AppTheme.surfaceColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildRecentReads(), // now first
                  _buildMyCollection(), // now second
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    final user = FirebaseAuth.instance.currentUser;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.inkMaroon,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.inkMaroon.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.menu_book_rounded,
                  color: AppTheme.inkCanvas, size: 28),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Library',
                     style: AppTypography.headingLg.copyWith(
                        color: Colors.white,
                        fontSize: 26,
                      )
                  ),
                  Text(
                    'Your personal reading shelf',
                    style: AppTypography.bodySm.copyWith(
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Stats row
          if (user != null)
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('library')
                  .snapshots(),
              builder: (context, snap) {
                final count = snap.data?.docs.length ?? 0;
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .collection('readingProgress')
                      .snapshots(),
                  builder: (context, progSnap) {
                    final inProgress = (progSnap.data?.docs ?? []).where((d) {
                      final data = d.data() as Map<String, dynamic>;
                      final status =
                          (data['status'] as String?) ?? 'not_started';
                      return status == 'in_progress';
                    }).length;
                    final completed = (progSnap.data?.docs ?? []).where((d) {
                      final data = d.data() as Map<String, dynamic>;
                      final status =
                          (data['status'] as String?) ?? 'not_started';
                      return status == 'completed';
                    }).length;
                    return Row(
                      children: [
                        _statChip(Icons.bookmark_outlined, '$count', 'Saved'),
                        const SizedBox(width: 10),
                        _statChip(Icons.auto_stories_outlined, '$inProgress',
                            'In Progress'),
                        const SizedBox(width: 10),
                        _statChip(
                            Icons.check_circle_outline, '$completed', 'Completed'),
                      ],
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }
  Widget _statChip(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.inkGold, size: 18),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 20,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  // ── Search bar ────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
        decoration: InputDecoration(
          filled: true,
          fillColor: AppTheme.inkBgCard,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide:
                BorderSide(color: Colors.black.withValues(alpha: 0.05), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: AppTheme.inkMaroon, width: 1.5),
          ),
          hintText: 'Search library...',
          hintStyle: GoogleFonts.manrope(
            fontSize: 14,
            color: AppTheme.inkUmber.withValues(alpha: 0.5),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: AppTheme.inkUmber.withValues(alpha: 0.7),
            size: 20,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        style: GoogleFonts.manrope(fontSize: 14, color: AppTheme.inkEspresso),
      ),
    );
  }
  // ── Tab bar ───────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppTheme.inkBgCard,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            // Left: Recent Reads (index 0)
            Expanded(child: _tabBtn('Recent Reads', 0)),
            // Right: Collection (index 1)
            Expanded(child: _tabBtn('Collection', 1)),
          ],
        ),
      ),
    );
  }
  Widget _tabBtn(String label, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedTab = index);
        _tabController.animateTo(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.inkMaroon : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppTheme.inkUmber,
          ),
        ),
      ),
    );
  }
  // ── My Collection ─────────────────────────────────────────────────────────
  Widget _buildMyCollection() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Center(
          child:
              Text('Please login to view library', style: AppTypography.bodyMd));
    }
    return StreamBuilder<QuerySnapshot>(
      key: const ValueKey('library_collection'),
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('library')
          .orderBy('savedAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.inkMaroon));
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return _buildEmptyState(isCollection: true);
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchWithProgress(user.uid, docs, fromLibrary: true),
          builder: (context, storySnap) {
            if (storySnap.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: AppTheme.inkMaroon));
            }
            var stories = storySnap.data ?? [];
            if (_searchQuery.isNotEmpty) {
              stories = stories
                  .where((s) =>
                      (s['title'] ?? '').toLowerCase().contains(_searchQuery) ||
                      (s['authorUsername'] ?? '')
                          .toLowerCase()
                          .contains(_searchQuery))
                  .toList();
            }
            if (stories.isEmpty) return _buildEmptyState(isCollection: true);
            return _buildCardGrid(stories, user.uid);
          },
        );
      },
    );
  }
  // ── Recent Reads ──────────────────────────────────────────────────────────
  Widget _buildRecentReads() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Center(
          child:
              Text('Please login to view library', style: AppTypography.bodyMd));
    }
    return StreamBuilder<QuerySnapshot>(
      key: const ValueKey('library_recent'),
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('readingProgress')
          .orderBy('lastOpenedAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.inkMaroon));
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return _buildEmptyState(isCollection: false);
        return FutureBuilder<List<Map<String, dynamic>>>(
          key: ValueKey(_refreshKey),
          future: _fetchWithProgress(user.uid, docs, fromLibrary: false),
          builder: (context, storySnap) {
            if (storySnap.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: AppTheme.inkMaroon));
            }
            var stories = storySnap.data ?? [];
            if (_searchQuery.isNotEmpty) {
              stories = stories
                  .where((s) =>
                      (s['title'] ?? '').toLowerCase().contains(_searchQuery) ||
                      (s['authorUsername'] ?? '')
                          .toLowerCase()
                          .contains(_searchQuery))
                  .toList();
            }
            if (stories.isEmpty) return _buildEmptyState(isCollection: false);
            return _buildCardGrid(stories, user.uid);
          },
        );
      },
    );
  }
  // ── Card grid (2-column) ──────────────────────────────────────────────────
  Widget _buildCardGrid(List<Map<String, dynamic>> stories, String uid) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 12,
        childAspectRatio: 0.80,
      ),
      itemCount: stories.length,
      itemBuilder: (context, i) {
        final story = stories[i];
        return _LibraryStoryCard(
          data: story,
          onTap: () => _openStory(story),
        );
      },
    );
  }
  // ── Data fetchers ─────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> _fetchWithProgress(
    String uid,
    List<QueryDocumentSnapshot> docs, {
    required bool fromLibrary,
  }) async {
    final results = <Map<String, dynamic>>[];
    for (final doc in docs) {
      final storyId = doc.id;
      try {
        final storyDoc =
            await FirebaseFirestore.instance.collection('stories').doc(storyId).get();
        if (!storyDoc.exists) continue;
        final storyData = storyDoc.data() as Map<String, dynamic>;
        final storyType = storyData['storyType'] as String? ?? '';
        // Fetch reading progress
        final progressDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('readingProgress')
            .doc(storyId)
            .get();
        int lastChapter = 0;
        int totalChapters = 0;
        bool hasRead = false;
        String status = 'not_started';
        double progressPercent = 0.0;
        if (progressDoc.exists) {
          final p = progressDoc.data() as Map<String, dynamic>;
          lastChapter = (p['lastChapterNumber'] as int?) ?? 0;
          totalChapters = (p['totalChapters'] as int?) ?? 0;
          hasRead = (p['hasRead'] as bool?) ?? false;
          status = (p['status'] as String?) ?? status;
          progressPercent =
              ((p['progressPercent'] as num?)?.toDouble() ?? 0.0).clamp(0.0, 1.0);
        }
        // For novels, always get the real published chapter count
        if (storyType == 'Novel') {
          try {
            final countSnap = await FirebaseFirestore.instance
                .collection('stories')
                .doc(storyId)
                .collection('chapters')
                .where('isPublished', isEqualTo: true)
                .count()
                .get();
            totalChapters = countSnap.count ?? totalChapters;
          } catch (_) {}
        } else {
          // Short story / Poetry: always 1 total
          totalChapters = 1;
          if (lastChapter < 1) lastChapter = hasRead ? 1 : 0;
        }
        results.add({
          ...storyData,
          'storyId': storyId,
          'lastChapterNumber': lastChapter,
          'totalChapters': totalChapters,
          'hasRead': hasRead,
          'status': status.isNotEmpty
              ? status
              : (hasRead
                  ? 'completed'
                  : (lastChapter > 0 ? 'in_progress' : 'not_started')),
          'progressPercent': progressPercent,
        });
      } catch (e) {
        debugPrint('Error fetching story $storyId: $e');
      }
    }
    return results;
  }
  // ── Open story ────────────────────────────────────────────────────────────
  Future<void> _openStory(Map<String, dynamic> storyData) async {
    final user = FirebaseAuth.instance.currentUser;
    final storyType = storyData['storyType'] as String? ?? 'Short Story';
    final storyId = storyData['storyId'] as String? ?? '';
    if (user != null && storyId.isNotEmpty) {
      _saveLastOpened(storyId);
    }
    if (storyType == 'Novel' && storyId.isNotEmpty) {
      try {
        // Prefer lastChapterNumber if exists, otherwise 0 (Prologue) if present
        int chapterToOpen = storyData['lastChapterNumber'] as int? ?? 0;
        // Try to open exactly the last seen chapter
        QuerySnapshot chaptersSnap = await FirebaseFirestore.instance
            .collection('stories')
            .doc(storyId)
            .collection('chapters')
            .where('isPublished', isEqualTo: true)
            .where('chapterNumber', isEqualTo: chapterToOpen)
            .limit(1)
            .get();
        if (chaptersSnap.docs.isEmpty) {
          // Try prologue if chapterToOpen wasn't 0
          if (chapterToOpen != 0) {
            final proSnap = await FirebaseFirestore.instance
                .collection('stories')
                .doc(storyId)
                .collection('chapters')
                .where('isPublished', isEqualTo: true)
                .where('chapterNumber', isEqualTo: 0)
                .limit(1)
                .get();
            if (proSnap.docs.isNotEmpty) {
              chaptersSnap = proSnap;
              chapterToOpen = 0;
            }
          }
        }
        late QuerySnapshot fallbackSnap;
        if (chaptersSnap.docs.isEmpty) {
          fallbackSnap = await FirebaseFirestore.instance
              .collection('stories')
              .doc(storyId)
              .collection('chapters')
              .where('isPublished', isEqualTo: true)
              .orderBy('chapterNumber')
              .limit(1)
              .get();
        }
        final finalSnap = chaptersSnap.docs.isNotEmpty ? chaptersSnap : fallbackSnap;
        if (finalSnap.docs.isNotEmpty) {
          final chapterData = finalSnap.docs.first.data() as Map<String, dynamic>;
          final payload = {
            ...storyData,
            'title': chapterData['title'] ??
                chapterData['contentType'] ??
                (chapterData['chapterNumber'] == 0 ? 'Prologue' : 'Chapter'),
            'body': chapterData['body'] ?? '',
            'content': chapterData['content'],
            'chapterNumber': chapterData['chapterNumber'] ?? 0,
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
    // Non-novels
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
    } catch (_) {}
  }
  // ── Empty state ───────────────────────────────────────────────────────────
  Widget _buildEmptyState({required bool isCollection}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
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
              isCollection ? 'Your collection is empty' : 'No recent reads yet',
              style: GoogleFonts.dmSerifDisplay(
                fontSize: 18,
                color: AppTheme.inkEspresso,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isCollection
                  ? 'Save stories from Home to fill it up!'
                  : 'Open a story to start your reading history!',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: AppTheme.inkUmber.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// ─── Story card ───────────────────────────────────────────────────────────────
class _LibraryStoryCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;
  const _LibraryStoryCard({
    required this.data,
    required this.onTap,
  });
  // ── Status & Progress Helpers ──────────────────────────────────────────────
  String get _statusFromDB => (data['status'] as String?) ?? '';
  int get _lastChapter => (data['lastChapterNumber'] as int?) ?? 0;
  int get _totalChapters => (data['totalChapters'] as int?) ?? 0;
  bool get _isNovel => (data['storyType'] as String?) == 'Novel';
  bool get _hasRead => (data['hasRead'] as bool?) ?? false;
  double get _progressPercentSmooth =>
      ((data['progressPercent'] as num?)?.toDouble() ?? _derivedProgressValue)
          .clamp(0.0, 1.0);
  bool get _isCompleted {
    if (_statusFromDB.isNotEmpty) {
      return _statusFromDB == 'completed';
    }
    if (_isNovel) {
      return _totalChapters > 0 &&
          _lastChapter >= _totalChapters - 1 &&
          _progressPercentSmooth >= 0.999;
    }
    return _hasRead || _progressPercentSmooth >= 0.999;
  }
  bool get _isStarted {
    if (_statusFromDB.isNotEmpty) {
      return _statusFromDB == 'in_progress' || _statusFromDB == 'completed';
    }
    return _isCompleted || _lastChapter > 0 || _hasRead || _progressPercentSmooth > 0.0;
  }
  double get _derivedProgressValue {
    if (_isNovel) {
      if (_totalChapters <= 0) return 0.0;
      return (_lastChapter / _totalChapters).clamp(0.0, 1.0);
    }
    return _hasRead ? 1.0 : (_statusFromDB == 'in_progress' ? 0.5 : 0.0);
  }
  double get _progressValue => _isCompleted ? 1.0 : _progressPercentSmooth;
  String get _progressLabel {
    if (_statusFromDB == 'completed' || _isCompleted) {
      return 'Completed';
    }
    if (_statusFromDB == 'not_started' || _statusFromDB.isEmpty && !_isStarted) {
      return 'Not started';
    }
    if (_isNovel && _totalChapters > 0) {
      final ch = _lastChapter; // index aligned (0 = prologue)
      return 'Ch $ch of $_totalChapters';
    }
    return 'In Progress';
  }
  Color _coverColor(String genre) {
    switch (genre.toLowerCase()) {
      case 'romance':
        return const Color(0xFFF3D1D1);
      case 'mystery':
      case 'detective':
        return const Color(0xFFD5D6EA);
      case 'fantasy':
      case 'adventure':
        return const Color(0xFFD1E7DD);
      case 'sci-fi':
        return const Color(0xFFD1DCE7);
      case 'horror':
        return const Color(0xFFE7D5D5);
      case 'thriller':
        return const Color(0xFFE7E2D5);
      case 'drama':
        return const Color(0xFFE7D5E2);
      case 'poetry':
        return const Color(0xFFF0E6D3);
      default:
        return AppTheme.inkBgCard;
    }
  }
  @override
  Widget build(BuildContext context) {
    final genre = (data['genre'] as String?) ?? 'Fantasy';
    final storyType = (data['storyType'] as String?) ?? '';
    final title = (data['title'] as String?) ?? 'Untitled';
    final cover = _coverColor(genre);
    final percentLabel = '${(_progressValue * 100).round()}%';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Cover ───────────────────────────────────
            Stack(
              children: [
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: cover,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(18),
                    ),
                  ),
                  child: Center(
                    child: Opacity(
                      opacity: 0.4,
                      child: Icon(
                        PostScreenUtils.getGenreIcon(genre),
                        size: 48,
                        color: AppTheme.inkEspresso,
                      ),
                    ),
                  ),
                ),
                // Status badge (top-left)
                Positioned(
                  top: 10,
                  left: 10,
                  child: _StatusBadge(
                    isCompleted: _isCompleted,
                    isStarted: _isStarted,
                    statusFromDB: _statusFromDB,
                  ),
                ),
              ],
            ),
            // ── Info ─────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 14,
                        color: AppTheme.inkEspresso,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 11),
                    // Type · Genre
                    Text(
                      storyType.isNotEmpty && genre.isNotEmpty
                          ? '$genre · $storyType'
                          : genre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        fontSize: 10,
                        color: AppTheme.inkUmber.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 11),
                    // Progress bar + label
                    _ProgressSection(
                      isCompleted: _isCompleted,
                      isStarted: _isStarted,
                      progressValue: _progressValue,
                      progressLabel: _progressLabel,
                      rightPercentLabel:
                          percentLabel, // keep right 100% text like screenshot
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Status badge ──────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final bool isCompleted;
  final bool isStarted;
  final String statusFromDB;
  const _StatusBadge({
    required this.isCompleted,
    required this.isStarted,
    required this.statusFromDB,
  });
  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color dotColor;
    final String label;
    if (statusFromDB == 'completed' || isCompleted) {
      bg = const Color(0xFFE8F5E9);
      dotColor = const Color(0xFF4CAF50);
      label = 'Completed';
    } else if (statusFromDB == 'in_progress' || isStarted) {
      bg = const Color(0xFFFFF8E1);
      dotColor = AppTheme.inkGold;
      label = 'In Progress';
    } else {
      bg = AppTheme.inkBgCard;
      dotColor = AppTheme.inkUmber.withValues(alpha: 0.4);
      label = 'Unread';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: (statusFromDB == 'completed' || isCompleted)
                  ? const Color(0xFF388E3C)
                  : (statusFromDB == 'in_progress' || isStarted)
                      ? AppTheme.inkUmber
                      : AppTheme.inkUmber.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
// ── Progress section ──────────────────────────────────────────────────────────
class _ProgressSection extends StatelessWidget {
  final bool isCompleted;
  final bool isStarted;
  final double progressValue;
  final String progressLabel;
  final String? rightPercentLabel;
  const _ProgressSection({
    required this.isCompleted,
    required this.isStarted,
    required this.progressValue,
    required this.progressLabel,
    this.rightPercentLabel,
  });
  @override
  Widget build(BuildContext context) {
    final Color barColor = isCompleted
        ? const Color(0xFF4CAF50)
        : isStarted
            ? AppTheme.inkMaroon
            : AppTheme.inkUmber.withValues(alpha: 0.2);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              isCompleted ? Icons.check_circle_outline : Icons.auto_stories_outlined,
              size: 11,
              color:
                  isCompleted ? const Color(0xFF4CAF50) : AppTheme.inkUmber.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                progressLabel,
                style: GoogleFonts.manrope(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isCompleted
                      ? const Color(0xFF388E3C)
                      : AppTheme.inkUmber.withValues(alpha: 0.7),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isCompleted)
              const Icon(Icons.check, size: 11, color: Color(0xFF4CAF50)),
            if (!isCompleted && isStarted && rightPercentLabel != null)
              Text(
                rightPercentLabel!,
                style: GoogleFonts.manrope(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.inkMaroon,
                ),
              ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progressValue,
            minHeight: 4,
            backgroundColor: AppTheme.inkUmber.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}