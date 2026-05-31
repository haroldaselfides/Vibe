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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

  Future<void> _handleSave() async {
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

    setState(() => _isSaving = true);

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
        _showSnack('Story saved!', color: AppTheme.inkSage);
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
  // LIST VIEW
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildListView() {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.inkBgMain,
      appBar: AppBar(
        backgroundColor: AppTheme.inkBgMain,
        elevation: 0,
        leading: const SizedBox(),
        title: const Text('My Stories',
            style: TextStyle(
              fontFamily: 'Paytone One',
              fontSize: 17, 
              fontWeight: FontWeight.bold, 
              color: AppTheme.inkEspresso)),
        centerTitle: true,
      ),
      body: currentUser == null
          ? const Center(child: Text('Not logged in'))
          : Column(
              children: [
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
                          child: CircularProgressIndicator(color: AppTheme.inkTerracotta),
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

                      return GridView.builder(
                        padding: const EdgeInsets.fromLTRB(10, 12, 10, 16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.72,
                        ),
                        itemCount: sorted.length,
                        itemBuilder: (context, index) {
                          final doc = sorted[index];
                          final data = doc.data() as Map<String, dynamic>;
                          return StoryCard(
                            docId: doc.id,
                            data: data,
                            authorName: _authorName,
                            onEdit: () async => await _loadStory(doc.id, data),
                            onDelete: () => _deleteStory(doc.id),
                          );
                        },
                      );
                    },
                  ),
                ),
                Container(
                  padding: EdgeInsets.fromLTRB(
                      16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
                  decoration: BoxDecoration(
                    color: AppTheme.inkCanvas,
                    border: Border(
                        top: BorderSide(color: AppTheme.inkUmber.withValues(alpha: 0.12))),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _openNewStory,
                      icon: const Icon(Icons.add, size: 20),
                      label: const Text('New Story',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.inkTerracotta,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EDITOR VIEW
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildEditorView() {
    return Scaffold(
      backgroundColor: AppTheme.inkBgMain,
      appBar: AppBar(
        backgroundColor: AppTheme.inkBgMain,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppTheme.inkEspresso),
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
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: TextButton(
              onPressed: _isSaving ? null : _handleSave,
              style: TextButton.styleFrom(
                backgroundColor: AppTheme.inkTerracotta,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppTheme.inkTerracotta.withValues(alpha: 0.5),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                  : const Text('Save',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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
              color: AppTheme.inkCanvas,
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

  // ── Metadata bar ──────────────────────────────────────────────────────────
  // Shows genre · storyType · @author · wordCount · saved icon.
  // Reads directly from state so it re-renders on every setState() call,
  // including those triggered by the modal's onGenreChanged /
  // onStoryTypeChanged / onContentTypeChanged callbacks.
  Widget _buildMetadataBar() {
    final isPoetry = _storyType == 'Poetry';

    // For poetry: show poetry-type (stored in _selectedGenre) and theme
    // (stored in _contentType). For everything else: show genre and storyType.
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
          // Decorative dash
          Container(
            width: 32,
            height: 3,
            decoration: BoxDecoration(
              color: AppTheme.inkTerracotta.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),

          // Left tag (genre or poetry-type)
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

          // Right tag (storyType or theme)
          Text(
            rightLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: rightColor,
              letterSpacing: 0.5,
            ),
          ),

          // Author name
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

          // Word count
          Text(
            '$_wordCount words',
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.inkUmber.withValues(alpha: 0.6),
            ),
          ),

          // Saved indicator
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

  // ── Story setup modal ─────────────────────────────────────────────────────
  // KEY FIX: every callback calls setState() so _buildMetadataBar() re-renders
  // immediately — even while the modal overlay is still open — because the
  // parent Scaffold rebuilds and the metadata bar is part of the editor body
  // that sits *behind* the modal (still rendered, just overlaid).
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
            // Reset to sensible defaults when switching types
            if (value == 'Poetry') {
              _selectedGenre = 'Lyric Poetry';
              _contentType = 'Love';
            } else {
              // Coming back from poetry: restore prose defaults if needed
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