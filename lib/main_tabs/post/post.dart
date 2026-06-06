import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../story/story_setup_modal.dart';
import '../../theme/new_app_theme.dart';
import '../../theme/app_typography.dart';
import 'editor_chapters_sidebar.dart';
import 'package:vibewrite_app/main_tabs/post/editors_content_widgets.dart';
import 'post_screen_utils.dart';
import 'dart:convert';
import 'package:flutter_quill/flutter_quill.dart';

enum _ViewMode { list, editor }

enum _StoryStatus { drafting, completed }

class PostScreen extends StatefulWidget {
  final Function(bool)? onEditorModeChanged;

  const PostScreen({
    super.key,
    this.onEditorModeChanged,
  });

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  _ViewMode _viewMode = _ViewMode.list;
  String _currentChapterTitle = '';

  final TextEditingController _titleController = TextEditingController();
  late QuillController _bodyController;
  final FocusNode _bodyFocusNode = FocusNode();
  final TextEditingController _chapterController =
      TextEditingController(text: '1');
  final TextEditingController _chapterTitleController =
      TextEditingController();

  String _selectedGenre = 'Romance';
  String _storyType = 'Short Story';
  String _contentType = 'Chapter';

  bool _isSaving = false;
  bool _isSaved = false;
  bool _isPublished = false;
  bool _currentChapterPublished = false;

  _StoryStatus _storyStatus = _StoryStatus.drafting;

  String? _savedStoryId;
  String _authorName = '';

  final List<String> _storyTypes = [
    'Short Story',
    'Flash Fiction',
    'Novel',
    'Poetry'
  ];
  final List<String> _contentTypes = ['Prologue', 'Chapter', 'Epilogue'];
  final List<String> _genres = [
    'Romance',
    'Mystery',
    'Fantasy',
    'Sci-Fi',
    'Drama',
    'Horror',
    'Thriller'
  ];

  @override
  void initState() {
    super.initState();
    _bodyController = QuillController.basic();
    _listenToEditor();
    _loadAuthorName();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _bodyFocusNode.dispose();
    _chapterController.dispose();
    _chapterTitleController.dispose();
    super.dispose();
  }

