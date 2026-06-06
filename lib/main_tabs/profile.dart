import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/new_app_theme.dart';
import '../../theme/app_typography.dart';
import '../pages/settings.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;
  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final targetUid = widget.userId ?? currentUser?.uid;

    if (targetUid == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view your profile')),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ═══════════════════════════════════════════════════════
                // PROFILE HEADER CARD
                // ═══════════════════════════════════════════════════════
                _buildProfileHeader(targetUid),
                const SizedBox(height: 24),
                // ═══════════════════════════════════════════════════════
                // MY STORIES (Author's Own Projects)
                // ═══════════════════════════════════════════════════════
                _buildMyStoriesSection(targetUid),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────
  // PROFILE HEADER
  // ────────────────────────────────────────────────────────────────────
  Widget _buildProfileHeader(String userId) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final bool isMe = userId == currentUser?.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        final userData = snapshot.data?.data() as Map<String, dynamic>?;
        final displayName = userData?['displayName'] ?? 'User';
        final email = FirebaseAuth.instance.currentUser?.email ?? '';
        final photoUrl = userData?['photoUrl'];

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.inkMaroon,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // Avatar
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    child: photoUrl != null
                        ? ClipOval(
                            child: Image.network(
                              photoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.white.withValues(alpha: 0.8),
                                );
                              },
                            ),
                          )
                        : Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                  ),
                  const SizedBox(width: 20),
                  // User Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: AppTypography.headingMd.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: AppTypography.bodySm.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Settings icon (only for own profile)
                  if (isMe)
                    IconButton(
                      icon: const Icon(Icons.settings_outlined,
                          color: Colors.white, size: 24),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        );
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),
              // Stats Row - Fetch from Firestore
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('stories')
                    .where('authorId', isEqualTo: userId)
                    .snapshots(),
                builder: (context, storiesSnap) {
                  final storiesDocs = storiesSnap.data?.docs ?? [];
                  final publishedCount = storiesDocs
                      .where((doc) => (doc.data() as Map<String, dynamic>)['isPublished'] == true)
                      .length;

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .collection('readingProgress')
                        .snapshots(),
                    builder: (context, progressSnap) {
                      final progressDocs = progressSnap.data?.docs ?? [];
                      final inProgress = progressDocs
                          .where((doc) => (doc.data() as Map<String, dynamic>)['status'] == 'in_progress')
                          .length;
                      final completed = progressDocs
                          .where((doc) => (doc.data() as Map<String, dynamic>)['status'] == 'completed')
                          .length;

                      return Row(
                        children: [
                          Expanded(
                            child: _buildStatBox(
                              publishedCount.toString(),
                              'Stories Published',
                              Icons.public_rounded,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatBox(
                              inProgress.toString(),
                              'In rogress',
                              Icons.menu_book,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatBox(
                              completed.toString(),
                              'Completed',
                              Icons.check_circle,
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatBox(String number, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 20),
          const SizedBox(height: 8),
          Text(
            number,
            style: AppTypography.headingSm.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 2,
            textAlign: TextAlign.center,
            style: AppTypography.bodySm.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
  // ────────────────────────────────────────────────────────────────────
  // PUBLISH STORIES
  // ────────────────────────────────────────────────────────────────────
  Widget _buildMyStoriesSection(String userId) {
    debugPrint('ProfileScreen: Fetching stories for userId: $userId');

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('stories')
          .where('authorId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        debugPrint(
            'ProfileScreen stories snapshot: ${snapshot.connectionState}, hasError: ${snapshot.hasError}');

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPublishStoriesHeader(),
              const SizedBox(height: 12),
              const Center(
                child: CircularProgressIndicator(color: AppTheme.inkMaroon),
              ),
            ],
          );
        }

        if (snapshot.hasError) {
          debugPrint('ProfileScreen stories error: ${snapshot.error}');
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPublishStoriesHeader(),
              const SizedBox(height: 12),
              Text('Error: ${snapshot.error}'),
            ],
          );
        }

        var docs = snapshot.data?.docs ?? [];
        debugPrint(
            'ProfileScreen found ${docs.length} stories for userId: $userId');

        // Sort by updatedAt in code instead of Firestore
        docs.sort((a, b) {
          final aTime =
              (a.data() as Map<String, dynamic>)['updatedAt'] as Timestamp?;
          final bTime =
              (b.data() as Map<String, dynamic>)['updatedAt'] as Timestamp?;
          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime);
        });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPublishStoriesHeader(storyCount: docs.length),
            const SizedBox(height: 12),
            if (docs.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(
                        Icons.public_outlined,
                        size: 48,
                        color: AppTheme.inkUmber.withValues(alpha: 0.2),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No stories yet',
                        style: AppTypography.bodySm.copyWith(
                          color: AppTheme.inkUmber.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: .80,
                ),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final storyData =
                      docs[index].data() as Map<String, dynamic>;
                  return _buildMyStoryCard(
                    title: storyData['title'] ?? 'Untitled',
                    genre: storyData['genre'] ?? 'Fiction',
                    storyType: storyData['storyType'] ?? 'Short Story',
                    wordCount: storyData['wordCount'] as int? ?? 0,
                    isPublished: storyData['isPublished'] as bool? ?? false,
                    updatedAt: storyData['updatedAt'] as Timestamp?,
                    iconColor:
                        _getColorByGenre(storyData['genre'] ?? 'Fiction'),
                    icon: _getIconByGenre(storyData['genre'] ?? 'Fiction'),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  // ── "Publish Stories" styled header container ─────────────────────────────

  Widget _buildPublishStoriesHeader({int? storyCount}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.inkMaroon.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.inkMaroon.withValues(alpha: 0.18),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Icon badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.inkMaroon.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.public_rounded,
              size: 18,
              color: AppTheme.inkMaroon,
            ),
          ),
          const SizedBox(width: 12),

          // Title + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Publish Stories',
                  style: AppTypography.headingMd.copyWith(
                    color: AppTheme.inkMaroon,
                    fontSize: 16,
                    height: 1.1,
                  ),
                ),
                if (storyCount != null)
                  Text(
                    storyCount == 0
                        ? 'No stories published yet'
                        : '$storyCount ${storyCount == 1 ? 'story' : 'stories'} published',
                    style: AppTypography.caption.copyWith(
                      color: AppTheme.inkMaroon.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),

          // Story count badge (only when there are stories)
          if (storyCount != null && storyCount > 0)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.inkMaroon,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$storyCount',
                style: AppTypography.labelSm.copyWith(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getTimeAgo(Timestamp? ts) {
    if (ts == null) return '';
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.inMinutes < 60) return 'Updated ${diff.inMinutes}m ago';
    if (diff.inHours < 24) return 'Updated ${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Updated yesterday';
    return 'Updated ${diff.inDays}d ago';
  }

Widget _buildMyStoryCard({
    required String title,
    required String genre,
    required String storyType,
    required int wordCount,
    required bool isPublished,
    required Timestamp? updatedAt,
    required Color iconColor,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,          // ← shrink-wrap the column
        children: [
          // Cover area with status badge
          Stack(
            children: [
              Container(
                height: 100,
                decoration: BoxDecoration(
                  color: iconColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14),
                  ),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 40,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ),
              // Status badge
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPublished
                        ? const Color(0xFF4CAF50)
                        : AppTheme.inkGold,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isPublished ? 'Published' : 'Draft',
                        style: AppTypography.bodySm.copyWith(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Info — no trailing SizedBoxes, padding is the only spacing
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.headingSm.copyWith(
                    fontSize: 13,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),

                // Genre · Story Type
                Text(
                  '$genre · $storyType',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySm.copyWith(
                    color: const Color(0xFFA0A0A0),
                    fontSize: 9,
                  ),
                ),
                const SizedBox(height: 5),

                // Word count
                Row(
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 10,
                      color: AppTheme.inkUmber.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        '$wordCount words',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          fontSize: 8,
                          color: const Color(0xFFA0A0A0),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),

                // Updated time
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 10,
                      color: AppTheme.inkUmber.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        _getTimeAgo(updatedAt),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          fontSize: 8,
                          color: const Color(0xFFA0A0A0),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Completed row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Completed',
                      style: AppTypography.caption.copyWith(
                        fontSize: 9,
                        color: const Color(0xFFA0A0A0),
                      ),
                    ),
                    const Icon(
                      Icons.check,
                      size: 11,
                      color: Color(0xFF4CAF50),
                    ),
                  ],
                ),
                const SizedBox(height: 3),

                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: 1.0,
                    minHeight: 3,
                    backgroundColor:
                        AppTheme.inkUmber.withValues(alpha: 0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF4CAF50),
                    ),
                  ),
                ),
                const SizedBox(height: 5),

                // Genre tag — last item, no trailing SizedBox
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: 9,
                        color: AppTheme.inkEspresso.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        genre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 8,
                          color: AppTheme.inkEspresso.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                // ← no SizedBox here — padding(bottom:8) handles the gap
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorByGenre(String genre) {
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

  IconData _getIconByGenre(String genre) {
    switch (genre.toLowerCase()) {
      case 'romance':
        return Icons.favorite_border;
      case 'fantasy':
        return Icons.auto_awesome;
      case 'mystery':
        return Icons.search;
      case 'sci-fi':
        return Icons.rocket_launch_outlined;
      case 'horror':
        return Icons.nightlight_outlined;
      case 'thriller':
        return Icons.bolt_outlined;
      case 'poetry':
        return Icons.format_quote;
      case 'drama':
        return Icons.theater_comedy_outlined;
      default:
        return Icons.book_outlined;
    }
  }

}