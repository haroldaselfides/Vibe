import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/new_app_theme.dart';
import '../theme/app_typography.dart';
import 'package:vibewrite_app/main_tabs/post/post.dart';
import 'package:vibewrite_app/story/read_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedGenreIndex = 0;

  String _userInitials = '';
  String _firstName = '';
  String _lastName = '';
  bool _isLoadingUserData = true;

  final Set<String> _savedStoryIds = {};

  final List<String> _genres = [
    'All', 'Romance', 'Mystery', 'Fantasy', 'Sci-Fi'
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadSavedStoryIds();
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
          _userInitials =
              _generateInitialsFromEmail(currentUser.email ?? '');
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      _userInitials = 'U';
    } finally {
      if (mounted) setState(() => _isLoadingUserData = false);
    }
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

  Future<void> _toggleLibrary(
    String storyId,
    Map<String, dynamic> storyData,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: AppTheme.surfaceColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            icon: Icon(
              Icons.login_outlined,
              color: AppTheme.inkMaroon,
              size: 48,
            ),
            title: Text(
              'Login Required',
              style: AppTypography.headingSm.copyWith(
                color: AppTheme.inkEspresso,
              ),
              textAlign: TextAlign.center,
            ),
            content: Text(
              'Please log in to save stories',
              style: AppTypography.bodyMd.copyWith(
                color: AppTheme.inkUmber,
              ),
              textAlign: TextAlign.center,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: AppTypography.labelMd.copyWith(
                    color: AppTheme.inkMaroon,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushNamed('/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.inkMaroon,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  'Go to Login',
                  style: AppTypography.labelMd.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          );
        },
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
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                backgroundColor: AppTheme.surfaceColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                icon: Icon(
                  Icons.bookmark_outline,
                  color: AppTheme.inkMaroon,
                  size: 48,
                ),
                title: Text(
                  'Removed',
                  style: AppTypography.headingSm.copyWith(
                    color: AppTheme.inkEspresso,
                  ),
                  textAlign: TextAlign.center,
                ),
                content: Text(
                  'Story removed from Library',
                  style: AppTypography.bodyMd.copyWith(
                    color: AppTheme.inkUmber,
                  ),
                  textAlign: TextAlign.center,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'OK',
                      style: AppTypography.labelMd.copyWith(
                        color: AppTheme.inkMaroon,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        }
      } else {
        await ref.set({
          'storyId': storyId,
          'title': storyData['title'] ?? '',
          'genre': storyData['genre'] ?? '',
          'authorUsername': storyData['authorUsername'] ?? '',
          'authorEmail': storyData['authorEmail'] ?? '',
          'storyType': storyData['storyType'] ?? 'Short Story',
          'savedAt': FieldValue.serverTimestamp(),
        });
        if (mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                backgroundColor: AppTheme.surfaceColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                icon: Icon(
                  Icons.bookmark_rounded,
                  color: Colors.green,
                  size: 48,
                ),
                title: Text(
                  'Saved!',
                  style: AppTypography.headingSm.copyWith(
                    color: AppTheme.inkEspresso,
                  ),
                  textAlign: TextAlign.center,
                ),
                content: Text(
                  'Story added to Library',
                  style: AppTypography.bodyMd.copyWith(
                    color: AppTheme.inkUmber,
                  ),
                  textAlign: TextAlign.center,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'OK',
                      style: AppTypography.labelMd.copyWith(
                        color: AppTheme.inkMaroon,
                      ),
                    ),
                  ),
                ],
              );
            },
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
      debugPrint('Error toggling library: $e');
    }
  }

  Future<void> _openStory(Map<String, dynamic> storyData) async {
    final storyType = storyData['storyType'] as String? ?? 'Short Story';
    final storyId   = storyData['storyId']   as String? ?? '';

    final user = FirebaseAuth.instance.currentUser;
    if (user != null && storyId.isNotEmpty) {
      _saveLastOpened(user.uid, storyId);
    }

    if (storyType == 'Novel' && storyId.isNotEmpty) {
      try {
        final chaptersRef = FirebaseFirestore.instance
          .collection('stories')
          .doc(storyId)
          .collection('chapters')
          .where('isPublished', isEqualTo: true)
          .orderBy('chapterNumber')
          .limit(1);

        final snapshot = await chaptersRef.get();
        if (snapshot.docs.isNotEmpty) {
          final chapterData = snapshot.docs.first.data();
          chapterData['storyId']   = storyId;
          chapterData['storyType'] = storyData['storyType'];
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

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StoryReadScreen(story: storyData),
      ),
    );
  }

  static Future<void> _saveLastOpened(String uid, String storyId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
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

  String _generateInitials(String first, String last) {
    String i = '';
    if (first.isNotEmpty) i += first[0].toUpperCase();
    if (last.isNotEmpty)  i += last[0].toUpperCase();
    return i.isEmpty ? 'U' : i;
  }

  String _generateInitialsFromEmail(String email) =>
      email.isEmpty ? 'U' : email[0].toUpperCase();

  Color _genreTagColor(String genre) {
    switch (genre) {
      case 'Romance': return AppTheme.inkTagRomance;
      case 'Mystery': return AppTheme.inkTagMystery;
      case 'Fantasy': return AppTheme.inkTagFantasy;
      case 'Sci-Fi':  return AppTheme.inkTagSciFi;
      default:        return AppTheme.inkSage;
    }
  }

  Query<Map<String, dynamic>> get _storiesQuery =>
      FirebaseFirestore.instance
          .collection('stories')
          .orderBy('createdAt', descending: true)
          .limit(50);

  String get _selectedGenre => _genres[_selectedGenreIndex];

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(color: AppTheme.surfaceColor),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(child: _buildFeaturedSection()),
              SliverToBoxAdapter(child: _buildGenreChips()),
              SliverToBoxAdapter(
                child: _buildSectionHeader('Recent Stories', 'See all'),
              ),
              SliverToBoxAdapter(child: _buildRecentStoriesStream()),
              SliverToBoxAdapter(
                child: SizedBox(
                    height: MediaQuery.of(context).padding.bottom + 80),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
       mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset(
            'assets/images/vibe_header.png',
            height: 50,
            // fit: BoxFit.contain,
          ),
          // Avatar
          GestureDetector(
            onTap: () {
              Navigator.of(context).pushNamed('/profile');
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.inkMaroon,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.inkMaroon.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: _isLoadingUserData
                    ? const SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        _userInitials,
                        // labelMd — Manrope 12 bold, white on terracotta
                        style: AppTypography.labelMd.copyWith(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Featured Banner ────────────────────────────────────────────────────────
  // Place banner.png in assets/images/. The image fills the card; the
  // dark gradient overlay keeps the text legible over any image content.
  Widget _buildFeaturedSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      height: 220,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Banner image ───────────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            child: Image.asset(
              'assets/images/vibe_banner.png',
              fit: BoxFit.cover,
            ),
          ),

          // ── Dark scrim so text stays readable over any image ───────────
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          ),

          // ── Text overlay ───────────────────────────────────────────────
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.inkMaroon
                            .withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(
                            AppTheme.radiusXs),
                        border: Border.all(
                          color: AppTheme.inkMaroon
                              .withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'FEATURED',
                        style: AppTypography.labelMd.copyWith(
                          color: AppTheme.inkIvory,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Start Your\nWriting Journey',
                      style: AppTypography.headingLg.copyWith(
                        color: AppTheme.inkIvory,
                        fontSize: 26,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Explore new stories',
                      style: AppTypography.bodyMd.copyWith(
                        color: AppTheme.inkIvory
                            .withValues(alpha: 0.85),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const PostScreen()),
                      ),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.maroon,
                          borderRadius: BorderRadius.circular(
                              AppTheme.radiusSm),
                          boxShadow: AppTheme.softShadow,
                        ),
                        child: const Center(
                          child: Icon(Icons.arrow_forward,
                              color: AppTheme.inkGold, size: 18),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.inkMaroon
                    : AppTheme.inkMaroon.withValues(alpha: 0.10),
                borderRadius:
                    BorderRadius.circular(AppTheme.radiusFull),
              ),
              child: Text(
                _genres[index],
                // labelMd — Manrope 12 bold
                style: AppTypography.labelMd.copyWith(
                  color: isSelected
                      ? Colors.white
                      : AppTheme.inkMaroon
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
          // headingSm — DM Serif Display 20
          Text(
            title,
            style: AppTypography.headingSm.copyWith(
              color: AppTheme.inkEspresso,
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Text(
              action,
              // labelMd — Manrope 12 bold, terracotta
              style: AppTypography.labelMd.copyWith(
                color: AppTheme.inkMaroon
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
                valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.inkMaroon),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.inkEspresso,
                borderRadius:
                    BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: AppTheme.inkMaroon, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Could not load stories. Check Firestore rules.',
                      // bodySm — Manrope 12
                      style: AppTypography.bodySm.copyWith(
                        color: AppTheme.inkUmber,
                      ),
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
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 24),
            child: Column(
              children: [
                Icon(Icons.auto_stories_outlined,
                    size: 48,
                    color: AppTheme.inkUmber.withValues(alpha: 0.3)),
                const SizedBox(height: 12),
                Text(
                  'No stories yet.',
                  // bodyLg — Manrope 16 medium
                  style: AppTypography.bodyLg.copyWith(
                    color: AppTheme.inkUmber.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Be the first to write one!',
                  // bodyMd — Manrope 14
                  style: AppTypography.bodyMd.copyWith(
                    color: AppTheme.inkUmber.withValues(alpha: 0.45),
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const PostScreen()),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.inkMaroon,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusFull),
                    ),
                    child: Text(
                      'Write a Story',
                      // labelMd — Manrope 12 bold, white
                      style: AppTypography.labelMd.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final filtered = _selectedGenre == 'All'
            ? docs
            : docs
                .where((d) => d.data()['genre'] == _selectedGenre)
                .toList();

        if (filtered.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 24),
            child: Column(
              children: [
                Icon(Icons.auto_stories_outlined,
                    size: 48,
                    color: AppTheme.inkUmber.withValues(alpha: 0.3)),
                const SizedBox(height: 12),
                Text(
                  'No $_selectedGenre stories yet.',
                  style: AppTypography.bodyLg.copyWith(
                    color: AppTheme.inkUmber.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Be the first to write one!',
                  style: AppTypography.bodyMd.copyWith(
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
              final data    = doc.data();
              final storyId = doc.id;
              return GestureDetector(
                onTap: () => _openStory({...data, 'storyId': storyId}),
                child: _buildStoryCard(data, storyId),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // ── Story card ─────────────────────────────────────────────────────────────
  Widget _buildStoryCard(Map<String, dynamic> story, String storyId) {
    final genre       = story['genre']       as String? ?? 'General';
    final title       = story['title']       as String? ?? 'Untitled';
    final wordCount   = story['wordCount']   as int?    ?? 0;
    final storyType   = story['storyType']   as String? ?? 'Short Story';
    final contentType = story['contentType'] as String? ?? '';
    final tagColor    = _genreTagColor(genre);
    final isSaved     = _savedStoryIds.contains(storyId);

    final authorUsername = story['authorUsername'] as String?;
    final authorEmail    = story['authorEmail']    as String? ?? '';
    final authorHandle   = (authorUsername != null &&
            authorUsername.trim().isNotEmpty)
        ? '@${authorUsername.trim()}'
        : '@${authorEmail.split('@').first}';

    IconData genreIcon;
    switch (genre) {
      case 'Romance':  genreIcon = Icons.favorite_outline;     break;
      case 'Mystery':  genreIcon = Icons.search_outlined;       break;
      case 'Fantasy':  genreIcon = Icons.auto_awesome_outlined; break;
      case 'Sci-Fi':   genreIcon = Icons.public_outlined;       break;
      case 'Horror':   genreIcon = Icons.nights_stay_outlined;  break;
      case 'Thriller': genreIcon = Icons.bolt_outlined;         break;
      default:         genreIcon = Icons.article_outlined;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.inkBgMain,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.borderColor, width: 1),
        boxShadow: AppTheme.softShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Main row: genre icon + story info + chevron ───────────────
            Row(
              children: [
                Container(
                  width: 52,
                  height: 62,
                  decoration: BoxDecoration(
                    color: tagColor.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusXs),
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
                      // Story title — headingSm weight, espresso
                      Text(
                        title,
                        style: AppTypography.bodyLg.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.inkEspresso,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Author handle — authorName (Manrope 13 semi-bold)
                      Text(
                        authorHandle,
                        style: AppTypography.authorName.copyWith(
                          color: AppTheme.inkUmber,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // ── FIXED: Metadata row with horizontal scroll ───────
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            // Genre tag
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: tagColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(
                                    AppTheme.radiusXs),
                              ),
                              child: Text(
                                genre,
                                style: AppTypography.labelSm.copyWith(
                                  color: tagColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Story type tag
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.inkUmber
                                    .withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(
                                    AppTheme.radiusXs),
                              ),
                              child: Text(
                                contentType.isNotEmpty
                                    ? '$storyType · $contentType'
                                    : storyType,
                                style: AppTypography.labelSm.copyWith(
                                  color: AppTheme.inkUmber
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Icon(Icons.text_fields_outlined,
                                size: 12, color: AppTheme.inkUmber),
                            const SizedBox(width: 3),
                            // Word count — bodySm
                            Text(
                              '$wordCount w',
                              style: AppTypography.bodySm.copyWith(
                                color: AppTheme.inkUmber,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right,
                    color: AppTheme.inkUmber, size: 20),
              ],
            ),

            // ── Add to Library button ─────────────────────────────────────
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _toggleLibrary(storyId, story),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: isSaved
                      ? AppTheme.inkMaroon.withValues(alpha: 0.12)
                      : AppTheme.inkMaroon,
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusXs),
                  border: isSaved
                      ? Border.all(
                          color: AppTheme.inkMaroon
                              .withValues(alpha: 0.4),
                          width: 1,
                        )
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isSaved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_add_outlined,
                      size: 15,
                      color: isSaved
                          ? AppTheme.inkMaroon
                          : Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isSaved ? 'Saved to Library' : 'Add to Library',
                      // labelMd — Manrope 12 bold
                      style: AppTypography.labelMd.copyWith(
                        color: isSaved
                            ? AppTheme.inkMaroon
                            : Colors.white,
                      ),
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