  Future<void> _loadAuthorName() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      if (mounted) {
        if (doc.exists && doc.data() != null) {
          final username =
              (doc.data()?['username'] as String? ?? '').trim();
          if (username.isNotEmpty) {
            setState(() => _authorName = username);
          }
        } else {
          setState(
              () => _authorName = currentUser.displayName ?? "Anonymous");
        }
      }
    } catch (e) {
      debugPrint('Could not load author username: $e');
    }
  }

  void _openNewStory() {
    _titleController.clear();
    _chapterTitleController.clear();
    _currentChapterTitle = '';
    _bodyController.document = Document()..insert(0, '\n');
    _chapterController.text = '1';
    setState(() {
      _selectedGenre = 'Romance';
      _storyType = 'Short Story';
      _contentType = 'Chapter';
      _isSaved = false;
      _isPublished = false;
      _savedStoryId = null;
      _viewMode = _ViewMode.editor;
      _currentChapterPublished = false;
      _storyStatus = _StoryStatus.drafting;
    });
    widget.onEditorModeChanged?.call(true);
  }

  Future<void> _loadStory(
      String storyId, Map<String, dynamic> data) async {
    try {
      final bodyData = data['body'] ?? '';
      Document document = Document()..insert(0, '\n');

      if (bodyData is String && bodyData.isNotEmpty) {
        try {
          final decoded = jsonDecode(bodyData);
          document = Document.fromJson(decoded);
        } catch (e) {
          document = Document()..insert(0, '$bodyData\n');
        }
      } else if (bodyData is Map || bodyData is List) {
        try {
          document = Document.fromJson(bodyData);
        } catch (e) {
          document = Document()..insert(0, '\n');
        }
      }

      final statusStr = data['status'] as String? ?? 'drafting';
      final loadedStatus = statusStr == 'completed'
          ? _StoryStatus.completed
          : _StoryStatus.drafting;

      if (mounted) {
        setState(() {
          _bodyController.document = document;
          _titleController.text = data['title'] ?? '';
          _selectedGenre = data['genre'] ?? 'Romance';
          _storyType = data['storyType'] ?? 'Short Story';
          _contentType = data['contentType'] ?? 'Chapter';
          _chapterController.text = (data['chapter'] ?? 1).toString();
          _savedStoryId = storyId;
          _isPublished = data['isPublished'] ?? false;
          _currentChapterPublished = data['isPublished'] ?? false;
          _isSaved = true;
          _viewMode = _ViewMode.editor;
          _storyStatus = loadedStatus;
        });
        widget.onEditorModeChanged?.call(true);
      }

      if (_storyType == 'Novel') {
        try {
          final chaptersSnapshot = await FirebaseFirestore.instance
              .collection('stories')
              .doc(storyId)
              .collection('chapters')
              .orderBy('chapterNumber', descending: true)
              .limit(1)
              .get();

          if (chaptersSnapshot.docs.isNotEmpty && mounted) {
            final chapterData = chaptersSnapshot.docs.first.data();
            final chapterBodyData = chapterData['body'] ?? '';
            Document chapterDocument = Document()..insert(0, '\n');

            if (chapterBodyData is String && chapterBodyData.isNotEmpty) {
              try {
                final decoded = jsonDecode(chapterBodyData);
                chapterDocument = Document.fromJson(decoded);
              } catch (e) {
                chapterDocument =
                    Document()..insert(0, '$chapterBodyData\n');
              }
            }

            setState(() {
              _chapterController.text =
                  (chapterData['chapterNumber'] ?? 1).toString();
              _chapterTitleController.text = chapterData['title'] ?? '';
              _currentChapterTitle = chapterData['title'] ?? '';
              _contentType = chapterData['contentType'] ?? 'Chapter';
              _bodyController.document = chapterDocument;
              _currentChapterPublished =
                  chapterData['isPublished'] ?? false;
            });
          }
        } catch (e) {
          debugPrint('Error loading chapters: $e');
        }
      }
    } catch (e) {
      debugPrint('Error loading story: $e');
      if (mounted)
        _showSnack('Error loading story. Please try again.',
            color: AppTheme.inkMaroon);
    }
  }

  Future<void> _deleteStory(String storyId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete story?',
            style: AppTypography.headingSm
                .copyWith(color: AppTheme.inkMaroon)),
        content:
            Text('This cannot be undone.', style: AppTypography.bodyMd),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel',
                style: AppTypography.labelMd
                    .copyWith(color: AppTheme.inkUmber)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.inkMaroon,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
            child: Text('Delete', style: AppTypography.buttonMedium),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        final storyRef =
            FirebaseFirestore.instance.collection('stories').doc(storyId);
        final chapters = await storyRef.collection('chapters').get();
        for (final doc in chapters.docs) {
          await doc.reference.delete();
        }
        await storyRef.delete();
        if (mounted) {
          _showSnack('Story deleted', color: AppTheme.inkMaroon);
        }
      } catch (e) {
        if (mounted) {
          _showSnack('Error deleting: $e', color: AppTheme.inkMaroon);
        }
      }
    }
  }

  Future<void> _handleSave({bool? publishStatus}) async {
    final title = _titleController.text.trim();
    final body =
        jsonEncode(_bodyController.document.toDelta().toJson());

    if (title.isEmpty) {
      _showSnack('Please add a title before saving.',
          color: AppTheme.inkUmber);
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _showSnack('You must be logged in to save.',
          color: AppTheme.inkUmber);
      return;
    }

    final targetPublishState = publishStatus ?? _isPublished;
    setState(() {
      _isSaving = true;
      _isPublished = targetPublishState;
    });

    try {
      final storiesRef =
          FirebaseFirestore.instance.collection('stories');
      bool parentStoryPublishState = targetPublishState;

      if (_storyType == 'Novel' && _savedStoryId != null) {
        final chaptersSnapshot = await FirebaseFirestore.instance
            .collection('stories')
            .doc(_savedStoryId)
            .collection('chapters')
            .where('isPublished', isEqualTo: true)
            .limit(1)
            .get();
        parentStoryPublishState =
            targetPublishState || chaptersSnapshot.docs.isNotEmpty;
      }

      final data = {
        'title': title,
        'genre': _selectedGenre,
        'storyType': _storyType,
        'contentType': _contentType,
        'wordCount': _wordCount,
        'updatedAt': FieldValue.serverTimestamp(),
        'authorUsername': _authorName,
        'isPublished': parentStoryPublishState,
        'status': _storyStatus == _StoryStatus.completed
            ? 'completed'
            : 'drafting',
      };

      if (_savedStoryId == null) {
        final docRef = await storiesRef.add({
          ...data,
          'body': body,
          'createdAt': FieldValue.serverTimestamp(),
          'authorId': currentUser.uid,
          'authorEmail': currentUser.email ?? '',
          'likes': 0,
        });
        _savedStoryId = docRef.id;
      } else {
        await storiesRef
            .doc(_savedStoryId)
            .update({...data, 'body': body});
      }

      if (_storyType == 'Novel' && _savedStoryId != null) {
        int chapterNum;
        if (_contentType == 'Prologue') {
          chapterNum = 0;
        } else if (_contentType == 'Epilogue') {
          chapterNum = 999;
        } else {
          chapterNum = int.tryParse(_chapterController.text) ?? 1;
        }

        final chapterRef = storiesRef
            .doc(_savedStoryId)
            .collection('chapters')
            .doc('chapter_$chapterNum');

        final existing = await chapterRef.get();

        await chapterRef.set({
          'chapterNumber': chapterNum,
          'title': _currentChapterTitle,
          'body': body,
          'wordCount': _wordCount,
          'contentType': _contentType,
          'updatedAt': FieldValue.serverTimestamp(),
          'isPublished': targetPublishState,
          if (!existing.exists)
            'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        _currentChapterPublished = targetPublishState;
      }

      if (mounted) {
        setState(() {
          _isSaved = true;
          _currentChapterPublished = targetPublishState;
        });
        if (targetPublishState) {
          _showSnack(
            'Chapter published successfully!',
            color: AppTheme.inkSage,
          );
        } else {
          _showSnack(
            'Draft saved securely!',
            color: AppTheme.inkSage,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Save failed: $e', color: AppTheme.inkMaroon);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _handleChapterSelected(
      int chapterNumber, Map<String, dynamic> data) {
    final bodyData = data['body'] ?? '';
    Document document = Document()..insert(0, '\n');

    if (bodyData is String && bodyData.isNotEmpty) {
      try {
        final decoded = jsonDecode(bodyData);
        document = Document.fromJson(decoded);
      } catch (e) {
        document = Document()..insert(0, '$bodyData\n');
      }
    } else if (bodyData is Map || bodyData is List) {
      try {
        document = Document.fromJson(bodyData);
      } catch (e) {
        debugPrint('Error parsing chapter body: $e');
      }
    }

    setState(() {
      _bodyController.document = document;
      _chapterController.text = chapterNumber.toString();
      _chapterTitleController.text = data['title'] ?? '';
      _contentType = data['contentType'] ?? 'Chapter';
      _currentChapterTitle = data['title'] ?? '';
      _currentChapterPublished = data['isPublished'] ?? false;
      _isSaved = true;
    });
  }

  void _listenToEditor() {
    _bodyController.document.changes.listen((event) {
      if (mounted) setState(() => _isSaved = false);
    });
  }

  void _handleAddNewChapter(int chapterNumber) {
    setState(() {
      _chapterController.text = chapterNumber.toString();
      _bodyController.document = Document()..insert(0, '\n');
      _chapterTitleController.clear();
      _currentChapterTitle = '';
      _contentType = 'Chapter';
      _isSaved = false;
      _currentChapterPublished = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bodyFocusNode.requestFocus();
    });
  }

  void _openChaptersModal() {
    if (_savedStoryId == null || _savedStoryId!.isEmpty) return;
    EditorChaptersSidebar.show(
      context: context,
      storyId: _savedStoryId!,
      currentChapter: int.tryParse(_chapterController.text) ?? 1,
      onChapterSelected: _handleChapterSelected,
      onAddNewChapter: _handleAddNewChapter,
    );
  }

  void _showSnack(String message, {required Color color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style:
                AppTypography.bodyMd.copyWith(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  int get _wordCount =>
      PostScreenUtils.getWordCount(
          _bodyController.document.toPlainText());

  Future<void> _confirmDiscard() async {
    final hasUnsaved =
        (_titleController.text.isNotEmpty ||
                _bodyController.document.length > 1) &&
            !_isSaved;

    if (!hasUnsaved) {
      setState(() => _viewMode = _ViewMode.list);
      widget.onEditorModeChanged?.call(false);
      return;
    }

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Unsaved changes',
            style: AppTypography.headingSm
                .copyWith(color: AppTheme.inkEspresso)),
        content: Text('Would you like to save before leaving?',
            style: AppTypography.bodyMd),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('discard'),
            style:
                TextButton.styleFrom(foregroundColor: AppTheme.inkUmber),
            child: Text('Discard', style: AppTypography.labelMd),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('keep'),
            child: Text('Keep Writing',
                style: AppTypography.labelMd
                    .copyWith(color: AppTheme.inkMaroon)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop('save'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.inkMaroon,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
            child: Text('Save & Back', style: AppTypography.buttonMedium),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (result == 'discard') {
      setState(() => _viewMode = _ViewMode.list);
      widget.onEditorModeChanged?.call(false);
    } else if (result == 'save') {
      await _handleSave();
      if (mounted && _isSaved) {
        setState(() => _viewMode = _ViewMode.list);
        widget.onEditorModeChanged?.call(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _viewMode == _ViewMode.list
        ? _buildListView()
        : _buildEditorView();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LIST VIEW
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildListView() {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      floatingActionButton: FloatingActionButton(
        onPressed: _openNewStory,
        backgroundColor: AppTheme.inkMaroon,
        elevation: 6,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        bottom: false,
        child: currentUser == null
            ? Center(
                child:
                    Text('Not logged in', style: AppTypography.bodyMd))
            : Column(
                children: [
                  _buildDashboardHeader(currentUser),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('stories')
                          .where('authorId',
                              isEqualTo: currentUser.uid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Text('Error loading stories',
                                style: AppTypography.bodyMd.copyWith(
                                    color: AppTheme.inkMaroon)),
                          );
                        }
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                                color: AppTheme.inkMaroon),
                          );
                        }

                        final docs = snapshot.data?.docs ?? [];

                        if (docs.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Icon(Icons.history_edu,
                                    size: 56,
                                    color: AppTheme.inkUmber
                                        .withValues(alpha: 0.25)),
                                const SizedBox(height: 12),
                                Text('No stories yet',
                                    style:
                                        AppTypography.headingSm.copyWith(
                                            color: AppTheme.inkUmber
                                                .withValues(
                                                    alpha: 0.5))),
                                const SizedBox(height: 6),
                                Text('Tap + below to start writing.',
                                    style: AppTypography.bodySm.copyWith(
                                        color: AppTheme.inkUmber
                                            .withValues(alpha: 0.4))),
                              ],
                            ),
                          );
                        }

                        final sorted = List.of(docs);
                        sorted.sort((a, b) {
                          final aTs = (a.data()
                              as Map<String,
                                  dynamic>)['updatedAt'] as Timestamp?;
                          final bTs = (b.data()
                              as Map<String,
                                  dynamic>)['updatedAt'] as Timestamp?;
                          if (aTs == null && bTs == null) return 0;
                          if (aTs == null) return 1;
                          if (bTs == null) return -1;
                          return bTs.compareTo(aTs);
                        });

                        return _buildStoryCards(sorted);
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ── Dashboard header ──────────────────────────────────────────────────────

  Widget _buildDashboardHeader(User currentUser) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('stories')
          .where('authorId', isEqualTo: currentUser.uid)
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        final count = docs.length;

        int totalWords = 0;
        for (final doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          totalWords += (data['wordCount'] as int? ?? 0);
        }

        final formattedWords = totalWords >= 1000
            ? '${(totalWords / 1000).toStringAsFixed(1)}k'
            : '$totalWords';

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: AppTheme.inkMaroon,
            boxShadow: [
              BoxShadow(
                color: AppTheme.inkMaroon.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Title row ──
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.history_edu,
                          color: Colors.white, size: 30),
                    ),
                    Text(
                      '  My Stories',
                      style: AppTypography.headingLg.copyWith(
                        color: Colors.white,
                        fontSize: 26,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$count Active ${count == 1 ? 'Project' : 'Projects'} · $formattedWords Total Words',
                  style: AppTypography.bodySm.copyWith(
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildStatChip(
                      icon: Icons.auto_stories_outlined,
                      label: 'Stories Active',
                      value: '$count',
                    ),
                    const SizedBox(width: 10),
                    _buildStatChip(
                      icon: Icons.text_fields_rounded,
                      label: 'Total Words',
                      value: formattedWords,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 16, color: Colors.white.withValues(alpha: 0.8)),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTypography.headingSm.copyWith(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.1,
                  ),
                ),
                Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Story cards grid ──────────────────────────────────────────────────────

  Widget _buildStoryCards(List<QueryDocumentSnapshot> documents) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      itemCount: (documents.length / 2).ceil(),
      itemBuilder: (context, rowIndex) {
        final int startIndex = rowIndex * 2;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(2, (colIndex) {
              final itemIndex = startIndex + colIndex;
              if (itemIndex >= documents.length) {
                return const Expanded(child: SizedBox.shrink());
              }
              final doc = documents[itemIndex];
              final data = doc.data() as Map<String, dynamic>;

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: colIndex == 1 ? 8 : 0,
                    right: colIndex == 0 ? 8 : 0,
                  ),
                  child: _StoryDashCard(
                    docId: doc.id,
                    data: data,
                    onEdit: () async => await _loadStory(doc.id, data),
                    onDelete: () => _deleteStory(doc.id),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EDITOR VIEW
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildEditorView() {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back, color: AppTheme.inkEspresso),
          onPressed: _confirmDiscard,
        ),
        title: Text(
          _savedStoryId == null ? 'New Story' : 'Edit Story',
          style: AppTypography.headingSm
              .copyWith(color: AppTheme.inkEspresso),
        ),
        centerTitle: true,
        actions: [
          if (_storyType == 'Novel' && _savedStoryId != null)
            Padding(
              padding: const EdgeInsets.only(right: 4.0),
              child: GestureDetector(
                onTap: _openChaptersModal,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color:
                        AppTheme.inkMaroon.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppTheme.inkMaroon
                            .withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.menu_book_outlined,
                          size: 16, color: AppTheme.inkMaroon),
                    ],
                  ),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: GestureDetector(
              onTap: _openStorySetupModal,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.inkUmber.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color:
                          AppTheme.inkUmber.withValues(alpha: 0.12)),
                ),
                child: const Icon(Icons.tune,
                    size: 16, color: AppTheme.inkUmber),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _storyStatus =
                      _storyStatus == _StoryStatus.completed
                          ? _StoryStatus.drafting
                          : _StoryStatus.completed;
                  _isSaved = false;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _storyStatus == _StoryStatus.completed
                      ? AppTheme.inkSage.withValues(alpha: 0.15)
                      : AppTheme.inkGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _storyStatus == _StoryStatus.completed
                        ? AppTheme.inkSage.withValues(alpha: 0.4)
                        : AppTheme.inkGold.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _storyStatus == _StoryStatus.completed
                          ? Icons.check_circle_outline
                          : Icons.edit_outlined,
                      size: 14,
                      color: _storyStatus == _StoryStatus.completed
                          ? AppTheme.inkSage
                          : AppTheme.inkUmber,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _storyStatus == _StoryStatus.completed
                          ? 'Completed'
                          : 'In Progress',
                      style: AppTypography.labelSm.copyWith(
                        color: _storyStatus == _StoryStatus.completed
                            ? AppTheme.inkSage
                            : AppTheme.inkUmber,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: PopupMenuButton<bool>(
              offset: const Offset(0, 40),
              onSelected: (bool publishSetting) =>
                  _handleSave(publishStatus: publishSetting),
              itemBuilder: (BuildContext context) => [
                PopupMenuItem<bool>(
                  value: false,
                  child: Row(
                    children: [
                      Icon(Icons.insert_drive_file_outlined,
                          size: 18, color: AppTheme.inkUmber),
                      const SizedBox(width: 8),
                      Text('Save as Draft',
                          style: AppTypography.bodyMd),
                    ],
                  ),
                ),
                PopupMenuItem<bool>(
                  value: true,
                  child: Row(
                    children: [
                      Icon(Icons.public_rounded,
                          size: 18, color: AppTheme.inkSage),
                      const SizedBox(width: 8),
                      Text(
                        _isPublished
                            ? 'Update Public Post'
                            : 'Publish to Public',
                        style: AppTypography.bodyMd,
                      ),
                    ],
                  ),
                ),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: (_storyType == 'Novel'
                          ? _currentChapterPublished
                          : _isPublished)
                      ? AppTheme.inkSage
                      : AppTheme.inkMaroon,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(
                                    Colors.white)))
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _storyType == 'Novel'
                                ? (_currentChapterPublished
                                    ? 'Chapter Public'
                                    : 'Save Options')
                                : (_isPublished
                                    ? 'Published'
                                    : 'Save Options'),
                            style: AppTypography.labelMd
                                .copyWith(color: Colors.white),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_drop_down,
                              size: 16, color: Colors.white),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _buildEditorContent(),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              border: Border(
                  top: BorderSide(
                      color:
                          AppTheme.inkUmber.withValues(alpha: 0.12))),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: QuillSimpleToolbar(
                  controller: _bodyController,
                  config: QuillSimpleToolbarConfig(
                    showAlignmentButtons: true,
                    showLeftAlignment: true,
                    showCenterAlignment: true,
                    showRightAlignment: true,
                    showJustifyAlignment: true,
                    showBoldButton: true,
                    showItalicButton: true,
                    showUnderLineButton: true,
                    showStrikeThrough: true,
                    showListBullets: true,
                    showListNumbers: true,
                    showQuote: true,
                    showIndent: false,
                    showLink: false,
                    showSearchButton: false,
                    showSubscript: false,
                    showSuperscript: false,
                    showHeaderStyle: false,
                    showSmallButton: false,
                    showInlineCode: false,
                    showColorButton: false,
                    showBackgroundColorButton: false,
                    showClearFormat: true,
                    showUndo: true,
                    showRedo: true,
                    showFontFamily: false,
                    showFontSize: false,
                    showDividers: true,
                    multiRowsDisplay: false,
                    toolbarSize: 42,
                    buttonOptions: QuillSimpleToolbarButtonOptions(
                      base: QuillToolbarBaseButtonOptions(
                        iconTheme: QuillIconTheme(
                          iconButtonSelectedData: IconButtonData(
                            style: ButtonStyle(
                              backgroundColor:
                                  WidgetStatePropertyAll(
                                      AppTheme.inkMaroon),
                              foregroundColor:
                                  const WidgetStatePropertyAll(
                                      Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorContent() {
    switch (_storyType) {
      case 'Poetry':
        return PoetryEditorContent(
          titleController: _titleController,
          bodyController: _bodyController,
          bodyFocusNode: _bodyFocusNode,
          onTitleChanged: () => setState(() => _isSaved = false),
          metadataBar: _buildMetadataBar(),
        );
      case 'Novel':
        return NovelEditorContent(
          titleController: _titleController,
          chapterTitleController: _chapterTitleController,
          bodyController: _bodyController,
          bodyFocusNode: _bodyFocusNode,
          onTitleChanged: () => setState(() => _isSaved = false),
          onChapterTitleChanged: () {
            _currentChapterTitle = _chapterTitleController.text;
            setState(() => _isSaved = false);
          },
          metadataBar: _buildMetadataBar(),
          hintText: PostScreenUtils.getNovelHintText(_contentType),
        );
      default:
        return StandardEditorContent(
          titleController: _titleController,
          bodyController: _bodyController,
          bodyFocusNode: _bodyFocusNode,
          onTitleChanged: () => setState(() => _isSaved = false),
          metadataBar: _buildMetadataBar(),
        );
    }
  }

  Widget _buildMetadataBar() {
    final isPoetry = _storyType == 'Poetry';
    final String leftLabel = _selectedGenre;
    final String rightLabel =
        isPoetry ? _contentType : _storyType;
    final Color leftColor = isPoetry
        ? PostScreenUtils.getContentTypeColor(_selectedGenre)
        : PostScreenUtils.getGenreTagColor(_selectedGenre);
    final Color rightColor = isPoetry
        ? PostScreenUtils.getContentTypeColor(_contentType)
        : PostScreenUtils.getStoryTypeTagColor(_storyType);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 3,
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(leftLabel,
              style:
                  AppTypography.tagGenre.copyWith(color: leftColor)),
          const SizedBox(width: 6),
          Text('·',
              style: AppTypography.caption.copyWith(
                  color:
                      AppTheme.inkUmber.withValues(alpha: 0.5))),
          const SizedBox(width: 6),
          Text(rightLabel,
              style: AppTypography.tagStoryType
                  .copyWith(color: rightColor)),
          if (_authorName.isNotEmpty) ...[
            const SizedBox(width: 10),
            Text('@$_authorName',
                style: AppTypography.caption.copyWith(
                    color:
                        AppTheme.inkUmber.withValues(alpha: 0.6))),
          ],
          const Spacer(),
          Text('$_wordCount words',
              style: AppTypography.wordCount),
          if (_isSaved) ...[
            const SizedBox(width: 10),
            Icon(Icons.cloud_done_outlined,
                size: 13,
                color: AppTheme.inkSage.withValues(alpha: 0.8)),
          ],
        ],
      ),
    );
  }

  void _openStorySetupModal() {
    StorySetupModal.show(
      context: context,
      selectedGenre: _selectedGenre,
      storyType: _storyType,
      contentType: _contentType,
      storyTypes: _storyTypes,
      genres: _genres,
      contentTypes: _contentTypes,
      onGenreChanged: (value) {
        if (mounted) setState(() => _selectedGenre = value);
      },
      onStoryTypeChanged: (value) {
        if (mounted) {
          setState(() {
            _storyType = value;
            if (value != 'Poetry') {
              final validGenres = [
                'Romance',
                'Mystery',
                'Fantasy',
                'Sci-Fi',
                'Drama',
                'Horror',
                'Thriller'
              ];
              if (!validGenres.contains(_selectedGenre))
                _selectedGenre = 'Romance';
              final validContentTypes = [
                'Prologue',
                'Chapter',
                'Epilogue'
              ];
              if (!validContentTypes.contains(_contentType))
                _contentType = 'Chapter';
            }
          });
        }
      },
      onContentTypeChanged: (value) {
        if (mounted) setState(() => _contentType = value);
      },
      genreColor: PostScreenUtils.getGenreTagColor,
      storyTypeColor: PostScreenUtils.getStoryTypeTagColor,
      contentTypeColor: PostScreenUtils.getContentTypeColor,
    );
  }
}

// ─── Story dash card ──────────────────────────────────────────────────────────

class _StoryDashCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _StoryDashCard({
    required this.docId,
    required this.data,
    required this.onEdit,
    required this.onDelete,
  });

  Color _coverColor(String genre) {
    switch (genre.toLowerCase()) {
      case 'romance':   return const Color(0xFFF3D1D1);
      case 'mystery':   return const Color(0xFFD5D6EA);
      case 'fantasy':   return const Color(0xFFD1E7DD);
      case 'sci-fi':    return const Color(0xFFD1DCE7);
      case 'horror':    return const Color(0xFFE7D5D5);
      case 'thriller':  return const Color(0xFFE7E2D5);
      case 'drama':     return const Color(0xFFE7D5E2);
      default:          return const Color(0xFFEFE5D8);
    }
  }

  String _timeAgo(Timestamp? ts) {
    if (ts == null) return '';
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.inMinutes < 60) return 'Updated ${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return 'Updated ${diff.inHours}h ago';
    if (diff.inDays == 1)    return 'Updated yesterday';
    return 'Updated ${diff.inDays} days ago';
  }

  @override
  Widget build(BuildContext context) {
    final genre       = data['genre']       as String?  ?? 'Fantasy';
    final title       = data['title']       as String?  ?? 'Untitled';
    final storyType   = data['storyType']   as String?  ?? 'Short Story';
    final isPublished = data['isPublished'] as bool?    ?? false;
    final wordCount   = data['wordCount']   as int?     ?? 0;
    final updatedAt   = data['updatedAt']   as Timestamp?;
    final cover       = _coverColor(genre);

    final statusStr  = data['status'] as String? ?? 'drafting';
    final isCompleted = statusStr == 'completed';

    final targetWords = storyType == 'Novel'
        ? 80000
        : storyType == 'Short Story'
            ? 7500
            : 1000;
    final progress = isCompleted
        ? 1.0
        : (wordCount / targetWords).clamp(0.0, 1.0);

    final progressLabel = isCompleted ? 'Completed' : 'Still Updating';
    final progressColor = isCompleted
        ? AppTheme.inkSage
        : isPublished
            ? AppTheme.inkSage
            : AppTheme.inkMaroon;

    return GestureDetector(
      onTap: onEdit,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.inkCanvas,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Cover ────────────────────────────────────
            Stack(
              children: [
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: cover,
                    borderRadius: const BorderRadius.only(
                      topLeft:  Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Center(
                    child: Opacity(
                      opacity: 0.35,
                      child: Icon(
                        PostScreenUtils.getGenreIcon(genre),
                        size: 52,
                        color: AppTheme.inkEspresso,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 10, left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isPublished
                          ? AppTheme.inkSage.withValues(alpha: 0.9)
                          : AppTheme.inkGold.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5, height: 5,
                          decoration: BoxDecoration(
                            color: isPublished
                                ? Colors.white
                                : AppTheme.inkEspresso,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isPublished ? 'Published' : 'Draft',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isPublished
                                ? Colors.white
                                : AppTheme.inkEspresso,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 6, right: 6,
                  child: PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert,
                        size: 18,
                        color: AppTheme.inkEspresso
                            .withValues(alpha: 0.6)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    onSelected: (v) {
                      if (v == 'edit')   onEdit();
                      if (v == 'delete') onDelete();
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(children: [
                          const Icon(Icons.edit_outlined, size: 16),
                          const SizedBox(width: 8),
                          Text('Edit', style: AppTypography.bodyMd),
                        ]),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [
                          Icon(Icons.delete_outline,
                              size: 16, color: AppTheme.inkMaroon),
                          const SizedBox(width: 8),
                          Text('Delete',
                              style: AppTypography.bodyMd.copyWith(
                                  color: AppTheme.inkMaroon)),
                        ]),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ── Info ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.headingSm.copyWith(
                      fontSize: 15,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$genre · $storyType',
                    style: AppTypography.caption.copyWith(
                      color: AppTheme.inkUmber.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Word count
                  Row(
                    children: [
                      Icon(Icons.description_outlined,
                          size: 11,
                          color: AppTheme.inkUmber
                              .withValues(alpha: 0.6)),
                      const SizedBox(width: 3),
                      Text(
                        '${wordCount >= 1000 ? '${(wordCount / 1000).toStringAsFixed(1)}k' : wordCount} words',
                        style: AppTypography.caption
                            .copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                  if (updatedAt != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded,
                            size: 11,
                            color: AppTheme.inkUmber
                                .withValues(alpha: 0.6)),
                        const SizedBox(width: 3),
                        Text(
                          _timeAgo(updatedAt),
                          style: AppTypography.caption
                              .copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),

                  // Progress
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isCompleted
                                ? Icons.check_circle_outline
                                : Icons.edit_outlined,
                            size: 10,
                            color: progressColor
                                .withValues(alpha: 0.8),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            progressLabel,
                            style: AppTypography.caption.copyWith(
                              fontSize: 10,
                              color: progressColor
                                  .withValues(alpha: 0.85),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        isCompleted
                            ? '✓'
                            : '${(progress * 100).toInt()}%',
                        style: AppTypography.caption.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.inkEspresso,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 5,
                      backgroundColor:
                          AppTheme.inkUmber.withValues(alpha: 0.12),
                      valueColor:
                          AlwaysStoppedAnimation<Color>(progressColor),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Genre tag
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: cover,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          PostScreenUtils.getGenreIcon(genre),
                          size: 11,
                          color: AppTheme.inkEspresso
                              .withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          genre,
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.inkEspresso
                                .withValues(alpha: 0.8),
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
      ),
    );
  }
}