import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

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

  Color _getGenreColor(String genre) {
    switch (genre.toLowerCase()) {
      case 'romance':   return const Color(0xFFD4557E);
      case 'mystery':   return const Color(0xFF7B68A6);
      case 'fantasy':   return const Color(0xFF5FA35C);
      case 'sci-fi':    return const Color(0xFF2E7D9F);
      case 'drama':     return const Color(0xFFB8860B);
      case 'horror':    return const Color(0xFF4A4A4A);
      case 'thriller':  return const Color(0xFFC85A54);
      default:          return const Color(0xFF8B8B8B);
    }
  }

  LinearGradient _getCoverGradient(String genre) {
    final color = _getGenreColor(genre);
    return LinearGradient(
      colors: [
        color.withValues(alpha: 0.95),
        color.withValues(alpha: 0.6),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  IconData _getGenreIcon(String genre) {
    switch (genre.toLowerCase()) {
      case 'romance':   return Icons.favorite_outline;
      case 'mystery':   return Icons.search;
      case 'fantasy':   return Icons.auto_awesome_outlined;
      case 'sci-fi':    return Icons.rocket_launch_outlined;
      case 'drama':     return Icons.theater_comedy_outlined;
      case 'horror':    return Icons.dark_mode_outlined;
      case 'thriller':  return Icons.local_police_outlined;
      default:          return Icons.category_outlined;
    }
  }
  @override
Widget build(BuildContext context) {
  final genre = data['genre'] ?? 'Fantasy';
  final title = data['title'] ?? 'Untitled';
  final author = authorName.isEmpty ? 'Unknown' : authorName;
  final genreColor = _getGenreColor(genre);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      // ── Cover (no buttons here anymore) ─────────────────────────
      Container(
        width: double.infinity,
        height: 150,
        decoration: BoxDecoration(
          gradient: _getCoverGradient(genre),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Icon(
              _getGenreIcon(genre),
              size: 38,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ],
        ),
      ),

      const SizedBox(height: 8),

      // ── Title ────────────────────────────────────────────────────
      Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppTheme.inkEspresso,
          height: 1.2,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),

      const SizedBox(height: 2),

      // ── Author ───────────────────────────────────────────────────
      Text(
        'By $author',
        style: TextStyle(
          fontSize: 10,
          color: AppTheme.inkUmber.withValues(alpha: 0.6),
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),

      const SizedBox(height: 5),

      // ── Genre badge ──────────────────────────────────────────────
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: genreColor.withValues(alpha: 0.10),
          border: Border.all(
            color: genreColor.withValues(alpha: 0.25),
            width: 0.8,
          ),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_getGenreIcon(genre), size: 9, color: genreColor),
            const SizedBox(width: 3),
            Text(
              genre,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: genreColor,
              ),
            ),
          ],
        ),
      ),

      const SizedBox(height: 8),

      // ── Edit / Delete buttons ────────────────────────────────────
      Row(
        children: [
          // Edit
          Expanded(
            child: GestureDetector(
              onTap: onEdit,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.inkTerracotta.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.inkTerracotta.withValues(alpha: 0.25),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.edit_rounded,
                      size: 14,
                      color: AppTheme.inkTerracotta,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'Edit',
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
          ),

          const SizedBox(width: 6),

          // Delete
          Expanded(
            child: GestureDetector(
              onTap: onDelete,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.20),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.delete_rounded,
                      size: 14,
                      color: Colors.red.shade400,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'Delete',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ],
  );
}
}