import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/new_app_theme.dart';

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
              GestureDetector(
                onTap: () => Navigator.of(ctx).pop(),
                behavior: HitTestBehavior.opaque,
                child: const SizedBox.expand(),
              ),
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

// ─── Internal widget ──────────────────────────────────────────────────────────

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

  // ── Helpers ───────────────────────────────────────────────────────────────

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
      case 'Prologue': return AppTheme.inkSage;
      case 'Epilogue': return AppTheme.inkGold;
      case 'Chapter':  return AppTheme.inkMaroon;
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
      while (existing.contains(next)) {
        next++;
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onAddNewChapter(next);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _addingChapter = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            'Could not add chapter: $e',
            style: GoogleFonts.manrope(fontSize: 13),
          ),
          backgroundColor: AppTheme.inkMaroon,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

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
            color: AppTheme.inkBgMain,
            borderRadius:
                BorderRadius.horizontal(left: Radius.circular(24)),
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

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      decoration: BoxDecoration(
        color: AppTheme.inkBgMain,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.inkUmber.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
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
                  color: AppTheme.inkMaroon.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.menu_book_rounded,
                    size: 17, color: AppTheme.inkMaroon),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chapters',
                    style: GoogleFonts.dmSerifDisplay(
                      fontSize: 18,
                      color: AppTheme.inkEspresso,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    'Tap to switch chapters',
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      color: AppTheme.inkUmber.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppTheme.inkBgCard,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close,
                      size: 15, color: AppTheme.inkUmber),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // New chapter button
          GestureDetector(
            onTap: _addingChapter ? null : _handleAddNewChapter,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _addingChapter
                    ? AppTheme.inkMaroon.withValues(alpha: 0.7)
                    : AppTheme.inkMaroon,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.inkMaroon,
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
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
                      children: [
                        const Icon(Icons.add, size: 16, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          'New Chapter',
                          style: GoogleFonts.manrope(
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

  // ── Chapter list ──────────────────────────────────────────────────────────

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
            return Center(
              child: Text(
                'Error loading chapters',
                style: GoogleFonts.manrope(
                    fontSize: 12, color: AppTheme.inkUmber),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                  color: AppTheme.inkMaroon, strokeWidth: 2),
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
                    style: GoogleFonts.manrope(
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
              // Chapter count row
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Text(
                      '${chapters.length} ${chapters.length == 1 ? 'CHAPTER' : 'CHAPTERS'}',
                      style: GoogleFonts.manrope(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: AppTheme.inkMaroon.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 1,
                        color: AppTheme.inkUmber.withValues(alpha: 0.1),
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
                    final doc  = chapters[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final chapterNumber =
                        data['chapterNumber'] as int? ?? 0;
                    final title =
                        data['title'] as String? ?? 'Untitled';
                    final contentType =
                        data['contentType'] as String? ?? 'Chapter';
                    final isSelected =
                        chapterNumber == widget.currentChapter;

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
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.inkMaroon
                                  .withValues(alpha: 0.08)
                              : AppTheme.inkBgCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.inkMaroon
                                    .withValues(alpha: 0.35)
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Number badge
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.inkMaroon
                                    : AppTheme.inkBgMain,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Center(
                                child: Text(
                                  badge,
                                  style: GoogleFonts.manrope(
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
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        label,
                                        style: GoogleFonts.manrope(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.3,
                                          color: isSelected
                                              ? AppTheme.inkMaroon
                                              : tColor,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: tColor
                                              .withValues(alpha: 0.10),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          contentType,
                                          style: GoogleFonts.manrope(
                                            fontSize: 8,
                                            fontWeight: FontWeight.w700,
                                            color: tColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    title.isEmpty ? 'Untitled' : title,
                                    style: GoogleFonts.dmSerifDisplay(
                                      fontSize: 14,
                                      color: AppTheme.inkEspresso,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 4),
                            // Edit icon (selected) or 3-dot menu
                            if (isSelected)
                              Container(
                                width: 26,
                                height: 26,
                                decoration: const BoxDecoration(
                                  color: AppTheme.inkMaroon,
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

  // ── Footer ────────────────────────────────────────────────────────────────

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      decoration: BoxDecoration(
        color: AppTheme.inkBgMain,
        border: Border(
          top: BorderSide(
            color: AppTheme.inkUmber.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.drag_indicator,
              size: 14,
              color: AppTheme.inkUmber.withValues(alpha: 0.3)),
          const SizedBox(width: 5),
          Text(
            'Drag to reorder',
            style: GoogleFonts.manrope(
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
          color: AppTheme.inkBgMain,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: AppTheme.inkUmber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Chapter title in sheet
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Text(
                data['title'] as String? ?? 'Untitled',
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 16,
                  color: AppTheme.inkEspresso,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Divider(
                height: 1,
                color: AppTheme.inkUmber.withValues(alpha: 0.08)),
            ListTile(
              leading: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.inkMaroon.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.edit_outlined,
                    size: 16, color: AppTheme.inkMaroon),
              ),
              title: Text(
                'Edit chapter',
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppTheme.inkEspresso,
                ),
              ),
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
              leading: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.inkMaroon.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.delete_outline,
                    size: 16, color: AppTheme.inkMaroon),
              ),
              title: Text(
                'Delete chapter',
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppTheme.inkMaroon,
                ),
              ),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}