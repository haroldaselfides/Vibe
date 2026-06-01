import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../main_tabs/post/post_screen_utils.dart';
import 'edit_profile.dart';
import '../pages/settings.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;
  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    final bool isMe = widget.userId == null ||
        widget.userId == FirebaseAuth.instance.currentUser?.uid;
    _tabController = TabController(length: isMe ? 2 : 1, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final targetUid = widget.userId ?? currentUser?.uid;
    final bool isMe = targetUid == currentUser?.uid;

    if (targetUid == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view your profile')),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.inkBgMain,
      body: CustomScrollView(
        slivers: [
          // ═══════════════════════════════════════════════════════════════
          // PROFILE HEADER — Botanical Illustrated Style
          // ═══════════════════════════════════════════════════════════════
          SliverAppBar(
            expandedHeight: 360,
            automaticallyImplyLeading: widget.userId != null,
            pinned: true,
            backgroundColor: AppTheme.inkBgMain,
            elevation: 0,
            // Settings icon top-right (only on own profile)
            actions: isMe
                ? [
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.inkBgCard,
                          border: Border.all(
                            color: AppTheme.inkUmber.withValues(alpha: 0.15),
                          ),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.settings_outlined,
                              size: 20, color: AppTheme.inkEspresso),
                          onPressed: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => const SettingsScreen(),
                            ));
                          },
                        ),
                      ),
                    ),
                  ]
                : null,
            flexibleSpace: FlexibleSpaceBar(
              background: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(targetUid)
                    .snapshots(),
                builder: (context, snapshot) {
                  final userData =
                      snapshot.data?.data() as Map<String, dynamic>?;

                  final bool isPublic = userData?['isPublic'] ?? true;
                  if (!isMe && !isPublic) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_outline,
                              size: 48, color: AppTheme.inkUmber),
                          SizedBox(height: 12),
                          Text('This profile is private',
                              style: TextStyle(color: AppTheme.inkUmber)),
                        ],
                      ),
                    );
                  }

                  final displayName = userData?['displayName'] ??
                      (isMe ? currentUser?.displayName : 'Writer') ??
                      'Writer';
                  final username = userData?['username'] ?? 'user';
                  final bio = userData?['bio'] ?? 'No bio yet.';
                  final photoUrl = userData?['photoUrl'] ??
                      (isMe ? currentUser?.photoURL : null);

                  return _BotanicalProfileHeader(
                    displayName: displayName,
                    username: username,
                    bio: bio,
                    photoUrl: photoUrl,
                    isMe: isMe,
                    userData: {
                      'displayName': displayName,
                      'username': username,
                      'bio': bio,
                      'photoUrl': photoUrl,
                    },
                    onEditProfile: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => EditProfileScreen(userData: {
                          'displayName': displayName,
                          'username': username,
                          'bio': bio,
                          'photoUrl': photoUrl,
                        }),
                      ));
                    },
                  );
                },
              ),
            ),
          ),

          // ═══════════════════════════════════════════════════════════════
          // TAB NAVIGATION
          // ═══════════════════════════════════════════════════════════════
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverTabBarDelegate(
              isMe: isMe,
              tabController: _tabController,
              onTabChanged: (index) {
                setState(() => _selectedTabIndex = index);
              },
            ),
          ),

          // ═══════════════════════════════════════════════════════════════
          // CONTENT GRID
          // ═══════════════════════════════════════════════════════════════
          if (_selectedTabIndex == 0)
            _buildStoriesGrid(targetUid)
          else
            _buildReadingListGrid(targetUid),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────

  Widget _buildStoriesGrid(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('stories')
          .where('authorId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SliverToBoxAdapter(
            child: Center(
                child: Padding(
              padding: EdgeInsets.all(40.0),
              child:
                  CircularProgressIndicator(color: AppTheme.inkTerracotta),
            )),
          );
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return _buildEmptySliver('No stories published yet');

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 16,
              childAspectRatio: 0.65,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildStoryCardFromDoc(docs[index]),
              childCount: docs.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildReadingListGrid(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('library')
          .orderBy('savedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SliverToBoxAdapter(
            child: Center(
                child:
                    CircularProgressIndicator(color: AppTheme.inkTerracotta)),
          );
        }
        final savedDocs = snapshot.data!.docs;
        if (savedDocs.isEmpty) return _buildEmptySliver('Your library is empty');

        return SliverPadding(
          padding: const EdgeInsets.all(10),
          sliver: SliverToBoxAdapter(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchStoriesFromLibrary(savedDocs),
              builder: (context, storySnap) {
                if (!storySnap.hasData) return const SizedBox.shrink();
                final stories = storySnap.data!;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 20,
                    childAspectRatio: 0.58,
                  ),
                  itemCount: stories.length,
                  itemBuilder: (context, index) =>
                      _buildReadingCard(stories[index]),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchStoriesFromLibrary(
      List<QueryDocumentSnapshot> libraryDocs) async {
    final results = <Map<String, dynamic>>[];
    for (final libDoc in libraryDocs) {
      final storyId = libDoc.id;
      final storyDoc = await FirebaseFirestore.instance
          .collection('stories')
          .doc(storyId)
          .get();
      if (storyDoc.exists) {
        results.add({...(storyDoc.data()!), 'storyId': storyId});
      }
    }
    return results;
  }

  Widget _buildReadingCard(Map<String, dynamic> data) {
    final genre = data['genre'] ?? 'Fantasy';
    final color = PostScreenUtils.getGenreTagColor(genre);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
                child: Icon(PostScreenUtils.getGenreIcon(genre),
                    color: color, size: 30)),
          ),
        ),
        const SizedBox(height: 4),
        Text(data['title'] ?? 'Untitled',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
      ],
    );
  }

  Widget _buildStoryCardFromDoc(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final genre = data['genre'] ?? 'Fantasy';
    return _buildStoryCard(
      title: data['title'] ?? 'Untitled',
      genre: genre,
      image: data['coverImageUrl'] ?? '',
      color: PostScreenUtils.getGenreTagColor(genre),
    );
  }

  Widget _buildEmptySliver(String message) {
    final isFavorites = message.contains('favorites');
    return SliverPadding(
      padding: const EdgeInsets.all(12),
      sliver: SliverToBoxAdapter(
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            color: AppTheme.inkBgCard,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isFavorites
                      ? Icons.favorite_border
                      : Icons.auto_stories_outlined,
                  size: 48,
                  color: AppTheme.inkTerracotta.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.inkUmber.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStoryCard({
    required String title,
    required String genre,
    required String image,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        // Decorative corner border matching the screenshot's story cards
        border: Border.all(
          color: AppTheme.inkUmber.withValues(alpha: 0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image or Placeholder
            Builder(
              builder: (context) {
                if (image.isEmpty) {
                  return Container(color: color.withValues(alpha: 0.8));
                }
                return Image.network(
                  image,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                            colors: [color.withValues(alpha: 0.8), color]),
                      ),
                    );
                  },
                );
              },
            ),

            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.5),
                    Colors.black.withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),

            // Decorative corner flourishes (matching screenshot)
            Positioned(
              top: 8,
              right: 8,
              child: _CornerFlourish(),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Title
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Divider + Genre Badge (matching screenshot layout)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Golden star divider
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 0.5,
                                color: Colors.amber.withOpacity(0.5),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6),
                              child: Icon(Icons.star_rounded,
                                  size: 10, color: Colors.amber),
                            ),
                            Expanded(
                              child: Container(
                                height: 0.5,
                                color: Colors.amber.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Genre Badge — centered like in screenshot
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            genre,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
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
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTANICAL PROFILE HEADER WIDGET
// Matches the illustrated parchment header in the screenshot.
// ─────────────────────────────────────────────────────────────────────────────

class _BotanicalProfileHeader extends StatelessWidget {
  const _BotanicalProfileHeader({
    required this.displayName,
    required this.username,
    required this.bio,
    required this.photoUrl,
    required this.isMe,
    required this.userData,
    required this.onEditProfile,
  });

  final String displayName;
  final String username;
  final String? photoUrl;
  final String bio;
  final bool isMe;
  final Map<String, dynamic> userData;
  final VoidCallback onEditProfile;

  @override
  Widget build(BuildContext context) {
    return Container(
      // Warm parchment background matching the screenshot
      color: AppTheme.inkBgMain,
      child: Stack(
        children: [
          // ── Botanical Illustrations ──────────────────────────────────

          // Top-left: large leaf sprig
          Positioned(
            top: 24,
            left: -12,
            child: _BotanicalLeafSprig(
              width: 140,
              height: 160,
              flipped: false,
              opacity: 0.55,
            ),
          ),

          // Top-right: wildflower / golden berry branch
          Positioned(
            top: 12,
            right: 8,
            child: _GoldenBerryBranch(
              width: 110,
              height: 120,
              opacity: 0.65,
            ),
          ),

          // Bottom-right: stacked books illustration
          Positioned(
            bottom: 60,
            right: -10,
            child: _StackedBooksIllustration(
              width: 140,
              height: 120,
            ),
          ),

          // ── Center Profile Content ───────────────────────────────────
          Positioned.fill(
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),

                  // Avatar
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 104,
                        height: 104,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.inkTerracotta,
                            width: 3,
                          ),
                          image: photoUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(photoUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          color: AppTheme.inkCanvas,
                        ),
                        child: photoUrl == null
                            ? const Icon(Icons.person,
                                size: 80, color: AppTheme.inkUmber)
                            : null,
                      ),
                      // Book badge
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.inkTerracotta,
                          border: Border.all(
                            color: AppTheme.inkBgMain,
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.book_rounded,
                          color: Colors.white,
                          size: 17,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Display Name
                  Text(
                    displayName,
                    style: Theme.of(context)
                        .textTheme
                        .displayMedium!
                        .copyWith(
                          color: AppTheme.inkEspresso,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 3),

                  // Username handle
                  Text(
                    '@$username',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.inkUmber.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Decorative golden divider (star + lines)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 80),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 0.8,
                            color: const Color(0xFFB8960C).withValues(alpha: 0.45),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(
                            Icons.star_rounded,
                            size: 12,
                            color: const Color(0xFFB8960C).withValues(alpha: 0.8),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 0.8,
                            color: const Color(0xFFB8960C).withValues(alpha: 0.45),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Bio
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Text(
                      bio,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.inkEspresso.withValues(alpha: 0.85),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Edit Profile Button
                  if (isMe)
                    GestureDetector(
                      onTap: onEditProfile,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.inkBgCard,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: AppTheme.inkUmber.withValues(alpha: 0.18),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person_outline,
                                size: 18, color: AppTheme.inkEspresso),
                            const SizedBox(width: 8),
                            Text(
                              'Edit Profile',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.inkEspresso,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DECORATIVE ILLUSTRATION WIDGETS
// Drawn with CustomPainter to match the botanical screenshot aesthetic.
// ─────────────────────────────────────────────────────────────────────────────

/// Left-side large leaf sprig
class _BotanicalLeafSprig extends StatelessWidget {
  final double width;
  final double height;
  final bool flipped;
  final double opacity;

  const _BotanicalLeafSprig({
    required this.width,
    required this.height,
    this.flipped = false,
    this.opacity = 0.6,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Transform.flip(
        flipX: flipped,
        child: CustomPaint(
          size: Size(width, height),
          painter: _LeafSprigPainter(),
        ),
      ),
    );
  }
}

class _LeafSprigPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stemPaint = Paint()
      ..color = const Color(0xFF8A9E7A)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final leafPaint = Paint()
      ..color = const Color(0xFF9EAF8E)
      ..style = PaintingStyle.fill;

    final leafOutlinePaint = Paint()
      ..color = const Color(0xFF7A9068)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    // Main stem — flowing curve from bottom-center upward to top-right
    final stemPath = Path()
      ..moveTo(size.width * 0.55, size.height * 0.95)
      ..cubicTo(
        size.width * 0.5, size.height * 0.7,
        size.width * 0.6, size.height * 0.45,
        size.width * 0.7, size.height * 0.1,
      );
    canvas.drawPath(stemPath, stemPaint);

    // Draw leaves along the stem
    _drawLeaf(canvas, leafPaint, leafOutlinePaint,
        Offset(size.width * 0.38, size.height * 0.78), 28, 14, -0.8);
    _drawLeaf(canvas, leafPaint, leafOutlinePaint,
        Offset(size.width * 0.62, size.height * 0.65), 32, 16, 0.4);
    _drawLeaf(canvas, leafPaint, leafOutlinePaint,
        Offset(size.width * 0.44, size.height * 0.52), 36, 18, -0.6);
    _drawLeaf(canvas, leafPaint, leafOutlinePaint,
        Offset(size.width * 0.68, size.height * 0.40), 30, 14, 0.5);
    _drawLeaf(canvas, leafPaint, leafOutlinePaint,
        Offset(size.width * 0.50, size.height * 0.28), 28, 13, -0.4);
    _drawLeaf(canvas, leafPaint, leafOutlinePaint,
        Offset(size.width * 0.72, size.height * 0.18), 22, 11, 0.6);

    // Secondary branch from mid-stem
    final branchPath = Path()
      ..moveTo(size.width * 0.53, size.height * 0.60)
      ..cubicTo(
        size.width * 0.35, size.height * 0.55,
        size.width * 0.20, size.height * 0.48,
        size.width * 0.10, size.height * 0.38,
      );
    canvas.drawPath(branchPath, stemPaint);

    _drawLeaf(canvas, leafPaint, leafOutlinePaint,
        Offset(size.width * 0.28, size.height * 0.52), 26, 13, -1.2);
    _drawLeaf(canvas, leafPaint, leafOutlinePaint,
        Offset(size.width * 0.12, size.height * 0.42), 20, 10, -1.5);
  }

  void _drawLeaf(Canvas canvas, Paint fill, Paint outline, Offset center,
      double length, double width, double angle) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    final path = Path()
      ..moveTo(0, -length / 2)
      ..cubicTo(width / 2, -length / 4, width / 2, length / 4, 0, length / 2)
      ..cubicTo(
          -width / 2, length / 4, -width / 2, -length / 4, 0, -length / 2);

    canvas.drawPath(path, fill);
    canvas.drawPath(path, outline);

    // Midrib
    canvas.drawLine(
      Offset(0, -length / 2),
      Offset(0, length / 2),
      outline
        ..strokeWidth = 0.6
        ..color = const Color(0xFF6A8050),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Top-right golden berry / wildflower branch
class _GoldenBerryBranch extends StatelessWidget {
  final double width;
  final double height;
  final double opacity;

  const _GoldenBerryBranch({
    required this.width,
    required this.height,
    this.opacity = 0.7,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: CustomPaint(
        size: Size(width, height),
        painter: _GoldenBerryPainter(),
      ),
    );
  }
}

class _GoldenBerryPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stemPaint = Paint()
      ..color = const Color(0xFFA08040)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final berryPaint = Paint()
      ..color = const Color(0xFFD4A843)
      ..style = PaintingStyle.fill;

    final berryOutline = Paint()
      ..color = const Color(0xFFB8860B)
      ..strokeWidth = 0.6
      ..style = PaintingStyle.stroke;

    // Main stem
    final stem = Path()
      ..moveTo(size.width * 0.5, size.height * 0.95)
      ..cubicTo(
        size.width * 0.5, size.height * 0.6,
        size.width * 0.4, size.height * 0.35,
        size.width * 0.3, size.height * 0.05,
      );
    canvas.drawPath(stem, stemPaint);

    // Branches with berry clusters
    _drawBranch(canvas, stemPaint, berryPaint, berryOutline,
        Offset(size.width * 0.48, size.height * 0.72),
        Offset(size.width * 0.85, size.height * 0.55), 3, 4.5);

    _drawBranch(canvas, stemPaint, berryPaint, berryOutline,
        Offset(size.width * 0.44, size.height * 0.52),
        Offset(size.width * 0.90, size.height * 0.35), 4, 4.0);

    _drawBranch(canvas, stemPaint, berryPaint, berryOutline,
        Offset(size.width * 0.40, size.height * 0.34),
        Offset(size.width * 0.82, size.height * 0.18), 3, 3.5);

    _drawBranch(canvas, stemPaint, berryPaint, berryOutline,
        Offset(size.width * 0.35, size.height * 0.18),
        Offset(size.width * 0.10, size.height * 0.08), 2, 3.0);

    _drawBranch(canvas, stemPaint, berryPaint, berryOutline,
        Offset(size.width * 0.38, size.height * 0.10),
        Offset(size.width * 0.65, size.height * 0.02), 3, 3.5);
  }

  void _drawBranch(
    Canvas canvas,
    Paint stem,
    Paint berryFill,
    Paint berryOutline,
    Offset start,
    Offset end,
    int berryCount,
    double berryRadius,
  ) {
    canvas.drawLine(start, end, stem);

    // Scatter berries near the end
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    for (int i = 0; i < berryCount; i++) {
      final t = 0.6 + (i * 0.15);
      final cx = start.dx + dx * t + (i % 2 == 0 ? berryRadius * 1.2 : -berryRadius * 0.8);
      final cy = start.dy + dy * t + (i.isEven ? -berryRadius : berryRadius * 0.5);
      canvas.drawCircle(Offset(cx, cy), berryRadius, berryFill);
      canvas.drawCircle(Offset(cx, cy), berryRadius, berryOutline);
      // Tiny stem to berry
      canvas.drawLine(
        Offset(start.dx + dx * (t - 0.08), start.dy + dy * (t - 0.08)),
        Offset(cx, cy),
        stem..strokeWidth = 0.8,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Bottom-right stacked books illustration
class _StackedBooksIllustration extends StatelessWidget {
  final double width;
  final double height;

  const _StackedBooksIllustration({
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _BooksPainter(),
    );
  }
}

class _BooksPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Book 1 — large dark teal book (bottom)
    _drawBook(
      canvas,
      rect: Rect.fromLTWH(
          size.width * 0.05, size.height * 0.65, size.width * 0.88, size.height * 0.22),
      spineColor: const Color(0xFF3D6B6B),
      coverColor: const Color(0xFF4A7E7E),
      pageColor: const Color(0xFFF5EDD8),
      angle: -0.04,
    );

    // Book 2 — medium warm brown book (middle)
    _drawBook(
      canvas,
      rect: Rect.fromLTWH(
          size.width * 0.08, size.height * 0.38, size.width * 0.80, size.height * 0.30),
      spineColor: const Color(0xFF6B4A2A),
      coverColor: const Color(0xFF8B6035),
      pageColor: const Color(0xFFF5EDD8),
      angle: 0.02,
    );

    // Book 3 — tall dark brown book (top)
    _drawBook(
      canvas,
      rect: Rect.fromLTWH(
          size.width * 0.12, size.height * 0.05, size.width * 0.72, size.height * 0.36),
      spineColor: const Color(0xFF4A2E1A),
      coverColor: const Color(0xFF6B4020),
      pageColor: const Color(0xFFF2E8CC),
      angle: -0.02,
    );
  }

  void _drawBook(
    Canvas canvas, {
    required Rect rect,
    required Color spineColor,
    required Color coverColor,
    required Color pageColor,
    double angle = 0,
  }) {
    canvas.save();
    canvas.translate(rect.center.dx, rect.center.dy);
    canvas.rotate(angle);
    canvas.translate(-rect.center.dx, -rect.center.dy);

    final spineWidth = rect.width * 0.12;

    // Pages (right side edge)
    final pagesPaint = Paint()..color = pageColor;
    canvas.drawRect(
      Rect.fromLTWH(rect.left + spineWidth, rect.top + 2,
          rect.width - spineWidth - 2, rect.height - 4),
      pagesPaint,
    );

    // Cover
    final coverPaint = Paint()..color = coverColor;
    canvas.drawRect(
      Rect.fromLTWH(rect.left + spineWidth, rect.top,
          rect.width - spineWidth, rect.height),
      coverPaint,
    );

    // Spine
    final spinePaint = Paint()..color = spineColor;
    canvas.drawRect(
      Rect.fromLTWH(rect.left, rect.top, spineWidth, rect.height),
      spinePaint,
    );

    // Decorative line on cover
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    canvas.drawRect(
      Rect.fromLTWH(
        rect.left + spineWidth + 6,
        rect.top + 6,
        rect.width - spineWidth - 12,
        rect.height - 12,
      ),
      linePaint,
    );

    // Shadow under each book
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawRect(
      Rect.fromLTWH(rect.left + 4, rect.bottom, rect.width - 4, 6),
      shadowPaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// STORY CARD CORNER FLOURISH
// ─────────────────────────────────────────────────────────────────────────────

class _CornerFlourish extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(36, 36),
      painter: _CornerFlourishPainter(),
    );
  }
}

class _CornerFlourishPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Corner bracket
    canvas.drawLine(Offset(size.width, 0), Offset(size.width * 0.4, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, size.height * 0.6), paint);

    // Tiny leaf accent
    final leafPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    final leaf = Path()
      ..moveTo(size.width * 0.55, size.height * 0.2)
      ..cubicTo(size.width * 0.7, size.height * 0.1, size.width * 0.85,
          size.height * 0.2, size.width * 0.8, size.height * 0.38)
      ..cubicTo(size.width * 0.65, size.height * 0.32, size.width * 0.52,
          size.height * 0.28, size.width * 0.55, size.height * 0.2);
    canvas.drawPath(leaf, leafPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// SLIVER TAB BAR DELEGATE
// ─────────────────────────────────────────────────────────────────────────────

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverTabBarDelegate({
    required this.isMe,
    required this.tabController,
    required this.onTabChanged,
  });

  final bool isMe;
  final TabController tabController;
  final Function(int) onTabChanged;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppTheme.inkBgMain,
      child: Column(
        children: [
          Container(
            color: AppTheme.inkBgMain,
            child: TabBar(
              controller: tabController,
              onTap: onTabChanged,
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(
                  color: AppTheme.inkTerracotta,
                  width: 2,
                ),
                insets: const EdgeInsets.symmetric(horizontal: 16),
              ),
              indicatorSize: TabBarIndicatorSize.label,
              labelColor: AppTheme.inkEspresso,
              unselectedLabelColor:
                  AppTheme.inkUmber.withValues(alpha: 0.5),
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              tabs: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Stories'),
                ),
                if (isMe)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Reading List'),
                  ),
              ],
            ),
          ),
          Container(
            height: 1,
            color: AppTheme.inkUmber.withValues(alpha: 0.08),
          ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 48;

  @override
  double get minExtent => 48;

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) => false;
}