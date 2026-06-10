import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/new_app_theme.dart';
import '../theme/app_typography.dart';

class WriterProfileScreen extends StatelessWidget {
  final String userId;
  const WriterProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.inkBgMain,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .snapshots(),
        builder: (context, userSnap) {
          final userData = userSnap.data?.data() as Map<String, dynamic>? ?? {};
          final displayName =
              (userData['displayName'] as String?)?.trim().isNotEmpty == true
                  ? userData['displayName'] as String
                  : 'Writer';
          final username = (userData['username'] as String?)?.trim() ?? '';
          final email    = (userData['email']    as String?)?.trim() ?? '';
          final photoUrl = userData['photoUrl']  as String?;

          return CustomScrollView(
            slivers: [

              // ── Header card ───────────────────────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  margin: EdgeInsets.only(
                    top  : MediaQuery.of(context).padding.top + 12,
                    left : 16,
                    right: 16,
                  ),
                  decoration: BoxDecoration(
                    color        : AppTheme.inkMaroon,
                    borderRadius : BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    children: [

                      // Back button — left aligned
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width : 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color        : Colors.white.withValues(alpha: 0.15),
                              borderRadius : BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new,
                              color: Colors.white,
                              size : 16,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Avatar — centered
                      Container(
                        width : 84,
                        height: 84,
                        decoration: BoxDecoration(
                          shape : BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                          color : Colors.white.withValues(alpha: 0.2),
                        ),
                        child: (photoUrl != null && photoUrl.isNotEmpty)
                            ? ClipOval(
                                child: Image.network(
                                  photoUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(
                                    Icons.person,
                                    size : 44,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                              )
                            : Icon(
                                Icons.person,
                                size : 44,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                      ),

                      const SizedBox(height: 12),

                      // Display name — centered
                      Text(
                        displayName,
                        textAlign: TextAlign.center,
                        style: AppTypography.headingMd.copyWith(
                          color        : Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),

                      const SizedBox(height: 4),

                      // Username / email — centered
                      Text(
                        username.isNotEmpty ? '@$username' : email,
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySm.copyWith(
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                        maxLines : 1,
                        overflow : TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // ── Published stories container ────────────────────────────
              SliverToBoxAdapter(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('stories')
                      .where('authorId',   isEqualTo: userId)
                      .where('isPublished', isEqualTo: true)
                      .snapshots(),
                  builder: (context, storiesSnap) {
                    final count = storiesSnap.data?.docs.length ?? 0;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color       : AppTheme.inkBgCard,
                          borderRadius: BorderRadius.circular(16),
                          border      : Border.all(
                            color: AppTheme.inkMaroon.withValues(alpha: 0.18),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Icon badge
                            Container(
                              width : 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color       : AppTheme.inkMaroon.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.public_rounded,
                                size : 20,
                                color: AppTheme.inkMaroon,
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Label
                            Expanded(
                              child: Text(
                                'Published Stories',
                                style: AppTypography.headingSm.copyWith(
                                  color   : AppTheme.inkEspresso,
                                  fontSize: 15,
                                ),
                              ),
                            ),

                            // Count badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color       : AppTheme.inkMaroon,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '$count',
                                style: AppTypography.labelMd.copyWith(
                                  color     : Colors.white,
                                  fontSize  : 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // ── Stories grid ──────────────────────────────────────────
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('stories')
                    .where('authorId',    isEqualTo: userId)
                    .where('isPublished', isEqualTo: true)
                    .snapshots(),
                builder: (context, storiesSnap) {
                  if (!storiesSnap.hasData) {
                    return const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 40),
                          child: CircularProgressIndicator(
                              color: AppTheme.inkMaroon),
                        ),
                      ),
                    );
                  }

                  final docs = storiesSnap.data!.docs;

                  if (docs.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 48),
                          child: Column(
                            children: [
                              Icon(Icons.auto_stories_outlined,
                                  size : 56,
                                  color: AppTheme.inkUmber.withValues(alpha: 0.2)),
                              const SizedBox(height: 12),
                              Text(
                                'No published stories yet',
                                style: AppTypography.bodyMd
                                    .copyWith(color: AppTheme.inkUmber),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  final rows = <Widget>[];
                  for (int i = 0; i < docs.length; i += 2) {
                    final left  = docs[i].data() as Map<String, dynamic>;
                    final right = i + 1 < docs.length
                        ? docs[i + 1].data() as Map<String, dynamic>
                        : null;
                    rows.add(Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildStoryCard(left)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: right != null
                              ? _buildStoryCard(right)
                              : const SizedBox(),
                        ),
                      ],
                    ));
                    rows.add(const SizedBox(height: 12));
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    sliver: SliverToBoxAdapter(
                      child: Column(children: rows),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Story card ─────────────────────────────────────────────────────────────

  Widget _buildStoryCard(Map<String, dynamic> data) {
    final title     = (data['title']     as String?) ?? 'Untitled';
    final genre     = (data['genre']     as String?) ?? '';
    final storyType = (data['storyType'] as String?) ?? 'Short Story';
    final wordCount = (data['wordCount'] as int?)    ?? 0;
    final iconColor = _getColorByGenre(genre);
    final icon      = _getIconByGenre(genre);

    return Container(
      decoration: BoxDecoration(
        color       : AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border      : Border.all(color: AppTheme.borderColor, width: 0.5),
        boxShadow   : [
          BoxShadow(
            color     : Colors.black.withValues(alpha:0.04),
            blurRadius: 8,
            offset    : const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [

          // Cover
          Container(
            height: 96,
            width : double.infinity,
            color : iconColor,
            child : Center(
              child: Icon(icon,
                  size : 36,
                  color: Colors.white.withValues(alpha: 0.55)),
            ),
          ),

          // Info
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [

                // Title
                Text(
                  title,
                  maxLines : 2,
                  overflow : TextOverflow.ellipsis,
                  style: AppTypography.bodyMd.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize  : 13,
                    color     : AppTheme.inkEspresso,
                    height    : 1.2,
                  ),
                ),
                const SizedBox(height: 4),

                // Genre · Type
                Text(
                  genre.isNotEmpty ? '$genre · $storyType' : storyType,
                  maxLines : 1,
                  overflow : TextOverflow.ellipsis,
                  style: AppTypography.labelSm
                      .copyWith(color: AppTheme.inkUmber, fontSize: 10),
                ),
                const SizedBox(height: 8),

                // Word count
                Row(
                  children: [
                    Icon(Icons.description_outlined,
                        size : 11,
                        color: AppTheme.inkUmber.withValues(alpha: 0.6)),
                    const SizedBox(width: 3),
                    Text(
                      '$wordCount words',
                      style: AppTypography.caption
                          .copyWith(color: AppTheme.inkUmber, fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Genre tag
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color       : iconColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon,
                          size : 9,
                          color: AppTheme.inkEspresso.withValues(alpha: 0.7)),
                      const SizedBox(width: 3),
                      Text(
                        genre.isNotEmpty ? genre : 'Fiction',
                        style: AppTypography.caption.copyWith(
                          fontSize  : 9,
                          fontWeight: FontWeight.w600,
                          color     : AppTheme.inkEspresso.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Color _getColorByGenre(String genre) {
    switch (genre.toLowerCase()) {
      case 'romance':   return const Color(0xFFF3D1D1);
      case 'mystery':
      case 'detective': return const Color(0xFFD5D6EA);
      case 'fantasy':
      case 'adventure': return const Color(0xFFD1E7DD);
      case 'sci-fi':    return const Color(0xFFD1DCE7);
      case 'horror':    return const Color(0xFFE7D5D5);
      case 'thriller':  return const Color(0xFFE7E2D5);
      case 'drama':     return const Color(0xFFE7D5E2);
      case 'poetry':    return const Color(0xFFF0E6D3);
      default:          return const Color(0xFFE8D8C4);
    }
  }

  IconData _getIconByGenre(String genre) {
    switch (genre.toLowerCase()) {
      case 'romance':  return Icons.favorite_border;
      case 'fantasy':  return Icons.auto_awesome;
      case 'mystery':  return Icons.search;
      case 'sci-fi':   return Icons.rocket_launch_outlined;
      case 'horror':   return Icons.nightlight_outlined;
      case 'thriller': return Icons.bolt_outlined;
      case 'poetry':   return Icons.format_quote;
      case 'drama':    return Icons.theater_comedy_outlined;
      default:         return Icons.auto_stories_outlined;
    }
  }
}