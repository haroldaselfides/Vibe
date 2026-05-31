import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../main_tabs/post/post_screen_utils.dart';
import 'edit_profile.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId; // If null, shows the current logged-in user
  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0; // 0 for Stories, 1 for Reading List

  @override
  void initState() {
    super.initState();
    // Only show Reading List if it's my own profile
    final bool isMe = widget.userId == null || widget.userId == FirebaseAuth.instance.currentUser?.uid;
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
          // PROFILE HEADER
          // ═══════════════════════════════════════════════════════════════
          SliverAppBar(
            expandedHeight: 320,
            // Show back button only if we navigated here (not a tab)
            automaticallyImplyLeading: widget.userId != null,
            pinned: true,
            backgroundColor: AppTheme.inkBgMain,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(targetUid)
                    .snapshots(),
                builder: (context, snapshot) {
                  final userData = snapshot.data?.data() as Map<String, dynamic>?;
                  
                  // Check privacy
                  final bool isPublic = userData?['isPublic'] ?? true;
                  if (!isMe && !isPublic) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_outline, size: 48, color: AppTheme.inkUmber),
                          SizedBox(height: 12),
                          Text('This profile is private', style: TextStyle(color: AppTheme.inkUmber)),
                        ],
                      ),
                    );
                  }

                  final displayName = userData?['displayName'] ?? (isMe ? currentUser?.displayName : 'Writer') ?? 'Writer';
                  final username = userData?['username'] ?? 'user';
                  final bio = userData?['bio'] ?? 'No bio yet.';
                  final photoUrl = userData?['photoUrl'] ?? (isMe ? currentUser?.photoURL : null);

                  return Container(
                    color: AppTheme.inkBgMain,
                    child: Column(
                      children: [
                        // ─── Stats Bar ────────────────────────────────────────
                        // Stats bar removed as per request

                        // ─── Avatar & Info ────────────────────────────────────
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Avatar with Badge
                              Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppTheme.inkTerracotta,
                                        width: 3,
                                      ),
                                      image: photoUrl != null
                                          ? DecorationImage(
                                              image: NetworkImage(photoUrl),
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
                                  // Badge
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppTheme.inkTerracotta,
                                      border: Border.all(
                                        color: AppTheme.inkBgMain,
                                        width: 2,
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
                                      size: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Name
                              Text(
                                displayName,
                                style: Theme.of(context)
                                    .textTheme
                                    .displayMedium!
                                    .copyWith(
                                      color: AppTheme.inkEspresso,
                                      fontSize: 22,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              // Handle
                              Text(
                                '@$username',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.inkUmber.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Bio
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: Text(
                                  bio,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.inkEspresso,
                                    height: 1.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (isMe) _buildEditProfileButton({
                                'displayName': displayName,
                                'username': username,
                                'bio': bio,
                                'photoUrl': photoUrl,
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
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
            _buildStoriesGrid(targetUid) // Stories tab
          else
            _buildReadingListGrid(targetUid),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────

  Widget _buildEditProfileButton(Map<String, dynamic> currentData) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.inkBgCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.inkUmber.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => EditProfileScreen(userData: currentData),
              ),
            );
          },
          borderRadius: BorderRadius.circular(24),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_outline, size: 18, color: AppTheme.inkEspresso),
                SizedBox(width: 8),
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
      ),
    );
  }

  Widget _buildStoriesGrid(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('stories')
          .where('authorId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SliverToBoxAdapter(
            child: Center(child: Padding(
              padding: EdgeInsets.all(40.0),
              child: CircularProgressIndicator(color: AppTheme.inkTerracotta),
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
            child: Center(child: CircularProgressIndicator(color: AppTheme.inkTerracotta)),
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
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 20,
                    childAspectRatio: 0.58,
                  ),
                  itemCount: stories.length,
                  itemBuilder: (context, index) => _buildReadingCard(stories[index]),
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
      final storyDoc = await FirebaseFirestore.instance.collection('stories').doc(storyId).get();
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
            child: Center(child: Icon(PostScreenUtils.getGenreIcon(genre), color: color, size: 30)),
          ),
        ),
        const SizedBox(height: 4),
        Text(data['title'] ?? 'Untitled', 
            maxLines: 1, 
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
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

  // ─────────────────────────────────────────────────────────────────────

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
                  isFavorites ? Icons.favorite_border : Icons.auto_stories_outlined,
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
                        gradient: LinearGradient(colors: [color.withValues(alpha: 0.8), color]),
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

                  // Genre Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      genre,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
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

// ─────────────────────────────────────────────────────────────────────────

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
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
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
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Stories'),
                ),
                if (isMe)
                  Padding(
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
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}

// Add this import at the top of your file:
// import 'dart:ui' as ui;