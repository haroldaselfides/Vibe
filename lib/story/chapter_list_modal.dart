import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/new_app_theme.dart';
import '../theme/app_typography.dart';

class ChaptersListModal extends StatelessWidget {
  final String storyId;
  final int currentChapter;
  final Function(int chapterNumber, Map<String, dynamic> data) onChapterSelected;
  final Function(int chapterNumber) onAddNewChapter;
  final bool isReadMode;
  final VoidCallback? onClose; // ← nullable, not required

  const ChaptersListModal({
    super.key,
    required this.storyId,
    required this.currentChapter,
    required this.onChapterSelected,
    required this.onAddNewChapter,
    this.isReadMode = false,
    this.onClose, // ← optional
  });

  void _close(BuildContext context) {
    if (onClose != null) {
      onClose!();
    } else {
      Navigator.pop(context);
    }
  }

  String _getChapterLabel(int chapterNum, String contentType) {
    if (contentType == 'Prologue') return 'Prologue';
    if (contentType == 'Epilogue') return 'Epilogue';
    return 'Ch. $chapterNum';
  }

  String _getCircleLabel(int chapterNum, String contentType) {
    if (contentType == 'Prologue') return 'P';
    if (contentType == 'Epilogue') return 'E';
    return '$chapterNum';
  }

  Color _getContentTypeColor(String contentType) {
    switch (contentType) {
      case 'Prologue':
        return AppTheme.inkSage;
      case 'Epilogue':
        return AppTheme.inkEspresso;
      case 'Chapter':
      default:
        return AppTheme.inkMaroon;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.inkMaroon.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.menu_book_rounded,
                      color: AppTheme.inkMaroon, size: 20),
                ),
                const SizedBox(width: 10),
                Text('Chapters', style: AppTypography.headingSm),
                const Spacer(),
                GestureDetector(
                  onTap: () => _close(context),
                  child: const Icon(Icons.close,
                      color: AppTheme.inkEspresso, size: 22),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('stories')
                    .doc(storyId)
                    .collection('chapters')
                    .where('isPublished', isEqualTo: true)
                    .orderBy('chapterNumber', descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error loading chapters',
                          style: AppTypography.bodySm
                              .copyWith(color: AppTheme.inkTerracotta)),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: AppTheme.inkMaroon));
                  }

                  final chapters = snapshot.data?.docs ?? [];

                  if (chapters.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.menu_book_outlined,
                              size: 48,
                              color: AppTheme.inkUmber.withValues(alpha: 0.2)),
                          const SizedBox(height: 12),
                          Text('No chapters yet',
                              style: AppTypography.bodySm.copyWith(
                                  color: AppTheme.inkUmber
                                      .withValues(alpha: 0.5))),
                        ],
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── New Chapter button (write mode only) ──
                      if (!isReadMode) ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              int maxChapter = 0;
                              for (var doc in chapters) {
                                final d = doc.data() as Map<String, dynamic>;
                                final num = d['chapterNumber'] as int? ?? 0;
                                final type =
                                    d['contentType'] as String? ?? 'Chapter';
                                if (type == 'Chapter' && num > maxChapter) {
                                  maxChapter = num;
                                }
                              }
                              onAddNewChapter(maxChapter + 1);
                              _close(context);
                            },
                            icon: const Icon(Icons.add, size: 18),
                            label: Text('New chapter',
                                style: AppTypography.buttonMedium),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.inkMaroon,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ] else
                        const SizedBox(height: 8),

                      // ── Chapter count label ───────────
                      Text(
                        '${chapters.length} CHAPTER${chapters.length == 1 ? '' : 'S'}',
                        style: AppTypography.labelSm.copyWith(
                          color: AppTheme.inkUmber.withValues(alpha: 0.5),
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // ── Chapter list ──────────────────
                      Expanded(
                        child: ListView.separated(
                          itemCount: chapters.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 0),
                          itemBuilder: (context, index) {
                            final doc = chapters[index];
                            final data = doc.data() as Map<String, dynamic>;
                            final chapterNumber =
                                data['chapterNumber'] as int? ?? 0;
                            final contentType =
                                data['contentType'] as String? ?? 'Chapter';
                            final title = data['title'] as String? ?? '';
                            final isSelected = chapterNumber == currentChapter;
                            final typeColor = _getContentTypeColor(contentType);
                            final circleLabel =
                                _getCircleLabel(chapterNumber, contentType);
                            final chapterLabel =
                                _getChapterLabel(chapterNumber, contentType);

                            return GestureDetector(
                              onTap: () {
                                onChapterSelected(chapterNumber, data);
                              },
                              child: Container(
                                margin:
                                    const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.inkMaroon
                                          .withValues(alpha: 0.08)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                  border: isSelected
                                      ? Border.all(
                                          color: AppTheme.inkMaroon
                                              .withValues(alpha: 0.2),
                                          width: 1,
                                        )
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    // Circle number
                                    if (isSelected)
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: AppTheme.inkMaroon,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Center(
                                          child: Text(
                                            circleLabel,
                                            style: GoogleFonts.dmSerifDisplay(
                                              fontSize: 14,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      )
                                    else
                                      SizedBox(
                                        width: 36,
                                        child: Center(
                                          child: Text(
                                            circleLabel,
                                            style: GoogleFonts.dmSerifDisplay(
                                              fontSize: 15,
                                              color: AppTheme.inkUmber
                                                  .withValues(alpha: 0.4),
                                            ),
                                          ),
                                        ),
                                      ),
                                    const SizedBox(width: 10),

                                    // Labels + title
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                chapterLabel,
                                                style: AppTypography.labelMd
                                                    .copyWith(
                                                  color: isSelected
                                                      ? AppTheme.inkMaroon
                                                      : AppTheme.inkUmber
                                                          .withValues(
                                                              alpha: 0.6),
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 7,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: typeColor
                                                      .withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  contentType,
                                                  style: AppTypography.labelSm
                                                      .copyWith(
                                                    color: typeColor,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (title.isNotEmpty) ...[
                                            const SizedBox(height: 3),
                                            Text(
                                              title,
                                              style: GoogleFonts.dmSerifDisplay(
                                                fontSize: 15,
                                                color: AppTheme.inkEspresso,
                                                height: 1.2,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),

                                    // Trailing icon
                                    if (!isReadMode)
                                      isSelected
                                          ? GestureDetector(
                                              onTap: () {},
                                              child: Container(
                                                width: 32,
                                                height: 32,
                                                decoration: BoxDecoration(
                                                  color: AppTheme.inkMaroon,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(Icons.edit,
                                                    size: 15,
                                                    color: Colors.white),
                                              ),
                                            )
                                          : Icon(
                                              Icons.more_vert,
                                              size: 20,
                                              color: AppTheme.inkUmber
                                                  .withValues(alpha: 0.35),
                                            )
                                    else if (isSelected)
                                      Icon(
                                        Icons.check_circle,
                                        size: 18,
                                        color: AppTheme.inkMaroon
                                            .withValues(alpha: 0.6),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // ── Footer ────────────────────────
                      if (!isReadMode)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.drag_indicator,
                                  size: 16,
                                  color: AppTheme.inkUmber
                                      .withValues(alpha: 0.35)),
                              const SizedBox(width: 6),
                              Text(
                                'Drag to reorder',
                                style: AppTypography.caption.copyWith(
                                  color: AppTheme.inkUmber
                                      .withValues(alpha: 0.45),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        const SizedBox(height: 16),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}