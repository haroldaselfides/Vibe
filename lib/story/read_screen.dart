import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _panelAnim.dispose();
    super.dispose();
  }

  // ── Get chapter label ───────────────────────────────────────────
  String _getChapterLabel() {
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
                            // Chapter title
                            Text(
                              _currentTitle.isEmpty
                                  ? 'Untitled'
                                  : _currentTitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: _fontSize + 12,
                                fontWeight: FontWeight.bold,
                                color: _theme.text,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      const SizedBox(height: 24),
                      // Story content
                      Text(
                        _currentContent,
                        style: TextStyle(
                          fontSize: _fontSize,
                          height: 1.9,
                          color: _theme.text,
                        ),
                      ),
                      const SizedBox(height: 100),
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

  /// Badge label color per content type (using AppTheme)
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

  /// Badge background per content type
  Color _getContentTypeBg(String contentType) {
    return _getContentTypeColor(contentType).withValues(alpha: 0.12);
  }

  /// Number badge letter for Prologue / Epilogue
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
          // ── Drag handle ──────────────────────────
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

          // ── Header ──────────────────────────────
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

          // ── Chapter list ─────────────────────────
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

                // ── Chapter count label ──────────────
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
                                  // ── Number badge ──────────────
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

                                  // ── Chapter info ──────────────
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Label + type tag row
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
                                        // Chapter title
                                        Text(
                                          title.isEmpty ? 'Untitled' : title,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: isSelected
                                                ? AppTheme.inkEspresso
                                                : AppTheme.inkEspresso,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),

                                  // ── Check icon ────────────────
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