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

class _LibraryScreenState extends State<LibraryScreen> with SingleTickerProviderStateMixin {
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
        centerTitle: false,
        title: const Text(
          'Library',
          style: TextStyle(
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
          unselectedLabelColor: AppTheme.inkUmber.withOpacity(0.5),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(text: 'My Collection'),
            Tab(text: 'Recent Reads'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStoryGrid(isCollection: true),
          _buildStoryGrid(isCollection: false),
        ],
      ),
    );
  }

  Widget _buildStoryGrid({required bool isCollection}) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text('Please login to view library'));

    Query query = FirebaseFirestore.instance.collection('stories');

    if (isCollection) {
      // Filter for stories where the current user is the author
      query = query.where('authorId', isEqualTo: user.uid);
    }

    // Order by the most recently updated
    query = query.orderBy('updatedAt', descending: true);

    return StreamBuilder<QuerySnapshot>(
      key: ValueKey('library_grid_$isCollection'),
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text('Something went wrong'));
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.inkTerracotta));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return _buildEmptyState();
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 20,
            childAspectRatio: 0.65,
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final docId = docs[index].id;
            return _LibraryBookCard(
              data: data,
              docId: docId,
              onTap: () async {
                final storyId = docId;
                final storyType = data['storyType'] ?? 'Short Story';

                Map<String, dynamic> storyPayload = {...data, 'storyId': storyId};

                if (storyType == 'Novel') {
                  // Load the first chapter for novels
                  try {
                    final chaptersSnap = await FirebaseFirestore.instance
                        .collection('stories')
                        .doc(storyId)
                        .collection('chapters')
                        .orderBy('chapterNumber')
                        .limit(1)
                        .get();

                    if (chaptersSnap.docs.isNotEmpty) {
                      final chapterData = chaptersSnap.docs.first.data();
                      storyPayload = {
                        ...data,
                        'storyId': storyId,
                        'body': chapterData['body'] ?? '',
                        'chapterNumber': chapterData['chapterNumber'] ?? 1,
                        'contentType': chapterData['contentType'] ?? 'Chapter',
                        'title': data['title'] ?? 'Untitled', // keep story title
                      };
                    }
                  } catch (e) {
                    debugPrint('Error loading chapter: $e');
                  }
                } else {
                  // For poetry, short story, flash fiction — body is on the story doc itself
                  storyPayload = {
                    ...data,
                    'storyId': storyId,
                    'body': data['body'] ?? '',
                    'chapterNumber': 1,
                    'contentType': data['contentType'] ?? 'Chapter',
                  };
                }

                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StoryReadScreen(story: storyPayload),
                    ),
                  );
                }
              },
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_stories_outlined, size: 64, color: AppTheme.inkUmber.withOpacity(0.2)),
          const SizedBox(height: 16),
          const Text(
            'Your shelf is empty',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.inkEspresso),
          ),
          const SizedBox(height: 8),
          Text(
            'Start reading stories to fill it up!',
            style: TextStyle(color: AppTheme.inkUmber.withOpacity(0.6)),
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

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Spine effect
                  Container(
                    width: 12,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.1),
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
                      color: color.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            data['title'] ?? 'Untitled',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppTheme.inkEspresso,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data['authorUsername'] ?? 'Unknown Author',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.inkUmber.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}
