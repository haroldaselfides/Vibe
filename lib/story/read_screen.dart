import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../story/chapter_list_modal.dart'; // adjust path as needed
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import '../theme/new_app_theme.dart';
import 'package:vibewrite_app/widgets/comment_section.dart';

// ── Reading Progress Status ───────────────────────────────────────────────────
enum ReadingStatus {
  notStarted,
  inProgress,
  completed,
}
extension ReadingStatusExt on ReadingStatus {
  String get value {
    switch (this) {
      case ReadingStatus.notStarted:
        return 'not_started';
      case ReadingStatus.inProgress:
        return 'in_progress';
      case ReadingStatus.completed:
        return 'completed';
    }
  }
  static ReadingStatus fromString(String? str) {
    switch (str) {
      case 'completed':
        return ReadingStatus.completed;
      case 'in_progress':
        return ReadingStatus.inProgress;
      default:
        return ReadingStatus.notStarted;
    }
  }
}

// ── Reading theme data ────────────────────────────────────────────────────────
class _ReadTheme {
  final String name;
  final Color bg;
  final Color surface;
  final Color text;
  final Color muted;
  final Color border;
  final Color card;
  final bool isDark;
  const _ReadTheme({
    required this.name,
    required this.bg,
    required this.surface,
    required this.text,
    required this.muted,
    required this.border,
    required this.card,
    this.isDark = false,
  });
}
const List<_ReadTheme> _kThemes = [
  _ReadTheme(
    name: 'Light',
    bg: Color(0xFFFFFFFF),
    surface: Color(0xFFF2F2F2),
    text: Color(0xFF2B1410),
    muted: Color(0xFF8B6F47),
    border: Color(0xFFE9DCC5),
    card: Color(0xFFF5EDE0),
  ),
  _ReadTheme(
    name: 'Sepia',
    bg: Color(0xFFF5F0E8),
    surface: Color(0xFFEDE8DF),
    text: Color(0xFF2C1A0E),
    muted: Color(0xFF8C7B6B),
    border: Color(0xFFD5CEBF),
    card: Color(0xFFE3DDD3),
  ),
  _ReadTheme(
    name: 'Dark',
    bg: Color(0xFF1E1E1E),
    surface: Color(0xFF2A2A2A),
    text: Color(0xFFE8E0D0),
    muted: Color(0xFF9A9080),
    border: Color(0xFF3A3A3A),
    card: Color(0xFF333333),
    isDark: true,
  ),
  _ReadTheme(
    name: 'Midnight',
    bg: Color(0xFF12151E),
    surface: Color(0xFF1A1E2A),
    text: Color(0xFFD4CEBF),
    muted: Color(0xFF7A7566),
    border: Color(0xFF2A2E3A),
    card: Color(0xFF222530),
    isDark: true,
  ),
];

// ── Line height options ───────────────────────────────────────────────────────
enum _LineHeight { compact, comfortable, spacious }
extension _LineHeightExt on _LineHeight {
  double get value {
    switch (this) {
      case _LineHeight.compact:
        return 1.6;
      case _LineHeight.comfortable:
        return 1.9;
      case _LineHeight.spacious:
        return 2.3;
    }
  }
  String get label {
    switch (this) {
      case _LineHeight.compact:
        return 'Compact';
      case _LineHeight.comfortable:
        return 'Comfortable';
      case _LineHeight.spacious:
        return 'Spacious';
    }
  }
}

