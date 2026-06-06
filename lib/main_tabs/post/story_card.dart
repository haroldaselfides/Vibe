import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import 'post_screen_utils.dart';

class StoryCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final String authorName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const StoryCard({
    super.key,
    required this.docId,
    required this.data,
    required this.authorName,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final genre = data['genre'] ?? 'Fantasy';
    final title = data['title'] ?? 'Untitled';
    final storyType = data['storyType'] ?? 'Short Story';
    final wordCount = data['wordCount'] ?? 0;
    
    // Formatting timestamp safely
    String formattedDate = '';
    if (data['updatedAt'] != null) {
      try {
        final timestamp = data['updatedAt'];
        final dateTime = timestamp.toDate();
        formattedDate = DateFormat('MMM d, yyyy').format(dateTime);
      } catch (e) {
        formattedDate = '';
      }
    }

    // Get color profile matching the genre type
    final baseColor = PostScreenUtils.getGenreTagColor(genre);
    final pastelColor = _getRefinedPastelColor(genre);

    return GestureDetector(
      onTap: onEdit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 3D Bound Book Cover Component 
          AspectRatio(
            aspectRatio: 0.76, // Perfectly matching structural dimension ratio of your Library books
            child: Container(
              decoration: BoxDecoration(
                color: pastelColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  bottomLeft: Radius.circular(6),
                  topRight: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(3, 4),
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.4),
                    blurRadius: 0,
                    offset: const Offset(-1, 0), // Realistic paper page stack edge highlight
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Spine Crease Line Accent Layer
                  Positioned(
                    left: 8,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 1.5,
                      color: Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                  // Left Spine Shaded Binding Ribbon Overlay
                  Container(
                    width: 8,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.08),
                          Colors.white.withValues(alpha: 0.08),
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(6),
                        bottomLeft: Radius.circular(6),
                      ),
                    ),
                  ),
                  // Centered Genre Icon Display
                  Center(
                    child: Opacity(
                      opacity: 0.45,
                      child: Icon(
                        PostScreenUtils.getGenreIcon(genre),
                        size: 36,
                        color: AppTheme.inkEspresso,
                      ),
                    ),
                  ),
                  // Quick Management Actions Layer
                  Positioned(
                    top: 4,
                    right: 4,
                    child: PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert, 
                        size: 18, 
                        color: AppTheme.inkEspresso.withValues(alpha: 0.5)
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(maxWidth: 110),
                      color: AppTheme.inkBgMain,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onSelected: (val) {
                        if (val == 'delete') onDelete();
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'delete',
                          height: 36,
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, size: 16, color: AppTheme.inkTerracotta),
                              SizedBox(width: 6),
                              Text('Delete', style: TextStyle(fontSize: 12, color: AppTheme.inkTerracotta)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          
          // Book Descriptive Information Metadata
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: AppTheme.inkEspresso,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            storyType,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: baseColor,
            ),
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$wordCount words',
                style: TextStyle(
                  fontSize: 9,
                  color: AppTheme.inkUmber.withValues(alpha: 0.5),
                ),
              ),
              if (formattedDate.isNotEmpty)
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 9,
                    color: AppTheme.inkUmber.withValues(alpha: 0.5),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getRefinedPastelColor(String genre) {
    // Exactly mapping the soft, artistic cover palettes used in the library view
    switch (genre.toLowerCase()) {
      case 'romance':
        return const Color(0xFFF3D1D1); // Soft Valentine Rose
      case 'mystery':
      case 'detective':
        return const Color(0xFFD5D6EA); // Periwinkle Lavender Blue
      case 'fantasy':
      case 'adventure':
        return const Color(0xFFD1E7DD); // Soft Sage Mint Green
      default:
        return const Color(0xFFEFE5D8); // Warm Oatmeal Cream Dust
    }
  }
}