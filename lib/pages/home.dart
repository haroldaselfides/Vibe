import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import 'package:vibewrite_app/main_tabs/post/post.dart';
import 'package:vibewrite_app/story/read_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedGenreIndex = 0;

  // User data from Firebase
  String _userInitials = '';
  String _firstName = '';
  String _lastName = '';
  bool _isLoadingUserData = true;

  final List<String> _genres = ['All', 'Romance', 'Mystery', 'Fantasy', 'Sci-Fi'];

  

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data();
          _firstName = userData?['firstname'] ?? '';
          _lastName  = userData?['lastname']  ?? '';
          _userInitials = _generateInitials(_firstName, _lastName);
        } else {
          _userInitials = _generateInitialsFromEmail(currentUser.email ?? '');
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      _userInitials = 'U';
    } finally {
      if (mounted) setState(() => _isLoadingUserData = false);
    }
  }

  String _generateInitials(String first, String last) {
    String i = '';
    if (first.isNotEmpty) i += first[0].toUpperCase();
    if (last.isNotEmpty)  i += last[0].toUpperCase();
    return i.isEmpty ? 'U' : i;
  }

  String _generateInitialsFromEmail(String email) =>
      email.isEmpty ? 'U' : email[0].toUpperCase();

  // ── Genre tag color ────────────────────────────────────────────────────────
  Color _genreTagColor(String genre) {
    switch (genre) {
      case 'Romance': return AppTheme.inkTagRomance;
      case 'Mystery': return AppTheme.inkTagMystery;
      case 'Fantasy': return AppTheme.inkTagFantasy;
      case 'Sci-Fi':  return AppTheme.inkTagSciFi;
      default:        return AppTheme.inkSage;
    }
  }

  // ── Firestore query for recent stories ────────────────────────────────────
  // Always fetch ordered by createdAt only (no composite index needed).
  // Genre is filtered client-side in _buildRecentStoriesStream.
  Query<Map<String, dynamic>> get _storiesQuery =>
      FirebaseFirestore.instance
          .collection('stories')
          .orderBy('createdAt', descending: true)
          .limit(50);

  String get _selectedGenre => _genres[_selectedGenreIndex];

  // ── Navigate to read screen ────────────────────────────────────────────────
  // ── Navigate to read screen ────────────────────────────────────────────────
  // UPDATED: Handles novels by fetching the first chapter
  Future<void> _openStory(Map<String, dynamic> storyData) async {
    final storyType = storyData['storyType'] as String? ?? 'Short Story';
    final storyId = storyData['storyId'] as String? ?? '';
    
    // If it's a novel, fetch the first chapter instead
    if (storyType == 'Novel' && storyId.isNotEmpty) {
      try {
        final chaptersRef = FirebaseFirestore.instance
            .collection('stories')
            .doc(storyId)
            .collection('chapters')
            .orderBy('chapterNumber')
            .limit(1);
        
        final snapshot = await chaptersRef.get();
        if (snapshot.docs.isNotEmpty) {
          final chapterData = snapshot.docs.first.data();
          chapterData['storyId'] = storyId; // Add storyId for chapters modal
          chapterData['storyType'] = storyData['storyType']; // ← ADD THIS LINE
          if (!mounted) return;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => StoryReadScreen(story: chapterData),
            ),
          );
          return;
        }
      } catch (e) {
        debugPrint('Error fetching chapter: $e');
      }
    }
    
    // For short stories or if no chapters found, open normally
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StoryReadScreen(story: storyData),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(color: AppTheme.inkBgMain),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(child: _buildSearchBar()),
              SliverToBoxAdapter(child: _buildFeaturedSection()),
              SliverToBoxAdapter(child: _buildGenreChips()),
              SliverToBoxAdapter(child: _buildSectionHeader('Recent Stories', 'See all')),
              SliverToBoxAdapter(child: _buildRecentStoriesStream()),
              SliverToBoxAdapter(
                child: SizedBox(height: MediaQuery.of(context).padding.bottom + 80),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'VIBEWRITE',
            style: TextStyle(
              fontSize: 20,
              fontFamily: 'Paytone One',
              fontWeight: FontWeight.bold,
              color: AppTheme.inkEspresso,
            ),
          ),
          GestureDetector(
            onTap: () => ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('Profile tapped'))),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.inkTerracotta,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.inkTerracotta.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: _isLoadingUserData
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        _userInitials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Search Bar ─────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: AppTheme.inkCanvas,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.inkCanvas, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppTheme.inkEspresso.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            const Icon(Icons.search, color: AppTheme.inkUmber, size: 20),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Search stories, users...',
                style: TextStyle(color: AppTheme.inkUmber, fontSize: 14),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.inkUmber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.tune, color: AppTheme.inkUmber, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  // ── Featured Section ───────────────────────────────────────────────────────
  Widget _buildFeaturedSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      height: 220,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: AppTheme.inkCanvas,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.inkUmber.withValues(alpha: 0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  Positioned(
                    top: -30, right: -30,
                    child: Container(
                      width: 120, height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.inkTerracotta.withValues(alpha: 0.12),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 20, right: 50,
                    child: Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.inkGold.withValues(alpha: 0.10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.inkTerracotta.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'FEATURED',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.inkTerracotta,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Start Your\nWriting Journey',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.inkEspresso,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Explore new stories',
                      style: TextStyle(fontSize: 13, color: AppTheme.inkUmber),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PostScreen()),
                      ),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.inkTerracotta,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Genre Chips ────────────────────────────────────────────────────────────
  Widget _buildGenreChips() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _genres.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = _selectedGenreIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedGenreIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.inkTerracotta
                    : AppTheme.inkTerracotta.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _genres[index],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppTheme.inkTerracotta,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Section Header ─────────────────────────────────────────────────────────
  Widget _buildSectionHeader(String title, String action) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.inkEspresso,
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Text(
              action,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.inkTerracotta,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Recent Stories — live Firestore stream ─────────────────────────────────
  Widget _buildRecentStoriesStream() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _storiesQuery.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.inkTerracotta),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.inkCanvas,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: AppTheme.inkTerracotta, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Could not load stories. Check Firestore rules.',
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.inkUmber),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              children: [
                Icon(Icons.auto_stories_outlined,
                    size: 48,
                    color: AppTheme.inkUmber.withValues(alpha: 0.3)),
                const SizedBox(height: 12),
                Text(
                  'No stories yet.',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.inkUmber.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Be the first to write one!',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.inkUmber.withValues(alpha: 0.45),
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PostScreen()),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.inkTerracotta,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Write a Story',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // Filter by genre client-side (avoids composite Firestore index)
        final filtered = _selectedGenre == 'All'
            ? docs
            : docs.where((d) => d.data()['genre'] == _selectedGenre).toList();

        if (filtered.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              children: [
                Icon(Icons.auto_stories_outlined,
                    size: 48,
                    color: AppTheme.inkUmber.withValues(alpha: 0.3)),
                const SizedBox(height: 12),
                Text(
                  'No $_selectedGenre stories yet.',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.inkUmber.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Be the first to write one!',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.inkUmber.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: filtered.map((doc) {
              final data = doc.data();
              return GestureDetector(
                onTap: () => _openStory({
                  ...data,
                  'storyId': doc.id, // IMPORTANT
                }),
                child: _buildStoryCard(data),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // ── Story card (built from Firestore data) ────────────────────────────────
  Widget _buildStoryCard(Map<String, dynamic> story) {
    final genre     = story['genre']      as String? ?? 'General';
    final title     = story['title']      as String? ?? 'Untitled';
    final wordCount = story['wordCount']  as int?    ?? 0;
    final likes     = story['likes']      as int?    ?? 0;
    final tagColor  = _genreTagColor(genre);

    // Use stored username, fall back to email prefix
    final authorUsername = story['authorUsername'] as String?;
    final authorEmail    = story['authorEmail']    as String? ?? '';
    final authorHandle   = (authorUsername != null && authorUsername.trim().isNotEmpty)
        ? '@${authorUsername.trim()}'
        : '@${authorEmail.split('@').first}';

    IconData genreIcon;
    switch (genre) {
      case 'Romance':  genreIcon = Icons.favorite_outline;       break;
      case 'Mystery':  genreIcon = Icons.search_outlined;         break;
      case 'Fantasy':  genreIcon = Icons.auto_awesome_outlined;   break;
      case 'Sci-Fi':   genreIcon = Icons.public_outlined;         break;
      case 'Horror':   genreIcon = Icons.nights_stay_outlined;    break;
      case 'Thriller': genreIcon = Icons.bolt_outlined;           break;
      default:         genreIcon = Icons.article_outlined;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.inkBgMain,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.inkCanvas, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppTheme.inkEspresso.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 62,
              decoration: BoxDecoration(
                color: tagColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: tagColor.withValues(alpha: 0.2)),
              ),
              child: Icon(genreIcon, color: tagColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.inkEspresso,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    authorHandle,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.inkUmber),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: tagColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          genre,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: tagColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.text_fields_outlined,
                          size: 12, color: AppTheme.inkUmber),
                      const SizedBox(width: 3),
                      Text(
                        '$wordCount w',
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.inkUmber),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.favorite_outline,
                          size: 12, color: AppTheme.inkUmber),
                      const SizedBox(width: 3),
                      Text(
                        '$likes',
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.inkUmber),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppTheme.inkUmber, size: 20),
          ],
        ),
      ),
    );
  }
}