// ── Delta → RichText renderer ─────────────────────────────────────────────────
class _DeltaText extends StatelessWidget {
  final String rawContent;
  final double fontSize;
  final double lineHeight;
  final Color color;
  const _DeltaText({
    required this.rawContent,
    required this.fontSize,
    required this.lineHeight,
    required this.color,
  });
  List<_Para> _buildParagraphs() {
    dynamic decoded;
    try {
      decoded = jsonDecode(rawContent);
    } catch (_) {
      return rawContent
          .split('\n')
          .map((line) => _Para(
                spans: line.isEmpty ? [] : [TextSpan(text: line)],
                align: TextAlign.start,
              ))
          .toList();
    }
    List<dynamic> ops;
    if (decoded is List) {
      ops = decoded;
    } else if (decoded is Map && decoded['ops'] is List) {
      ops = decoded['ops'] as List<dynamic>;
    } else {
      return [_Para(spans: [TextSpan(text: rawContent)], align: TextAlign.start)];
    }
    final paragraphs = <_Para>[];
    var currentSpans = <TextSpan>[];
    for (final op in ops) {
      if (op is! Map) continue;
      final insert = op['insert'];
      if (insert == null || insert is! String) continue;
      final attrs = op['attributes'];
      final align = _parseAlign(attrs);
      if (insert.isNotEmpty && insert.replaceAll('\n', '').isEmpty) {
        for (int i = 0; i < insert.length; i++) {
          paragraphs.add(_Para(spans: List.of(currentSpans), align: align));
          currentSpans = [];
        }
        continue;
      }
      final bool bold = attrs is Map && attrs['bold'] == true;
      final bool italic = attrs is Map && attrs['italic'] == true;
      final bool underline = attrs is Map && attrs['underline'] == true;
      final bool strike = attrs is Map && attrs['strike'] == true;
      final parts = insert.split('\n');
      for (int i = 0; i < parts.length; i++) {
        final text = parts[i];
        if (text.isNotEmpty) {
          currentSpans.add(TextSpan(
            text: text,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              fontStyle: italic ? FontStyle.italic : FontStyle.normal,
              decoration: _buildDecoration(underline, strike),
              decorationColor: color,
            ),
          ));
        }
        if (i < parts.length - 1) {
          paragraphs.add(_Para(spans: List.of(currentSpans), align: TextAlign.start));
          currentSpans = [];
        }
      }
    }
    if (currentSpans.isNotEmpty) {
      paragraphs.add(_Para(spans: currentSpans, align: TextAlign.start));
    }
    return paragraphs;
  }
  TextAlign _parseAlign(dynamic attrs) {
    if (attrs is! Map) return TextAlign.start;
    switch (attrs['align']) {
      case 'center':
        return TextAlign.center;
      case 'right':
        return TextAlign.right;
      case 'justify':
        return TextAlign.justify;
      default:
        return TextAlign.start;
    }
  }
  TextDecoration _buildDecoration(bool underline, bool strike) {
    if (underline && strike) {
      return TextDecoration.combine(
          [TextDecoration.underline, TextDecoration.lineThrough]);
    }
    if (underline) return TextDecoration.underline;
    if (strike) return TextDecoration.lineThrough;
    return TextDecoration.none;
  }
  @override
  Widget build(BuildContext context) {
    final paragraphs = _buildParagraphs();
    final baseStyle = GoogleFonts.manrope(
      fontSize: fontSize,
      height: lineHeight,
      color: color,
      fontWeight: FontWeight.w400,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: paragraphs.map((para) {
        if (para.spans.isEmpty) {
          return SizedBox(height: fontSize * lineHeight);
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: RichText(
            textAlign: para.align,
            text: TextSpan(style: baseStyle, children: para.spans),
          ),
        );
      }).toList(),
    );
  }
}

// ── Paragraph model ───────────────────────────────────────────────────────────
class _Para {
  final List<TextSpan> spans;
  final TextAlign align;
  const _Para({required this.spans, required this.align});
}

