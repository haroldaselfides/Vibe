import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';

class EditorChaptersModal extends StatefulWidget {
  final String storyId;
  final int currentChapter;
  final void Function(int chapterNumber, Map<String, dynamic> data) onChapterSelected;
  final void Function(int chapterNumber) onAddNewChapter;

  const EditorChaptersModal({
    required this.storyId,
    required this.currentChapter,
    required this.onChapterSelected,
    required this.onAddNewChapter,
  });

  @override
  State<EditorChaptersModal> createState() => _EditorChaptersModalState();
}

class _EditorChaptersModalState extends State<EditorChaptersModal> {
  bool _addingChapter = false;

  String _getChapterLabel(int chapterNum, String contentType) {
    if (contentType == 'Prologue') return 'Prologue';
    if (contentType == 'Epilogue') return 'Epilogue';
    return 'Chapter $chapterNum';
  }

  String _getBadgeLabel(int chapterNum, String contentType) {
    if (contentType == 'Prologue') return 'P';
    if (contentType == 'Epilogue') return 'E';
    return '$chapterNum';
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

  Future<void> _handleAddNewChapter() async {
    if (_addingChapter) return;
    setState(() => _addingChapter = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('stories')
          .doc(widget.storyId)
          .collection('chapters')
          .get();

      final existingNumbers = snapshot.docs
          .map((d) => (d.data()['chapterNumber'] as int?) ?? 0)
          .where((n) => n > 0 && n < 999)
          .toSet();

      int nextNum = 1;
      while (existingNumbers.contains(nextNum)) {
        nextNum++;
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onAddNewChapter(nextNum);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _addingChapter = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not add chapter: $e'),
            backgroundColor: AppTheme.inkTerracotta,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: AppTheme.inkIvory,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                  onTap: _addingChapter ? null : _handleAddNewChapter,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppTheme.inkTerracotta.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppTheme.inkTerracotta.withValues(alpha: 0.3)),
                    ),
                    child: _addingChapter
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.inkTerracotta),
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.add,
                                  size: 14, color: AppTheme.inkTerracotta),
                              SizedBox(width: 4),
                              Text(
                                'New chapter',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.inkTerracotta,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(width: 8),
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
                  .doc(widget.storyId)
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
                        color: AppTheme.inkTerracotta),
                  );
                }

                final chapters = snapshot.data!.docs;

                if (chapters.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.menu_book_outlined,
                            size: 48,
                            color: AppTheme.inkUmber.withValues(alpha: 0.25)),
                        const SizedBox(height: 12),
                        Text(
                          'No chapters yet',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.inkUmber.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Save your first chapter to see it here.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.inkUmber.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 20, bottom: 12),
                      child: Text(
                        '${chapters.length} ${chapters.length == 1 ? 'CHAPTER' : 'CHAPTERS'}',
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
                        padding:
                            const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        itemCount: chapters.length,
                        itemBuilder: (context, index) {
                          final doc = chapters[index];
                          final data =
                              doc.data() as Map<String, dynamic>;
                          final chapterNumber =
                              data['chapterNumber'] as int? ?? 0;
                          final title =
                              data['title'] as String? ?? 'Untitled';
                          final contentType =
                              data['contentType'] as String? ?? 'Chapter';
                          final isSelected =
                              chapterNumber == widget.currentChapter;

                          final typeColor =
                              _getContentTypeColor(contentType);
                          final typeBg =
                              typeColor.withValues(alpha: 0.12);
                          final badgeLabel =
                              _getBadgeLabel(chapterNumber, contentType);

                          return GestureDetector(
                            onTap: () {
                              widget.onChapterSelected(chapterNumber, data);
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
                                      borderRadius:
                                          BorderRadius.circular(10),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              _getChapterLabel(
                                                  chapterNumber,
                                                  contentType),
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
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 7,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: typeBg,
                                                borderRadius:
                                                    BorderRadius.circular(10),
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
                                      decoration: BoxDecoration(
                                        color: AppTheme.inkTerracotta,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.edit,
                                        size: 12,
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