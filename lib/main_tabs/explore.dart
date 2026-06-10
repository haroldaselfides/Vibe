import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/new_app_theme.dart';
import '../pages/writer.dart';
import '../theme/app_typography.dart';

// Cover art background colors (not in AppTheme, kept local)
const _coverTeal = Color(0xFFC8DDD8);
const _coverSand = Color(0xFFE8D8C4);

// Top-level stream cache — survives widget rebuilds entirely
final _usersStreamCache =
    FirebaseFirestore.instance.collection('users').snapshots();
final _storiesStreamCache =
    FirebaseFirestore.instance.collection('stories').snapshots();

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery        = '';
  bool   _isSearchingStories = true;

  final Set<String> _savedStoryIds  = {};
  final Set<String> _followingIds   = {};   // tracks who current user follows

  QuerySnapshot? _cachedUsersSnapshot;
  QuerySnapshot? _cachedStoriesSnapshot;

  @override
  void initState() {
    super.initState();
    _loadSavedStoryIds();
    _loadFollowingIds();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Load saved library IDs ─────────────────────────────────────────────────

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
        setState(() => _savedStoryIds.addAll(snap.docs.map((d) => d.id)));
      }
    } catch (e) {
      debugPrint('Error loading saved story IDs: $e');
    }
  }

  // ── Load following IDs ─────────────────────────────────────────────────────

  Future<void> _loadFollowingIds() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('following')
          .get();
      if (mounted) {
        setState(() => _followingIds.addAll(snap.docs.map((d) => d.id)));
      }
    } catch (e) {
      debugPrint('Error loading following IDs: $e');
    }
  }

  // ── Toggle follow ──────────────────────────────────────────────────────────

  Future<void> _toggleFollow(String targetUserId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showDialog(
        icon: Icon(Icons.login_outlined, color: AppTheme.inkMaroon, size: 48),
        title: 'Login Required',
        content: 'Please log in to follow writers',
        actions: [
          _dialogTextButton('Cancel', () => Navigator.of(context).pop()),
          _dialogElevatedButton('Go to Login', () {
            Navigator.of(context).pop();
            Navigator.of(context).pushNamed('/login');
          }),
        ],
      );
      return;
    }
    if (user.uid == targetUserId) return;

    final alreadyFollowing = _followingIds.contains(targetUserId);

    // Optimistic update
    setState(() {
      if (alreadyFollowing) {
        _followingIds.remove(targetUserId);
      } else {
        _followingIds.add(targetUserId);
      }
    });

    try {
      final followingRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('following')
          .doc(targetUserId);

      final followersRef = FirebaseFirestore.instance
          .collection('users')
          .doc(targetUserId)
          .collection('followers')
          .doc(user.uid);

      if (alreadyFollowing) {
        await followingRef.delete();
        await followersRef.delete();
      } else {
        final now = FieldValue.serverTimestamp();

        // Fetch target user's profile to store their name in current user's following
        final targetSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(targetUserId)
            .get();
        final targetData = targetSnap.data() ?? {};

        // Store target's info under current user's /following/{targetId}
        await followingRef.set({
          'followedAt'  : now,
          'displayName' : targetData['displayName'] ?? '',
          'username'    : targetData['username']    ?? '',
          'photoUrl'    : targetData['photoUrl']    ?? '',
        });

        // Store current user's info under target's /followers/{currentUid}
        await followersRef.set({
          'followedAt'  : now,
          'displayName' : user.displayName ?? '',
          'username'    : user.email?.split('@').first ?? '',
          'photoUrl'    : user.photoURL ?? '',
        });

        // Notify the followed person
        final fromName = user.displayName?.isNotEmpty == true 
            ? user.displayName! 
            : (user.email?.split('@').first ?? 'Someone');

        await FirebaseFirestore.instance
            .collection('users')
            .doc(targetUserId)
            .collection('notifications')
            .add({
          'title': 'New Follower',
          'body': '$fromName started following you',
          'type': 'follow',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
          'fromId': user.uid,
        });
        debugPrint('[Notification] Follow notification sent to author: $targetUserId');
      }
    } catch (e) {
      // Revert on error
      setState(() {
        if (alreadyFollowing) {
          _followingIds.add(targetUserId);
        } else {
          _followingIds.remove(targetUserId);
        }
      });
      debugPrint('Error toggling follow: $e');
    }
  }

  // ── Toggle library ─────────────────────────────────────────────────────────

  Future<void> _toggleLibrary(
      String storyId, Map<String, dynamic> storyData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showDialog(
        icon: Icon(Icons.login_outlined, color: AppTheme.inkMaroon, size: 48),
        title: 'Login Required',
        content: 'Please log in to save stories',
        actions: [
          _dialogTextButton('Cancel', () => Navigator.of(context).pop()),
          _dialogElevatedButton('Go to Login', () {
            Navigator.of(context).pop();
            Navigator.of(context).pushNamed('/login');
          }),
        ],
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
          _showDialog(
            icon: Icon(Icons.bookmark_outline,
                color: AppTheme.inkMaroon, size: 48),
            title: 'Removed',
            content: 'Story removed from Library',
            actions: [
              _dialogTextButton('OK', () => Navigator.of(context).pop())
            ],
          );
        }
      } else {
        await ref.set({
          'storyId'        : storyId,
          'savedAt'        : FieldValue.serverTimestamp(),
          'title'          : storyData['title']          ?? '',
          'authorUsername' : storyData['authorUsername'] ?? '',
          'genre'          : storyData['genre']          ?? '',
          'storyType'      : storyData['storyType']      ?? 'Short Story',
        });
        if (mounted) {
          _showDialog(
            icon: Icon(Icons.bookmark_rounded, color: Colors.green, size: 48),
            title: 'Saved!',
            content: 'Story added to Library',
            actions: [
              _dialogTextButton('OK', () => Navigator.of(context).pop())
            ],
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

  // ── Shared dialog helpers ──────────────────────────────────────────────────

  void _showDialog({
    required Widget icon,
    required String title,
    required String content,
    required List<Widget> actions,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: icon,
        title: Text(
          title,
          style: AppTypography.headingSm
              .copyWith(color: AppTheme.inkEspresso),
          textAlign: TextAlign.center,
        ),
        content: Text(
          content,
          style:
              AppTypography.bodyMd.copyWith(color: AppTheme.inkUmber),
          textAlign: TextAlign.center,
        ),
        actions: actions,
      ),
    );
  }

  Widget _dialogTextButton(String label, VoidCallback onPressed) {
    return TextButton(
      onPressed: onPressed,
      child: Text(label,
          style:
              AppTypography.labelMd.copyWith(color: AppTheme.inkMaroon)),
    );
  }

  Widget _dialogElevatedButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.inkMaroon,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(label,
          style: AppTypography.labelMd.copyWith(color: Colors.white)),
    );
  }

  // ── Root ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      body: Column(
        children: [
          _buildHeader(),
          _buildToggleRow(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      margin: EdgeInsets.only(
        top  : MediaQuery.of(context).padding.top + 12,
        left : 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        color        : AppTheme.inkMaroon,
        borderRadius : BorderRadius.circular(AppTheme.radiusXl),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Explore',
                    style: AppTypography.headingLg.copyWith(
                      color   : Colors.white,
                      fontSize: 26,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Discover stories and writers',
                    style: AppTypography.bodySm.copyWith(
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          // ── Search bar ──
          Container(
            height    : 46,
            decoration: BoxDecoration(
              color        : AppTheme.inkCanvas,
              borderRadius : BorderRadius.circular(AppTheme.radiusFull),
            ),
            child: TextField(
              controller        : _searchController,
              textAlignVertical : TextAlignVertical.center,
              onChanged: (v) =>
                  setState(() => _searchQuery = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText  : _isSearchingStories
                    ? 'Search stories...'
                    : 'Search writers...',
                prefixIcon: const Icon(Icons.search,
                    color: AppTheme.inkUmber, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close,
                            color: AppTheme.inkUmber, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border         : InputBorder.none,
                isDense        : true,
                contentPadding :
                    const EdgeInsets.symmetric(horizontal: 12),
                hintStyle      : AppTypography.bodyMd.copyWith(
                    color: AppTheme.inkUmber.withValues(alpha: 0.6)),
              ),
              style: AppTypography.bodyMd
                  .copyWith(color: AppTheme.inkEspresso),
            ),
          ),
        ],
      ),
    );
  }

  // ── Stories / Writers toggle ───────────────────────────────────────────────

  Widget _buildToggleRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        height    : 46,
        decoration: BoxDecoration(
          color        : AppTheme.inkBgCard,
          borderRadius : BorderRadius.circular(AppTheme.radiusFull),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            _buildPill('Stories', _isSearchingStories,
                () => setState(() => _isSearchingStories = true)),
            _buildPill('Writers', !_isSearchingStories,
                () => setState(() => _isSearchingStories = false)),
          ],
        ),
      ),
    );
  }

  Widget _buildPill(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration  : const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color        : active ? AppTheme.inkMaroon : Colors.transparent,
            borderRadius : BorderRadius.circular(AppTheme.radiusFull),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTypography.labelMd.copyWith(
              color   : active ? AppTheme.inkCanvas : AppTheme.inkUmber,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  // ── Body ───────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    if (_searchQuery.isEmpty) return _buildEmptyState();
    return _isSearchingStories ? _buildStoryGrid() : _buildUserResults();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_stories_outlined,
              size : 64,
              color: AppTheme.inkUmber.withValues(alpha: 0.25)),
          const SizedBox(height: 16),
          Text(
            _isSearchingStories
                ? 'Search for your next favorite story'
                : 'Search for writers to follow',
            style:
                AppTypography.bodyMd.copyWith(color: AppTheme.inkUmber.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }

  // ── Story grid ─────────────────────────────────────────────────────────────

  Widget _buildStoryGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: _storiesStreamCache,
      builder: (context, snapshot) {
        if (snapshot.hasData) _cachedStoriesSnapshot = snapshot.data;
        if (_cachedStoriesSnapshot == null) {
          return const Center(
              child:
                  CircularProgressIndicator(color: AppTheme.inkMaroon));
        }

        final docs = _cachedStoriesSnapshot!.docs.where((doc) {
          final data  = doc.data() as Map<String, dynamic>? ?? {};
          if (data.isEmpty) return false;
          final title = (data['title'] ?? '').toString().toLowerCase();
          final genre = (data['genre']  ?? '').toString().toLowerCase();
          return title.contains(_searchQuery) ||
              genre.contains(_searchQuery);
        }).toList();

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off_outlined,
                    size : 52,
                    color: AppTheme.inkUmber.withValues(alpha: 0.25)),
                const SizedBox(height: 12),
                Text('No stories found',
                    style: AppTypography.bodyMd
                        .copyWith(color: AppTheme.inkUmber)),
                const SizedBox(height: 4),
                Text('Try a different title or genre',
                    style: AppTypography.bodySm.copyWith(color: AppTheme.inkUmber.withValues(alpha: 0.6))),
              ],
            ),
          );
        }

        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Text('Top Results', style: AppTypography.headingSm),
                  const SizedBox(height: 14),
                  _buildGrid(docs),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGrid(List<QueryDocumentSnapshot> docs) {
    final rows = <Widget>[];
    for (int i = 0; i < docs.length; i += 2) {
      final left  = docs[i];
      final right = i + 1 < docs.length ? docs[i + 1] : null;
      rows.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildStoryCard(left, i)),
          const SizedBox(width: 10),
          Expanded(
            child: right != null
                ? _buildStoryCard(right, i + 1)
                : const SizedBox(),
          ),
        ],
      ));
      rows.add(const SizedBox(height: 10));
    }
    return Column(children: rows);
  }

  Widget _buildStoryCard(QueryDocumentSnapshot doc, int index) {
    final data           = doc.data() as Map<String, dynamic>;
    final storyId        = doc.id;
    final isSaved        = _savedStoryIds.contains(storyId);
    final title          = (data['title']     as String?) ?? 'Untitled';
    final genre          = (data['genre']     as String?) ?? '';
    final storyType      = (data['storyType'] as String?) ?? 'Short Story';
    final progress       = (data['progress']      as num?)?.toDouble() ?? 0.0;
    final currentChapter = (data['currentChapter'] as int?) ?? 0;
    final totalChapters  = (data['totalChapters']  as int?) ?? 0;
    final isInProgress   = progress > 0 || currentChapter > 0;
    final coverColor     = index.isEven ? _coverTeal : _coverSand;

    return GestureDetector(
      child: Container(
        decoration: BoxDecoration(
          color        : AppTheme.surfaceColor,
          borderRadius : BorderRadius.circular(AppTheme.radiusMd),
          border       : Border.all(color: AppTheme.borderColor, width: 0.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Cover art ──
            Stack(
              children: [
                Container(
                  height: 90,
                  width : double.infinity,
                  color : coverColor,
                  child : Center(child: _buildCoverIcon(genre, index)),
                ),
                if (isInProgress)
                  Positioned(
                    top: 8, left: 8,
                    child: _buildStatusBadge('In Progress'),
                  )
                else if (isSaved)
                  Positioned(
                    top: 8, left: 8,
                    child: _buildStatusBadge('Saved'),
                  ),
              ],
            ),
            // ── Info ──
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMd.copyWith(
                      fontWeight: FontWeight.w700,
                      color     : AppTheme.inkEspresso,
                      fontSize  : 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    genre.isNotEmpty ? '$genre · $storyType' : storyType,
                    style: AppTypography.labelSm
                        .copyWith(color: AppTheme.inkUmber),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  if (isInProgress) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [
                          const Icon(Icons.menu_book_outlined,
                              size: 11, color: AppTheme.inkUmber),
                          const SizedBox(width: 3),
                          Text(
                            totalChapters > 0
                                ? 'Ch $currentChapter of $totalChapters'
                                : 'In Progress',
                            style: AppTypography.caption
                                .copyWith(color: AppTheme.inkUmber),
                          ),
                        ]),
                        Text(
                          '${progress.toInt()}%',
                          style: AppTypography.captionBold
                              .copyWith(color: AppTheme.inkMaroon),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value          : progress / 100,
                        minHeight      : 2,
                        backgroundColor: AppTheme.inkBgCard,
                        color          : AppTheme.inkMaroon,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  // ── Save to Library button ──
                  SizedBox(
                    width : double.infinity,
                    height: 32,
                    child: isSaved
                        ? OutlinedButton.icon(
                            onPressed: () =>
                                _toggleLibrary(storyId, data),
                            icon : Icon(Icons.bookmark,
                                size : 14,
                                color: AppTheme.inkMaroon),
                            label: Text(
                              'Saved to Library',
                              style: AppTypography.buttonMedium.copyWith(
                                color   : AppTheme.inkMaroon,
                                fontSize: 11,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding        : EdgeInsets.zero,
                              side           : BorderSide(
                                  color: AppTheme.inkMaroon, width: 1),
                              shape          : RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.radiusXs)),
                              backgroundColor: AppTheme.inkMaroon
                                  .withValues(alpha: 0.06),
                            ),
                          )
                        : ElevatedButton.icon(
                            onPressed: () =>
                                _toggleLibrary(storyId, data),
                            icon : Icon(Icons.bookmark_add_outlined,
                                size : 14,
                                color: AppTheme.inkCanvas),
                            label: Text(
                              'Save to Library',
                              style: AppTypography.buttonMedium.copyWith(
                                color   : AppTheme.inkCanvas,
                                fontSize: 11,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding        : EdgeInsets.zero,
                              backgroundColor: AppTheme.inkMaroon,
                              elevation      : 0,
                              shape          : RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.radiusXs)),
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

  Widget _buildCoverIcon(String genre, int index) {
    final lowerGenre = genre.toLowerCase();
    late final IconData icon;
    if (lowerGenre.contains('fantasy') || lowerGenre.contains('magic')) {
      icon = Icons.auto_awesome;
    } else if (lowerGenre.contains('sci') || lowerGenre.contains('space')) {
      icon = Icons.rocket_launch_outlined;
    } else if (lowerGenre.contains('poet') ||
        lowerGenre.contains('narrative')) {
      icon = Icons.format_quote_rounded;
    } else if (lowerGenre.contains('post') ||
        lowerGenre.contains('apocalyptic')) {
      icon = Icons.public_off_outlined;
    } else {
      icon = Icons.auto_stories_outlined;
    }
    return Icon(icon,
        color: AppTheme.inkUmber.withValues(alpha: 0.5), size: 32);
  }

  Widget _buildStatusBadge(String label) {
    final isProgress = label == 'In Progress';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color        : AppTheme.inkCanvas,
        borderRadius : BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isProgress) ...[
            Container(
              width : 6,
              height: 6,
              decoration: BoxDecoration(
                  color: AppTheme.inkGold, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color     : AppTheme.inkEspresso,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Writers list ───────────────────────────────────────────────────────────

  Widget _buildUserResults() {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: _usersStreamCache,
      builder: (context, snapshot) {
        if (snapshot.hasData) _cachedUsersSnapshot = snapshot.data;
        if (_cachedUsersSnapshot == null) {
          return const Center(
              child:
                  CircularProgressIndicator(color: AppTheme.inkMaroon));
        }

        final docs = _cachedUsersSnapshot!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          if (data.isEmpty) return false;
          if (doc.id == currentUid) return false;

          final rawPublic = data['isPublic'];
          bool isPublic;
          if (rawPublic == null) {
            isPublic = true;
          } else if (rawPublic is bool) {
            isPublic = rawPublic;
          } else if (rawPublic is int) {
            isPublic = rawPublic != 0;
          } else {
            isPublic = rawPublic.toString().toLowerCase() == 'true';
          }
          if (!isPublic) return false;

          final name     = (data['displayName'] ?? '').toString().toLowerCase();
          final username = (data['username']    ?? '').toString().toLowerCase();
          final bio      = (data['bio']         ?? '').toString().toLowerCase();

          return name.contains(_searchQuery)
              || username.contains(_searchQuery)
              || bio.contains(_searchQuery);
        }).toList();

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_search_outlined,
                    size : 52,
                    color: AppTheme.inkUmber.withValues(alpha: 0.25)),
                const SizedBox(height: 12),
                Text('No writers found',
                    style: AppTypography.bodyMd
                        .copyWith(color: AppTheme.inkUmber)),
                const SizedBox(height: 4),
                Text('Try a different name or username',
                    style: AppTypography.bodySm.copyWith(color: AppTheme.inkUmber.withValues(alpha: 0.6))),
              ],
            ),
          );
        }

        return ListView.separated(
          padding          : const EdgeInsets.fromLTRB(16, 16, 16, 24),
          itemCount        : docs.length,
          separatorBuilder : (_, __) =>
              Divider(color: AppTheme.borderColor, height: 1),
          itemBuilder: (context, index) {
            final doc         = docs[index];
            final data        = doc.data() as Map<String, dynamic>;
            final targetId    = doc.id;
            final photoUrl    = data['photoUrl'] as String?;
            final isFollowing = _followingIds.contains(targetId);

            final rawPublic = data['isPublic'];
            final isPublic  = rawPublic == null
                ? true
                : rawPublic is bool
                    ? rawPublic
                    : rawPublic is int
                        ? rawPublic != 0
                        : rawPublic.toString().toLowerCase() == 'true';

            final displayName =
                (data['displayName'] as String?)?.trim().isNotEmpty == true
                    ? data['displayName'] as String
                    : 'Writer';
            final username =
                (data['username'] as String?)?.trim() ?? '';
            final bio = (data['bio'] as String?)?.trim() ?? '';

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
              leading: GestureDetector(
                onTap: () => isPublic
                    ? Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              WriterProfileScreen(userId: targetId),
                        ),
                      )
                    : null,
                child: CircleAvatar(
                  radius         : 22,
                  backgroundColor: AppTheme.inkBgCard,
                  backgroundImage:
                      (photoUrl != null && photoUrl.isNotEmpty)
                          ? NetworkImage(photoUrl)
                          : null,
                  child: (photoUrl == null || photoUrl.isEmpty)
                      ? Text(
                          displayName.isNotEmpty
                              ? displayName[0].toUpperCase()
                              : '?',
                          style: AppTypography.labelMd
                              .copyWith(color: AppTheme.inkUmber),
                        )
                      : null,
                ),
              ),
              title: Text(displayName, style: AppTypography.authorName),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (username.isNotEmpty)
                    Text('@$username', style: AppTypography.authorMeta),
                  if (bio.isNotEmpty)
                    Text(
                      bio,
                      style: AppTypography.bodySm.copyWith(
                          color: AppTheme.inkUmber.withValues(alpha: 0.7)),
                      maxLines: 1, // This is the target.
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
              // ── Follow button ──────────────────────────────────────────
              trailing: currentUid != null && currentUid != targetId
                  ? AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: isFollowing
                          ? OutlinedButton(
                              key      : const ValueKey('following'),
                              onPressed: () => _toggleFollow(targetId),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14),
                                side : BorderSide(
                                    color: AppTheme.inkSage, width: 1),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(20)),
                              ),
                              child: Text(
                                'Following',
                                style: AppTypography.labelSm.copyWith(
                                  color   : AppTheme.inkSage,
                                  fontSize: 12,
                                ),
                              ),
                            )
                          : ElevatedButton(
                              key      : const ValueKey('follow'),
                              onPressed: () => _toggleFollow(targetId),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.inkMaroon,
                                elevation      : 0,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(20)),
                              ),
                              child: Text(
                                'Follow',
                                style: AppTypography.labelSm.copyWith(
                                  color   : Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                    )
                  : null,
              onTap: () {
                if (isPublic) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          WriterProfileScreen(userId: targetId),
                    ),
                  );
                } else {
                  _showDialog(
                    icon: Icon(Icons.lock_outline,
                        color: AppTheme.inkMaroon, size: 48),
                    title: 'Profile Private',
                    content: 'This profile is private',
                    actions: [
                      _dialogTextButton(
                          'OK', () => Navigator.of(context).pop()),
                    ],
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