// ── Completion Dialog Widget ──────────────────────────────────────────────────
class _CompletionDialog extends StatelessWidget {
  final String storyType;
  final String title;
  final String author;
  final VoidCallback onContinue;
  const _CompletionDialog({
    required this.storyType,
    required this.title,
    required this.author,
    required this.onContinue,
  });
  String _getCompletionMessage() {
    switch (storyType.toLowerCase()) {
      case 'novel':
        return 'You\'ve completed this novel! 🎉';
      case 'poetry':
        return 'You\'ve finished this poem! ✨';
      case 'short story':
      case 'shortstory':
        return 'You\'ve finished this story! 📖';
      case 'fast fiction':
      case 'fastfiction':
        return 'You\'ve completed this quick read! ⚡';
      default:
        return 'Congratulations! 🎉';
    }
  }
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Celebration icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.inkMaroon.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.check_circle,
                  size: 48,
                  color: AppTheme.inkMaroon,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Message
            Text(
              _getCompletionMessage(),
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSerifDisplay(
                fontSize: 24,
                color: AppTheme.inkEspresso,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),
            // Story info
            Column(
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.inkEspresso,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'by $author',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: AppTheme.inkUmber.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            // Stats
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.inkBgCard,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline,
                      size: 18, color: Color(0xFF4CAF50)),
                  const SizedBox(width: 8),
                  Text(
                    'Story Completed',
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.inkEspresso,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios,
                      size: 14, color: AppTheme.inkUmber),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.inkMaroon,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Back to Library',
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────
class StoryReadScreen extends StatefulWidget {
  final Map<String, dynamic> story;
  const StoryReadScreen({
    super.key,
    required this.story,
  });
  @override
  State<StoryReadScreen> createState() => _StoryReadScreenState();
}

class _StoryReadScreenState extends State<StoryReadScreen>
    with SingleTickerProviderStateMixin {
  int _themeIndex = 0;
  double _fontSize = 16;
  _LineHeight _lineHeight = _LineHeight.comfortable;
  bool _showPanel = false;
  bool _loadingNext = false;
  double _readProgress = 0.0; // 0..1 across whole story
  bool _hasShowedCompletion = false;
  bool _reachedEnd = false;
  bool _isLiked = false;
  int _likeCount = 0;
  final ScrollController _scrollCtrl = ScrollController();
  late AnimationController _panelAnim;
  late Animation<double> _panelSlide;
  // ── Chapter state ─────────────────────────────
  String _currentContent = '';
  String _currentTitle = '';
  int _currentChapterNum = 0; // Novel: Prologue = 0, then 1,2,...
  int _totalChapters = 0; // Novel: includes prologue if present
  _ReadTheme get _theme => _kThemes[_themeIndex];
  @override
  void initState() {
    super.initState();
    _panelAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _panelSlide = CurvedAnimation(
      parent: _panelAnim,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    // Default values from payload:
    final isNovel = (widget.story['storyType'] ?? '') == 'Novel';
    final payloadChapter = widget.story['chapterNumber'] as int?;
    _currentChapterNum = isNovel ? (payloadChapter ?? 0) : (payloadChapter ?? 1);
    _currentTitle = widget.story['title'] ?? 'Untitled';
    _currentContent =
        widget.story['content'] ?? widget.story['body'] ?? 'No content available.';
    _loadTotalChapters();
    _initializeReadingProgress();
    _loadLikeStatus();
    _scrollCtrl.addListener(_onScroll);

    // If opened from a notification specifically for comments
    if (widget.story['openComments'] == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openCommentsModal();
      });
    }
  }

  /// Load like status for this story
  Future<void> _loadLikeStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    final storyId = widget.story['storyId'] as String? ?? '';
    if (storyId.isEmpty) return;

    try {
      // Get total likes - fetch all documents to count (safer approach)
      final likeSnap = await FirebaseFirestore.instance
          .collection('stories')
          .doc(storyId)
          .collection('likes')
          .get();
      
      final totalLikes = likeSnap.docs.length;

      // Check if current user liked
      bool userLiked = false;
      if (user != null) {
        final userLikeSnap = await FirebaseFirestore.instance
            .collection('stories')
            .doc(storyId)
            .collection('likes')
            .doc(user.uid)
            .get();
        userLiked = userLikeSnap.exists;
      }

      if (mounted) {
        setState(() {
          _likeCount = totalLikes;
          _isLiked = userLiked;
        });
      }
    } catch (e) {
      debugPrint('Error loading like status: $e');
      // Set defaults on error
      if (mounted) {
        setState(() {
          _likeCount = 0;
          _isLiked = false;
        });
      }
    }
  }

