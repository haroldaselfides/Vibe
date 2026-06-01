import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../story/story_setup_modal.dart';
import '../../theme/app_theme.dart';
import 'editor_chapters_modal.dart';
import 'package:vibewrite_app/main_tabs/post/editors_content_widgets.dart';
import 'post_screen_utils.dart';
import 'story_card.dart';
import 'dart:convert';
import 'package:flutter_quill/flutter_quill.dart';

enum _ViewMode { list, editor }

class PostScreen extends StatefulWidget {
  const PostScreen({super.key});

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  _ViewMode _viewMode = _ViewMode.list;
  String _currentChapterTitle = '';

  final TextEditingController _titleController = TextEditingController();
  late QuillController _bodyController;
  final FocusNode _bodyFocusNode = FocusNode();
  final TextEditingController _chapterController = TextEditingController(text: '1');
  final TextEditingController _chapterTitleController = TextEditingController();

  String _selectedGenre = 'Romance';
  String _storyType = 'Short Story';
  String _contentType = 'Chapter';

  bool _isSaving = false;
  bool _isSaved = false;
  bool _isPublished = false; // Tracks if the story is a draft or public

  String? _savedStoryId;
  String _authorName = '';

  final List<String> _storyTypes = ['Short Story', 'Flash Fiction', 'Novel', 'Poetry'];
  final List<String> _contentTypes = ['Prologue', 'Chapter', 'Epilogue'];
  final List<String> _genres = ['Romance', 'Mystery', 'Fantasy', 'Sci-Fi', 'Drama', 'Horror', 'Thriller'];

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
      if (doc.exists) {
        final username = (doc.data()?['username'] as String? ?? '').trim();
        if (mounted && username.isNotEmpty) setState(() => _authorName = username);
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
      _isPublished = false; // New stories default to draft status
      _savedStoryId = null;
      _viewMode = _ViewMode.editor;
    });
  }

  Future<void> _loadStory(String storyId, Map<String, dynamic> data) async {
    try {
      final bodyData = data['body'] ?? '';
      Document document = Document()..insert(0, '\n');

      if (bodyData is String && bodyData.isNotEmpty) {
        try {
          final decoded = jsonDecode(bodyData);
          document = Document.fromJson(decoded);
        } catch (e) {
          debugPrint('Error parsing body JSON string: $e');
          document = Document()..insert(0, '$bodyData\n');
        }
      } else if (bodyData is Map || bodyData is List) {
        try {
          document = Document.fromJson(bodyData);
        } catch (e) {
          debugPrint('Error parsing body Map/List: $e');
          document = Document()..insert(0, '\n');
        }
      }

      if (mounted) {
        setState(() {
          _bodyController.document = document;
          _titleController.text = data['title'] ?? '';
          _selectedGenre = data['genre'] ?? 'Romance';
          _storyType = data['storyType'] ?? 'Short Story';
          _contentType = data['contentType'] ?? 'Chapter';
          _chapterController.text = (data['chapter'] ?? 1).toString();
          _savedStoryId = storyId;
          _isPublished = data['isPublished'] ?? false; // Load existing draft/published status
          _isSaved = true;
          _viewMode = _ViewMode.editor;
        });
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
                debugPrint('Error parsing body JSON string: $e');
                document = Document()..insert(0, bodyData);
              }
            }

            setState(() {
              _chapterController.text = (chapterData['chapterNumber'] ?? 1).toString();
              _chapterTitleController.text = chapterData['title'] ?? '';
              _currentChapterTitle = chapterData['title'] ?? '';
              _contentType = chapterData['contentType'] ?? 'Chapter';
              _bodyController.document = chapterDocument;
            });
          }
        } catch (e) {
          debugPrint('Error loading chapters: $e');
        }
      }
    } catch (e) {
      debugPrint('Error loading story: $e');
      if (mounted) {
        _showSnack('Error loading story. Please try again.', color: AppTheme.inkTerracotta);
      }
    }
  }

  Future<void> _deleteStory(String storyId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.inkBgMain,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete story?',
            style: TextStyle(color: AppTheme.inkEspresso, fontWeight: FontWeight.bold)),
        content: const Text('This cannot be undone.',
            style: TextStyle(fontSize: 14, color: AppTheme.inkUmber)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.inkUmber)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.inkTerracotta,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        final storyRef = FirebaseFirestore.instance.collection('stories').doc(storyId);
        final chapters = await storyRef.collection('chapters').get();
        for (final doc in chapters.docs) {
          await doc.reference.delete();
        }
        await storyRef.delete();
        if (mounted) _showSnack('Story deleted', color: AppTheme.inkTerracotta);
      } catch (e) {
        if (mounted) _showSnack('Error deleting: $e', color: AppTheme.inkTerracotta);
      }
    }
  }

  Future<void> _handleSave({bool? publishStatus}) async {
    final title = _titleController.text.trim();
    final body = jsonEncode(_bodyController.document.toDelta().toJson());

    if (title.isEmpty) {
      _showSnack('Please add a title before saving.', color: AppTheme.inkUmber);
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _showSnack('You must be logged in to save.', color: AppTheme.inkUmber);
      return;
    }

    setState(() {
      _isSaving = true;
      if (publishStatus != null) {
        _isPublished = publishStatus;
      }
    });

    try {
      final storiesRef = FirebaseFirestore.instance.collection('stories');
      final data = {
        'title': title,
        'genre': _selectedGenre,
        'storyType': _storyType,
        'contentType': _contentType,
        'wordCount': _wordCount,
        'updatedAt': FieldValue.serverTimestamp(),
        'authorUsername': _authorName,
        'isPublished': _isPublished, // Saves draft/published boolean to Firestore
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
        await storiesRef.doc(_savedStoryId).update({...data, 'body': body});
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

        await storiesRef
            .doc(_savedStoryId)
            .collection('chapters')
            .doc('chapter_$chapterNum')
            .set({
          'chapterNumber': chapterNum,
          'title': _currentChapterTitle,
          'body': body,
          'wordCount': _wordCount,
          'contentType': _contentType,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        setState(() => _isSaved = true);
        _showSnack(
          _isPublished ? 'Story published to the public!' : 'Draft saved securely!', 
          color: AppTheme.inkSage
        );
      }
    } catch (e) {
      if (mounted) _showSnack('Save failed: $e', color: AppTheme.inkTerracotta);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _handleChapterSelected(int chapterNumber, Map<String, dynamic> data) {
    final bodyData = data['body'] ?? '';
    Document document = Document()..insert(0, '\n');

    if (bodyData is String && bodyData.isNotEmpty) {
      try {
        final decoded = jsonDecode(bodyData);
        document = Document.fromJson(decoded);
      } catch (e) {
        debugPrint('Error parsing chapter JSON: $e');
        document = Document()..insert(0, '$bodyData\n');
      }
    } else if (bodyData is Map || bodyData is List) {
      try {
        document = Document.fromJson(bodyData);
      } catch (e) {
        debugPrint('Error parsing chapter body Map/List: $e');
      }
    }

    setState(() {
      _bodyController.document = document;
      _chapterController.text = chapterNumber.toString();
      _chapterTitleController.text = data['title'] ?? '';
      _contentType = data['contentType'] ?? 'Chapter';
      _currentChapterTitle = data['title'] ?? '';
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
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  int get _wordCount =>
      PostScreenUtils.getWordCount(_bodyController.document.toPlainText());

  Future<void> _confirmDiscard() async {
    final hasUnsaved =
        (_titleController.text.isNotEmpty || _bodyController.document.length > 1) &&
            !_isSaved;

    if (!hasUnsaved) {
      setState(() => _viewMode = _ViewMode.list);
      return;
    }

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.inkBgMain,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Unsaved changes',
            style: TextStyle(color: AppTheme.inkEspresso, fontWeight: FontWeight.bold)),
        content: const Text('Would you like to save before leaving?',
            style: TextStyle(fontSize: 14, color: AppTheme.inkUmber)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('discard'),
            style: TextButton.styleFrom(foregroundColor: AppTheme.inkUmber),
            child: const Text('Discard'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('keep'),
            style: TextButton.styleFrom(foregroundColor: AppTheme.inkTerracotta),
            child: const Text('Keep Writing'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop('save'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.inkTerracotta,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Save & Back'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (result == 'discard') {
      setState(() => _viewMode = _ViewMode.list);
    } else if (result == 'save') {
      await _handleSave();
      if (mounted && _isSaved) setState(() => _viewMode = _ViewMode.list);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _viewMode == _ViewMode.list ? _buildListView() : _buildEditorView();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LIST VIEW (RE-DESIGNED WITH THE REALISTIC WOODEN SHELF ENVIRONMENT)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildListView() {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF6ECE1), // Warm, textured cream base background
      body: SafeArea(
        bottom: false,
        child: currentUser == null
            ? const Center(child: Text('Not logged in'))
            : Column(
                children: [
                  _buildCustomDashboardHeader(),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('stories')
                          .where('authorId', isEqualTo: currentUser.uid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                'Error loading stories:\n${snapshot.error}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 13, color: AppTheme.inkTerracotta),
                              ),
                            ),
                          );
                        }

                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(color: Color(0xFFC87A53)),
                          );
                        }

                        final docs = snapshot.data?.docs ?? [];

                        if (docs.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.edit_note,
                                    size: 56, color: AppTheme.inkUmber.withValues(alpha: 0.25)),
                                const SizedBox(height: 12),
                                Text('No stories yet',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.inkUmber.withValues(alpha: 0.5))),
                                const SizedBox(height: 6),
                                Text('Tap "New Story" below to start writing.',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.inkUmber.withValues(alpha: 0.4))),
                              ],
                            ),
                          );
                        }

                        final sorted = List.of(docs);
                        sorted.sort((a, b) {
                          final aTs = (a.data() as Map<String, dynamic>)['updatedAt'] as Timestamp?;
                          final bTs = (b.data() as Map<String, dynamic>)['updatedAt'] as Timestamp?;
                          if (aTs == null && bTs == null) return 0;
                          if (aTs == null) return 1;
                          if (bTs == null) return -1;
                          return bTs.compareTo(aTs);
                        });

                        return _buildShelfGrid(sorted);
                      },
                    ),
                  ),
                  // Bottom Bar Container with Floating New Story Call-to-Action
                  Container(
                    padding: EdgeInsets.fromLTRB(
                        24, 12, 24, MediaQuery.of(context).padding.bottom + 16),
                    color: Colors.transparent,
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _openNewStory,
                        icon: const Icon(Icons.add, size: 20, color: Colors.white),
                        label: const Text('New Story',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC87A53),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          elevation: 4,
                          shadowColor: const Color(0xFFAC5C37).withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // Visual header matching the "My Stories" dashboard view from your mockups
  Widget _buildCustomDashboardHeader() {
    final currentUser = FirebaseAuth.instance.currentUser;
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: AppTheme.inkEspresso,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFAC5C37).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'My Stories',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('stories')
                          .where('authorId', isEqualTo: currentUser?.uid)
                          .snapshots(),
                      builder: (context, snap) {
                        final count = snap.data?.docs.length ?? 0;
                        return Text(
                          '$count Writing Projects Active',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
            const Icon(
              Icons.draw_rounded,
              color: AppTheme.inkTagRomance,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }

  // Row-by-Row 3D Wood Shelf renderer for the active dashboard
  Widget _buildShelfGrid(List<QueryDocumentSnapshot> documents) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: (documents.length / 2).ceil(), // Changing matrix allocation to 2 columns to align with wide StoryCards
      itemBuilder: (context, rowIndex) {
        final int startIndex = rowIndex * 2;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
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
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: StoryCard(
                        docId: doc.id,
                        data: data,
                        authorName: _authorName,
                        onEdit: () async => await _loadStory(doc.id, data),
                        onDelete: () => _deleteStory(doc.id),
                      ),
                    ),
                  );
                }),
              ),
            ),
            // Wood Shelf ledge divider matching the updated Library layout exactly
            Container(
              height: 14,
              margin: const EdgeInsets.only(bottom: 28, top: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFD2B48C), // Highlighting top wood reflection
                    Color(0xFFB58A55), // Mid wood core
                    Color(0xFF8B5A2B), // Deep ambient baseline drop-shadow
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: 6,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EDITOR VIEW
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildEditorView() {
    return Scaffold(
      backgroundColor: const Color(0xFFF6ECE1), // Harmonized cream canvas background
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6ECE1),
        elevation: 0,
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.inkEspresso),
          onPressed: _confirmDiscard,
        ),
        title: Text(
          _savedStoryId == null ? 'New Story' : 'Edit Story',
          style: const TextStyle(
              fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.inkEspresso),
        ),
        centerTitle: true,
        actions: [
          if (_storyType == 'Novel' && _savedStoryId != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: GestureDetector(
                onTap: _openChaptersModal,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.inkIndigo.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.inkIndigo.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.menu_book_outlined, size: 16, color: AppTheme.inkIndigo),
                      const SizedBox(width: 4),
                      const Text('Chapters',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.inkIndigo)),
                    ],
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: _openStorySetupModal,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.inkUmber.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.inkUmber.withValues(alpha: 0.12)),
                ),
                child: const Icon(Icons.tune, size: 16, color: AppTheme.inkUmber),
              ),
            ),
          ),
          
          // Split Save Draft & Publish Action Selector Menu
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: PopupMenuButton<bool>(
              offset: const Offset(0, 40),
              onSelected: (bool publishSetting) => _handleSave(publishStatus: publishSetting),
              itemBuilder: (BuildContext context) => [
                PopupMenuItem<bool>(
                  value: false,
                  child: Row(
                    children: [
                      Icon(Icons.insert_drive_file_outlined, size: 18, color: AppTheme.inkUmber),
                      const SizedBox(width: 8),
                      const Text('Save as Draft', style: TextStyle(fontSize: 13, color: AppTheme.inkEspresso)),
                    ],
                  ),
                ),
                PopupMenuItem<bool>(
                  value: true,
                  child: Row(
                    children: [
                      const Icon(Icons.public_rounded, size: 18, color: AppTheme.inkSage),
                      const SizedBox(width: 8),
                      Text(
                        _isPublished ? 'Update Public Post' : 'Publish to Public', 
                        style: const TextStyle(fontSize: 13, color: AppTheme.inkEspresso)
                      ),
                    ],
                  ),
                ),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _isPublished ? AppTheme.inkSage : const Color(0xFFC87A53),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _isPublished ? 'Published' : 'Save Options',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_drop_down, size: 16, color: Colors.white),
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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _buildEditorContent(),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFEFE4D6),
              border: Border(
                  top: BorderSide(color: AppTheme.inkUmber.withValues(alpha: 0.12))),
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
    final String rightLabel = isPoetry ? _contentType : _storyType;

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
              color: const Color(0xFFC87A53).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            leftLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: leftColor,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '·',
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.inkUmber.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            rightLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: rightColor,
              letterSpacing: 0.5,
            ),
          ),
          if (_authorName.isNotEmpty) ...[
            const SizedBox(width: 10),
            Text(
              '@$_authorName',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.inkUmber.withValues(alpha: 0.6),
              ),
            ),
          ],
          const Spacer(),
          Text(
            '$_wordCount words',
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.inkUmber.withValues(alpha: 0.6),
            ),
          ),
          if (_isSaved) ...[
            const SizedBox(width: 10),
            Icon(
              Icons.cloud_done_outlined,
              size: 13,
              color: AppTheme.inkSage.withValues(alpha: 0.8),
            ),
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
            if (value == 'Poetry') {
              _selectedGenre = 'Lyric Poetry';
              _contentType = 'Love';
            } else {
              final validGenres = ['Romance', 'Mystery', 'Fantasy', 'Sci-Fi', 'Drama', 'Horror', 'Thriller'];
              if (!validGenres.contains(_selectedGenre)) {
                _selectedGenre = 'Romance';
              }
              final validContentTypes = ['Prologue', 'Chapter', 'Epilogue'];
              if (!validContentTypes.contains(_contentType)) {
                _contentType = 'Chapter';
              }
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