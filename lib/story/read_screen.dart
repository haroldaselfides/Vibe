import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import '../theme/app_theme.dart';

// ── Reading theme data ────────────────────────────────────────────────────────
class _ReadTheme {
  final String name;
  final Color bg;
  final Color surface;
  final Color text;
  final Color muted;
  final Color border;

  const _ReadTheme({
    required this.name,
    required this.bg,
    required this.surface,
    required this.text,
    required this.muted,
    required this.border,
  });
}

const List<_ReadTheme> _kThemes = [
  _ReadTheme(
    name: 'Parchment',
    bg: Color(0xFFF5F0E8),
    surface: Color(0xFFEDE8DF),
    text: Color(0xFF2C1A0E),
    muted: Color(0xFF8C7B6B),
    border: Color(0xFFD5CEBF),
  ),
  _ReadTheme(
    name: 'White',
    bg: Color(0xFFFFFFFF),
    surface: Color(0xFFF2F2F2),
    text: Color(0xFF1A1A1A),
    muted: Color(0xFF888888),
    border: Color(0xFFE0E0E0),
  ),
  _ReadTheme(
    name: 'Dark',
    bg: Color(0xFF1E1E1E),
    surface: Color(0xFF2A2A2A),
    text: Color(0xFFE8E0D0),
    muted: Color(0xFF9A9080),
    border: Color(0xFF3A3A3A),
  ),
];

// ── Delta → RichText renderer ─────────────────────────────────────────────────
// Parses a Quill Delta JSON string (or raw list) and renders it as a Flutter
// RichText widget, honouring bold, italic, underline, and strikethrough.
class _DeltaText extends StatelessWidget {
  final String rawContent;
  final double fontSize;
  final Color color;

  const _DeltaText({
    required this.rawContent,
    required this.fontSize,
    required this.color,
  });

  // Parse ops into paragraphs: each paragraph has a list of spans + alignment
List<_Para> _buildParagraphs() {
  dynamic decoded;
  try {
    decoded = jsonDecode(rawContent);
  } catch (_) {
    // Plain text fallback — split by newline and render each line
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

    // Check if this op is purely newlines (e.g. "\n" or "\n\n")
    // In Quill Delta, a pure-newline op carries the block alignment
    // for ALL the newlines it contains.
    if (insert.isNotEmpty && insert.replaceAll('\n', '').isEmpty) {
      // Every \n in this op flushes the current spans with this alignment
      for (int i = 0; i < insert.length; i++) {
        paragraphs.add(_Para(spans: List.of(currentSpans), align: align));
        currentSpans = [];
      }
      continue;
    }

    // Mixed content op — split on \n
    final bool bold      = attrs is Map && attrs['bold']      == true;
    final bool italic    = attrs is Map && attrs['italic']    == true;
    final bool underline = attrs is Map && attrs['underline'] == true;
    final bool strike    = attrs is Map && attrs['strike']    == true;

    final parts = insert.split('\n');
    for (int i = 0; i < parts.length; i++) {
      final text = parts[i];
      if (text.isNotEmpty) {
        currentSpans.add(TextSpan(
          text: text,
          style: TextStyle(
            fontWeight: bold   ? FontWeight.bold   : FontWeight.normal,
            fontStyle:  italic ? FontStyle.italic  : FontStyle.normal,
            decoration: _buildDecoration(underline, strike),
            decorationColor: color,
          ),
        ));
      }
      // Embedded \n — flush with start since no block attrs here
      if (i < parts.length - 1) {
        paragraphs.add(_Para(spans: List.of(currentSpans), align: TextAlign.start));
        currentSpans = [];
      }
    }
  }

  // Flush remaining
  if (currentSpans.isNotEmpty) {
    paragraphs.add(_Para(spans: currentSpans, align: TextAlign.start));
  }

  return paragraphs;
}