  /// Toggle like status
  Future<void> _toggleLike() async {
    final user = FirebaseAuth.instance.currentUser;
    final storyId = widget.story['storyId'] as String? ?? '';
    
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to like stories')),
      );
      return;
    }

    if (storyId.isEmpty) return;

    try {
      final likeRef = FirebaseFirestore.instance
          .collection('stories')
          .doc(storyId)
          .collection('likes')
          .doc(user.uid);

      if (_isLiked) {
        await likeRef.delete();
        setState(() {
          _isLiked = false;
          _likeCount = (_likeCount - 1).clamp(0, 999999);
        });
      } else {
        await likeRef.set({
          'timestamp': FieldValue.serverTimestamp(),
          'username': user.email?.split('@').first ?? 'Anonymous',
        });

        // Create a detailed notification for the author
        final authorId = widget.story['authorId'] as String? ?? '';
        final storyTitle = widget.story['title'] ?? 'your story';

        if (authorId.isNotEmpty && authorId != user.uid) {
          // Fetch the current user's profile info to get their display name
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
          final fromName = userDoc.data()?['displayName'] ?? 
                           userDoc.data()?['username'] ??
                           user.email?.split('@').first ?? 
                           'Someone';

          await FirebaseFirestore.instance
              .collection('users')
              .doc(authorId)
              .collection('notifications')
              .add({
            'title': 'New Like!',
            'body': '$fromName liked your story "$storyTitle"',
            'type': 'like',
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
            'fromId': user.uid,
            'storyId': storyId,
          });
          debugPrint('[Notification] Like notification sent to author: $authorId');
        }

        setState(() {
          _isLiked = true;
          _likeCount++;
        });
      }
    } catch (e) {
      debugPrint('Error toggling like: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  /// Initialize reading progress - mark as "in_progress" on first open
  Future<void> _initializeReadingProgress() async {
    final storyId = widget.story['storyId'] as String? ?? '';
    if (storyId.isEmpty) return;
    try {
      await _updateReadingProgress(
        storyId: storyId,
        status: ReadingStatus.inProgress,
        chapterNumber: _currentChapterNum,
        progressPercent: 0.0,
      );
      // The _readingStatus field was unused, so it has been removed.
    } catch (e) {
      debugPrint('Error initializing reading progress: $e');
    }
  }
  Future<void> _loadTotalChapters() async {
    final storyId = widget.story['storyId'] as String? ?? '';
    final storyType = widget.story['storyType'] ?? '';
    if (storyId.isEmpty) return;
    if (storyType != 'Novel') {
      if (mounted) {
        setState(() => _totalChapters = 1);
      }
      return;
    }
    try {
      final snap = await FirebaseFirestore.instance
          .collection('stories')
          .doc(storyId)
          .collection('chapters')
          .where('isPublished', isEqualTo: true)
          .count()
          .get();
      final total = snap.count ?? 0;
      if (mounted) {
        setState(() => _totalChapters = total);
        if (total > 0) {
          await _updateReadingProgress(
            storyId: storyId,
            status: ReadingStatus.inProgress,
            chapterNumber: _currentChapterNum,
            totalChapters: total,
            progressPercent: _readProgress,
          );
        }
      }
      // If novel and payload did not specify a chapter and Prologue exists, ensure we open it
      if ((widget.story['storyType'] ?? '') == 'Novel' && mounted) {
        if ((_currentChapterNum == 1 || _currentChapterNum == 0) && total > 0) {
          if ((_currentContent.isEmpty || _currentContent == 'No content available.') &&
              _currentChapterNum == 1) {
            await _jumpToChapterPreferingPrologue();
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading total chapters: $e');
    }
  }

  Future<int?> _getLastPublishedChapterNumber() async {
    final storyId = widget.story['storyId'] as String? ?? '';

    if (storyId.isEmpty) return null;

    try {
      final snap = await FirebaseFirestore.instance
          .collection('stories')
          .doc(storyId)
          .collection('chapters')
          .where('isPublished', isEqualTo: true)
          .orderBy('chapterNumber', descending: true)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) return null;

      return snap.docs.first.data()['chapterNumber'] as int?;
    } catch (e) {
      debugPrint('Error getting last chapter: $e');
      return null;
    }
  }

  Future<void> _jumpToChapterPreferingPrologue() async {
    final storyId = widget.story['storyId'] as String? ?? '';
    if (storyId.isEmpty) return;
    try {
      final proSnap = await FirebaseFirestore.instance
          .collection('stories')
          .doc(storyId)
          .collection('chapters')
          .where('isPublished', isEqualTo: true)
          .where('chapterNumber', isEqualTo: 0)
          .limit(1)
          .get();
      if (proSnap.docs.isNotEmpty) {
        if (mounted) { // Add mounted check
          final data = proSnap.docs.first.data() as Map<String, dynamic>;
          setState(() {
            _currentChapterNum = 0;
            _currentTitle = data['title'] ?? 'Untitled'; // Use title from data
            _currentContent = data['content'] ?? data['body'] ?? '';
            _readProgress = 0.0;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollCtrl.jumpTo(0));
        }
      }
    } catch (e) {
      debugPrint('Error jumping to prologue: $e');
    }
  }
  // Debounce guard to avoid repeated triggers at bottom
  DateTime? _lastBottomHit;
  void _onScroll() {
    if (_scrollCtrl.position.maxScrollExtent > 0) {
      final currentChapterProgress =
          (_scrollCtrl.position.pixels / _scrollCtrl.position.maxScrollExtent)
              .clamp(0.0, 1.0);
      final storyType = widget.story['storyType'] ?? '';
      final isNovel = storyType == 'Novel';
      double overallProgress;
      if (isNovel && _totalChapters > 0) {
        overallProgress =
            ((_currentChapterNum) + currentChapterProgress) / _totalChapters;
      } else {
        overallProgress = currentChapterProgress;
      }
      overallProgress = overallProgress.clamp(0.0, 1.0);
      if ((overallProgress - _readProgress).abs() > 0.005) {
        setState(() => _readProgress = overallProgress);
      }
      // Persist smooth progress
      final storyId = widget.story['storyId'] as String? ?? '';
      if (storyId.isNotEmpty) {
        _updateReadingProgress(
          storyId: storyId,
          status: ReadingStatus.inProgress,
          chapterNumber: _currentChapterNum,
          totalChapters: _totalChapters > 0 ? _totalChapters : null,
          progressPercent: overallProgress,
        );
      }
    }
    final storyType = widget.story['storyType'] ?? '';
    final isNovel = storyType == 'Novel';
    final atBottom = _scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 2;
    // For non-novels: trigger completion at end of page
    if (!isNovel && atBottom && !_hasShowedCompletion && !_reachedEnd) {
      final now = DateTime.now();
      if (_lastBottomHit == null ||
          now.difference(_lastBottomHit!) > const Duration(milliseconds: 600)) {
        _lastBottomHit = now;
        // small delay to stabilize at bottom
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && !_hasShowedCompletion && !_reachedEnd) {
            _handleReachedEnd();
          }
        });
      }
    }
    // For novels: try loading next chapter when near bottom; if no next, complete.
    if (isNovel &&
        _scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent - 20) {
      if (!_loadingNext && !_reachedEnd) {
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted && !_loadingNext && !_reachedEnd) {
            _tryLoadNextChapter();
          }
        });
      }
    }
  }
  /// Handle when user reaches the end of the story (all types)
  Future<void> _handleReachedEnd() async {
    setState(() => _reachedEnd = true);
    final storyId = widget.story['storyId'] as String? ?? '';
    if (storyId.isNotEmpty) {
      await _updateReadingProgress(
        storyId: storyId,
        status: ReadingStatus.completed,
        chapterNumber: _currentChapterNum,
        totalChapters: _totalChapters > 0 ? _totalChapters : 1,
        progressPercent: 1.0,
      );
    }
    if (mounted && !_hasShowedCompletion) {
      setState(() => _hasShowedCompletion = true);
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        _showCompletionDialog();
      }
    }
  }
  /// Show the completion celebration dialog
  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CompletionDialog(
        storyType: widget.story['storyType'] ?? 'Story',
        title: widget.story['title'] ?? 'Untitled',
        author: widget.story['authorUsername'] ?? 'Unknown',
        onContinue: () {
          Navigator.pop(context); // Close dialog
          Navigator.pop(context); // Return to library
        },
      ),
    );
  }
  /// Update reading progress in Firestore
  Future<void> _updateReadingProgress({
    required String storyId,
    required ReadingStatus status,
    required int chapterNumber,
    int? totalChapters,
    double? progressPercent, // 0..1
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final data = <String, dynamic>{
        'storyId': storyId,
        'status': status.value,
        'lastChapterNumber': chapterNumber,
        'lastOpenedAt': FieldValue.serverTimestamp(),
      };
      if (totalChapters != null && totalChapters > 0) {
        data['totalChapters'] = totalChapters;
      }
      if (progressPercent != null) {
        data['progressPercent'] = progressPercent.clamp(0.0, 1.0);
      }
      if (status == ReadingStatus.completed) {
        data['completedAt'] = FieldValue.serverTimestamp();
      }
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('readingProgress')
          .doc(storyId)
          .set(data, SetOptions(merge: true));
      debugPrint('✓ Reading progress updated: $storyId - ${status.value}');
    } catch (e) {
      debugPrint('✗ Error updating reading progress: $e');
    }
  }
  Future<void> _tryLoadNextChapter() async {
    final storyType = widget.story['storyType'] ?? '';
    final storyId = widget.story['storyId'] as String? ?? '';
    if (storyType != 'Novel' || storyId.isEmpty || _loadingNext) return;
    final maxScroll = _scrollCtrl.position.maxScrollExtent;
    final current = _scrollCtrl.position.pixels;
    if (maxScroll <= 0 || current < maxScroll - 80) return;
    setState(() {
      _readProgress = 1.0;
      _loadingNext = true;
    });
    await Future.delayed(const Duration(milliseconds: 600));
    try {
      final snap = await FirebaseFirestore.instance
          .collection('stories')
          .doc(storyId)
          .collection('chapters')
          .where('isPublished', isEqualTo: true)
          .where('chapterNumber', isGreaterThan: _currentChapterNum)
          .orderBy('chapterNumber')
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        final data = snap.docs.first.data();
        final int chNum =
            (data['chapterNumber'] as int?) ?? (_currentChapterNum + 1);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Loading Chapter $chNum...'),
              duration: const Duration(seconds: 1),
              backgroundColor: AppTheme.inkTerracotta,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
        await _updateReadingProgress(
          storyId: storyId,
          status: ReadingStatus.inProgress,
          chapterNumber: chNum,
          totalChapters: _totalChapters,
          progressPercent:
              (_totalChapters > 0) ? (chNum / _totalChapters).clamp(0.0, 1.0) : null,
        );
        await Future.delayed(const Duration(milliseconds: 400));
        if (mounted) {
          setState(() {
            _currentChapterNum = chNum;
            _currentTitle = data['title'] ?? 'Untitled';
            _currentContent = data['content'] ?? data['body'] ?? '';
            _readProgress = (_totalChapters > 0)
                ? (_currentChapterNum / _totalChapters).clamp(0.0, 1.0)
                : 0.0;
            _hasShowedCompletion = false;
            _reachedEnd = false;
            _loadingNext = false;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollCtrl.jumpTo(0));
        }
      } else {
        if (mounted) {
          setState(() => _reachedEnd = true);

          if (!_hasShowedCompletion) {
            setState(() => _hasShowedCompletion = true);

            if (storyId.isNotEmpty) {
              await _updateReadingProgress(
                storyId: storyId,
                status: ReadingStatus.completed,
                chapterNumber: _currentChapterNum,
                totalChapters: _totalChapters,
                progressPercent: 1.0,
              );
            }

            await Future.delayed(const Duration(milliseconds: 500));

            if (mounted) {
              _showCompletionDialog();
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading next chapter: $e');
    } finally {
      if (mounted) setState(() => _loadingNext = false);
    }
  }
  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    _panelAnim.dispose();
    super.dispose();
  }
  String _getChapterLabel() {
    final storyType = widget.story['storyType'] ?? '';
    final genre = widget.story['genre'] ?? '';
    if (storyType.isNotEmpty && genre.isNotEmpty) {
      return '${storyType.toUpperCase()} · ${genre.toUpperCase()}';
    } else if (storyType.isNotEmpty) {
      return storyType.toUpperCase();
    }
    return '';
  }
  void _openChaptersModal() {
    final storyId = widget.story['storyId'] as String? ?? '';
    if (storyId.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Story ID not found')));
      return;
    }
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'chapters-sidebar',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, animation, _, __) {
        final slide = Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        ));
        return Stack(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              child: const SizedBox.expand(),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: SlideTransition(
                position: slide,
                child: Material(
                  color: Colors.transparent,
                  child: SafeArea(
                    child: Container(
                      width: 360,
                      //width: MediaQuery.of(ctx).size.width * 0.82,
                      height: MediaQuery.of(ctx).size.height,
                      decoration: BoxDecoration(
                        color: AppTheme.inkCanvas,
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(24),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 32,
                            offset: const Offset(-6, 0),
                          ),
                        ],
                      ),
                      child: ChaptersListModal(
                        storyId: storyId,
                        currentChapter: _currentChapterNum,
                        isReadMode: true,
                        onClose: () => Navigator.of(ctx).pop(),
                        onChapterSelected: (chapterNum, data) {
                          Navigator.of(ctx).pop();
                          Future.microtask(
                              () => _handleChapterSelected(chapterNum, data));
                        },
                        onAddNewChapter: (_) {},
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  void _handleChapterSelected(int chapterNumber, Map<String, dynamic> data) {
    final storyId = widget.story['storyId'] as String? ?? '';
    if (storyId.isNotEmpty) {
      _updateReadingProgress(
        storyId: storyId,
        status: ReadingStatus.inProgress,
        chapterNumber: chapterNumber,
        totalChapters: _totalChapters,
        progressPercent: (_totalChapters > 0)
            ? (chapterNumber / _totalChapters).clamp(0.0, 1.0)
            : null,
      );
    }
    setState(() {
      _currentChapterNum = chapterNumber;
      _currentTitle = data['title'] ?? 'Untitled';
      _currentContent = data['content'] ?? data['body'] ?? 'No content available.';
      _readProgress =
          (_totalChapters > 0) ? (chapterNumber / _totalChapters).clamp(0.0, 1.0) : 0.0;
      _reachedEnd = false;
      _hasShowedCompletion = false;
    });
    _scrollCtrl.jumpTo(0);
  }
  void _togglePanel() {
    setState(() => _showPanel = !_showPanel);
    if (_showPanel) {
      _panelAnim.forward();
    } else {
      _panelAnim.reverse();
    }
  }

  void _openCommentsModal() {
    final storyId = widget.story['storyId'] as String? ?? '';
    final authorId = widget.story['authorId'] as String? ?? '';
    if (storyId.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Story ID not found')));
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,  
        minChildSize: 0.6,      
        maxChildSize: 0.6,      
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController, // ← pass this so inner scroll works
          child: CommentsSection(
            storyId: storyId,
            authorId: authorId,
            storyTitle: widget.story['title'] ?? 'your story',
          ),
        ),
      ),
    );
  }

  // ── Top bar icon button ───────────────────────────────
  Widget _iconBtn({
    required Widget child,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _theme.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(child: child),
      ),
    );
  }
  // ── Progress percentage string ────────────────────────
  String get _progressLabel => '${(_readProgress * 100).round()}%';
  // ── Chapter / page label ──────────────────────────────
  String _getPageLabel() {
    final type =
        (widget.story['contentType'] ?? '')
            .toString()
            .toLowerCase();

    if (type == 'prologue') {
      return 'Prologue';
    }

    if (type == 'epilogue') {
      return 'Epilogue';
    }

    return 'Chapter $_currentChapterNum';
  }
  @override
  Widget build(BuildContext context) {
    final storyType = widget.story['storyType'] ?? 'Short Story';
    final isNovel = storyType == 'Novel';
    final isPoetry = storyType == 'Poetry';
    final overlayStyle =
        _theme.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor: _theme.bg,
        body: SafeArea(
          child: Column(
            children: [
              // ── Top Bar ──────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    _iconBtn(
                      onTap: () => Navigator.pop(context),
                      child: Icon(Icons.arrow_back_ios_new,
                          size: 16, color: _theme.text),
                    ),
                    const Spacer(),
                    Text(
                      'Reading',
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _theme.text,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const SizedBox(width: 8),
                        // Like button
                        _iconBtn(
                          onTap: _toggleLike,
                          child: Icon(
                            _isLiked ? Icons.favorite : Icons.favorite_border,
                            size: 18,
                            color: _isLiked ? AppTheme.inkMaroon : _theme.text,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Comments button
                        _iconBtn(
                          onTap: _openCommentsModal,
                          child: Icon(Icons.comment_outlined,
                              size: 18, color: _theme.text),
                        ),
                        const SizedBox(width: 8),
                        // Chapters (novel only)
                        if (isNovel) ...[
                          _iconBtn(
                            onTap: _openChaptersModal,
                            child: Icon(Icons.menu_book_outlined,
                                size: 18, color: _theme.text),
                          ),
                          const SizedBox(width: 8),
                        ],
                        // Font / Settings — shows "Aa"
                        _iconBtn(
                          onTap: _togglePanel,
                          child: Text(
                            'Aa',
                            style: GoogleFonts.dmSerifDisplay(
                              fontSize: 14,
                              color: _theme.text,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ],
                ),
              ),
              // ── Scrollable content ────────────────────
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title block
                      Center(
                        child: Column(
                          children: [
                            Text(
                              isPoetry
                                  ? (widget.story['genre'] ?? '').toUpperCase()
                                  : _getChapterLabel(),
                              style: GoogleFonts.manrope(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2,
                                color: _theme.muted,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _currentTitle.isEmpty ? 'Untitled' : _currentTitle,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.dmSerifDisplay(
                                fontSize: _fontSize + 14,
                                color: _theme.text,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Author
                            if ((widget.story['authorUsername'] ?? '').isNotEmpty)
                              Text(
                                'by ${widget.story['authorUsername']}',
                                style: GoogleFonts.manrope(
                                  fontSize: 13,
                                  color: _theme.muted,
                                ),
                              ),
                            const SizedBox(height: 10),
                            // Word count + read time + engagement
                            _StoryStats(
                              story: widget.story,
                              theme: _theme,
                              likeCount: _likeCount,
                            ),
                          ],
                        ),
                      ),
                      // Divider
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 28),
                        child: Center(
                          child: Container(
                            width: 40,
                            height: 1,
                            color: _theme.border,
                          ),
                        ),
                      ),
                      // ── Story content ──
                      _DeltaText(
                        rawContent: _currentContent,
                        fontSize: _fontSize,
                        lineHeight: _lineHeight.value,
                        color: _theme.text,
                      ),
                      const SizedBox(height: 60),
                      // ── Chapter end / loader ──
                      if (_loadingNext)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: CircularProgressIndicator(
                                color: AppTheme.inkMaroon),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(bottom: 80),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(width: 36, height: 1, color: _theme.border),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(
                                    isNovel
                                        ? '— end of chapter —'
                                        : isPoetry
                                            ? '— end of poem —'
                                            : '— end of story —',
                                    style: GoogleFonts.manrope(
                                      fontSize: 11,
                                      letterSpacing: 1,
                                      color: _theme.muted.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ),
                                Container(width: 36, height: 1, color: _theme.border),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // ── Bottom Bar (progress + engagement) ───
              Container(
                decoration: BoxDecoration(
                  color: _theme.bg,
                  border: Border(
                    top: BorderSide(color: _theme.border, width: 1),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Progress row
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: _readProgress,
                                minHeight: 3,
                                backgroundColor: _theme.border,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                    AppTheme.inkMaroon),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _progressLabel,
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _theme.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Engagement row
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                      child: Row(
                        children: [
                          const Spacer(),
                          if (_getPageLabel().isNotEmpty)
                            Text(
                              _getPageLabel(),
                              style: GoogleFonts.manrope(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _theme.muted,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // ── Reading Settings Panel ────────────────
              SizeTransition(
                sizeFactor: _panelSlide,
                alignment: Alignment.centerLeft, // Replaced deprecated axisAlignment
                child: _ReadingSettingsPanel(
                  theme: _theme,
                  themeIndex: _themeIndex,
                  fontSize: _fontSize,
                  lineHeight: _lineHeight,
                  onClose: _togglePanel,
                  onThemeChanged: (i) => setState(() => _themeIndex = i),
                  onFontSizeChanged: (v) => setState(() => _fontSize = v),
                  onLineHeightChanged: (lh) => setState(() => _lineHeight = lh),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// ── Story stats row ───────────────────────────────────────────────────────────
class _StoryStats extends StatelessWidget {
  final Map<String, dynamic> story;
  final _ReadTheme theme;
  final int likeCount;
  const _StoryStats({
    required this.story,
    required this.theme,
    this.likeCount = 0,
  });
  int _wordCount(String content) {
    try {
      final decoded = jsonDecode(content);
      List<dynamic> ops = [];
      if (decoded is List) {
        ops = decoded;
      } else if (decoded is Map && decoded['ops'] is List) {
        ops = decoded['ops'] as List;
      }
      final text = ops.map((op) => op['insert'] ?? '').join('');
      return text.trim().split(RegExp(r'\s+')).length;
    } catch (_) {
      return content.trim().split(RegExp(r'\s+')).length;
    }
  }
  @override
  Widget build(BuildContext context) {
    final content = story['content'] ?? story['body'] ?? '';
    final words = _wordCount(content);
    final minutes = (words / 200).ceil();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.menu_book_outlined, size: 13, color: theme.muted),
        const SizedBox(width: 4),
        Text(
          '$words words',
          style: GoogleFonts.manrope(fontSize: 12, color: theme.muted),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Container(
              width: 3,
              height: 3,
              decoration: BoxDecoration(color: theme.muted, shape: BoxShape.circle)),
        ),
        Icon(Icons.access_time, size: 13, color: theme.muted),
        const SizedBox(width: 4),
        Text(
          '$minutes min read',
          style: GoogleFonts.manrope(fontSize: 12, color: theme.muted),
        ),
        if (likeCount > 0) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Container(
                width: 3,
                height: 3,
                decoration: BoxDecoration(color: theme.muted, shape: BoxShape.circle)),
          ),
          Icon(Icons.favorite, size: 13, color: AppTheme.inkMaroon),
          const SizedBox(width: 4),
          Text(
            '$likeCount',
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: theme.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
// ── Reading Settings Panel ────────────────────────────────────────────────────
class _ReadingSettingsPanel extends StatelessWidget {
  final _ReadTheme theme;
  final int themeIndex;
  final double fontSize;
  final _LineHeight lineHeight;
  final VoidCallback onClose;
  final ValueChanged<int> onThemeChanged;
  final ValueChanged<double> onFontSizeChanged;
  final ValueChanged<_LineHeight> onLineHeightChanged;
  const _ReadingSettingsPanel({
    required this.theme,
    required this.themeIndex,
    required this.fontSize,
    required this.lineHeight,
    required this.onClose,
    required this.onThemeChanged,
    required this.onFontSizeChanged,
    required this.onLineHeightChanged,
  });
  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: GoogleFonts.manrope(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: theme.muted,
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: theme.surface,
        border: Border(top: BorderSide(color: theme.border, width: 1)),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle + header
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: theme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Text(
                'Reading Settings',
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: theme.text,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onClose,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: theme.card,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close, size: 14, color: theme.muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Font size
          _sectionLabel('FONT SIZE'),
          Row(
            children: [
              _sizeBtn(
                label: 'A−',
                onTap: () => onFontSizeChanged((fontSize - 1).clamp(12, 28)),
                theme: theme,
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppTheme.inkTerracotta,
                    inactiveTrackColor: AppTheme.inkTerracotta.withValues(alpha: 0.2),
                    thumbColor: AppTheme.inkTerracotta,
                    overlayColor: AppTheme.inkTerracotta.withValues(alpha: 0.12),
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                  ),
                  child: Slider(
                    value: fontSize,
                    min: 12,
                    max: 28,
                    onChanged: onFontSizeChanged,
                  ),
                ),
              ),
              _sizeBtn(
                label: 'A+',
                onTap: () => onFontSizeChanged((fontSize + 1).clamp(12, 28)),
                theme: theme,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Theme
          _sectionLabel('THEME'),
          Row(
            children: List.generate(_kThemes.length, (i) {
              final t = _kThemes[i];
              final isActive = themeIndex == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onThemeChanged(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                    decoration: BoxDecoration(
                      color: t.bg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isActive ? AppTheme.inkTerracotta : t.border,
                        width: isActive ? 1.5 : 1,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Column(
                          children: [
                            Text(
                              'Aa',
                              style: GoogleFonts.dmSerifDisplay(
                                fontSize: 18,
                                color: t.text,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              t.name,
                              style: GoogleFonts.manrope(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: t.muted,
                              ),
                            ),
                          ],
                        ),
                        if (isActive)
                          Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: AppTheme.inkTerracotta,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check,
                                size: 10, color: Colors.white),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          // Line height
          _sectionLabel('LINE HEIGHT'),
          Row(
            children: _LineHeight.values.map((lh) {
              final isActive = lineHeight == lh;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onLineHeightChanged(lh),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    decoration: BoxDecoration(
                      color: theme.bg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isActive ? AppTheme.inkTerracotta : theme.border,
                        width: isActive ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        if (isActive)
                          const Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Icon(Icons.check_circle,
                                size: 13, color: AppTheme.inkTerracotta),
                          ),
                        Flexible(
                          child: Text(
                            lh.label,
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isActive
                                  ? AppTheme.inkTerracotta
                                  : theme.muted,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  Widget _sizeBtn({
    required String label,
    required VoidCallback onTap,
    required _ReadTheme theme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: theme.bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.border, width: 1),
        ),
        child: Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: theme.text,
          ),
        ),
      ),
    );
  }
}