import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';

class ChaptersListModal extends StatelessWidget {
  final String storyId;
  final int currentChapter;
  final Function(int chapterNumber, Map<String, dynamic> data) onChapterSelected;
  final Function(int chapterNumber) onAddNewChapter;

  const ChaptersListModal({
    super.key,
    required this.storyId,
    required this.currentChapter,
    required this.onChapterSelected,
    required this.onAddNewChapter,
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppTheme.inkCanvas,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Chapters',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.inkEspresso,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppTheme.inkEspresso),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('stories')
                    .doc(storyId)
                    .collection('chapters')
                    .orderBy('chapterNumber', descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading chapters',
                        style: TextStyle(
                          color: AppTheme.inkTerracotta,
                          fontSize: 13,
                        ),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.inkTerracotta,
                      ),
                    );
                  }

                  final chapters = snapshot.data?.docs ?? [];

                  if (chapters.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.menu_book_outlined,
                            size: 48,
                            color: AppTheme.inkUmber.withValues(alpha: 0.25),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No chapters yet',
                            style: TextStyle(
                              color: AppTheme.inkUmber.withValues(alpha: 0.5),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: chapters.length,
                          itemBuilder: (context, index) {
                            final doc = chapters[index];
                            final data = doc.data() as Map<String, dynamic>;
                            final chapterNumber = data['chapterNumber'] as int? ?? 0;
                            final contentType = data['contentType'] as String? ?? 'Chapter';
                            final title = data['title'] as String? ?? '';
                            final wordCount = data['wordCount'] as int? ?? 0;
                            final isSelected = chapterNumber == currentChapter;
                            final contentTypeColor = _getContentTypeColor(contentType);

                            return GestureDetector(
                              onTap: () {
                                onChapterSelected(chapterNumber, data);
                                Navigator.pop(context);
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.inkIndigo
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppTheme.inkIndigo
                                        : AppTheme.inkUmber.withValues(alpha: 0.1),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              _getChapterLabel(chapterNumber, contentType),
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: isSelected
                                                    ? AppTheme.inkIndigo
                                                    : AppTheme.inkEspresso,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: contentTypeColor
                                                    .withValues(alpha: 0.12),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                contentType,
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w600,
                                                  color: contentTypeColor,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (title.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            title,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.inkUmber
                                                  .withValues(alpha: 0.7),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                    const Spacer(),
                                    Text(
                                      '$wordCount words',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.inkUmber
                                            .withValues(alpha: 0.55),
                                      ),
                                    ),
                                    if (isSelected) ...[
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.check_circle,
                                        size: 18,
                                        color: AppTheme.inkIndigo,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Find the highest chapter number (excluding prologue=0 and epilogue=999)
                            int maxChapter = 0;
                            for (var doc in chapters) {
                              final data = doc.data() as Map<String, dynamic>;
                              final chapterNum = data['chapterNumber'] as int? ?? 0;
                              final contentType = data['contentType'] as String? ?? 'Chapter';
                              
                              // Only count regular chapters (not Prologue or Epilogue)
                              if (contentType == 'Chapter' && chapterNum > maxChapter) {
                                maxChapter = chapterNum;
                              }
                            }
                            // Next chapter is maxChapter + 1
                            onAddNewChapter(maxChapter + 1);
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('New Chapter'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.inkTerracotta,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
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