  TextAlign _parseAlign(dynamic attrs) {
    if (attrs is! Map) return TextAlign.start;
    switch (attrs['align']) {
      case 'center': return TextAlign.center;
      case 'right':  return TextAlign.right;
      case 'justify': return TextAlign.justify;
      default:       return TextAlign.start;
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
    debugPrint('=== RAW DELTA: $rawContent');  
    final paragraphs = _buildParagraphs();
    final baseStyle = TextStyle(
      fontSize: fontSize,
      height: 1.9,
      color: color,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: paragraphs.map((para) {
        if (para.spans.isEmpty) {
          // Empty paragraph = spacer line
          return SizedBox(height: fontSize * 1.9);
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

  bool _showPanel = false;

  final ScrollController _scrollCtrl = ScrollController();

  late AnimationController _panelAnim;
  late Animation<double> _panelSlide;

  // ── Chapter state ─────────────────────────────────────────────
  String _currentContent = '';
  String _currentTitle = '';
  String _currentContentType = '';
  int _currentChapterNum = 0;

  _ReadTheme get _theme => _kThemes[_themeIndex];

  @override
  void initState() {
    super.initState();

    _panelAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    _panelSlide = CurvedAnimation(
      parent: _panelAnim,
      curve: Curves.easeOutCubic,
    );

    _currentChapterNum = widget.story['chapterNumber'] ?? 0;
    _currentTitle = widget.story['title'] ?? 'Untitled';
    _currentContentType = widget.story['contentType'] ?? 'Chapter';
    _currentContent =
        widget.story['content'] ?? widget.story['body'] ?? 'No content available.';

    _scrollCtrl.addListener(_onScroll);  
  }

    void _onScroll() {
      if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 80) {
        _tryLoadNextChapter();
      }
    }

    bool _loadingNext = false;

    Future<void> _tryLoadNextChapter() async {
      final storyType = widget.story['storyType'] ?? '';
      final storyId = widget.story['storyId'] as String? ?? '';
      
      // Only for novels with a valid storyId
      if (storyType != 'Novel' || storyId.isEmpty || _loadingNext) return;
      
      setState(() => _loadingNext = true);

      try {
        // Find the next chapter number
        final nextChapterNum = _currentChapterNum + 1;

        final snap = await FirebaseFirestore.instance
            .collection('stories')
            .doc(storyId)
            .collection('chapters')
            .where('chapterNumber', isGreaterThan: _currentChapterNum)
            .orderBy('chapterNumber')
            .limit(1)
            .get();

        if (snap.docs.isNotEmpty) {
          final data = snap.docs.first.data();
          final chapterNum = data['chapterNumber'] ?? nextChapterNum;

          // Show a snackbar hint
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Loading Chapter $chapterNum...'),
                duration: const Duration(seconds: 1),
                backgroundColor: AppTheme.inkTerracotta,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }

          await Future.delayed(const Duration(milliseconds: 400));

          if (mounted) {
            setState(() {
              _currentChapterNum = chapterNum;
              _currentTitle = data['title'] ?? 'Untitled';
              _currentContentType = data['contentType'] ?? 'Chapter';
              _currentContent = data['content'] ?? data['body'] ?? '';
            });

            // Scroll back to top for the new chapter
            _scrollCtrl.animateTo(
              0,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
            );
          }
        } else {
          // No more chapters — show end message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('You\'ve reached the end of this story.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
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

  // ── Get chapter label ───────────────────────────────────────────
  String _getChapterLabel() {
    final storyType = widget.story['storyType'] ?? '';
    if (storyType == 'Poetry') {
      // For poetry, show the poetry type (stored as genre) e.g. "HAIKU", "SONNET"
      final genre = widget.story['genre'] ?? _currentContentType;
      return genre.toString().toUpperCase();
    }
    if (_currentContentType == 'Prologue') {
      return 'PROLOGUE';
    } else if (_currentContentType == 'Epilogue') {
      return 'EPILOGUE';
    } else {
      return 'CHAPTER $_currentChapterNum';
    }
  }

  // ── Open chapter modal ────────────────────────────────────────
  void _openChaptersModal() {
    final storyId = widget.story['storyId'] as String? ?? '';

    if (storyId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Story ID not found')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChaptersListModal(
        storyId: storyId,
        currentChapterNum: _currentChapterNum,
        onChapterSelected: _handleChapterSelected,
      ),
    );
  }

  // ── Handle chapter tap ────────────────────────────────────────
  void _handleChapterSelected(int chapterNumber, Map<String, dynamic> data) {
    setState(() {
      _currentChapterNum = chapterNumber;
      _currentTitle = data['title'] ?? 'Untitled';
      _currentContentType = data['contentType'] ?? 'Chapter';
      _currentContent =
          data['content'] ?? data['body'] ?? 'No content available.';
      _scrollCtrl.jumpTo(0);
    });
  }

  void _togglePanel() {
    setState(() => _showPanel = !_showPanel);
    if (_showPanel) {
      _panelAnim.forward();
    } else {
      _panelAnim.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final storyType = widget.story['storyType'] ?? 'Short Story';
    final isNovel = storyType == 'Novel';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _theme.bg,
        body: SafeArea(
          child: Column(
            children: [
              // ── Top Bar ─────────────────────────────
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: _theme.surface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new,
                          size: 18,
                          color: _theme.text,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Reading',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _theme.text,
                      ),
                    ),
                    const Spacer(),
                    // ── Chapter Button ─────────────────
                    if (isNovel)
                      GestureDetector(
                        onTap: _openChaptersModal,
                        child: Container(
                          width: 38,
                          height: 38,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: _theme.surface,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.menu_book_outlined,
                            size: 18,
                            color: _theme.text,
                          ),
                        ),
                      ),
                    GestureDetector(
                      onTap: _togglePanel,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: _theme.surface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.tune,
                          size: 18,
                          color: _theme.text,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Content ─────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            // Chapter type label (PROLOGUE, CHAPTER 1, etc)
                            Text(
                              _getChapterLabel(),
                              style: TextStyle(
                                fontSize: 13,
                                letterSpacing: 2,
                                fontWeight: FontWeight.w600,
                                color: _theme.muted,
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Chapter title — italic + centered for poetry
                            Text(
                              _currentTitle.isEmpty
                                  ? 'Untitled'
                                  : _currentTitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: _fontSize + 12,
                                fontWeight: FontWeight.bold,
                                fontStyle: (widget.story['storyType'] == 'Poetry')
                                    ? FontStyle.normal
                                    : FontStyle.normal,
                                color: _theme.text,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      const SizedBox(height: 24),

                      // ── Story content (Delta-aware) ──
                      _DeltaText(
                        rawContent: _currentContent,
                        fontSize: _fontSize,
                        color: _theme.text,
                      ),

                      const SizedBox(height: 100),

                      // ── End of chapter indicator ──
                      if (_loadingNext)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: CircularProgressIndicator(color: AppTheme.inkTerracotta),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Column(
                              children: [
                                Container(
                                  width: 40,
                                  height: 1,
                                  color: AppTheme.inkUmber.withValues(alpha: 0.2),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '— end of chapter —',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.inkUmber.withValues(alpha: 0.4),
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 60),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // ── Settings Panel ─────────────────────
              SizeTransition(
                sizeFactor: _panelSlide,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  color: _theme.surface,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Font size
                      Text(
                        'FONT SIZE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _theme.muted,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _fontSize = (_fontSize - 1).clamp(12, 30);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: _theme.bg,
                                borderRadius: BorderRadius.circular(8),
                                border:
                                    Border.all(color: _theme.border, width: 1),
                              ),
                              child: Text(
                                'A−',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _theme.text,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: AppTheme.inkTerracotta,
                                inactiveTrackColor:
                                    AppTheme.inkTerracotta.withValues(alpha: 0.2),
                                thumbColor: AppTheme.inkTerracotta,
                                overlayColor:
                                    AppTheme.inkTerracotta.withValues(alpha: 0.12),
                              ),
                              child: Slider(
                                value: _fontSize,
                                min: 12,
                                max: 30,
                                onChanged: (v) {
                                  setState(() {
                                    _fontSize = v;
                                  });
                                },
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _fontSize = (_fontSize + 1).clamp(12, 30);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: _theme.bg,
                                borderRadius: BorderRadius.circular(8),
                                border:
                                    Border.all(color: _theme.border, width: 1),
                              ),
                              child: Text(
                                'A+',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _theme.text,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Theme
                      Text(
                        'BACKGROUND',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _theme.muted,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: List.generate(_kThemes.length, (i) {
                          final isActive = _themeIndex == i;
                          return GestureDetector(
                            onTap: () => setState(() => _themeIndex = i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              margin: const EdgeInsets.only(right: 10),
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: _kThemes[i].bg,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isActive
                                      ? AppTheme.inkTerracotta
                                      : _kThemes[i].border,
                                  width: isActive ? 2.5 : 1,
                                ),
                              ),
                              child: isActive
                                  ? Icon(Icons.check,
                                      size: 14,
                                      color: AppTheme.inkTerracotta)
                                  : null,
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Chapters Modal ────────────────────────────────────────────────────────────
class _ChaptersListModal extends StatelessWidget {
  final String storyId;
  final int currentChapterNum;
  final Function(int chapterNumber, Map<String, dynamic> data) onChapterSelected;

  const _ChaptersListModal({
    required this.storyId,
    required this.currentChapterNum,
    required this.onChapterSelected,
  });

  String _getChapterLabel(int chapterNum, String contentType) {
    if (contentType == 'Prologue') return 'Prologue';
    if (contentType == 'Epilogue') return 'Epilogue';
    return 'Chapter $chapterNum';
  }

  Color _getContentTypeColor(String contentType) {
    switch (contentType) {
      case 'Prologue':
        return AppTheme.inkTeal;
      case 'Epilogue':
        return AppTheme.inkTerracotta;
      case 'Chapter':
        return AppTheme.inkIndigo;
      default:
        return AppTheme.inkUmber;
    }
  }

  Color _getContentTypeBg(String contentType) {
    return _getContentTypeColor(contentType).withValues(alpha: 0.12);
  }

  String _getBadgeLabel(int chapterNum, String contentType) {
    if (contentType == 'Prologue') return 'P';
    if (contentType == 'Epilogue') return 'E';
    return '$chapterNum';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppTheme.inkIvory,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.wabiSand,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Text(
                  'Chapters',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.inkEspresso,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.inkCanvas,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: AppTheme.inkUmber,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('stories')
                  .doc(storyId)
                  .collection('chapters')
                  .orderBy('chapterNumber')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Error loading chapters',
                      style: TextStyle(color: AppTheme.inkUmber),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.inkTerracotta,
                    ),
                  );
                }

                final chapters = snapshot.data!.docs;

                if (chapters.isEmpty) {
                  return const Center(
                    child: Text(
                      'No chapters found',
                      style: TextStyle(color: AppTheme.inkUmber),
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 20, bottom: 12),
                      child: Text(
                        '${chapters.length} CHAPTERS',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.inkUmber,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        itemCount: chapters.length,
                        itemBuilder: (context, index) {
                          final doc = chapters[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final chapterNumber = data['chapterNumber'] ?? 0;
                          final title = data['title'] ?? 'Untitled';
                          final contentType = data['contentType'] ?? 'Chapter';
                          final isSelected = chapterNumber == currentChapterNum;

                          final typeColor = _getContentTypeColor(contentType);
                          final typeBg = _getContentTypeBg(contentType);
                          final badgeLabel = _getBadgeLabel(chapterNumber, contentType);

                          return GestureDetector(
                            onTap: () {
                              onChapterSelected(chapterNumber, data);
                              Navigator.pop(context);
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppTheme.inkCanvas,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.inkTerracotta
                                      : Colors.transparent,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppTheme.inkTerracotta
                                          : AppTheme.inkIvory,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Text(
                                        badgeLabel,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected
                                              ? AppTheme.inkIvory
                                              : AppTheme.inkUmber,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              _getChapterLabel(chapterNumber, contentType),
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 0.4,
                                                color: isSelected
                                                    ? AppTheme.inkTerracotta
                                                    : AppTheme.inkUmber,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 7, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: typeBg,
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                contentType,
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w700,
                                                  color: typeColor,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          title.isEmpty ? 'Untitled' : title,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.inkEspresso,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),

                                  if (isSelected) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 22,
                                      height: 22,
                                      decoration: const BoxDecoration(
                                        color: AppTheme.inkTerracotta,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        size: 13,
                                        color: AppTheme.inkIvory,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}