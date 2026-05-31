import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';

/// Opens the chapters sidebar sliding in from the RIGHT with animation.
///
/// Call this from anywhere:
/// ```dart
/// EditorChaptersSidebar.show(
///   context: context,
///   storyId: storyId,
///   currentChapter: currentChapter,
///   onChapterSelected: (num, data) { ... },
///   onAddNewChapter: (num) { ... },
/// );
/// ```
class EditorChaptersSidebar {
  static void show({
    required BuildContext context,
    required String storyId,
    required int currentChapter,
    required void Function(int, Map<String, dynamic>) onChapterSelected,
    required void Function(int) onAddNewChapter,
  }) {
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

        final fade = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: const Interval(0.0, 0.3),
          ),
        );

        return FadeTransition(
          opacity: fade,
          child: Stack(
            children: [
              // Tap outside to dismiss
              GestureDetector(
                onTap: () => Navigator.of(ctx).pop(),
                behavior: HitTestBehavior.opaque,
                child: const SizedBox.expand(),
              ),
              // Sidebar panel
              Align(
                alignment: Alignment.centerRight,
                child: SlideTransition(
                  position: slide,
                  child: _EditorChaptersSidebarContent(
                    storyId: storyId,
                    currentChapter: currentChapter,
                    onChapterSelected: onChapterSelected,
                    onAddNewChapter: onAddNewChapter,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Internal widget ─────────────────────────────────────────────────────────

class _EditorChaptersSidebarContent extends StatefulWidget {
  final String storyId;
  final int currentChapter;
  final void Function(int, Map<String, dynamic>) onChapterSelected;
  final void Function(int) onAddNewChapter;

  const _EditorChaptersSidebarContent({
    required this.storyId,
    required this.currentChapter,
    required this.onChapterSelected,
    required this.onAddNewChapter,
  });

  @override
  State<_EditorChaptersSidebarContent> createState() =>
      _EditorChaptersSidebarContentState();
}

class _EditorChaptersSidebarContentState
    extends State<_EditorChaptersSidebarContent> {
  bool _addingChapter = false;

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _getChapterLabel(int num, String type) {
    if (type == 'Prologue') return 'Prologue';
    if (type == 'Epilogue') return 'Epilogue';
    return 'Ch. $num';
  }

  String _getBadge(int num, String type) {
    if (type == 'Prologue') return 'P';
    if (type == 'Epilogue') return 'E';
    return '$num';
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'Prologue': return AppTheme.inkTeal;
      case 'Epilogue': return AppTheme.inkTerracotta;
      case 'Chapter':  return AppTheme.inkIndigo;
      default:         return AppTheme.inkUmber;
    }
  }

  Future<void> _handleAddNewChapter() async {
    if (_addingChapter) return;
    setState(() => _addingChapter = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('stories')
          .doc(widget.storyId)
          .collection('chapters')
          .get();

      final existing = snap.docs
          .map((d) => (d.data()['chapterNumber'] as int?) ?? 0)
          .where((n) => n > 0 && n < 999)
          .toSet();

      int next = 1;
      while (existing.contains(next)) next++;

      if (mounted) {
        Navigator.pop(context);
        widget.onAddNewChapter(next);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _addingChapter = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not add chapter: $e'),
          backgroundColor: AppTheme.inkTerracotta,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Container(
          width: 300,
          height: screenH,
          decoration: const BoxDecoration(
            color: AppTheme.inkIvory,
            borderRadius: BorderRadius.horizontal(left: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 32,
                offset: Offset(-6, 0),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              _buildChapterList(),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppTheme.inkTerracotta.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.menu_book_rounded,
                    size: 17, color: AppTheme.inkTerracotta),
              ),
              const SizedBox(width: 10),
              const Text(
                'Chapters',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.inkEspresso,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppTheme.inkCanvas,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close,
                      size: 15, color: AppTheme.inkUmber),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // New chapter button
          GestureDetector(
            onTap: _addingChapter ? null : _handleAddNewChapter,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: AppTheme.inkTerracotta,
                borderRadius: BorderRadius.circular(12),
              ),
              child: _addingChapter
                  ? const Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.add, size: 16, color: Colors.white),
                        SizedBox(width: 5),
                        Text(
                          'New chapter',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Chapter list ─────────────────────────────────────────────────────────

  Widget _buildChapterList() {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('stories')
            .doc(widget.storyId)
            .collection('chapters')
            .orderBy('chapterNumber')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Error loading chapters',
                  style: TextStyle(fontSize: 12, color: AppTheme.inkUmber)),
            );
          }
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                  color: AppTheme.inkTerracotta, strokeWidth: 2),
            );
          }

          final chapters = snapshot.data!.docs;

          if (chapters.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.menu_book_outlined,
                      size: 40,
                      color: AppTheme.inkUmber.withValues(alpha: 0.2)),
                  const SizedBox(height: 10),
                  Text(
                    'No chapters yet',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.inkUmber.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Chapter count divider
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    Text(
                      '${chapters.length} ${chapters.length == 1 ? 'CHAPTER' : 'CHAPTERS'}',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: AppTheme.inkTerracotta.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 1,
                        color: AppTheme.inkUmber.withValues(alpha: 0.12),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  itemCount: chapters.length,
                  itemBuilder: (context, index) {
                    final doc = chapters[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final chapterNumber = data['chapterNumber'] as int? ?? 0;
                    final title = data['title'] as String? ?? 'Untitled';
                    final contentType = data['contentType'] as String? ?? 'Chapter';
                    final isSelected = chapterNumber == widget.currentChapter;

                    final tColor = _typeColor(contentType);
                    final badge  = _getBadge(chapterNumber, contentType);
                    final label  = _getChapterLabel(chapterNumber, contentType);

                    return GestureDetector(
                      onTap: () {
                        widget.onChapterSelected(chapterNumber, data);
                        Navigator.pop(context);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.inkTerracotta.withValues(alpha: 0.10)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.inkTerracotta.withValues(alpha: 0.40)
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Number badge
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.inkTerracotta
                                    : AppTheme.inkCanvas,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  badge,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? Colors.white
                                        : AppTheme.inkUmber,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Labels
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        label,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.2,
                                          color: isSelected
                                              ? AppTheme.inkTerracotta
                                              : tColor,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: tColor.withValues(alpha: 0.10),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          contentType,
                                          style: TextStyle(
                                            fontSize: 8,
                                            fontWeight: FontWeight.w700,
                                            color: tColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    title.isEmpty ? 'Untitled' : title,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.inkEspresso,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 4),
                            // Edit (selected) or 3-dot menu
                            if (isSelected)
                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: AppTheme.inkTerracotta,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.edit,
                                    size: 13, color: Colors.white),
                              )
                            else
                              GestureDetector(
                                onTap: () => _showChapterMenu(
                                    context, chapterNumber, data),
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.more_vert,
                                    size: 16,
                                    color: AppTheme.inkUmber
                                        .withValues(alpha: 0.4),
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
            ],
          );
        },
      ),
    );
  }

  // ── Footer ───────────────────────────────────────────────────────────────

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      child: Row(
        children: [
          Icon(Icons.drag_indicator,
              size: 14, color: AppTheme.inkUmber.withValues(alpha: 0.3)),
          const SizedBox(width: 5),
          Text(
            'Drag to reorder',
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.inkUmber.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  // ── Chapter context menu ──────────────────────────────────────────────────

  void _showChapterMenu(
      BuildContext context, int chapterNumber, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        decoration: BoxDecoration(
          color: AppTheme.inkIvory,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.edit_outlined,
                  color: AppTheme.inkIndigo),
              title: const Text('Edit chapter',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.inkEspresso,
                      fontSize: 14)),
              onTap: () {
                Navigator.pop(context);
                widget.onChapterSelected(chapterNumber, data);
                Navigator.pop(context);
              },
            ),
            Divider(
                height: 1,
                color: AppTheme.inkUmber.withValues(alpha: 0.08)),
            ListTile(
              leading: const Icon(Icons.delete_outline,
                  color: AppTheme.inkTerracotta),
              title: const Text('Delete chapter',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.inkTerracotta,
                      fontSize: 14)),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}